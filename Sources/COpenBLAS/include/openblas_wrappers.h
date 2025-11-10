#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Compute eigenvalues and eigenvectors of a symmetric matrix using LAPACKE dsyev.
// Parameters:
//   n           : matrix dimension
//   cov         : input symmetric matrix (row-major, upper triangle used); size n*n
//   eigvals_out : output eigenvalues (descending after internal reorder); size n
//   eigvecs_out : output eigenvectors (row-major, columns are vectors after reorder); size n*n
// Returns 0 on success, nonzero LAPACKE info code otherwise.
int pca_dsyev(int n, const double* cov, double* eigvals_out, double* eigvecs_out);

#ifdef __cplusplus
}
#endif

