import Foundation
import COpenBLAS

// Eigen decomposition of a symmetric matrix using LAPACKE via COpenBLAS
func eigenDecompositionBLAS(_ A: Matrix) -> ([Double], Matrix) {
    precondition(A.rows == A.cols, "Matrix must be square.")
    let n = A.rows

    let cov = A.grid // row-major copy
    var eigvals = [Double](repeating: 0.0, count: n)
    var eigvecs = [Double](repeating: 0.0, count: n * n)

    let info: Int32 = eigvals.withUnsafeMutableBufferPointer { ev in
        eigvecs.withUnsafeMutableBufferPointer { evec in
            cov.withUnsafeBufferPointer { covBuf in
                pca_dsyev(Int32(n), covBuf.baseAddress, ev.baseAddress, evec.baseAddress)
            }
        }
    }
    precondition(info == 0, "LAPACKE dsyev failed with info=\(info)")

    var V = Matrix(n, n)
    for r in 0..<n {
        for c in 0..<n {
            V[r, c] = eigvecs[r * n + c]
        }
    }
    return (eigvals, V)
}
