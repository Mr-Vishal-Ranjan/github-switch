# ╔══════════════════════════════════════════════════════════════╗
# ║                  GitHub Switch (githubswitch)                ║
# ║          Manage multiple GitHub accounts on one machine      ║
# ║          Contact: mr.vishalranjan007@gmail.com               ║
# ╚══════════════════════════════════════════════════════════════╝

$SSH_DIR = Join-Path $HOME ".ssh"
$CONF_FILE = Join-Path $SSH_DIR "githubswitch.conf"
$SSH_CONFIG = Join-Path $SSH_DIR "config"

# ── Colors ────────────────────────────────────────────────────
function Write-Info($msg)    { Write-Host "  ℹ  $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "  ✔  $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "  ⚠  $msg" -ForegroundColor Yellow }
function Write-ErrorMsg($msg){ Write-Host "  ✖  $msg" -ForegroundColor Red }
function Write-Divider       { Write-Host "  " + ("─" * 42) -ForegroundColor DarkGray }

# ── Helpers ───────────────────────────────────────────────────
function Parse-GHRepo($input) {
    # Handles: https://github.com/user/repo, git@github.com:user/repo.git, user/repo
    $repo = $input -replace '.*github\.com[:/]', '' -replace '\.git$', ''
    return $repo
}

function Show-Banner {
    Clear-Host
    Write-Host "  ╔════════════════════════════════════════════╗" -ForegroundColor Blue -Object ( [PSObject]@{ } )
    Write-Host "  ║         GitHub Switch — githubswitch       ║" -ForegroundColor Blue
    Write-Host "  ╚════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Wait-Pause {
    Write-Host ""
    Read-Host "  Press Enter to continue..."
}

function Validate-Name($name) {
    if ($name -match '^[a-z]+$') { return $true }
    Write-ErrorMsg "Invalid name '$name'. Only lowercase letters (a-z) allowed."
    return $false
}

function Get-AccountExists($name) {
    if (-not (Test-Path $CONF_FILE)) { return $false }
    $content = Get-Content $CONF_FILE
    return $content -match "^\[account:$name\]"
}

function Get-ConfValue($account, $key) {
    if (-not (Test-Path $CONF_FILE)) { return $null }
    $found = $false
    foreach ($line in Get-Content $CONF_FILE) {
        if ($line -eq "[account:$account]") { $found = $true; continue }
        if ($found -and $line -match "^$($key)=") {
            return $line -replace "^$($key)=", ""
        }
        if ($found -and $line -match "^\[account:") { break }
    }
    return $null
}

function Get-AllAccounts {
    if (-not (Test-Path $CONF_FILE)) { return @() }
    return Get-Content $CONF_FILE | Where-Object { $_ -match "^\[account:" } | ForEach-Object { $_ -replace "\[account:", "" -replace "\]", "" }
}

function Get-Repos($account) {
    if (-not (Test-Path $CONF_FILE)) { return @() }
    $repos = @()
    $found = $false
    foreach ($line in Get-Content $CONF_FILE) {
        if ($line -eq "[account:$account]") { $found = $true; continue }
        if ($found -and $line -match "^repo=") {
            $repos += ($line -replace "^repo=", "")
        }
        if ($found -and $line -match "^\[account:") { break }
    }
    return $repos
}

function Select-Account {
    $accounts = Get-AllAccounts
    if ($accounts.Count -eq 0) {
        Write-Warn "No accounts found."
        return $null
    }

    Write-Host "  Select account:`n"
    for ($i = 0; $i -lt $accounts.Count; $i++) {
        Write-Host "    [$($i+1)] $($accounts[$i])" -ForegroundColor Cyan
    }
    Write-Host "    [b] Back to previous menu"
    Write-Host "    [q] Quit program"
    Write-Host ""
    
    $choice = Read-Host "  Enter choice (1-$($accounts.Count)/b/q)"
    
    if ($choice -eq 'q') { 
        Write-Host "`n  Bye!" -ForegroundColor Cyan
        exit 
    }
    if ($choice -eq 'b') { return "back" }

    $idx = [int]$choice - 1
    if ($idx -ge 0 -and $idx -lt $accounts.Count) {
        return $accounts[$idx]
    }
    
    Write-ErrorMsg "Invalid choice."
    return $null
}

function Write-AccountConf($name, $email, $keyPath) {
    $block = "`n[account:$name]`nemail=$email`nkey=$keyPath"
    Add-Content $CONF_FILE $block
}

