#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "openblas_wrappers.h"

// Fortran LAPACK symbol (dsyev) — column-major API
extern void dsyev_(char* jobz, char* uplo, int* n, double* a, int* lda,
                   double* w, double* work, int* lwork, int* info);

static void swap_cols(double* A, int n, int i, int j) {
    if (i == j) return;
    for (int r = 0; r < n; ++r) {
        double tmp = A[r * n + i];
        A[r * n + i] = A[r * n + j];
        A[r * n + j] = tmp;
    }
}

int pca_dsyev(int n, const double* cov, double* eigvals_out, double* eigvecs_out) {
    if (!cov || !eigvals_out || !eigvecs_out || n <= 0) return -1;

    // dsyev overwrites input matrix; work on a copy
    double* A = (double*)malloc((size_t)n * (size_t)n * sizeof(double));
    if (!A) return -1;
    memcpy(A, cov, (size_t)n * (size_t)n * sizeof(double));

    // Convert row-major input to column-major for Fortran LAPACK
    double* Ac = (double*)malloc((size_t)n * (size_t)n * sizeof(double));
    if (!Ac) { free(A); return -1; }
    for (int r = 0; r < n; ++r) {
        for (int c = 0; c < n; ++c) {
            Ac[r + c * n] = A[r * n + c];
        }
    }
    free(A);

    char jobz = 'V';
    char uplo = 'U';
    int lda = n;
    int lwork = -1;
    int info = 0;
    double wkopt = 0.0;
    dsyev_(&jobz, &uplo, &n, Ac, &lda, eigvals_out, &wkopt, &lwork, &info);
    if (info != 0) { free(Ac); return info; }
    lwork = (int)wkopt;
    double* work = (double*)malloc((size_t)lwork * sizeof(double));
    if (!work) { free(Ac); return -1; }
    dsyev_(&jobz, &uplo, &n, Ac, &lda, eigvals_out, work, &lwork, &info);
    free(work);
    if (info != 0) { free(Ac); return info; }

    // Convert column-major eigenvectors back to row-major
    for (int r = 0; r < n; ++r) {
        for (int c = 0; c < n; ++c) {
            eigvecs_out[r * n + c] = Ac[r + c * n];
        }
    }
    free(Ac);

    // Reorder to descending eigenvalues (LAPACK returns ascending)
    for (int i = 0; i < n / 2; ++i) {
        int j = n - 1 - i;
        double tmp = eigvals_out[i];
        eigvals_out[i] = eigvals_out[j];
        eigvals_out[j] = tmp;
        swap_cols(eigvecs_out, n, i, j);
    }

    // Deterministic sign: make largest |loading| positive for each eigenvector
    for (int c = 0; c < n; ++c) {
        int maxIdx = 0;
        double maxAbs = 0.0;
        for (int r = 0; r < n; ++r) {
            double v = fabs(eigvecs_out[r * n + c]);
            if (v > maxAbs) { maxAbs = v; maxIdx = r; }
        }
        if (eigvecs_out[maxIdx * n + c] < 0.0) {
            for (int r = 0; r < n; ++r) eigvecs_out[r * n + c] = -eigvecs_out[r * n + c];
        }
    }

    return 0;
}
