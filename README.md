# swift-pca

A tiny, self-contained Principal Component Analysis (PCA) implementation in pure Swift. It includes a minimal `Matrix` type, a QR-iteration–based eigen solver, and a simple API to fit and use PCA on 2D `[[Double]]` data.

## Features
- Simple `Matrix` with multiply, transpose, add/subtract by scalar
- Covariance computation and eigen decomposition via QR iteration
- Deterministic principal component signs (dominant loading made positive)
- Transform, inverse transform, explained variance, and ratios
- Zero dependencies; works with Swift Package Manager

## Requirements
- Swift 5.9+ (Xcode 15+) recommended
- macOS 13+ (other platforms may work with SPM)

## Quick Start
```swift
import PCA

// Example 2D dataset (rows = samples, cols = features)
let data: [[Double]] = [
    [2.5, 2.4], [0.5, 0.7], [2.2, 2.9], [1.9, 2.2],
    [3.1, 3.0], [2.3, 2.7], [2.0, 1.6], [1.0, 1.1],
    [1.5, 1.6], [1.1, 0.9]
]

// Fit a 2-component PCA model
let pca = PCA.fit(data: data, nComponents: 2)

// Project the data into the PCA space
let Z = pca.transform(data: data)

print("Mean:", pca.mean)
print("Explained Variance:", pca.explainedVariance)
print("Explained Variance Ratio:", pca.explainedVarianceRatio)
print("Components (columns are PCs):")
for r in 0..<pca.components.rows {
    print((0..<pca.components.cols).map { pca.components[r, $0] })
}

// Optionally reconstruct back to original space
let Xhat = pca.inverseTransform(data: Z)
```

## API
- `PCA.fit(data:nComponents:) -> PCA`
  - Learns principal components from row-major `[[Double]]` data.
- `PCA.transform(data:) -> [[Double]]`
  - Centers input by the learned mean and projects onto the components.
- `PCA.fitTransform(data:nComponents:) -> ([[Double]], PCA)`
  - Convenience to fit and immediately transform.
- `PCA.inverseTransform(data:) -> [[Double]]`
  - Reconstructs from component space back to original feature space.
- Properties
  - `components: Matrix` (columns are unit PCs)
  - `mean: [Double]`
  - `explainedVariance: [Double]`
  - `explainedVarianceRatio: [Double]`

## Implementation Notes
- Eigen decomposition uses classical Gram-Schmidt QR decomposition and QR iteration.
- Convergence: the loop stops when the maximum absolute off-diagonal element falls below `tol` (default `1e-10`).
- Deterministic signs: after sorting eigenvectors by descending eigenvalue, each component column is flipped so that its largest-magnitude loading is positive.
- The math is educational and compact, not production-optimized. For large, ill-conditioned, or high-precision workloads, consider Accelerate/LAPACK or other robust numerical libraries.

## Running
- Build: `swift build`
- Tests: `swift test`

The test at `Tests/PCATests/PCATests.swift` demonstrates fitting PCA to a small dataset and performs basic sanity checks.

## Data Shape
- Input is `[[Double]]` with shape `(nSamples, nFeatures)`.
- `nComponents` must be `<= nFeatures`.

## Limitations
- No input validation for NaNs/Infs.
- Naive numerical routines; not optimized for performance or stability on very large matrices.
- Single precision type (`Double`) only.

## Acknowledgments
- PCA formulation and QR iteration are standard linear algebra techniques; this project offers a lightweight Swift reference implementation.
