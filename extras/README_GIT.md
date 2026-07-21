# git config

See this repo's [`.gitconfig`](../stow/shared/.gitconfig) for the base setup
which enables the below functionality.

## HTTPS

### Repository access via HTTPS

- For HTTPS authentication, use the GitHub CLI; `gh auth login`.
- When HTTPS is desired, use
  `git clone --recursive https://github.com/user/repo.git`.

## Repository access via SSH

- Clone with `git clone --recursive git@github.com:user/repo.git`

### Vanilla ssh agent

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

- Verify keys `ssh-add -l`

Optionally enable specific key for e.g. SSO with `~/.gitconfig_ssh`:

```gitconfig
[core]
	sshCommand = ssh -o IdentitiesOnly=yes -i ~/.ssh/<workplace>.pub
```

Optionally enable commit signing with `~/.gitconfig_signing`. With
`gpg.format = ssh`, git signs via `ssh-keygen` by default, so no `program` line
is needed:

```gitconfig
[user]
	signingkey = ~/.ssh/id_ed25519.pub
[commit]
	gpgsign = true
[gpg]
	format = ssh
```

### 1Password

> [!NOTE]
>
> A biometric lock or password will have to be supplied before either git commit
> signing or accessing the 1Password agent.

Set up the agent for key access:

Example `~/.config/1Password/ssh/agent.toml`:

```toml
[[ssh-keys]]
vault = "Workplace"
[[ssh-keys]]
vault = "Personal"
```

Example `~/.gitconfig_ssh` which points git's SSH at the 1Password agent socket
([1Password docs](https://www.1password.dev/ssh/agent)). This git-scopes the
1Password agent; the official global alternative is `Host *` + `IdentityAgent`
in `~/.ssh/config`. The path below is 1Password's fixed macOS socket location:

```gitconfig
[core]
	sshCommand = ssh -o 'IdentityAgent="~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'
```

Note that `core.sshCommand` is single-valued: a later include that also sets it
(e.g. `~/.gitconfig_einride`, which pins a work key) replaces this line
entirely — it does not merge. When using this mode, repeat the `IdentityAgent`
option in that file's `sshCommand` too.

Optionally enable commit signing
([1Password docs](https://www.1password.dev/ssh/git-commit-signing)) with
`~/.gitconfig_signing`:

```gitconfig
[user]
	signingkey = ssh-ed25519 AAAA...
[commit]
	gpgsign = true
[gpg]
	format = ssh
[gpg "ssh"]
	program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
```

### Proton Pass (using `ssh-keygen`)

> [!IMPORTANT]
>
> After having authenticated with `pass-cli login`, the session stays
> authenticated indefinitely by default. Therefore, it's important to run
> `pass-cli session create-lock` to create a lock, which kicks in after an idle
> timeout (`--idle-timeout`, 30–900 seconds, default 300). And after reach
> reboot:
>
> ```sh
> pass-cli session unlock && \
>   pass-cli ssh-agent load --vault-name Personal && \
>   pass-cli session lock
> ```
>
> The lock only gates `pass-cli` itself. It does not lock keys already held by a
> running `ssh-agent`, so loaded SSH keys stay usable until the agent exits.
> Hopefully, `pass-cli` will in the future gain the same level of security as
> 1Password provides with its biometrick lock/password on each access of an SSH
> key.

- Authenticate once with `pass-cli login`
- Create lock with `pass-cli session create-lock`
- Load keys into the ssh-agent (on e.g. login) with
  `pass-cli ssh-agent load --vault-name Personal`
- Debug with e.g. `pass-cli ssh-agent debug --vault-name Personal`
- See which keys were loaded into the ssh-agent: `ssh-add -l`

> [!TIP]
>
> To see the fingerprint of SSH keys stored in Proton Pass, run
> `pass-cli ssh-agent debug --vault-name "Personal" | grep "Fingerprint" -B 3`.

No `~/.gitconfig_ssh` is needed for this mode. `pass-cli ssh-agent load` puts
the keys into your default system SSH agent, which git and `ssh` already reach
via `SSH_AUTH_SOCK` — so both authentication and signing work with no
git-specific SSH config. Leave `~/.gitconfig_ssh` absent (git silently skips
missing includes).

Optionally enable commit signing with `~/.gitconfig_signing`:

```gitconfig
[user]
	signingkey = ssh-ed25519 AAAA...
[commit]
	gpgsign = true
[gpg]
	format = ssh
[gpg "ssh"]
	program = "ssh-keygen"
```

### Proton Pass (using its own agent)

Instead of loading keys into the system agent, run `pass-cli` as the SSH agent
itself. It listens on `$HOME/.ssh/proton-pass-agent.sock`
([pass-cli docs](https://protonpass.github.io/pass-cli/commands/ssh-agent/)).

- Start it in the background: `pass-cli ssh-agent daemon start` (inspect/stop
  with `pass-cli ssh-agent daemon status` / `daemon stop`). You must already be
  logged in with `pass-cli login`, otherwise the daemon fails silently — use
  `--log-file` to capture startup errors.
- Point everything at that socket by exporting it in your shell profile:

  ```sh
  export SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-agent.sock"
  ```

With `SSH_AUTH_SOCK` set, both `ssh` (auth) and `ssh-keygen` (signing) use the
Proton agent, so — as with the `ssh-keygen` mode above — no `~/.gitconfig_ssh`
is needed.

> [!NOTE]
>
> A git-only `core.sshCommand`/`IdentityAgent` override would cover
> authentication but not signing: git's SSH signer (`ssh-keygen`) locates the
> agent through `SSH_AUTH_SOCK`, not through git's SSH config. Export
> `SSH_AUTH_SOCK` if you want signing too.

The session lock behaves the same as in the mode above: the lock gates
pass-cli's API operations (enforced server-side), while serving keys already
held in the daemon's memory needs no API access — so auth and signing keep
working while the session is locked. Per the
[session docs](https://protonpass.github.io/pass-cli/commands/session/), a
locked session only stops the daemon from refreshing keys from Proton Pass and
from creating new items via `ssh-add`. To actually revoke key access, stop the
daemon: `pass-cli ssh-agent daemon stop`.

Starting the daemon while the session is locked does NOT work (verified with
pass-cli 2.2.3): the launcher prints "Daemon started", but the daemon exits
immediately when its initial key fetch hits `SessionLocked` — no socket, no
keys. Check `daemon status` or `--log-file` to catch this.

A `~/.gitconfig_signing` is still needed for commit signing: the agent only
holds the key, while this file is what enables signing and names which key to
use. It is identical to the `ssh-keygen` mode above — `ssh-keygen` finds the
key via `SSH_AUTH_SOCK`, which now points at the Proton agent:

```gitconfig
[user]
	signingkey = ssh-ed25519 AAAA...
[commit]
	gpgsign = true
[gpg]
	format = ssh
[gpg "ssh"]
	program = "ssh-keygen"
```
