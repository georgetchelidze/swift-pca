#!/usr/bin/env bash
set -euo pipefail

# Build OpenBLAS (+LAPACK +LAPACKE) and the C PCA shim on Linux x86_64

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENBLAS_DIR="$ROOT_DIR/Vendor/OpenBLAS"
INSTALL_DIR="$ROOT_DIR/Vendor/build/linux-x86_64"

# Limit parallelism to avoid OOM/cc1 ICE in small containers
NPROC_RAW="${NPROC:-$(command -v nproc >/dev/null 2>&1 && nproc || echo 4)}"
NPROC="${NPROC_LIMIT:-2}"
if [ "${NPROC}" = "" ]; then NPROC=2; fi

export CC=${CC:-clang}
export FC=${FC:-gfortran}
export CFLAGS="${CFLAGS:--O1}"
export FCFLAGS="${FCFLAGS:--O2}"

echo "[linux-x86_64] Building OpenBLAS into $INSTALL_DIR"
cd "$OPENBLAS_DIR"
make clean || true
make libs USE_OPENMP=0 NO_SHARED=1 NO_CBLAS=1 BINARY=64 DYNAMIC_ARCH=1 -j"$NPROC"
make PREFIX="$INSTALL_DIR" install
# Skipping LAPACKE build; wrapper calls Fortran LAPACK symbols directly (dsyev_)

echo "[linux-x86_64] Stripping shared libs (keeping static .a only)"
rm -f "$INSTALL_DIR/lib"/*.so* || true
rm -f "$INSTALL_DIR/lib"/*.dylib || true
rm -f "$INSTALL_DIR/lib"/*.dll || true

echo "[linux-x86_64] Done. Artifacts: $INSTALL_DIR"
