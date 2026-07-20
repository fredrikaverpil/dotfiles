# Project config

This page talks about local per-project tooling and configuration.

## Workspace layout and tooling layers

Workflow takes folder path into consideration when e.g. enabling LLMs etc.

```bash
mkdir -p ~/code/public
mkdir -p ~/code/work/public
mkdir -p ~/code/work/private
```

Tools become available in layers, each building on the previous one:

```
Nix system        System-level packages (nix-darwin / NixOS)
    ↓
Nix home          User packages via home-manager (sessionPath, hm-session-vars)
    ↓
Shell init        .zshrc → exports.sh → aliases.sh → sourcing.sh
    ↓
direnv (.envrc)   Per-directory env vars, Nix dev shells, tool activation
    ↓
Project tools     nix / devbox / devenv / mise / pkgx — project-specific CLI versions
    ↓
Editor (Neovim)   Mason — LSPs, linters, formatters, debug adapters
```

Later layers override earlier ones. For example, a project's `.envrc` can
activate a Nix dev shell that shadows a home-manager-installed Go with a
project-pinned version, and Mason's `PATH = "append"` ensures those
project-local tools take precedence inside Neovim too.

### Shell initialization

The shell startup chain is:

1. **`.zshrc`** → sources `.zshrc_user`
2. **[`exports.sh`](shell/exports.sh)** — PATH construction, Homebrew shellenv,
   `$DOTFILES` and other globals, home-manager session vars, `~/.shell/.env`
3. **[`aliases.sh`](shell/aliases.sh)** — shell aliases
4. **[`sourcing.sh`](shell/sourcing.sh)** — Nix daemon, tool initialization
   (atuin, direnv, mise, zoxide, starship, fzf), zsh completions/plugins, and
   `cd` overrides

The `cd` override (and `z`/`zi`) automatically activates Python virtual
environments when entering directories with a `.python-version` or `.venv/`.
This works alongside direnv — direnv handles Nix shells and env vars, while the
`cd` override handles behaviors that would be too cumbersome to maintain in
scattered `.envrc` files across every project. Some things are simply easier to
handle centrally in one place.

## Direnv

