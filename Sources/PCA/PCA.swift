import Foundation

// MARK: - PCA

public struct PCA {
    public let components: Matrix
    public let mean: [Double]
    public let explainedVariance: [Double]
    public let explainedVarianceRatio: [Double]

    public init(components: Matrix, mean: [Double], explainedVariance: [Double]) {
        self.components = components
        self.mean = mean
        self.explainedVariance = explainedVariance
        let total = explainedVariance.reduce(0, +)
        self.explainedVarianceRatio = explainedVariance.map { $0 / total }
    }

    public static func fit(data: [[Double]], nComponents: Int) -> PCA {
        let X = Matrix(data)
        let mean = (0..<X.cols).map { c in X.column(c).reduce(0, +) / Double(X.rows) }

        var centered = X
        for r in 0..<X.rows {
            for c in 0..<X.cols {
                centered[r, c] -= mean[c]
            }
        }

        let C = (centered.transposed() * centered) / Double(X.rows - 1)
        var (eigenvalues, eigenvectors) = eigenDecompositionBLAS(C)

        // eigenDecompositionBLAS already returns descending by value and deterministic signs.
        var comps = Matrix(eigenvectors.rows, nComponents)
        for newCol in 0..<nComponents {
            for r in 0..<eigenvectors.rows {
                comps[r, newCol] = eigenvectors[r, newCol]
            }
        }

        let topEigenvalues = Array(eigenvalues.prefix(nComponents))
        return PCA(components: comps, mean: mean, explainedVariance: topEigenvalues)
    }

    public func transform(data: [[Double]]) -> [[Double]] {
        let X = Matrix(data)
        var centered = X
        for r in 0..<X.rows {
            for c in 0..<X.cols {
                centered[r, c] -= mean[c]
            }
        }
        let projected = centered * components
        return (0..<projected.rows).map { projected.row($0) }
    }

    public func fitTransform(data: [[Double]], nComponents: Int) -> ([[Double]], PCA) {
        let model = PCA.fit(data: data, nComponents: nComponents)
        let transformed = model.transform(data: data)
        return (transformed, model)
    }

    public func inverseTransform(data: [[Double]]) -> [[Double]] {
        let X = Matrix(data)
        let reconstructed = X * components.transposed()
        var restored = Matrix(reconstructed.rows, reconstructed.cols)
        for r in 0..<reconstructed.rows {
            for c in 0..<reconstructed.cols {
                restored[r, c] = reconstructed[r, c] + mean[c]
            }
        }
        return (0..<restored.rows).map { restored.row($0) }
    }
}
