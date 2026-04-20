# GitHub Switch (githubswitch)

Manage multiple GitHub accounts on a single machine with ease. `githubswitch` automates the complex process of managing SSH keys, SSH configurations, and Git identities, allowing you to switch between work, personal, or multiple client accounts seamlessly.

## 🚀 Features

- **Multi-Account Support**: Easily add and manage separate GitHub accounts.
- **SSH Key Automation**: Automatically generates Ed25519 SSH keys for each account.
- **Dynamic SSH Config**: Updates your `~/.ssh/config` with host aliases (e.g., `github-work`, `github-personal`).
- **Git Identity Management**: Sets the local repository `user.name` and `user.email` automatically.
- **Repo Registration**: Clone new repos or register existing ones with the correct account context.
- **Add Remote**: Quickly link local projects to a GitHub account.
- **Interactive CLI**: Simple, user-friendly terminal interface.

---

## 🛠 Installation

### One-Liner (Quick Install)
```bash
curl -sSL https://raw.githubusercontent.com/Mr-Vishal-Ranjan/github-switch/main/githubswitch -o githubswitch && chmod +x githubswitch
```

### Manual Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/Mr-Vishal-Ranjan/github-switch.git
   ```
2. Make the script executable:
   ```bash
   cd github-switch
   chmod +x githubswitch
   ```
3. (Optional) Add it to your PATH:
   ```bash
   sudo mv githubswitch /usr/local/bin/
   ```

---

## 📖 How to Use

1. **Run the script**:
   ```bash
   ./githubswitch
   ```
2. **Initial Setup**: The first time you run it, you'll be prompted to set up your accounts. You'll need to copy the generated SSH keys to your GitHub settings (links are provided in the script).
3. **Add a Repository**:
   - Choose **Add / Clone Repo** to start working on a project.
   - The script will configure the remote URL and local identity automatically.
4. **Link an Existing Project**:
   - Choose **Add Remote to Project** to link a local folder to a GitHub account.

### Main Menu Overview
- **Add / Clone Repo**: Clone from GitHub or register an existing folder.
- **Add Remote to Project**: Initialize Git and add a GitHub remote.
- **Add Account**: Setup a new GitHub account and generate its key.
- **Show All Accounts**: List all managed accounts and their linked repositories.
- **Show SSH Key**: Display the public key for any managed account.
- **Delete Account**: Safely remove an account and its keys.
- **Destroy All**: Completely remove all `githubswitch` configurations.

---

## 🔒 Security

`githubswitch` stores its configuration in `~/.ssh/githubswitch.conf` and creates SSH keys in `~/.ssh/`. It sets proper 600 permissions for these sensitive files.

---

## ☕ Support

If you find `githubswitch` helpful, consider supporting its development!

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://ko-fi.com/vishalranjan)

## 📬 Contact

If you have any questions, suggestions, or just want to say hi, feel free to reach out:

- **Email**: [mr.vishalranjan007@gmail.com](mailto:mr.vishalranjan007@gmail.com)
- **GitHub**: [@Mr-Vishal-Ranjan](https://github.com/Mr-Vishal-Ranjan)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.
