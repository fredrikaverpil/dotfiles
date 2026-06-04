# Apple `container` CLI

Tool for creating and running Linux containers as lightweight VMs on Apple
silicon. Requires macOS 26+ and Apple silicon. OCI-compatible.

- GitHub: <https://github.com/apple/container>
- Docs: <https://apple.github.io/container/documentation/>

## Docker-compatible clients

Use `docker-backend` to point Docker-compatible clients at a backend by setting
`DOCKER_HOST` and `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE`.

```bash
eval "$(docker-backend env socktainer)"
docker ps

docker-backend run socktainer -- lazydocker
```

Per-project overrides can use the same command from `.envrc`.

## Setup

```bash
brew install container

# Start the service (downloads a kernel on first run, ~required)
container system start --enable-kernel-install

# Check status
container system status

# Stop the service
container system stop
```

> `container system start` without `--enable-kernel-install` will interactively
> prompt about kernel installation — use the flag to skip the prompt.

## `container system` behavior

`container system start` starts Apple `container`'s own backend services via
launchd. The main service is `container-apiserver`, and
`container system status` reports whether that service is registered/running
plus the configured install, app, and log roots.

This backend is required for the `container` CLI itself. For example,
`container run`, `container image pull`, and `container build` talk to Apple's
apiserver after it has been started.

It does **not** expose a Docker Engine socket. Starting the system service does
not create `/var/run/docker.sock`, `$HOME/.docker/run/docker.sock`, or any other
Docker-compatible Unix socket that Docker clients can use through `DOCKER_HOST`.
The service uses Apple `container`'s own API over macOS service plumbing instead
of the Docker Engine HTTP API.

Use socktainer when a tool needs a Docker-compatible socket:

```bash
container system start --enable-kernel-install
socktainer --no-check-compatibility
eval "$(docker-backend env socktainer)"
docker ps
```

## Command mapping vs Docker/Podman

### Works — same syntax

| Action            | `container`         | Docker/Podman            |
| ----------------- | ------------------- | ------------------------ |
| Run               | `container run`     | `docker run`             |
| Build             | `container build`   | `docker build`           |
| Create            | `container create`  | `docker create`          |
| Exec              | `container exec`    | `docker exec`            |
| Stop              | `container stop`    | `docker stop`            |
| Kill              | `container kill`    | `docker kill`            |
| Start             | `container start`   | `docker start`           |
| Logs              | `container logs`    | `docker logs`            |
| Inspect           | `container inspect` | `docker inspect`         |
| Stats             | `container stats`   | `docker stats`           |
| Remove container  | `container rm`      | `docker rm`              |
| Prune stopped     | `container prune`   | `docker container prune` |
| Export filesystem | `container export`  | `docker export`          |
| Images            | `container image`   | `docker image`           |
| Volumes           | `container volume`  | `docker volume`          |
| Networks          | `container network` | `docker network`         |

### Works — different name

| Action          | `container`                       | Docker/Podman   |
| --------------- | --------------------------------- | --------------- |
| List containers | `container list` / `container ls` | `docker ps`     |
| Registry login  | `container registry login`        | `docker login`  |
| Registry logout | `container registry logout`       | `docker logout` |
| Pull image      | `container image pull`            | `docker pull`   |
| Push image      | `container image push`            | `docker push`   |

### Missing — not implemented (as of v0.12.3)

| Action                       | Docker/Podman equivalent          |
| ---------------------------- | --------------------------------- |
| Copy files to/from container | `docker cp`                       |
| Commit container to image    | `docker commit`                   |
| Show image history           | `docker history`                  |
| Import tarball as image      | `docker import`                   |
| Load image archive           | `docker load`                     |
| Save image to archive        | `docker save`                     |
| Search registry              | `docker search`                   |
| Tag an image                 | `docker tag`                      |
| Attach to container          | `docker attach`                   |
| Pause/unpause                | `docker pause` / `docker unpause` |
| Restart                      | `docker restart`                  |
| Rename                       | `docker rename`                   |
| List port mappings           | `docker port`                     |
| Show processes               | `docker top`                      |
| Wait for container exit      | `docker wait`                     |
| Compose                      | `docker compose`                  |
| Pods (Podman-specific)       | `podman pod`                      |

### No `docker.sock` / Docker API compatibility

`container system start` starts Apple's own `container-apiserver` daemon, but it
does not expose a Docker-compatible API endpoint or Unix socket. Tools that
connect directly to `/var/run/docker.sock` or another `DOCKER_HOST` socket (e.g.
Testcontainers, lazydocker, Portainer, Compose) **will not work** against Apple
`container` directly. The CLI surface is compatible; the daemon API is not.

