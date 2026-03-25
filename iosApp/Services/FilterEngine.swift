import CoreImage
import UIKit

class FilterEngine {

    private let context: CIContext

    init() {
        context = CIContext(options: [
            .useSoftwareRenderer: false,
            .highQualityDownsample: true
        ])
    }

    func apply(parameters: EditParameters, to image: CIImage) -> CIImage {
        var output = image
        output = applyExposure(output, value: parameters.exposure)
        output = applyColorControls(output, contrast: parameters.contrast, saturation: parameters.saturation)
        output = applyHighlightShadow(output, highlights: parameters.highlights, shadows: parameters.shadows)
        output = applyTemperature(output, warmth: parameters.warmth)
        output = applyVibrance(output, value: parameters.vibrance)
        output = applySharpness(output, value: parameters.sharpness)
        output = applyTexture(output, value: parameters.texture)
        output = applyClarity(output, value: parameters.clarity)
        output = applyDehaze(output, value: parameters.dehaze)
        if parameters.rotationCount > 0 {
            output = applyRotation(output, count: parameters.rotationCount)
        }
        if let codableCrop = parameters.cropRect {
            output = applyCrop(output, rect: codableCrop.cgRect)
        }
        return output
    }

    func generatePreview(parameters: EditParameters, source: CIImage, targetSize: CGSize) -> UIImage? {
        let processed = apply(parameters: parameters, to: source)
        let extent = processed.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        let scale = min(targetSize.width / extent.width, targetSize.height / extent.height, 1.0)
        let final: CIImage
        if scale < 1.0 {
            final = processed.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        } else {
            final = processed
        }
        guard let cgImage = context.createCGImage(final, from: final.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func renderFullResolution(parameters: EditParameters, source: CIImage) -> CGImage? {
        let processed = apply(parameters: parameters, to: source)
        return context.createCGImage(processed, from: processed.extent)
    }

    private func applyExposure(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let ev = value / 100.0 * 3.0
        guard let filter = CIFilter(name: "CIExposureAdjust") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(ev, forKey: "inputEV")
        return filter.outputImage ?? image
    }

    private func applyColorControls(_ image: CIImage, contrast: Float, saturation: Float) -> CIImage {
        guard contrast != 0 || saturation != 0 else { return image }
        let ciContrast = 1.0 + contrast / 100.0 * 0.75
        let ciSaturation = 1.0 + saturation / 100.0
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(ciContrast, forKey: "inputContrast")
        filter.setValue(ciSaturation, forKey: "inputSaturation")
        filter.setValue(Float(0), forKey: "inputBrightness")
        return filter.outputImage ?? image
    }

    private func applyHighlightShadow(_ image: CIImage, highlights: Float, shadows: Float) -> CIImage {
        guard highlights != 0 || shadows != 0 else { return image }
        let hlAmount = 1.0 - highlights / 100.0
        let shAmount = shadows / 100.0
        guard let filter = CIFilter(name: "CIHighlightShadowAdjust") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(hlAmount, forKey: "inputHighlightAmount")
        filter.setValue(shAmount, forKey: "inputShadowAmount")
        return filter.outputImage ?? image
    }

    private func applyTemperature(_ image: CIImage, warmth: Float) -> CIImage {
        guard warmth != 0 else { return image }
        let temperature = 6500.0 + Double(warmth) / 100.0 * 1500.0
        guard let filter = CIFilter(name: "CITemperatureAndTint") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: CGFloat(temperature), y: 0), forKey: "inputNeutral")
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
        return filter.outputImage ?? image
    }

    private func applyVibrance(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let amount = value / 100.0
        guard let filter = CIFilter(name: "CIVibrance") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount, forKey: "inputAmount")
        return filter.outputImage ?? image
    }

    private func applySharpness(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let sharpness = max(0, value) / 100.0 * 2.0
        guard let filter = CIFilter(name: "CISharpenLuminance") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(sharpness, forKey: "inputSharpness")
        return filter.outputImage ?? image
    }

    private func applyTexture(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let intensity = value / 100.0 * 1.5
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(abs(intensity), forKey: "inputIntensity")
        filter.setValue(0.5, forKey: "inputRadius")
        if value < 0 {
            return image.applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.0 + (value / 100.0 * 0.2)
            ])
        }
        return filter.outputImage ?? image
    }

    private func applyClarity(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let intensity = value / 100.0 * 2.0
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(abs(intensity), forKey: "inputIntensity")
        filter.setValue(5.0, forKey: "inputRadius")
        if value < 0 {
            guard let blur = CIFilter(name: "CIGaussianBlur") else { return image }
            blur.setValue(image, forKey: kCIInputImageKey)
            blur.setValue(abs(value) / 100.0 * 2.0, forKey: "inputRadius")
            guard let blurred = blur.outputImage else { return image }
            let alpha = abs(value) / 100.0 * 0.5
            return blurred.applyingFilter("CIColorControls", parameters: [
                "inputBrightness": 0,
                "inputContrast": 1.0 - alpha * 0.3
            ])
        }
        return filter.outputImage ?? image
    }

    private func applyDehaze(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let strength = value / 100.0
        guard let contrast = CIFilter(name: "CIColorControls") else { return image }
        contrast.setValue(image, forKey: kCIInputImageKey)
        contrast.setValue(1.0 + strength * 0.4, forKey: "inputContrast")
        contrast.setValue(1.0 + strength * 0.2, forKey: "inputSaturation")
        contrast.setValue(strength * 0.1, forKey: "inputBrightness")
        return contrast.outputImage ?? image
    }

    private func applyCrop(_ image: CIImage, rect: CGRect) -> CIImage {
        let clampedRect = rect.intersection(image.extent)
        guard !clampedRect.isEmpty else { return image }
        return image.cropped(to: clampedRect)
    }

    private func applyRotation(_ image: CIImage, count: Int) -> CIImage {
        let normalizedCount = ((count % 4) + 4) % 4
        guard normalizedCount > 0 else { return image }
        var output = image
        for _ in 0..<normalizedCount {
            output = rotate90Clockwise(output)
        }
        return output
    }

    private func rotate90Clockwise(_ image: CIImage) -> CIImage {
        let width = image.extent.width
        let rotation = CGAffineTransform(rotationAngle: -.pi / 2)
        let translation = CGAffineTransform(translationX: 0, y: width)
        var rotated = image.transformed(by: rotation.concatenating(translation))
        let origin = rotated.extent.origin
        if origin.x != 0 || origin.y != 0 {
            rotated = rotated.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))
        }
        return rotated
    }
}
