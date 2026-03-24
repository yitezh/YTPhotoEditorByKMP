import Foundation
import CoreGraphics

/// Core data structure holding all editing parameters.
struct EditParameters: Codable, Equatable {
    var exposure: Float = 0
    var contrast: Float = 0
    var highlights: Float = 0
    var shadows: Float = 0
    var saturation: Float = 0
    var vibrance: Float = 0
    var warmth: Float = 0
    var sharpness: Float = 0
    var texture: Float = 0
    var clarity: Float = 0
    var dehaze: Float = 0

    var cropRect: CodableCGRect?
    var rotationCount: Int = 0

    static let `default` = EditParameters()

    var isDefault: Bool {
        return self == EditParameters.default
    }
}

struct CodableCGRect: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    init(_ rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }
}
