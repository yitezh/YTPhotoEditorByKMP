import CoreGraphics

class CropViewModel {

    var cropRect: CGRect
    var aspectRatio: AspectRatio = .free
    var rotationCount: Int = 0

    private var savedCropRect: CGRect
    private var savedAspectRatio: AspectRatio = .free
    private var savedRotationCount: Int = 0

    init(imageBounds: CGRect) {
        self.cropRect = imageBounds
        self.savedCropRect = imageBounds
    }

    func rotate90Clockwise() {
        rotationCount = (rotationCount + 1) % 4
    }

    func constrainToAspectRatio(within bounds: CGRect) {
        guard let targetRatio = aspectRatio.ratioValue else { return }
        let centerX = cropRect.midX
        let centerY = cropRect.midY
        var newWidth: CGFloat
        var newHeight: CGFloat
        if cropRect.width / cropRect.height > targetRatio {
            newHeight = cropRect.height
            newWidth = cropRect.height * targetRatio
        } else {
            newWidth = cropRect.width
            newHeight = cropRect.width / targetRatio
        }
        newWidth = min(newWidth, bounds.width)
        newHeight = min(newHeight, bounds.height)
        var originX = max(bounds.origin.x, min(centerX - newWidth / 2, bounds.maxX - newWidth))
        var originY = max(bounds.origin.y, min(centerY - newHeight / 2, bounds.maxY - newHeight))
        cropRect = CGRect(x: originX, y: originY, width: newWidth, height: newHeight)
    }

    func saveState() {
        savedCropRect = cropRect
        savedAspectRatio = aspectRatio
        savedRotationCount = rotationCount
    }

    func restoreState() {
        cropRect = savedCropRect
        aspectRatio = savedAspectRatio
        rotationCount = savedRotationCount
    }

    func reset(to imageBounds: CGRect) {
        cropRect = imageBounds
        aspectRatio = .free
        rotationCount = 0
    }
}