[direnv](https://direnv.net) automatically loads/unloads environment variables
and dev shells when entering/leaving directories.

Add `.envrc` files in strategic locations:

- `~/code/work/.envrc` — work-wide env vars (gcloud config, etc.)
- `~/code/work/project/.envrc` — project-specific tooling

Run `direnv allow .` in each location to authorize.

### Basics

Inherit from parent folder's `.envrc`:

```sh
source_up_if_exists
```

### Direnv with per-project tools

Each tool described in the [Per-project tooling](#per-project-tooling) section
below has its own direnv integration. Add the relevant line to your `.envrc`:

```sh
# devbox
eval "$(devbox generate direnv --print-envrc)"

# devenv
eval "$(devenv direnvrc)"
use devenv

# mise (alternative: `use mise` if nix-direnv stdlib extension is available)
eval "$(mise activate bash)"

# pkgx (activates dependencies from .pkgx.yml or auto-detected project files)
source <(pkgx --internal.activate $(realpath .))

# Nix flake (tracked by git) — requires nix-direnv
use flake

# Nix flake (not tracked by git, e.g. in ./nix-devshell/) — requires nix-direnv
use flake path:./.nix-devshell --impure
```

> [!IMPORTANT]
>
> After editing any `.envrc`, you must re-run `direnv allow .` to authorize the
> changes. Direnv blocks modified `.envrc` files until explicitly re-allowed.

> [!NOTE]
>
> The `use flake` command in `.envrc` is provided by
> [nix-direnv](https://github.com/nix-community/nix-direnv), not stock direnv.
> It caches the Nix evaluation so that `cd`-ing into a directory is fast after
> the first build. Without nix-direnv, `use flake` would re-evaluate on every
> shell entry. nix-direnv is installed via home-manager in this dotfiles repo.
> If it's missing, `use flake` in `.envrc` will fail with an unknown command
> error.

#### Combining tools

These integrations can be combined — e.g. devbox for Nix packages + mise for
tasks or bleeding edge tool versions:

```sh
source_up_if_exists
eval "$(devbox generate direnv --print-envrc)"
eval "$(mise activate bash)"
```

### Environment variables

#### Google Cloud configuration

Create default (personal) and work configs:

```bash
gcloud config configurations create default
gcloud config configurations create work
```

The configs should look something like this:

```sh
[core]
disable_usage_reporting = False
account = my@email.com
```

Switch configs automatically via `.envrc` (e.g. in `~/code/work/.envrc`):

```sh
export CLOUDSDK_ACTIVE_CONFIG_NAME="work"
export CLOUDSDK_CORE_PROJECT="name-of-gcp-project"
export CLOUDSDK_COMPUTE_REGION="europe-west1"
export CLOUDSDK_COMPUTE_ZONE="europe-west1-b"
```

#### Connection strings

For `cloud-sql-proxy $DB1`:

```sh
export DB1="$CLOUDSDK_CORE_PROJECT:$CLOUDSDK_COMPUTE_REGION:$GCE_DATABASE_INSTANCE_1"
```

For `psql --expanded $PGCONN -f query.sql`:

```sh
export PGDRIVER="postgresql://"
export PGHOST="127.0.0.1"
export PGPORT="5432"
export GCE_DATABASE_NAME="db"
export DB_USER="postgres"
export DB_PASS="secret"
export PGFLAGS="?sslmode=disable"

export PGCONN="$PGDRIVER$DB_USER:$DB_PASS@$PGHOST:$PGPORT/$GCE_DATABASE_NAME$PGFLAGS"
```

## Per-project tooling

### Choosing a tool

|                | **devbox**      | **devenv**          | **Nix flake**             | **mise**                 | **pkgx**           | **pocket**                     |
| -------------- | --------------- | ------------------- | ------------------------- | ------------------------ | ------------------ | ------------------------------ |
| Config         | JSON            | Nix                 | Nix                       | TOML                     | YAML / auto-detect | Go                             |
| Package source | nixpkgs         | nixpkgs             | nixpkgs                   | Upstream binaries        | pkgx.dev pantry    | Go modules                     |
| Nix knowledge  | None            | Some                | Yes                       | None                     | None               | None                           |
| Services       | Via plugins     | Built-in            | Manual                    | No                       | No                 | No                             |
| Task runner    | Scripts         | Built-in            | No                        | Built-in                 | No                 | Built-in                       |
| Speed on `cd`  | Fast            | Fast (with caching) | Slow (without nix-direnv) | Near-instant             | Near-instant       | N/A                            |
| Nested configs | No (one .envrc) | No (one .envrc)     | No (one .envrc)           | Yes (.mise.toml per dir) | Yes (auto-detect)  | Yes (per dir via shims)        |
| Best for       | Simple Nix envs | Full Nix power      | Full control              | Fast versioning + tasks  | Quick prototyping  | Custom registry of tasks/tools |

These tools can be combined — e.g. use devbox/devenv for Nix packages and mise
for bleeding-edge versions or its task runner.

> [!TIP]
>
> **Monorepos with mixed versions:** In a monorepo with e.g. multiple sub
> projects with different tool versions, pkgx auto-detects the version from
> lockfiles with zero config. In contrast, mise requires a `.mise.toml` per
> subdirectory but is explicit. direnv-based tools (devbox, devenv, Nix flake)
> only trigger per `.envrc`, so they don't handle nested version switching well.

### devbox

[devbox](https://www.jetify.com/devbox) creates isolated dev environments using
Nix packages, configured via a simple JSON file. No Nix knowledge required.

```bash
devbox init
devbox add go_1_24 python@3.12
```

This creates a `devbox.json`. Search for available packages at
[nixhub.io](https://www.nixhub.io/).

Enter the environment or run a command inside it:

```bash
devbox shell            # enter the environment
devbox run go version   # run a single command
```

### devenv

[devenv](https://devenv.sh) provides Nix-native dev environments with built-in
support for languages, services, processes, and containers. Configured via
`devenv.nix` (requires some Nix knowledge).

```bash
devenv init
```

> [!NOTE]
>
> `devenv init` generates a `flake.nix` — don't run it in a project that already
> has one. Instead, integrate devenv into your existing flake manually.

Example `devenv.nix`:

```nix
{ pkgs, ... }:

{
  languages.go.enable = true;
  languages.python.enable = true;

  services.postgres.enable = true;

  processes.server.exec = "go run ./cmd/server";
}
```

Enter the environment, run tasks, or start services:

```bash
devenv shell            # enter the environment
devenv test             # run tests defined in devenv.nix
devenv up               # start processes (e.g. postgres, server)
```

### Nix flake (manual)

A `flake.nix` with `devShells` gives full control without any wrapper tool.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";                # stable
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";  # unstable
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgs-unstable = import nixpkgs-unstable { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs-unstable.go
          ];

          shellHook = ''
            export GOTOOLCHAIN=local
            echo -e "\033[32m[project-toolchain] $(go version | awk '{print $3}')\033[0m"
          '';
        };
      }
    );
}
```

Enter the environment or run a command inside it:

```bash
nix develop             # enter the dev shell
nix develop -c go version  # run a single command
```

### mise

[mise](https://mise.jdx.dev) is a fast (Rust-based) polyglot tool version
manager and task runner. It downloads tools directly from upstream (not via
Nix), so new versions are available almost immediately.

```toml
# .mise.toml
[tools]
go = "1.24"
python = "3.12"
node = "22"

[tasks]
lint = "golangci-lint run"
test = "go test ./..."
```

Install tools and run tasks:

```bash
mise install            # install tools declared in .mise.toml
mise run lint           # run a task
mise exec -- go version # run a command with mise-managed tools
```

### pkgx

> [!NOTE]
>
> pkgx is not available in nixpkgs. On macOS it's installed via Homebrew, on
> Linux via curl. See
> [installation docs](https://docs.pkgx.sh/pkgx/installing-pkgx).

[`pkgx`](https://docs.pkgx.sh) auto-detects tools from project files and runs
them on demand. Add a `.pkgx.yml` to define explicit dependencies:

```yaml
# .pkgx.yml

dependencies:
  - go
  - python@3.12
```

Run a command with pkgx-managed tools:

```bash
pkgx go version         # run with auto-detected version
dev                     # enter an environment with all dependencies
```

### pocket

[pocket](https://github.com/fredrikaverpil/pocket) is a Go-based task runner and
package manager. Tasks and dependencies are defined in Go, and shims (`./pok`)
are generated per directory to run them.

```bash
pocket init
```

List and run tasks:

```bash
./pok -h                # list available tasks
./pok <task>            # run a task
```

## Nix package pinning

These techniques apply to any Nix-based setup (flake.nix, devenv, devbox with
custom flakes).

### Use version-specific packages

```nix
packages = [
  pkgs.python311       # Python 3.11
  pkgs.python312       # Python 3.12
  pkgs.go_1_21         # Go 1.21
  pkgs.go_1_22         # Go 1.22
];
```

### Mix stable and unstable packages

```nix
packages = [
  pkgs.python311              # From stable
  pkgs-unstable.go_1_23       # From unstable
  pkgs-unstable.nodejs_22     # From unstable
];
```

### Pin to specific nixpkgs commit

If a specific version isn't available in stable or unstable, find a nixpkgs
commit that has it. Use [nixpkgs-track](https://nixpkgs-track.kohi.dev/) or
[Nixhub](https://www.nixhub.io/) to look up which commit introduced a version.

```nix
inputs = {
  nixpkgs-go126.url = "github:NixOS/nixpkgs/abc123def456";  # has go_1_26
};
```

Then import and use it:

```nix
let
  pkgs-go126 = import inputs.nixpkgs-go126 { inherit system; };
in
{
  packages = [ pkgs-go126.go_1_26 ];
}
```

### Override a package version

```nix
go_1_25_1 = pkgs-unstable.go_1_25.overrideAttrs (oldAttrs: rec {
  version = "1.25.1";
  src = pkgs.fetchurl {
    url = "https://go.dev/dl/go${version}.src.tar.gz";
    hash = "sha256-0BDBCc7pTYDv5oHqtGvepJGskGv0ZYPDLp8NuwvRpZQ=";
  };
});
```

### Access packages from older nixpkgs releases

Sometimes you need packages no longer available in current releases (e.g.,
Python 3.9). Add an older nixpkgs as an input:

```nix
inputs = {
  nixpkgs-python39.url = "github:NixOS/nixpkgs/nixos-24.11"; # has Python 3.9
};
```

Then use `pkgs-python39.python39` in your packages list.

### Search for available versions

- CLI stable: `nix search nixpkgs python3` or `nix search nixpkgs go`
- CLI unstable: `nix search github:NixOS/nixpkgs/nixpkgs-unstable python3`
- Online: [search.nixos.org/packages](https://search.nixos.org/packages) (toggle
  e.g. "25.05" ↔ "unstable" channel)
- Browse source: [github.com/NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)

## Editor tooling (Neovim)

LSPs, linters, formatters, and debug adapters used inside Neovim are managed by
[Mason](https://github.com/mason-org/mason.nvim), configured in
[`nvim-fredrik/lua/fredrik/plugins/core/mason.lua`](nvim-fredrik/lua/fredrik/plugins/core/mason.lua).
Mason installs tools into its own isolated location
(`~/.local/share/nvim-fredrik/mason/bin/`), separate from the shell environment.

Mason's `PATH` is set to `"append"`, meaning project-local tools (from Nix,
mise, etc.) take precedence over Mason-installed versions. This lets per-project
tooling override editor defaults automatically.

Per-language tool declarations (which LSPs, formatters, linters to install) live
in `nvim-fredrik/lua/fredrik/plugins/lang/*.lua` — e.g. `go.lua`, `python.lua`,
`typescript.lua`. Many Neovim plugins expect specific tooling (e.g. a formatter
plugin needs the formatter binary). Each plugin spec declares which Mason
packages it needs — on startup, Mason automatically downloads and installs any
missing tools. This means adding a new language setup is just a matter of
writing the plugin spec; opening Neovim takes care of the rest.

## LLM setup

### Claude Code

Claude Code is installed as a Nix package from the `llm-agents` flake input
(declared via `packageTools.llmAgents` in `nix/shared/home/common.nix`).

- [Claude code docs](https://docs.claude.com/en/docs/claude-code)
- Installation: Automatic on rebuild
- Updates: `nix flake update llm-agents`, then rebuild
- Settings: Managed in `stow/shared/.claude/` (synced via Stow)

#### Claude Work profile

Use a separate Claude config dir for work contexts (different settings, skills,
commands). Add to `~/code/work/.envrc`:

```sh
export CLAUDE_CONFIG_DIR="/Users/fredrik/.claude-work"
```

This switches Claude Code to use `~/.claude-work/` (synced from
`stow/shared/.claude-work/` via Stow) when working in that directory.

```sh
# you can import mcp servers from claude desktop, into ~/.claude.json
claude mcp add-from-claude-desktop --scope user
```

> [!NOTE]
>
> Claude Desktop does not support remote MCPs at the time of writing this. But
> Claude Code does.

Examples of manual config in `~/.claude.json`:

```json
{
  "mcpServers": {
    "serena": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--context",
        "ide-assistant"
      ],
      "env": {}
    },
    "github": {
      "disabled": false,
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp",
      "headers": {
        "Authorization": "Bearer ${GITHUB_MCP_SERVER_TOKEN}"
      }
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      }
    }
  }
}
```
