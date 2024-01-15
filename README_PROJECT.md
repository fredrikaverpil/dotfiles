# Project configs 🧢

- Use [direnv](https://direnv.net) to set environment variables dynamically when entering a folder.
- Use [Taskfile](https://taskfile.dev) to provide tasks which uses the environment variables provided by direnv.
- Use [pkgx](https://docs.pkgx.sh) to define project tooling (see `dev` command).

## Direnv

Add `.envrc` files in strategic locations, like:

- `~/code/_work/.envrc`
- `~/code/_work/project/.envrc`

Run `direnv allow .` in each location to allow it to execute.

### Inherit from parent folder's `.envrc` file

Start the `.envrc` file with:

```sh
source_up_if_exists
```

### Google Cloud configuration

#### Create configurations

Add default and work configs, something like this:

```bash
gcloud config configurations list
gcloud config configurations create work
gcloud config configurations activate work
gcloud config set account me@work.com

cat ~/.config/gcloud/configurations/config_work
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

## Taskfile

Dotfiles will install a global Taskfile into `~/Taskfile.yml` which can use the environment variables provided by direnv.

## Pkgx

In each project, add a `pkgx.yml` file to define project tooling, unless it is not picked up from lockfiles etc.

Note that the shell integration is required and that the `dev` command must be used to activate the dev tooling. See more info in the docs: https://docs.pkgx.sh

```yaml
# pkgx.yml

dependencies:
  - go # uses the latest version if no version is specified
  - python@3.12
```
