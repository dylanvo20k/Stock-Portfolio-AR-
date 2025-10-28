import Foundation
import simd

// MARK: - Helper Extensions for AR

extension SIMD3 where Scalar == Float {
    func distance(to other: SIMD3<Float>) -> Float {
        let dx = self.x - other.x
        let dy = self.y - other.y
        let dz = self.z - other.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }
}
