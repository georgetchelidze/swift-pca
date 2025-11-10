#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper to build both macOS (on mac) and Linux (via a container runtime if available)

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ensure_container_runtime() {
  # Prefer Docker if CLI exists and daemon is reachable
  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      CONTAINER_CLI=docker
      return 0
    fi
  fi
  # Try Colima (provides a Docker-compatible daemon)
  if command -v colima >/dev/null 2>&1; then
    echo "[build-all] Starting Colima (Docker-compatible)"
    colima start >/dev/null 2>&1 || true
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      CONTAINER_CLI=docker
      return 0
    fi
  fi
  # Try Podman as fallback
  if command -v podman >/dev/null 2>&1; then
    echo "[build-all] Ensuring Podman machine is running"
    if ! podman info >/dev/null 2>&1; then
      podman machine init >/dev/null 2>&1 || true
      podman machine start
    fi
    CONTAINER_CLI=podman
    return 0
  fi
  return 1
}

run_container() {
  local platform="$1"; shift
  local image="$1"; shift
  local cmd="$*"
  if [[ "${CONTAINER_CLI:-}" == "podman" ]]; then
    # podman uses --arch/--os instead of --platform; default to host arch
    $CONTAINER_CLI run --rm -t \
      -v "$ROOT_DIR":"/work" \
      -w /work \
      "$image" bash -lc "$cmd"
  else
    $CONTAINER_CLI run --rm -t --platform "$platform" \
      -v "$ROOT_DIR":"/work" \
      -w /work \
      "$image" bash -lc "$cmd"
  fi
}

case "$(uname -s)" in
  Darwin)
    echo "[build-all] Detected macOS. Building darwin-arm64 locally."
    bash "$ROOT_DIR/scripts/build-darwin-arm64.sh"
    if ensure_container_runtime; then
      echo "[build-all] Using $CONTAINER_CLI to build linux-x86_64."
      run_container linux/amd64 ubuntu:22.04 \
        "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential gfortran make git clang && NPROC_LIMIT=2 bash scripts/build-linux-x86_64.sh"
    else
      echo "[build-all] No container runtime found or reachable (docker/colima/podman)."
      echo "[build-all] To build Linux artifacts, run on a Linux x86_64 host:"
      echo "  bash scripts/build-linux-x86_64.sh"
    fi
    ;;
  Linux)
    echo "[build-all] Detected Linux. Building linux-x86_64 locally."
    bash "$ROOT_DIR/scripts/build-linux-x86_64.sh"
    ;;
  *)
    echo "Unsupported OS. Run the platform-specific scripts manually."
    exit 1
    ;;
esac
