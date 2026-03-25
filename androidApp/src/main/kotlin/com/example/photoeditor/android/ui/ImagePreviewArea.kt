package com.example.photoeditor.android.ui

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp

private val DarkBackground = Color(0xFF1A1A1A)

@Composable
fun ImagePreviewArea(
    bitmap: Bitmap?,
    isLoading: Boolean,
    error: String?,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(DarkBackground),
        contentAlignment = Alignment.Center
    ) {
        when {
            isLoading -> CircularProgressIndicator(color = Color.White)
            error != null -> Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(text = error, color = Color.White, style = MaterialTheme.typography.bodyMedium)
                Button(onClick = onRetry) { Text("重试") }
            }
            bitmap != null -> Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = "预览图",
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Fit
            )
            else -> Text("请选择照片", color = Color.Gray)
        }
    }
}
