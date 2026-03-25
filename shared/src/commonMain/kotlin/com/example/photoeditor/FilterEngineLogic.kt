package com.example.photoeditor

data class RenderParams(
    val exposure: Float,
    val contrast: Float,
    val highlights: Float,
    val shadows: Float,
    val saturation: Float,
    val vibrance: Float,
    val warmth: Float,
    val sharpness: Float
)

class FilterEngineLogic {

    val builtinPresets: List<FilterPreset> = buildBuiltinPresets()

    /** Merge preset parameters into current EditParameters */
    fun applyPreset(preset: FilterPreset, current: EditParameters): EditParameters {
        return current.copy(
            exposure = preset.parameters.exposure,
            contrast = preset.parameters.contrast,
            highlights = preset.parameters.highlights,
            shadows = preset.parameters.shadows,
            saturation = preset.parameters.saturation,
            vibrance = preset.parameters.vibrance,
            warmth = preset.parameters.warmth,
            sharpness = preset.parameters.sharpness
        )
    }

    /** Remove preset, restore to base parameters */
    fun removePreset(base: EditParameters): EditParameters = base

    /** Map EditParameters to normalized RenderParams for platform rendering */
    fun mapToRenderParams(parameters: EditParameters): RenderParams {
        return RenderParams(
            exposure = parameters.exposure / 100f,
            contrast = parameters.contrast / 100f,
            highlights = parameters.highlights / 100f,
            shadows = parameters.shadows / 100f,
            saturation = parameters.saturation / 100f,
            vibrance = parameters.vibrance / 100f,
            warmth = parameters.warmth / 100f,
            sharpness = parameters.sharpness / 100f
        )
    }

    /** Constrain crop rect to given aspect ratio */
    fun constrainToAspectRatio(aspectRatio: AspectRatio, width: Float, height: Float): CropRect {
        val ratio = aspectRatio.ratio ?: return CropRect(0f, 0f, width, height)
        return if (width / height > ratio) {
            val newWidth = height * ratio
            val x = (width - newWidth) / 2f
            CropRect(x, 0f, newWidth, height)
        } else {
            val newHeight = width / ratio
            val y = (height - newHeight) / 2f
            CropRect(0f, y, width, newHeight)
        }
    }

    private fun buildBuiltinPresets(): List<FilterPreset> = listOf(
        FilterPreset("vivid", "鲜艳", EditParameters(exposure = 10f, contrast = 20f, saturation = 30f, vibrance = 20f)),
        FilterPreset("warm", "暖色", EditParameters(warmth = 40f, saturation = 10f, exposure = 5f)),
        FilterPreset("cool", "冷色", EditParameters(warmth = -40f, saturation = 10f, exposure = 5f)),
        FilterPreset("bw", "黑白", EditParameters(saturation = -100f, contrast = 10f)),
        FilterPreset("vintage", "复古", EditParameters(warmth = 20f, saturation = -20f, contrast = -10f, shadows = 10f)),
        FilterPreset("fade", "褪色", EditParameters(contrast = -30f, saturation = -20f, exposure = 10f)),
        FilterPreset("cinematic", "电影感", EditParameters(contrast = 30f, highlights = -20f, shadows = 20f, saturation = -10f)),
        FilterPreset("fresh", "清新", EditParameters(exposure = 15f, saturation = 20f, highlights = 10f, warmth = -10f)),
        FilterPreset("sunset", "日落", EditParameters(warmth = 50f, saturation = 20f, highlights = -10f, exposure = 5f)),
        FilterPreset("film", "胶片", EditParameters(contrast = 15f, saturation = -15f, warmth = 15f, shadows = 15f))
    )
}
