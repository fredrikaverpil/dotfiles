## git 🐙

### Set up ssh

```bash
# Fix directory permissions
chmod 700 ~/.ssh

# Fix all key permissions
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub

# Fix special files permissions
chmod 644 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/known_hosts
chmod 644 ~/.ssh/config
```

### Repository access

- Add the machine's `id_rsa.pub` or `id_ed25519.pub` SSH key to GitHub.
- Hook up 1Password with the ssh agent, see `~/.config/1Password/ssh/agent.toml`.
- Always clone down using SSH (not HTTPS); `git clone git@github.com:user/repo.git`.
- For the GitHub CLI, use `gh auth login` to authenticate.

### 1Password commit signing

Find the item in 1Password containing the git commit signing key info and save this as `~/.gitconfig_1password`. This file is included by `~/.gitconfig` of these dotfiles.

On WSL, replace the path to the CLI with `/mnt/c/ ...` in `~/.gitconfig_1password`.

### Update gitconfig email

Review/update the email used in `~/.gitconfig_work`.