function Append-RepoToAccount($account, $repoPath) {
    $content = Get-Content $CONF_FILE
    $newContent = @()
    $found = $false
    foreach ($line in $content) {
        $newContent += $line
        if ($line -eq "[account:$account]") { $found = $true }
        if ($found -and ($line -match "^repo=" -or $line -eq "[account:$account]")) {
            # We'll wait until the end of the block or end of file
        }
    }
    
    # Simpler approach for PowerShell: Rebuild the file
    $finalContent = @()
    $inTarget = $false
    $added = $false
    foreach ($line in $content) {
        if ($line -match "^\[account:" -and $inTarget -and -not $added) {
            $finalContent += "repo=$repoPath"
            $added = $true
            $inTarget = $false
        }
        if ($line -eq "[account:$account]") { $inTarget = $true }
        $finalContent += $line
    }
    if ($inTarget -and -not $added) {
        $finalContent += "repo=$repoPath"
    }
    $finalContent | Set-Content $CONF_FILE
}

function Generate-Key($name, $email) {
    $keyPath = Join-Path $SSH_DIR "githubswitch_$name"
    if (Test-Path $keyPath) {
        Write-Warn "Key already exists for '$name' at $keyPath"
        return $keyPath
    }

    Write-Info "Generating SSH key for '$name'..."
    ssh-keygen -t ed25519 -C "$email" -f "$keyPath" -N '""' -q
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Failed to generate SSH key for '$name'"
        return $null
    }
    Write-Success "Key generated: $keyPath"
    return $keyPath
}

function Write-SSHConfig($name, $keyPath) {
    $host = "github-$name"
    if (Test-Path $SSH_CONFIG) {
        if (Select-String -Path $SSH_CONFIG -Pattern "Host $host") { return }
    }

    $block = @"

# githubswitch:$name
Host $host
    HostName github.com
    User git
    IdentityFile $keyPath
    IdentitiesOnly yes
"@
    Add-Content $SSH_CONFIG $block
}

function Display-KeyInstructions($name, $keyPath) {
    $pubKey = Get-Content "$keyPath.pub"
    Write-Host ""
    Write-Host "  ── SSH Key for account: $name ──────────────────────" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  $pubKey" -ForegroundColor Yellow
    Write-Host ""
    Write-Divider
    Write-Info "To add this key to your GitHub account:"
    Write-Host "  1. Copy the key above"
    Write-Host "  2. Open: https://github.com/settings/ssh/new" -ForegroundColor Cyan
    Write-Host "  3. Title: anything (e.g. $name-machine)"
    Write-Host "  4. Paste the key → Click Add SSH key"
    Write-Host ""
    Write-Divider
}

# ══════════════════════════════════════════════════════════════
#  SETUP
# ══════════════════════════════════════════════════════════════
function Run-Setup {
    Show-Banner
    Write-Host "  Welcome! Let's set up GitHub Switch."
    Write-Info "Config will be saved to: $CONF_FILE"
    Write-Host ""

    if (-not (Test-Path $SSH_DIR)) { New-Item -ItemType Directory -Path $SSH_DIR }
    "# githubswitch config — do not edit manually`n# Created: $(Get-Date)" | Set-Content $CONF_FILE

    $count = Read-Host "  How many GitHub accounts do you want to manage?"
    while ($count -notmatch '^[1-9][0-9]*$') {
        Write-ErrorMsg "Please enter a valid number."
        $count = Read-Host "  How many GitHub accounts do you want to manage?"
    }

    $accounts = @()
    for ($i = 1; $i -le $count; $i++) {
        Write-Host "`n  Account $i of $count"
        $name = Read-Host "  Name (e.g. work / personal)"
        while (-not (Validate-Name $name)) {
            $name = Read-Host "  Name (e.g. work / personal)"
        }
        $email = Read-Host "  GitHub email for '$name'"
        $accounts += @{ name = $name; email = $email }
    }

    Write-Divider
    Write-Info "Generating SSH keys..."
    foreach ($acc in $accounts) {
        $kp = Generate-Key $acc.name $acc.email
        Write-AccountConf $acc.name $acc.email $kp
        Write-SSHConfig $acc.name $kp
    }

    Write-Divider
    Write-Success "All keys generated! Now add them to GitHub."
    foreach ($acc in $accounts) {
        $kp = Join-Path $SSH_DIR "githubswitch_$($acc.name)"
        Display-KeyInstructions $acc.name $kp
        Read-Host "  Press Enter to continue..."
    }
}

