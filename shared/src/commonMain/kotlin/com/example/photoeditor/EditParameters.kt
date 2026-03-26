package com.example.photoeditor

import kotlinx.serialization.Serializable

@Serializable
data class CropRect(
    val x: Float,
    val y: Float,
    val width: Float,
    val height: Float
)

@Serializable
data class EditParameters(
    val exposure: Float = 0f,      // -100 ~ +100
    val contrast: Float = 0f,
    val highlights: Float = 0f,
    val shadows: Float = 0f,
    val saturation: Float = 0f,
    val vibrance: Float = 0f,
    val warmth: Float = 0f,
    val sharpness: Float = 0f,
    val texture: Float = 0f,
    val clarity: Float = 0f,
    val dehaze: Float = 0f,
    val cropRect: CropRect? = null,
    val rotationCount: Int = 0     // 0-3, clockwise 90° count
) {
    val isDefault: Boolean get() = this == EditParameters()
}

/** Returns a new EditParameters with rotationCount incremented by 1 (mod 4 semantics) */
fun EditParameters.rotate(): EditParameters = copy(rotationCount = (rotationCount + 1) % 4)
