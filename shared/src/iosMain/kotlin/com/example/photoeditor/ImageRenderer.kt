@file:OptIn(kotlinx.cinterop.ExperimentalForeignApi::class, kotlinx.cinterop.BetaInteropApi::class)

package com.example.photoeditor

import kotlinx.cinterop.*
import platform.CoreGraphics.*
import platform.CoreImage.*
import platform.Foundation.NSNumber
import platform.Foundation.setValue
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
        val inputData = platform.UIKit.UIImagePNGRepresentation(source.uiImage) ?: return null
        var ciImage = CIImage(data = inputData) ?: return null

        // Exposure
        CIFilter.filterWithName("CIExposureAdjust")?.let { filter ->
            filter.setDefaults()
            filter.setValue(ciImage, forKey = "inputImage")
            filter.setValue(NSNumber(float = renderParams.exposure * 3f), forKey = "inputEV")
            filter.outputImage?.let { ciImage = it }
        }

        // Color controls (contrast, saturation)
        CIFilter.filterWithName("CIColorControls")?.let { filter ->
            filter.setDefaults()
            filter.setValue(ciImage, forKey = "inputImage")
            filter.setValue(NSNumber(float = 1f + renderParams.contrast), forKey = "inputContrast")
            filter.setValue(NSNumber(float = 1f + renderParams.saturation), forKey = "inputSaturation")
            filter.outputImage?.let { ciImage = it }
        }

        // Sharpness
        if (renderParams.sharpness != 0f) {
            CIFilter.filterWithName("CISharpenLuminance")?.let { filter ->
                filter.setDefaults()
                filter.setValue(ciImage, forKey = "inputImage")
                filter.setValue(NSNumber(float = renderParams.sharpness), forKey = "inputSharpness")
                filter.outputImage?.let { ciImage = it }
            }
        }

        val extent = ciImage.extent
        val cgImage = context.createCGImage(ciImage, fromRect = extent) ?: return null
        return PlatformImage(UIImage(cGImage = cgImage))
    }
}