# ══════════════════════════════════════════════════════════════
#  MENUS
# ══════════════════════════════════════════════════════════════
function Menu-AddRepo {
    Show-Banner
    Write-Host "  Add / Register a Repo`n"
    $account = Select-Account
    if ($account -eq $null -or $account -eq "back") { return }

    $email = Get-ConfValue $account "email"
    $keyPath = Get-ConfValue $account "key"

    Write-Host "`n  What do you want to do?"
    Write-Host "    [1] Clone a remote GitHub repo"
    Write-Host "    [2] Register an existing local repo"
    $choice = Read-Host "  Enter choice"

    if ($choice -eq "1") {
        $ghInput = Read-Host "  GitHub repo URL or path"
        $destDir = Read-Host "  Local folder name (Enter for default)"
        
        $ghRepo = Parse-GHRepo $ghInput
        $host = "github-$account"
        $cloneUrl = "git@$host:$ghRepo.git"
        $finalDest = if ($destDir) { $destDir } else { Split-Path $ghRepo -Leaf }

        Write-Info "Cloning $cloneUrl..."
        git clone $cloneUrl $finalDest
        if ($LASTEXITCODE -eq 0) {
            $absPath = Resolve-Path $finalDest
            git -C $finalDest config user.name $account
            git -C $finalDest config user.email $email
            Append-RepoToAccount $account $absPath
            Write-Success "Repo tracked and identity set."
        }
    } elseif ($choice -eq "2") {
        $repoPath = Read-Host "  Path to local repo (Enter for current directory '.')"
        if (-not $repoPath) { $repoPath = "." }
        $absPath = Resolve-Path $repoPath
        
        if (-not (Test-Path (Join-Path $absPath ".git"))) {
            Write-ErrorMsg "Not a git repo."
        } else {
            git -C $absPath config user.name $account
            git -C $absPath config user.email $email
            Append-RepoToAccount $account $absPath
            Write-Success "Repo registered."
        }
    }
    Wait-Pause
}

function Menu-AddAccount {
    Show-Banner
    Write-Host "  Add a New GitHub Account`n"
    $name = Read-Host "  Account name"
    while (-not (Validate-Name $name) -or (Get-AccountExists $name)) {
        if (Get-AccountExists $name) { Write-ErrorMsg "Account exists." }
        $name = Read-Host "  Account name"
    }
    $email = Read-Host "  GitHub email"
    $kp = Generate-Key $name $email
    Write-AccountConf $name $email $kp
    Write-SSHConfig $name $kp
    Display-KeyInstructions $name $kp
    Wait-Pause
}

function Menu-ShowAccounts {
    Show-Banner
    $accounts = Get-AllAccounts
    foreach ($acc in $accounts) {
        $email = Get-ConfValue $acc "email"
        Write-Host "  ● $acc" -ForegroundColor Green
        Write-Host "    Email: $email"
        $repos = Get-Repos $acc
        if ($repos.Count -gt 0) {
            Write-Host "    Repos:"
            foreach ($r in $repos) { Write-Host "      → $r" -ForegroundColor Gray }
        }
        Write-Divider
    }
    Wait-Pause
}

function Menu-DestroyAll {
    Show-Banner
    Write-Warn "DESTROY ALL? This will remove all githubswitch config and keys."
    $confirm = Read-Host "  Type 'DESTROY' to confirm"
    if ($confirm -eq "DESTROY") {
        Remove-Item $CONF_FILE -ErrorAction SilentlyContinue
        # Simple cleanup (doesn't touch SSH config in this MVP for safety, but could)
        Write-Success "Deleted $CONF_FILE. Please manually clean ~/.ssh/config if needed."
    }
    Wait-Pause
}

# ══════════════════════════════════════════════════════════════
#  MAIN LOOP
# ══════════════════════════════════════════════════════════════
if (-not (Test-Path $CONF_FILE)) { Run-Setup }

while ($true) {
    Show-Banner
    Write-Host "  Main Menu`n"
    Write-Host "    [1] Add / Clone Repo"
    Write-Host "    [2] Add Remote to Project"
    Write-Host "    [3] Add Account"
    Write-Host "    [4] Show All Accounts"
    Write-Host "    [q] Quit"
    Write-Host ""
    $choice = Read-Host "  Enter choice"

    switch ($choice) {
        "1" { Menu-AddRepo }
        "2" { Write-Host "Not implemented yet"; Wait-Pause }
        "3" { Menu-AddAccount }
        "4" { Menu-ShowAccounts }
        "q" { exit }
    }
}
