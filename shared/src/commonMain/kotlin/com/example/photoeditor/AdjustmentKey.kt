package com.example.photoeditor

enum class ToolTab { LIGHT, COLOR, EFFECTS, DETAIL }

enum class AdjustmentKey {
    EXPOSURE, CONTRAST, HIGHLIGHTS, SHADOWS,
    SATURATION, VIBRANCE, WARMTH, SHARPNESS;

    val tabGroup: ToolTab get() = when (this) {
        EXPOSURE, CONTRAST, HIGHLIGHTS, SHADOWS -> ToolTab.LIGHT
        SATURATION, VIBRANCE, WARMTH -> ToolTab.COLOR
        SHARPNESS -> ToolTab.DETAIL
    }
}
