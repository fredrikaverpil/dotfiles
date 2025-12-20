# Project configs 🧢

## Folders

Workflow takes folder path into consideration when e.g. enabling LLMs etc.

```bash
mkdir -p ~/code/public
mkdir -p ~/code/work/public
mkdir -p ~/code/work/private
```

## Per-project tooling

### pkgx (legacy)

> [!NOTE]
>
> Prior to using Nix, I used [`pkgx`](https://docs.pkgx.sh) and I'm currently
> evaluating working with per-project Nix flakes but will keep this section in
> here until I have concluded my evaluation.

Use [`pkgx`](https://docs.pkgx.sh) to define project tooling (see `dev`
command), at least on macOS. This feels faster/simpler sometimes than resorting
to `flake.nix` (see below).

In each project, add a `.pkgx.yml` file to define project tooling, unless it is
not picked up from lockfiles etc.

Note that the shell integration is required and that the `dev` command must be
used to activate the dev tooling. See more info in the docs:
[docs.pkgx.sh](https://docs.pkgx.sh)

```yaml
# pkgx.yml

dependencies:
  - go # uses the latest version if no version is specified
  - python@3.12
```

### Nix flake

If not using pkgx, a `flake.nix` can also set up the project.

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

        # Override Go to use version 1.25.1 to match go.mod requirement
        go_1_25_1 = pkgs-unstable.go_1_25.overrideAttrs (oldAttrs: rec {
          version = "1.25.1";
          src = pkgs.fetchurl {
            url = "https://go.dev/dl/go${version}.src.tar.gz";
            hash = "sha256-0BDBCc7pTYDv5oHqtGvepJGskGv0ZYPDLp8NuwvRpZQ=";
          };
        });

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            # Use Go from unstable nix packages
            # pkgs-unstable.go

            # Use Go from override
            go_1_25_1

            # Add other tools as needed
            # ...
          ];

          shellHook = ''
            # Enforce using only the Nix-provided Go version, no auto-downloading
            export GOTOOLCHAIN=local

            # uv supplied via home-manager/neovim
            echo -e "\033[32m[project-toolchain] $(go version | awk '{print $3}') | $(uv --version)\033[0m"
          '';
        };
      }
    );
}
```

Direnv's `.envrc` must contain an entry for Nix to auto-load the flake when
entering the directory:

- Flake tracked by git: `use flake`
- Flake _not_ tracked by git: `use flake path:./.nix-devshell --impure` and
  place flake in project's `./nix-devshell/flake.nix`

<details><summary>Nix flake package pinning</summary>

To pin specific versions of tools like python or go in your dotfiles'
`flake.nix`:

**Method 1: Use version-specific packages**

```nix
packages = with inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin; [
  python311     # Python 3.11
  python312     # Python 3.12
  go_1_21       # Go 1.21
  go_1_22       # Go 1.22
];
```

**Method 2: Mix stable and unstable packages**

```nix
devShells.default = pkgs.mkShell {
  packages = [
    # From stable
    pkgs.python311

    # From unstable
    pkgs-unstable.go_1_23
    pkgs-unstable.nodejs_22
  ];
};
```

**Method 3: Pin to specific nixpkgs commit**

```nix
inputs = {
  nixpkgs-python311.url = "github:NixOS/nixpkgs/commit-hash-with-desired-version";
};
```

**Method 4: Access packages from older nixpkgs releases**

Sometimes you need packages that are no longer available in current releases
(e.g., Python 3.9). Add the older nixpkgs as an input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; # stable
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # unstable
    nixpkgs-python39.url = "github:NixOS/nixpkgs/nixos-24.11"; # has Python 3.9
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-python39,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgs-unstable = import nixpkgs-unstable { inherit system; };
        pkgs-python39 = import nixpkgs-python39 { inherit system; };
        python = pkgs-python39.python39;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            python
            (python.withPackages (p: [
              # Add pip packages here (but likely just use `uv sync` instead)
              # p.requests
              # p.numpy
            ]))

            # Add any other packages you need here
            pkgs-unstable.go
            pkgs.ruby
          ];

          shellHook = ''
            # uv supplied via home-manager/neovim
            echo -e "\033[32m[project-toolchain] $(python --version) | $(uv --version)\033[0m"

            # export UV_PYTHON_PREFERENCE="only-system"
            # export UV_PYTHON=${python}/bin/python
          '';
        };
      }
    );
}
```

