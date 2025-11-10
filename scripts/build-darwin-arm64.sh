#!/usr/bin/env bash
set -euo pipefail

# Build OpenBLAS (+LAPACK +LAPACKE) and the C PCA shim on macOS ARM64

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENBLAS_DIR="$ROOT_DIR/Vendor/OpenBLAS"
INSTALL_DIR="$ROOT_DIR/Vendor/build/darwin-arm64"

NPROC="$(sysctl -n hw.ncpu)"

echo "[darwin-arm64] Building OpenBLAS into $INSTALL_DIR"
cd "$OPENBLAS_DIR"
make clean || true
make libs USE_OPENMP=0 NO_SHARED=1 NO_CBLAS=1 BINARY=64 TARGET=ARMV8 -j"$NPROC"
make PREFIX="$INSTALL_DIR" install
# Skipping LAPACKE build; wrapper calls Fortran LAPACK symbols directly (dsyev_)

echo "[darwin-arm64] Stripping shared libs (keeping static .a only)"
rm -f "$INSTALL_DIR/lib"/*.dylib || true
rm -f "$INSTALL_DIR/lib"/*.so* || true
rm -f "$INSTALL_DIR/lib"/*.dll || true

echo "[darwin-arm64] Done. Artifacts: $INSTALL_DIR"
