#!/usr/bin/env bash
set -euo pipefail

# Build OpenBLAS (+LAPACK) for Linux x86_64 into Vendor/build/linux-x86_64

# Resolve repo root (this script lives in Vendor/build)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENBLAS_DIR="$ROOT_DIR/OpenBLAS"
INSTALL_DIR="$SCRIPT_DIR/linux-x86_64"

# Limit parallelism to avoid OOM/cc1 ICE in small containers
NPROC_RAW="${NPROC:-$(command -v nproc >/dev/null 2>&1 && nproc || echo 4)}"
NPROC="${NPROC_LIMIT:-2}"
if [ "${NPROC}" = "" ]; then NPROC=2; fi

export CC=${CC:-clang}
export FC=${FC:-gfortran}
export CFLAGS="${CFLAGS:--O1}"
export FCFLAGS="${FCFLAGS:--O2}"

echo "[linux-x86_64] Building OpenBLAS (with LAPACK) into $INSTALL_DIR"
cd "$OPENBLAS_DIR"
make clean || true
make USE_OPENMP=0 NO_SHARED=1 NO_CBLAS=1 BINARY=64 DYNAMIC_ARCH=1 -j"$NPROC"
# Ensure LAPACK objects are produced and merged
make lapack -j"$NPROC"
make PREFIX="$INSTALL_DIR" install

echo "[linux-x86_64] Stripping shared libs (keeping static .a only)"
rm -f "$INSTALL_DIR/lib"/*.so* || true
rm -f "$INSTALL_DIR/lib"/*.dylib || true
rm -f "$INSTALL_DIR/lib"/*.dll || true

echo "[linux-x86_64] Done. Artifacts: $INSTALL_DIR"

