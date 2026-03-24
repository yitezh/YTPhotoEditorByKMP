package com.example.photoeditor.android.ui

import android.graphics.Bitmap
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.photoeditor.AdjustmentKey
import com.example.photoeditor.CropRect
import com.example.photoeditor.ExportFormat
import com.example.photoeditor.ToolTab
import com.example.photoeditor.android.PhotoEditorViewModel

@Composable
fun PhotoEditorScreen(
    viewModel: PhotoEditorViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current

    var selectedTab by remember { mutableStateOf(ToolTab.LIGHT) }
    var showCrop by remember { mutableStateOf(false) }

    // Auto-load sample photo on first launch
    LaunchedEffect(Unit) {
        if (uiState.previewBitmap == null && !uiState.isLoading) {
            viewModel.loadSamplePhoto()
        }
    }

    // Photo picker launcher
    val photoPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri ->
        uri ?: return@rememberLauncherForActivityResult
        val stream = context.contentResolver.openInputStream(uri) ?: return@rememberLauncherForActivityResult
        val bitmap = android.graphics.BitmapFactory.decodeStream(stream)
        stream.close()
        bitmap?.let { viewModel.loadPhoto(it) }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            // Top bar
            TopBar(
                canUndo = uiState.canUndo,
                canRedo = uiState.canRedo,
                isExporting = uiState.isExporting,
                onUndo = viewModel::undo,
                onRedo = viewModel::redo,
                onPickPhoto = { photoPicker.launch("image/*") },
                onExport = { viewModel.exportPhoto(ExportFormat.JPEG) },
                onCrop = { showCrop = true },
                onLoadSample = { viewModel.loadSamplePhoto() }
            )

            // Preview area
            ImagePreviewArea(
                bitmap = uiState.previewBitmap,
                isLoading = uiState.isLoading,
                error = uiState.error,
                onRetry = { photoPicker.launch("image/*") },
                modifier = Modifier.weight(1f)
            )

            // Filter preset row
            FilterPresetRow(
                presets = com.example.photoeditor.FilterEngineLogic().builtinPresets,
                activePresetId = uiState.activePresetId,
                thumbnails = emptyMap(),
                onApplyPreset = viewModel::applyPreset,
                onRemovePreset = viewModel::removePreset,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(96.dp)
                    .padding(vertical = 8.dp)
            )

            // Tool tab bar
            ToolTabBar(
                selectedTab = selectedTab,
                onTabSelected = { selectedTab = it }
            )

            // Adjustment panel
            AdjustmentPanel(
                selectedTab = selectedTab,
                parameters = uiState.parameters,
                onParameterChange = { key: AdjustmentKey, value: Float ->
                    viewModel.updateParameter(key, value)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
            )
        }

        // Crop overlay (full-screen)
        if (showCrop) {
            val bitmap = uiState.previewBitmap
            val w = bitmap?.width?.toFloat() ?: 1080f
            val h = bitmap?.height?.toFloat() ?: 1920f
            CropOverlay(
                initialCropRect = uiState.parameters.cropRect,
                imageWidth = w,
                imageHeight = h,
                onConfirm = { rect: CropRect ->
                    viewModel.applyCrop(rect, uiState.parameters.rotationCount)
                    showCrop = false
                },
                onCancel = { showCrop = false },
                modifier = Modifier.fillMaxSize()
            )
        }

        // Export progress overlay
        if (uiState.isExporting) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }
    }
}

@Composable
private fun TopBar(
    canUndo: Boolean,
    canRedo: Boolean,
    isExporting: Boolean,
    onUndo: () -> Unit,
    onRedo: () -> Unit,
    onPickPhoto: () -> Unit,
    onExport: () -> Unit,
    onCrop: () -> Unit,
    onLoadSample: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onPickPhoto) {
            Icon(Icons.Filled.PhotoLibrary, contentDescription = "选择照片", tint = Color.White)
        }
        IconButton(onClick = onLoadSample) {
            Icon(Icons.Filled.Image, contentDescription = "测试图", tint = Color(0xFF888888))
        }
        Spacer(Modifier.weight(1f))
        IconButton(onClick = onUndo, enabled = canUndo) {
            Icon(Icons.Filled.Undo, contentDescription = "撤销",
                tint = if (canUndo) Color.White else Color.Gray)
        }
        IconButton(onClick = onRedo, enabled = canRedo) {
            Icon(Icons.Filled.Redo, contentDescription = "重做",
                tint = if (canRedo) Color.White else Color.Gray)
        }
        IconButton(onClick = onCrop) {
            Icon(Icons.Filled.Crop, contentDescription = "裁剪", tint = Color.White)
        }
        IconButton(onClick = onExport, enabled = !isExporting) {
            Icon(Icons.Filled.FileDownload, contentDescription = "导出",
                tint = if (!isExporting) Color.White else Color.Gray)
        }
    }
}
