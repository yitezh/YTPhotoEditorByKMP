package com.example.photoeditor.android.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.example.photoeditor.AspectRatio
import com.example.photoeditor.CropRect

private val aspectRatioLabels = listOf(
    AspectRatio.FREE        to "自由",
    AspectRatio.SQUARE      to "1:1",
    AspectRatio.FOUR_THREE  to "4:3",
    AspectRatio.THREE_TWO   to "3:2",
    AspectRatio.SIXTEEN_NINE to "16:9"
)

@Composable
fun CropOverlay(
    initialCropRect: CropRect?,
    imageWidth: Float,
    imageHeight: Float,
    onConfirm: (CropRect) -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedRatio by remember { mutableStateOf(AspectRatio.FREE) }
    var cropRect by remember {
        mutableStateOf(initialCropRect ?: CropRect(0f, 0f, imageWidth, imageHeight))
    }

    // Recompute crop rect when aspect ratio changes
    LaunchedEffect(selectedRatio, imageWidth, imageHeight) {
        val ratio = selectedRatio.ratio
        cropRect = if (ratio == null) {
            CropRect(0f, 0f, imageWidth, imageHeight)
        } else {
            if (imageWidth / imageHeight > ratio) {
                val w = imageHeight * ratio
                CropRect((imageWidth - w) / 2f, 0f, w, imageHeight)
            } else {
                val h = imageWidth / ratio
                CropRect(0f, (imageHeight - h) / 2f, imageWidth, h)
            }
        }
    }

    Column(modifier = modifier.fillMaxSize().background(Color(0xCC000000))) {
        // Crop canvas
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .pointerInput(imageWidth, imageHeight) {
                    detectDragGestures { change, dragAmount ->
                        change.consume()
                        val newX = (cropRect.x + dragAmount.x).coerceIn(0f, imageWidth - cropRect.width)
                        val newY = (cropRect.y + dragAmount.y).coerceIn(0f, imageHeight - cropRect.height)
                        cropRect = cropRect.copy(x = newX, y = newY)
                    }
                }
                .drawWithContent {
                    drawContent()
                    if (imageWidth > 0f && imageHeight > 0f) {
                        val scaleX = size.width / imageWidth
                        val scaleY = size.height / imageHeight
                        val rect = androidx.compose.ui.geometry.Rect(
                            left   = cropRect.x * scaleX,
                            top    = cropRect.y * scaleY,
                            right  = (cropRect.x + cropRect.width) * scaleX,
                            bottom = (cropRect.y + cropRect.height) * scaleY
                        )
                        drawRect(
                            color = Color.White,
                            topLeft = Offset(rect.left, rect.top),
                            size = Size(rect.width, rect.height),
                            style = Stroke(width = 2.dp.toPx())
                        )
                    }
                }
        )

        // Aspect ratio selector
        LazyRow(
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
            contentPadding = PaddingValues(horizontal = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(aspectRatioLabels) { (ratio, label) ->
                val isSelected = ratio == selectedRatio
                Text(
                    text = label,
                    color = if (isSelected) MaterialTheme.colorScheme.primary else Color.White,
                    style = MaterialTheme.typography.labelMedium,
                    modifier = Modifier
                        .border(
                            1.dp,
                            if (isSelected) MaterialTheme.colorScheme.primary else Color.Gray,
                            RoundedCornerShape(4.dp)
                        )
                        .clickable { selectedRatio = ratio }
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                )
            }
        }

        // Confirm / Cancel buttons
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            TextButton(onClick = onCancel) {
                Text("取消", color = Color.White)
            }
            Button(onClick = { onConfirm(cropRect) }) {
                Text("确认")
            }
        }
    }
}
