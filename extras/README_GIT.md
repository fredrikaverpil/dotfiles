# git 🐙

## HTTPS

### Repository access via HTTPS

- For HTTPS authentication, use the GitHub CLI; `gh auth login`.
- When HTTPS is desired, use `git clone --recursive https://github.com/user/repo.git`.

> [!NOTE]
> Please note that the GitHub CLI must be installed via `brew`. See the how the helper is invoked in [gitconfig](gitconfig).

## SSH

### Set up `~/.ssh`

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

### Repository access via SSH

- Add the machine's `id_rsa.pub` or `id_ed25519.pub` SSH key to GitHub.
- Hook up 1Password with the ssh agent, see `~/.config/1Password/ssh/agent.toml`.
- When SSH is desired, use `git clone --recursive git@github.com:user/repo.git`.

### 1Password commit signing

Find the item in 1Password containing the git commit signing key info and save this as `~/.gitconfig_1password`. This file is included by `~/.gitconfig` of these dotfiles. On WSL, replace the path to the CLI with `/mnt/c/ ...` in `~/.gitconfig_1password`.

Also, edit `~/.config/1Password/ssh/agent.toml` to say something like:

```toml
[[ssh-keys]]
vault = "Workplace"

[[ssh-keys]]
vault = "Personal"
```

## Update gitconfig email

Review/update the email used in `~/.gitconfig_work`.
