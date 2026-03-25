package com.example.photoeditor

import android.graphics.Bitmap
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Canvas
import android.graphics.Paint

actual class ImageRenderer {

    actual fun renderPreview(
        parameters: EditParameters,
        sourceImage: PlatformImage,
        targetSize: Size
    ): PlatformImage? {
        val scaled = Bitmap.createScaledBitmap(
            sourceImage.bitmap,
            targetSize.width,
            targetSize.height,
            true
        )
        return applyFilters(parameters, PlatformImage(scaled))
    }

    actual fun renderFullResolution(
        parameters: EditParameters,
        sourceImage: PlatformImage
    ): PlatformImage? {
        return applyFilters(parameters, sourceImage)
    }

    private fun applyFilters(parameters: EditParameters, source: PlatformImage): PlatformImage? {
        val renderParams = FilterEngineLogic().mapToRenderParams(parameters)
        val src = source.bitmap
        val result = src.copy(Bitmap.Config.ARGB_8888, true) ?: return null

        val paint = Paint()
        val colorMatrix = ColorMatrix()

        // Saturation
        val satMatrix = ColorMatrix()
        satMatrix.setSaturation(1f + renderParams.saturation)
        colorMatrix.postConcat(satMatrix)

        // Contrast & brightness (exposure mapped to brightness scale)
        val contrast = 1f + renderParams.contrast
        val brightness = renderParams.exposure * 255f
        val contrastMatrix = ColorMatrix(floatArrayOf(
            contrast, 0f, 0f, 0f, brightness,
            0f, contrast, 0f, 0f, brightness,
            0f, 0f, contrast, 0f, brightness,
            0f, 0f, 0f, 1f, 0f
        ))
        colorMatrix.postConcat(contrastMatrix)

        paint.colorFilter = ColorMatrixColorFilter(colorMatrix)

        val canvas = Canvas(result)
        canvas.drawBitmap(src, 0f, 0f, paint)

        return PlatformImage(result)
    }
}