Apple has explicitly closed this as **"not planned"** (issue #66):

> _"At present we don't have plans to support a Docker compatible API for
> managing the `container` tool, nor do we plan to implement a bridge from the
> Docker API to the container services."_

The maintainer did hint that the plugin architecture could support a
community-built bridge. A detailed proposal for a read-only Docker REST API
surface was submitted (issue #1476) by a fork (`full-chaos/container`) but was
also closed.

### Workaround: socktainer

[socktainer](https://github.com/socktainer/socktainer) is a community daemon
that sits on top of Apple `container` and exposes a Docker-compatible REST API
on a Unix socket (`~/.socktainer/container.sock`). This unblocks tools that talk
to `/var/run/docker.sock`.

Install and run:

```bash
brew install socktainer/tap/socktainer
socktainer --no-check-compatibility  # start the bridge daemon
```

Point Docker clients at it:

```bash
eval "$(docker-backend env socktainer)"
docker ps
docker compose up
```

What works through socktainer (as of v0.12.x):

- Container lifecycle: list, create, inspect, start, stop, restart, kill, wait,
  attach, remove, prune
- Image lifecycle: list, pull, push, tag, inspect, delete, prune, build
- Container archive (`docker cp`)
- Auth (`docker login`)
- Basic events: start, stop, restart, container destroy, image delete

What doesn't work yet (blocked on missing Apple `container` capabilities):

- `docker stats` — no resource usage API
- `docker top` / `docker pause` / `docker rename` — no matching capability
- WebSocket attach
- Most event types (exec, commit, copy, pause, oom, etc.)

See [issue #14](https://github.com/socktainer/socktainer/issues/14) and
[issue #90](https://github.com/socktainer/socktainer/issues/90) for the full API
parity tables.

### Testcontainers

Testcontainers can connect to Apple `container` through socktainer, but it
expects Docker-compatible network names that Apple `container` does not create
by default.

Create these compatibility networks once:

```bash
container network create bridge
container network create \
  --label org.testcontainers=true \
  --label org.testcontainers.lang=go \
  --label org.testcontainers.reap=true \
  reaper_default
```

Why these are needed:

- `bridge`: Testcontainers-go starts Ryuk with Docker's hard-coded `bridge`
  network mode. Apple `container` only creates a `default` NAT network by
  default, so Ryuk fails unless a network named `bridge` exists.
- `reaper_default`: when Testcontainers-go cannot find Docker's default bridge
  network, it creates or reuses `reaper_default` for container communication.
  Creating it up front avoids a network-create path that has failed through
  socktainer with a generic `Something went wrong` daemon error.

Blocking limitation:

- Testcontainers-go v0.42 creates Ryuk containers named
  `reaper_<64-char-session-id>`. Apple `container`/socktainer can fail to start
  containers with long names and published ports with
  `proxyVsock: failed to setup vsock proxy`. A shorter manually-created Ryuk
  container works, but Testcontainers does not expose a supported way to shorten
  the generated Ryuk container name.

For reliable Testcontainers support, prefer Docker, OrbStack, or Podman until
Apple `container` and socktainer have better Docker API parity for Ryuk.

**Relevant threads:**

- [#66 — Expose Docker Engine API](https://github.com/apple/container/issues/66)
  (closed: not planned)
- [#131 — Support testcontainers?](https://github.com/apple/container/issues/131)
  (closed)
- [#1476 — HTTP REST surface compatible with Docker Engine API](https://github.com/apple/container/issues/1476)
  (closed)
- [Discussion #194](https://github.com/apple/container/discussions/194) —
  community follow-up
- [Discussion #320](https://github.com/apple/container/discussions/320) —
  community follow-up
- [socktainer](https://github.com/socktainer/socktainer) — third-party bridge
  project (incomplete)
- [containerization#733 — Add ID length restriction](https://github.com/apple/containerization/pull/733)
  (merged: the 64-char `maxIDLength` limit and its rationale; adds validation on
  top of already existing constraint?)

### Quick/simple repro

```sh
container run --rm --name "$(printf 'a%.0s' $(seq 1 65))" busybox true   # fails Code=22
```

### Unique to `container`

| Command                   | Purpose                                        |
| ------------------------- | ---------------------------------------------- |
| `container system start`  | Start the macOS launchd service + kernel setup |
| `container system stop`   | Stop the service                               |
| `container system status` | Show service health and version info           |
| `container builder`       | Manage the BuildKit builder instance           |
