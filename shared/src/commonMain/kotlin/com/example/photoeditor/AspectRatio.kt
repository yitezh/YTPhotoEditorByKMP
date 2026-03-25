package com.example.photoeditor

enum class AspectRatio(val ratio: Float?) {
    FREE(null),
    SQUARE(1f),
    FOUR_THREE(4f / 3f),
    THREE_TWO(3f / 2f),
    SIXTEEN_NINE(16f / 9f)
}
