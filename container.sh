#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
name="${2:-}"
flake="${3:-}"
arg="${4:-}"

container_exists() {
  nixos-container status "$name" >/dev/null 2>&1
}

container_up() {
  status=$(nixos-container status "$name")
  [[ "$status" = "up" ]]
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
  watchexec --postpone --exts nix -- "$0" build "$name" "$flake" &
  pid=$!
  while (container_up || [[ "$arg" != "--live" ]]); do
    sleep 5
  done
  kill "$pid"
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
  local userid; userid=$(stat -c "%u" "$host_path")

  echo "Mounting $host_path → $container_path"
  sudo mkdir -p "$root/$container_path"
  sudo mount --map-users "$userid:2000:1" --map-groups 0:0:65535 --bind "$host_path" "$root/$container_path"
}

cmd_umount() {
  local name="$1"
  local container_path="$2"
  local root="/var/lib/nixos-containers/$name"

  echo "Unmounting $container_path"
  sudo umount "$root/$container_path"
}

usage() {
  cat <<EOF
Usage:
  container build  <name> <flake>
  container watch  <name> <flake> [--live]
  container up     <name>
  container down   <name>
  container status <name>
  container shell  <name>
  container mount  <name> <host_path> <container_path>
  container umount <name> <container_path>

Description:
  build    Create or update a container
  watch    Watch for .nix changes and auto-update the container
   --live  Watch for changes while the container is up
  up       Start a container
  down     Stop a container
  status   Print container status; exit 0 if up, 1 otherwise
  shell    Launch a root shell into the container
  mount    Bind-mount a host directory into the container
  umount   Unmount a host directory from the container
EOF
}

case "$cmd" in
  build | create | update) cmd_build ;;
  watch) cmd_watch ;;
  up | start | run) cmd_up ;;
  down | stop) cmd_down ;;
  status) cmd_status ;;
  shell | login) cmd_shell ;;
  mount) cmd_mount "$2" "$3" "$4" ;;
  umount | unmount) cmd_umount "$2" "$3" ;;
  ""|-h|--help) usage ;;
  *) echo "Unknown command: $cmd"; usage; exit 1 ;;
esac