Note that the example also includes an example of how to define pip dependencies
via Nix. However, the normal use case is to define these in a `pyproject.toml`
and use `uv sync` to install the virtual environment with these dependencies.

**Search for available versions:**

- CLI stable: `nix search nixpkgs python3` or `nix search nixpkgs go`
- CLI unstable: `nix search github:NixOS/nixpkgs/nixpkgs-unstable python3`
- Online: [search.nixos.org/packages](https://search.nixos.org/packages) (toggle
  e.g. "25.05" ↔ "unstable" channel)
- Browse source: [github.com/NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)

</details>

## Direnv

Use [direnv](https://direnv.net) to set environment variables dynamically when
entering a folder.

Add `.envrc` files in strategic locations, like:

- `~/code/work/.envrc`
- `~/code/work/project/.envrc`

Run `direnv allow .` in each location to allow it to execute.

### Inherit from parent folder's `.envrc` file

Start the project's `.envrc` file with:

```sh
source_up_if_exists
```

### Google Cloud configuration

#### Create configurations

Add default (personal) and work configs, something like this (replace `work`
with actual company name):

```bash
gcloud config configurations list

# personal
gcloud config configurations create default
gcloud config configurations activate default
cat ~/.config/gcloud/configurations/config_default  # review

# work
gcloud config configurations list
gcloud config configurations create work
gcloud config configurations activate work
cat ~/.config/gcloud/configurations/config_work  # review

# set active by default
gcloud config set account my@email.com
```

The configs should look something like this:

```sh
[core]
disable_usage_reporting = False
account = my@email.com
```

Then use `.envrc` file in `~/code/work/.envrc` to automatically switch from
default/personal account to work account:

```sh
export CLOUDSDK_ACTIVE_CONFIG_NAME="work"
```

#### Set active gcloud configuration using direnv

Add as needed to `.envrc`, per project or in a top-level work folder, or a mix:

```sh
export CLOUDSDK_ACTIVE_CONFIG_NAME="name-of-config"
export CLOUDSDK_CORE_PROJECT="name-of-gcp-project"
export CLOUDSDK_COMPUTE_REGION="europe-west1"
export CLOUDSDK_COMPUTE_ZONE="europe-west1-b"
```

### Connection string for `cloud-sql-proxy`

Add something like this so to enable `cloud-sql-proxy $DB1`:

```sh
export DB1="$CLOUDSDK_CORE_PROJECT:$CLOUDSDK_COMPUTE_REGION:$GCE_DATABASE_INSTANCE_1"
```

### Connection string for `psql`

Add something like this to enable `psql --expanded $PGCONN -f query.sql`:

```sh
export PGDRIVER="postgresql://"
export PGHOST="127.0.0.1"
export PGPORT="5432"
export GCE_DATABASE_NAME="db"
export DB_USER="postgres"
export DB_PASS="secret"
export PGFLAGS="?sslmode=disable"

export PGCONN="$PGDRIVER$DB_USER:$DB_USER@$PGHOST:$PGPORT/$GCE_DATABASE_NAME$PGFLAGS"
```

## LLM setup

### Claude Code

- MCPs defined in `claude_desktop_config.json` cannot hold remote MCPs.
- [Claude code docs](https://docs.claude.com/en/docs/claude-code)

```sh
# you can import mcp servers from claude desktop, into ~/.claude.json
claude mcp add-from-claude-desktop --scope user
```

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
