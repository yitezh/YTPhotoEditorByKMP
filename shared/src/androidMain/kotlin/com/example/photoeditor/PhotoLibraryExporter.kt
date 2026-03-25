package com.example.photoeditor

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.provider.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

// Application context holder - must be initialized in Application.onCreate()
object AppContextHolder {
    lateinit var context: Context
}

actual class PhotoLibraryExporter {
    actual suspend fun export(
        image: PlatformImage,
        format: ExportFormat,
        quality: Int
    ): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val context = AppContextHolder.context
            val bitmap = image.bitmap
            val mimeType = when (format) {
                ExportFormat.JPEG -> "image/jpeg"
                ExportFormat.PNG -> "image/png"
            }
            val extension = when (format) {
                ExportFormat.JPEG -> "jpg"
                ExportFormat.PNG -> "png"
            }
            val filename = "photo_edit_${System.currentTimeMillis()}.$extension"

            val contentValues = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/PhotoEditor")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
            }

            val resolver = context.contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw IllegalStateException("Failed to create MediaStore entry")

            resolver.openOutputStream(uri)?.use { stream ->
                val compressFormat = when (format) {
                    ExportFormat.JPEG -> Bitmap.CompressFormat.JPEG
                    ExportFormat.PNG -> Bitmap.CompressFormat.PNG
                }
                bitmap.compress(compressFormat, quality, stream)
            } ?: throw IllegalStateException("Failed to open output stream")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentValues.clear()
                contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)
            }
        }
    }
}
