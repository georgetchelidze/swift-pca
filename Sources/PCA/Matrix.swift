import Foundation

public struct Matrix {
    public let rows: Int
    public let cols: Int
    public var grid: [Double]

    public init(_ rows: Int, _ cols: Int, repeating value: Double = 0.0) {
        self.rows = rows
        self.cols = cols
        self.grid = Array(repeating: value, count: rows * cols)
    }

    public init(_ data: [[Double]]) {
        self.rows = data.count
        self.cols = data.first?.count ?? 0
        self.grid = data.flatMap { $0 }
    }

    public subscript(r: Int, c: Int) -> Double {
        get { grid[r * cols + c] }
        set { grid[r * cols + c] = newValue }
    }

    public func transposed() -> Matrix {
        var t = Matrix(cols, rows)
        for r in 0..<rows {
            for c in 0..<cols {
                t[c, r] = self[r, c]
            }
        }
        return t
    }

    public static func *(lhs: Matrix, rhs: Matrix) -> Matrix {
        precondition(lhs.cols == rhs.rows, "Matrix multiplication dimension mismatch.")
        var result = Matrix(lhs.rows, rhs.cols)
        for i in 0..<lhs.rows {
            for j in 0..<rhs.cols {
                var sum = 0.0
                for k in 0..<lhs.cols {
                    sum += lhs[i, k] * rhs[k, j]
                }
                result[i, j] = sum
            }
        }
        return result
    }

    public static func /(lhs: Matrix, scalar: Double) -> Matrix {
        var result = lhs
        for i in 0..<lhs.grid.count {
            result.grid[i] /= scalar
        }
        return result
    }

    public static func -(lhs: Matrix, rhs: Matrix) -> Matrix {
        precondition(lhs.rows == rhs.rows && lhs.cols == rhs.cols)
        var result = lhs
        for i in 0..<lhs.grid.count {
            result.grid[i] -= rhs.grid[i]
        }
        return result
    }

    public func column(_ c: Int) -> [Double] {
        stride(from: c, to: grid.count, by: cols).map { grid[$0] }
    }

    public func row(_ r: Int) -> [Double] {
        Array(grid[(r * cols)..<(r * cols + cols)])
    }
}

