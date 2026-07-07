# git config

## HTTPS

### Repository access via HTTPS

- For HTTPS authentication, use the GitHub CLI; `gh auth login`.
- When HTTPS is desired, use
  `git clone --recursive https://github.com/user/repo.git`.

> [!NOTE] Please note that the GitHub CLI must be installed via `brew`. See the
> how the helper is invoked in [gitconfig](gitconfig).

## Repository access via SSH

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

- Add the machine's `id_rsa.pub` or `id_ed25519.pub` SSH key to GitHub. Skip
  this step if the SSH key exists in 1Password or Proton Pass.
- When SSH is desired, use `git clone --recursive git@github.com:user/repo.git`.

## Notes on SSH key management via Proton Pass and 1Password

The git config in this repo dictates SSH keys management with either Proton Pass
or 1Password. See `~/.gitconfig` (and its includes) for the split. The default
is to load keys from Proton Pass into the native `ssh-agent`.

### 1Password notes

Configure SSH agent setup and git commit signing via the menu inside any SSH key
entry inside 1Password.

Example `~/.config/1Password/ssh/agent.toml`:

```toml
[[ssh-keys]]
vault = "Workplace"
[[ssh-keys]]
vault = "Personal"
```

Then setup `IdentityAgent` (can be done via `~/.ssh/config` or in
`~/.gitconfig`) to run 1Password's own agent and `op-ssh-sign` for git commit
signing. See `~/.gitconfig_1password` for the current setup.

### Proton Pass notes

> [!IMPORTANT]
>
> For SSH access to e.g. GitHub organizations requiring SSO/SAML, a
> `~/.ssh/<workplace>.pub` is required which should contain the public key.

- Check which keys will be loaded into the native ssh-agent:
  `pass-cli ssh-agent debug --vault-name Personal`
- Load all keys into the native ssh-agent:
  `pass-cli ssh-agent load --vault Personal`
- See which keys were loaded into the ssh-agent: `ssh-add -l`
- Loading of keys happens on startup, via Nix home-manager.

> [!TIP]
>
> To see the fingerprint of SSH keys stored in Proton Pass, run
> `pass-cli ssh-agent debug --vault-name "Personal" | grep "Fingerprint" -B 3`.
