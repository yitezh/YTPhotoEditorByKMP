package com.example.photoeditor

import platform.UIKit.UIImageJPEGRepresentation
import platform.UIKit.UIImagePNGRepresentation
import platform.UIKit.UIImageWriteToSavedPhotosAlbum

actual class PhotoLibraryExporter {
    actual suspend fun export(
        image: PlatformImage,
        format: ExportFormat,
        quality: Int
    ): Result<Unit> = runCatching {
        val uiImage = image.uiImage
        when (format) {
            ExportFormat.JPEG -> {
                val data = UIImageJPEGRepresentation(uiImage, quality / 100.0)
                    ?: throw IllegalStateException("Failed to encode JPEG")
                UIImageWriteToSavedPhotosAlbum(uiImage, null, null, null)
            }
            ExportFormat.PNG -> {
                UIImageWriteToSavedPhotosAlbum(uiImage, null, null, null)
            }
        }
    }
}
