package com.example.photoeditor.android

import android.graphics.Bitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.photoeditor.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class PhotoEditorUiState(
    val parameters: EditParameters = EditParameters(),
    val previewBitmap: Bitmap? = null,
    val canUndo: Boolean = false,
    val canRedo: Boolean = false,
    val activePresetId: String? = null,
    val isExporting: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)

class PhotoEditorViewModel : ViewModel() {

    private val editHistory = EditHistory()
    private val filterEngine = FilterEngineLogic()
    private val imageRenderer = ImageRenderer()
    private val exporter = PhotoLibraryExporter()

    private var sourceImage: PlatformImage? = null
    private var baseParameters = EditParameters()

    private val _uiState = MutableStateFlow(PhotoEditorUiState())
    val uiState: StateFlow<PhotoEditorUiState> = _uiState.asStateFlow()

    // MARK: - Photo Loading

    fun loadSamplePhoto() {
        val bitmap = Bitmap.createBitmap(800, 600, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bitmap)
        val paint = android.graphics.Paint()
        val shader = android.graphics.LinearGradient(
            0f, 0f, 800f, 600f,
            intArrayOf(0xFF1A6B3C.toInt(), 0xFF4A90D9.toInt(), 0xFFD4A017.toInt()),
            null,
            android.graphics.Shader.TileMode.CLAMP
        )
        paint.shader = shader
        canvas.drawRect(0f, 0f, 800f, 600f, paint)
        paint.shader = null
        paint.color = 0x44FFFFFF.toInt()
        canvas.drawCircle(200f, 200f, 120f, paint)
        canvas.drawCircle(600f, 400f, 80f, paint)
        paint.color = 0x33000000.toInt()
        canvas.drawCircle(400f, 300f, 150f, paint)
        loadPhoto(bitmap)
    }

    fun loadPhoto(bitmap: Bitmap) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val platformImage = PlatformImage(bitmap)
                sourceImage = platformImage
                val params = EditParameters()
                baseParameters = params
                editHistory.clear()
                editHistory.push(params)
                val preview = withContext(Dispatchers.Default) {
                    imageRenderer.renderPreview(
                        params, platformImage,
                        Size(bitmap.width.coerceAtMost(1080), bitmap.height.coerceAtMost(1920))
                    )
                }
                _uiState.value = _uiState.value.copy(
                    parameters = params,
                    previewBitmap = preview?.bitmap,
                    canUndo = editHistory.canUndo,
                    canRedo = editHistory.canRedo,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Failed to load photo: ${e.message}"
                )
            }
        }
    }

    // MARK: - Parameter Updates

    fun updateParameter(key: AdjustmentKey, value: Float) {
        val current = _uiState.value.parameters
        val clamped = value.coerceIn(-100f, 100f)
        val updated = when (key) {
            AdjustmentKey.EXPOSURE -> current.copy(exposure = clamped)
            AdjustmentKey.CONTRAST -> current.copy(contrast = clamped)
            AdjustmentKey.HIGHLIGHTS -> current.copy(highlights = clamped)
            AdjustmentKey.SHADOWS -> current.copy(shadows = clamped)
            AdjustmentKey.SATURATION -> current.copy(saturation = clamped)
            AdjustmentKey.VIBRANCE -> current.copy(vibrance = clamped)
            AdjustmentKey.WARMTH -> current.copy(warmth = clamped)
            AdjustmentKey.SHARPNESS -> current.copy(sharpness = clamped)
        }
        editHistory.push(updated)
        updateStateAndPreview(updated)
    }

    // MARK: - Filter Presets

    fun applyPreset(preset: FilterPreset) {
        val current = _uiState.value.parameters
        val updated = filterEngine.applyPreset(preset, current)
        editHistory.push(updated)
        updateStateAndPreview(updated, activePresetId = preset.id)
    }

    fun removePreset() {
        val updated = filterEngine.removePreset(baseParameters)
        editHistory.push(updated)
        updateStateAndPreview(updated, activePresetId = null)
    }

    // MARK: - Crop

    fun applyCrop(cropRect: CropRect, rotationCount: Int) {
        val current = _uiState.value.parameters
        val updated = current.copy(cropRect = cropRect, rotationCount = rotationCount)
        editHistory.push(updated)
        updateStateAndPreview(updated)
    }

    // MARK: - Undo / Redo

    fun undo() {
        editHistory.undo()?.let { restored ->
            updateStateAndPreview(restored)
        }
    }

    fun redo() {
        editHistory.redo()?.let { restored ->
            updateStateAndPreview(restored)
        }
    }

    // MARK: - Export

    fun exportPhoto(format: ExportFormat, quality: Int = 90) {
        val source = sourceImage ?: return
        val params = _uiState.value.parameters
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isExporting = true, error = null)
            val result = withContext(Dispatchers.Default) {
                val fullRes = imageRenderer.renderFullResolution(params, source)
                    ?: return@withContext Result.failure<Unit>(IllegalStateException("Render failed"))
                exporter.export(fullRes, format, quality)
            }
            _uiState.value = _uiState.value.copy(
                isExporting = false,
                error = result.exceptionOrNull()?.message
            )
        }
    }

    // MARK: - Helpers

    private fun updateStateAndPreview(
        parameters: EditParameters,
        activePresetId: String? = _uiState.value.activePresetId
    ) {
        _uiState.value = _uiState.value.copy(
            parameters = parameters,
            canUndo = editHistory.canUndo,
            canRedo = editHistory.canRedo,
            activePresetId = activePresetId
        )
        val source = sourceImage ?: return
        viewModelScope.launch(Dispatchers.Default) {
            val preview = imageRenderer.renderPreview(
                parameters, source,
                Size(1080, 1920)
            )
            _uiState.value = _uiState.value.copy(previewBitmap = preview?.bitmap)
        }
    }
}
