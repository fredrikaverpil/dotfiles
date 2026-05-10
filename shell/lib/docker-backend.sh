# shellcheck shell=bash

docker_backend_apply() {
  case "$DOCKER_BACKEND" in
  container)
    export DOCKER_HOST="unix://$HOME/.socktainer/container.sock"
    export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="$HOME/.socktainer/container.sock"
    ;;
  podman)
    if [ "$(uname)" = "Darwin" ]; then
      sock="$HOME/.local/share/containers/podman/machine/podman.sock"
      if [ ! -S "$sock" ] && command -v podman >/dev/null 2>&1; then
        sock=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
      fi
      export DOCKER_HOST="unix://$sock"
      # NOTE: for some weird reason, we must use the linux convention for testcontainers on macOS
      sock="/run/user/$(id -u)/podman/podman.sock"
      export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="$sock"
    else
      sock="/run/user/$(id -u)/podman/podman.sock"
      export DOCKER_HOST="unix://$sock"
      export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="$sock"
    fi
    ;;
  orbstack)
    export DOCKER_HOST="unix://$HOME/.orbstack/run/docker.sock"
    export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="$HOME/.orbstack/run/docker.sock"
    ;;
  docker)
    unset DOCKER_HOST
    unset TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE
    ;;
  "")
    ;;
  *)
    echo "Warning: unknown DOCKER_BACKEND '$DOCKER_BACKEND'" >&2
    ;;
  esac
}

docker_backend_status() {
  [ -t 2 ] || return 0
  if [ -n "$DOCKER_BACKEND" ]; then
    echo "→ docker backend: $DOCKER_BACKEND (DOCKER_HOST=${DOCKER_HOST:-unset})" >&2
  fi
}
