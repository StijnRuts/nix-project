#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
name="${2:-}"
flake="${3:-}"

container_exists() {
  nixos-container status "$name" >/dev/null 2>&1
}

cmd_build() {
  if container_exists; then
    echo "Updating container $name"
    sudo nixos-container update "$name" --flake ".#$flake"
  else
    echo "Creating container $name"
    sudo nixos-container create "$name" --flake ".#$flake"
  fi
}

cmd_watch() {
  echo "Watching for changes to .nix files..."
  watchexec --postpone --exts nix -- "$0" build "$name" "$flake"
}

cmd_up() {
  echo "Starting container $name"
  sudo nixos-container start "$name"
  cmd_status
}

cmd_down() {
  echo "Stopping container $name"
  sudo nixos-container stop "$name"
}

cmd_status() {
  if container_exists "$name"; then
    status=$(nixos-container status "$name")
    echo "Container $name is $status"
    [[ "$status" = "up" ]]
  else
    echo "Container $name does not exist"
    return 1
  fi
}

cmd_shell() {
  sudo nixos-container root-login "$name"
}

cmd_mount() {
  local name="$1"
  local host_path="$2"
  local container_path="$3"
  local root="/var/lib/nixos-containers/$name"

  echo "Mounting $host_path → $container_path"
  sudo mkdir -p "$root/$container_path"
  sudo mount --bind "$host_path" "$root/$container_path"
}

usage() {
  cat <<EOF
Usage:
  container build  <name> <flake>
  container watch  <name> <flake>
  container up     <name>
  container down   <name>
  container status <name>
  container shell  <name>
  container mount  <name> <host_path> <container_path>

Description:
  build    Create or update a container
  watch    Watch for .nix changes and auto-update the container
  up       Start a container
  down     Stop a container
  status   Print container status; exit 0 if up, 1 otherwise
  shell    Launch a root shell into the container
  mount    Bind-mount a host directory into the container
EOF
}

case "$cmd" in
  build)  cmd_build ;;
  watch)  cmd_watch ;;
  up)     cmd_up ;;
  down)   cmd_down ;;
  status) cmd_status ;;
  shell)  cmd_shell ;;
  mount)  cmd_mount "$2" "$3" "$4" ;;
  ""|-h|--help) usage ;;
  *) echo "Unknown command: $cmd"; usage; exit 1 ;;
esac

