# Project configs 🧢

## Folders

Workflow takes folder path into consideration when e.g. enabling LLMs etc.

```bash
mkdir -p ~/code/public
mkdir -p ~/code/work/public
mkdir -p ~/code/work/private
```

## Global tools via homebrew

Use [`brew`](https://brew.sh/) to define any global tooling.

## Per-project tools via pkgx

Use [`pkgx`](https://docs.pkgx.sh) to define project tooling (see `dev`
command).

In each project, add a `pkgx.yml` file to define project tooling, unless it is
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
