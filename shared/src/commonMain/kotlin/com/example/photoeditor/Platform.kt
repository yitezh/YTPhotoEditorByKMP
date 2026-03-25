package com.example.photoeditor

// Platform-specific image type
expect class PlatformImage

// Size data class
data class Size(val width: Int, val height: Int)

// Export format
enum class ExportFormat { JPEG, PNG }

// Platform-specific image renderer
expect class ImageRenderer {
    fun renderPreview(parameters: EditParameters, sourceImage: PlatformImage, targetSize: Size): PlatformImage?
    fun renderFullResolution(parameters: EditParameters, sourceImage: PlatformImage): PlatformImage?
}

// Platform-specific photo library exporter
expect class PhotoLibraryExporter {
    suspend fun export(image: PlatformImage, format: ExportFormat, quality: Int): Result<Unit>
}
