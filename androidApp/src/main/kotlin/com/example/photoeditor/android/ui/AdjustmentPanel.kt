package com.example.photoeditor.android.ui

import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.example.photoeditor.AdjustmentKey
import com.example.photoeditor.EditParameters
import com.example.photoeditor.ToolTab

private val tabKeys: Map<ToolTab, List<AdjustmentKey>> = mapOf(
    ToolTab.LIGHT   to listOf(AdjustmentKey.EXPOSURE, AdjustmentKey.CONTRAST, AdjustmentKey.HIGHLIGHTS, AdjustmentKey.SHADOWS),
    ToolTab.COLOR   to listOf(AdjustmentKey.SATURATION, AdjustmentKey.VIBRANCE, AdjustmentKey.WARMTH),
    ToolTab.EFFECTS to emptyList(),
    ToolTab.DETAIL  to listOf(AdjustmentKey.SHARPNESS)
)

private fun EditParameters.valueOf(key: AdjustmentKey): Float = when (key) {
    AdjustmentKey.EXPOSURE   -> exposure
    AdjustmentKey.CONTRAST   -> contrast
    AdjustmentKey.HIGHLIGHTS -> highlights
    AdjustmentKey.SHADOWS    -> shadows
    AdjustmentKey.SATURATION -> saturation
    AdjustmentKey.VIBRANCE   -> vibrance
    AdjustmentKey.WARMTH     -> warmth
    AdjustmentKey.SHARPNESS  -> sharpness
}

private fun AdjustmentKey.displayName(): String = when (this) {
    AdjustmentKey.EXPOSURE   -> "曝光"
    AdjustmentKey.CONTRAST   -> "对比度"
    AdjustmentKey.HIGHLIGHTS -> "高光"
    AdjustmentKey.SHADOWS    -> "阴影"
    AdjustmentKey.SATURATION -> "饱和度"
    AdjustmentKey.VIBRANCE   -> "自然饱和度"
    AdjustmentKey.WARMTH     -> "色温"
    AdjustmentKey.SHARPNESS  -> "锐化"
}

@Composable
fun AdjustmentPanel(
    selectedTab: ToolTab,
    parameters: EditParameters,
    onParameterChange: (AdjustmentKey, Float) -> Unit,
    modifier: Modifier = Modifier
) {
    val keys = tabKeys[selectedTab] ?: emptyList()
    if (keys.isEmpty()) {
        Box(modifier.fillMaxWidth().height(120.dp), contentAlignment = Alignment.Center) {
            Text("暂无调整项", color = Color.Gray)
        }
        return
    }
    LazyColumn(modifier = modifier.fillMaxWidth()) {
        items(keys) { key ->
            AdjustmentSliderRow(
                label = key.displayName(),
                value = parameters.valueOf(key),
                onValueChange = { onParameterChange(key, it) },
                onReset = { onParameterChange(key, 0f) }
            )
        }
    }
}

@Composable
private fun AdjustmentSliderRow(
    label: String,
    value: Float,
    onValueChange: (Float) -> Unit,
    onReset: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            color = Color.White,
            style = MaterialTheme.typography.bodySmall,
            modifier = Modifier.width(72.dp)
        )
        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = -100f..100f,
            modifier = Modifier
                .weight(1f)
                .pointerInput(Unit) {
                    detectTapGestures(onDoubleTap = { onReset() })
                }
        )
        Text(
            text = value.toInt().toString(),
            color = Color.Gray,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.width(32.dp).padding(start = 8.dp)
        )
    }
}
