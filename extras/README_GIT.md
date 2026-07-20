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
> After having authenticated with `pass-cli auth login`, the session stays
> authenticated indefinitely by default. Therefore, it's important to run
> `pass-cli session create-lock` to create a lock, which kicks in after some
> idle time.
>
> The lock only gates `pass-cli` itself. It does not lock keys already held by a
> running `ssh-agent`, so loaded SSH keys stay usable until the agent exits.
>
> Hopefully, `pass-cli` will gain the same level of security as 1Password
> provides.

- Check which keys will be loaded into the native ssh-agent:
  `pass-cli ssh-agent debug --vault-name Personal`
- Load all keys into the native ssh-agent:
  `pass-cli ssh-agent load --vault Personal`
- See which keys were loaded into the ssh-agent: `ssh-add -l`
- Loading of keys is manual: unlock the session with `pass-cli session unlock`
  first, then run the load command above. Auto-loading at login was removed — a
  PIN-locked session can't be unlocked non-interactively.

> [!NOTE]
>
> For SSH access to e.g. GitHub organizations requiring SSO/SAML, a
> `~/.ssh/<workplace>.pub` is required which should contain the public key.

> [!TIP]
>
> To see the fingerprint of SSH keys stored in Proton Pass, run
> `pass-cli ssh-agent debug --vault-name "Personal" | grep "Fingerprint" -B 3`.
