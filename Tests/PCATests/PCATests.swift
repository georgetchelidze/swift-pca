import Foundation
import Testing
@testable import PCA

@Test func pcaExample() async throws {
    // Classic 2D dataset used in many PCA tutorials
    let data: [[Double]] = [
        [2.5, 2.4],
        [0.5, 0.7],
        [2.2, 2.9],
        [1.9, 2.2],
        [3.1, 3.0],
        [2.3, 2.7],
        [2.0, 1.6],
        [1.0, 1.1],
        [1.5, 1.6],
        [1.1, 0.9]
    ]

    // Fit the PCA model
    let pca = PCA.fit(data: data, nComponents: 2)
    let transformed = pca.transform(data: data)

    print("Mean:", pca.mean)
    print("Explained Variance:", pca.explainedVariance)
    print("Explained Variance Ratio:", pca.explainedVarianceRatio)
    print("Principal Components (columns):")
    for r in 0..<pca.components.rows {
        print((0..<pca.components.cols).map { pca.components[r, $0] })
    }
    print("Transformed Data:")
    for row in transformed {
        print(row)
    }

    // Basic validation
    #expect(pca.components.cols == 2)
    #expect(pca.mean.count == 2)
    #expect(pca.explainedVariance.count == 2)
    #expect(transformed.count == data.count)

    // The variance should be non-negative
    #expect(pca.explainedVariance.allSatisfy { $0 >= 0 })
}
