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
        var (eigenvalues, eigenvectors) = eigenDecompositionQR(C)

        // Sort eigenvalues descending
        let sorted = zip(eigenvalues, (0..<eigenvalues.count)).sorted { $0.0 > $1.0 }
        eigenvalues = sorted.map { $0.0 }
        let order = sorted.map { $0.1 }
        var sortedVectors = Matrix(eigenvectors.rows, nComponents)
        for newCol in 0..<nComponents {
            let oldCol = order[newCol]
            for r in 0..<eigenvectors.rows {
                sortedVectors[r, newCol] = eigenvectors[r, oldCol]
            }
        }

        // Make component signs deterministic: largest |loading| should be positive
        for j in 0..<sortedVectors.cols {
            var maxIdx = 0
            var maxAbs = 0.0
            for i in 0..<sortedVectors.rows {
                let v = abs(sortedVectors[i, j])
                if v > maxAbs { maxAbs = v; maxIdx = i }
            }
            if sortedVectors[maxIdx, j] < 0 {
                for i in 0..<sortedVectors.rows { sortedVectors[i, j] *= -1 }
            }
        }

        let topEigenvalues = Array(eigenvalues.prefix(nComponents))
        return PCA(components: sortedVectors, mean: mean, explainedVariance: topEigenvalues)
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
