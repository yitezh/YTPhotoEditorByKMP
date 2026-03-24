import CoreImage
import UIKit

class PhotoEditorViewModel {

    let filterEngine: FilterEngine
    let editHistory: EditHistory

    private(set) var currentParameters: EditParameters = .default
    private(set) var activeFilter: FilterPreset?
    private var preFilterParameters: EditParameters?

    var sourceImage: CIImage?
    var previewSize: CGSize = CGSize(width: 1080, height: 1920)

    var onPreviewUpdated: ((UIImage?) -> Void)?
    var onHistoryChanged: (() -> Void)?

    var canUndo: Bool { editHistory.canUndo }
    var canRedo: Bool { editHistory.canRedo }

    init(filterEngine: FilterEngine = FilterEngine(), editHistory: EditHistory = EditHistory()) {
        self.filterEngine = filterEngine
        self.editHistory = editHistory
        editHistory.push(currentParameters)
    }

    func updateParameter(_ key: AdjustmentKey, value: Float) {
        let clamped = min(100, max(-100, value))
        applyKeyValue(key, value: clamped)
        pushAndRefresh()
    }

    func updateParameterPreview(_ key: AdjustmentKey, value: Float) {
        let clamped = min(100, max(-100, value))
        applyKeyValue(key, value: clamped)
        refreshPreview()
    }

    func commitParameterChange() {
        editHistory.push(currentParameters)
        onHistoryChanged?()
    }

    func resetParameter(_ key: AdjustmentKey) {
        updateParameter(key, value: 0)
    }

    func applyFilter(_ preset: FilterPreset) {
        preFilterParameters = currentParameters
        var newParams = preset.parameters
        newParams.cropRect = currentParameters.cropRect
        newParams.rotationCount = currentParameters.rotationCount
        currentParameters = newParams
        activeFilter = preset
        pushAndRefresh()
    }

    func removeFilter() {
        guard activeFilter != nil else { return }
        if let saved = preFilterParameters {
            var restored = saved
            restored.cropRect = currentParameters.cropRect
            restored.rotationCount = currentParameters.rotationCount
            currentParameters = restored
        }
        activeFilter = nil
        preFilterParameters = nil
        pushAndRefresh()
    }

    func applyCrop(_ rect: CGRect, rotation: Int) {
        currentParameters.cropRect = CodableCGRect(rect)
        currentParameters.rotationCount = rotation
        pushAndRefresh()
    }

    func undo() {
        if let restored = editHistory.undo() {
            currentParameters = restored
            refreshPreview()
            onHistoryChanged?()
        }
    }

    func redo() {
        if let restored = editHistory.redo() {
            currentParameters = restored
            refreshPreview()
            onHistoryChanged?()
        }
    }

    private func applyKeyValue(_ key: AdjustmentKey, value: Float) {
        switch key {
        case .exposure:   currentParameters.exposure = value
        case .contrast:   currentParameters.contrast = value
        case .highlights: currentParameters.highlights = value
        case .shadows:    currentParameters.shadows = value
        case .saturation: currentParameters.saturation = value
        case .vibrance:   currentParameters.vibrance = value
        case .warmth:     currentParameters.warmth = value
        case .sharpness:  currentParameters.sharpness = value
        case .texture:    currentParameters.texture = value
        case .clarity:    currentParameters.clarity = value
        case .dehaze:     currentParameters.dehaze = value
        }
    }

    private func pushAndRefresh() {
        editHistory.push(currentParameters)
        onHistoryChanged?()
        refreshPreview()
    }

    private func refreshPreview() {
        guard let source = sourceImage else { return }
        let preview = filterEngine.generatePreview(parameters: currentParameters, source: source, targetSize: previewSize)
        onPreviewUpdated?(preview)
    }
}
