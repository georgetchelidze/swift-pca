import Foundation

// MARK: - QR Decomposition (Eigen solver helpers)

func qrDecomposition(_ A: Matrix) -> (Matrix, Matrix) {
    var Q = Matrix(A.rows, A.cols)
    var R = Matrix(A.cols, A.cols)

    var u = (0..<A.cols).map { A.column($0) }
    var e = u

    for i in 0..<A.cols {
        for j in 0..<i {
            let dotVal = dot(A.column(i), e[j])
            R[j, i] = dotVal
            u[i] = zip(u[i], e[j]).map { $0 - dotVal * $1 }
        }
        let norm = sqrt(dot(u[i], u[i]))
        R[i, i] = norm
        e[i] = u[i].map { $0 / norm }
    }

    for i in 0..<A.rows {
        for j in 0..<A.cols {
            Q[i, j] = e[j][i]
        }
    }
    return (Q, R)
}

func dot(_ a: [Double], _ b: [Double]) -> Double {
    zip(a, b).reduce(0.0) { $0 + $1.0 * $1.1 }
}

// MARK: - Eigen Decomposition via QR Iteration

func eigenDecompositionQR(_ A: Matrix, maxIter: Int = 1000, tol: Double = 1e-10) -> ([Double], Matrix) {
    precondition(A.rows == A.cols, "Matrix must be square.")
    var Ak = A
    var V = Matrix(A.rows, A.cols)
    for i in 0..<A.rows { V[i, i] = 1.0 }

    for _ in 0..<maxIter {
        let (Q, R) = qrDecomposition(Ak)
        Ak = R * Q
        V = V * Q
        // Use the maximum absolute off-diagonal value as convergence criterion
        if (absOffDiagonal(Ak).max() ?? 0.0) < tol { break }
    }

    var eigenvalues = [Double]()
    for i in 0..<Ak.rows { eigenvalues.append(Ak[i, i]) }
    return (eigenvalues, V)
}

func absOffDiagonal(_ A: Matrix) -> [Double] {
    var vals: [Double] = []
    for i in 0..<A.rows {
        for j in 0..<A.cols where i != j {
            vals.append(abs(A[i, j]))
        }
    }
    return vals
}

