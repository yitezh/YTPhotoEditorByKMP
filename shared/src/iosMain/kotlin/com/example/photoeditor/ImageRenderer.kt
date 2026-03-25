package com.example.photoeditor

import platform.CoreImage.CIContext
import platform.CoreImage.CIFilter
import platform.CoreImage.CIImage
import platform.CoreImage.filterWithName
import platform.CoreImage.kCIInputEVKey
import platform.CoreImage.kCIInputImageKey
import platform.CoreImage.kCIInputSaturationKey
import platform.CoreImage.kCIInputSharpnessKey
import platform.UIKit.UIImage

actual class ImageRenderer {
    private val context = CIContext()

    actual fun renderPreview(
        parameters: EditParameters,
        sourceImage: PlatformImage,
        targetSize: Size
    ): PlatformImage? {
        return applyFilters(parameters, sourceImage)
    }

    actual fun renderFullResolution(
        parameters: EditParameters,
        sourceImage: PlatformImage
    ): PlatformImage? {
        return applyFilters(parameters, sourceImage)
    }

    private fun applyFilters(parameters: EditParameters, source: PlatformImage): PlatformImage? {
        val renderParams = FilterEngineLogic().mapToRenderParams(parameters)
        var ciImage = CIImage(image = source.uiImage) ?: return null

        // Exposure
        CIFilter.filterWithName("CIExposureAdjust")?.let { filter ->
            filter.setValue(ciImage, forKey = kCIInputImageKey)
            filter.setValue(renderParams.exposure * 3f, forKey = kCIInputEVKey)
            filter.outputImage?.let { ciImage = it }
        }

        // Color controls (contrast, saturation)
        CIFilter.filterWithName("CIColorControls")?.let { filter ->
            filter.setValue(ciImage, forKey = kCIInputImageKey)
            filter.setValue(1f + renderParams.contrast, forKey = "inputContrast")
            filter.setValue(1f + renderParams.saturation, forKey = kCIInputSaturationKey)
            filter.outputImage?.let { ciImage = it }
        }

        // Sharpness
        if (renderParams.sharpness != 0f) {
            CIFilter.filterWithName("CISharpenLuminance")?.let { filter ->
                filter.setValue(ciImage, forKey = kCIInputImageKey)
                filter.setValue(renderParams.sharpness, forKey = kCIInputSharpnessKey)
                filter.outputImage?.let { ciImage = it }
            }
        }

        val cgImage = context.createCGImage(ciImage, fromRect = ciImage.extent) ?: return null
        return PlatformImage(UIImage(cgImage))
    }
}
