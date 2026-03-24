package com.example.photoeditor

import kotlinx.serialization.Serializable

@Serializable
data class FilterPreset(
    val id: String,
    val name: String,
    val parameters: EditParameters
)
