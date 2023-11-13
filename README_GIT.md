## git 🐙

### Export key out of 1Password

Copy value of the public/private key and paste it into the corresponding file. Set persmissions as below.

```bash
chmod 700 ~/.ssh

touch ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

touch ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys

touch ~/.ssh/config
chmod 644 ~/.ssh/config

touch ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

touch ~/.ssh/id_rsa.pub
chmod 644 ~/.ssh/id_rsa.pub

touch ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

touch ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/id_ed25519.pub
```

### Repository access

- Add the machine's `id_rsa.pub` or `id_ed25519.pub` SSH key to GitHub.
- Always clone down using SSH (not HTTPS).
- For the GitHub CLI, use `gh auth login` to authenticate.

### 1Password commit signing

Find the item in 1Password containing the git commit signing key info and save this as `~/.gitconfig_1password`. This file is included by `~/.gitconfig` of these dotfiles.

On WSL, replace the path to the CLI with `/mnt/c/ ...` in `~/.gitconfig_1password`.
