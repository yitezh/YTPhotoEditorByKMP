import UIKit
import CoreImage
import shared

/// KMP-backed ViewModel that delegates business logic to the KMP shared module
/// via KMPBridge, while keeping the same interface as PhotoEditorViewModel.
class KMPPhotoEditorViewModel: PhotoEditorViewModelProtocol {

    let filterEngine: FilterEngine
    private let bridge = KMPBridge()

    private(set) var currentParameters: EditParameters = .default
    private(set) var activeFilter: FilterPreset?
    private var preFilterParameters: EditParameters?

    var sourceImage: CIImage?
    var previewSize: CGSize = CGSize(width: 1080, height: 1920)

    var onPreviewUpdated: ((UIImage?) -> Void)?
    var onHistoryChanged: (() -> Void)?

    var canUndo: Bool { bridge.canUndo }
    var canRedo: Bool { bridge.canRedo }

    init(filterEngine: FilterEngine = FilterEngine()) {
        self.filterEngine = filterEngine
        bridge.pushHistory(currentParameters)
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
        bridge.pushHistory(currentParameters)
        onHistoryChanged?()
    }

    func resetParameter(_ key: AdjustmentKey) {
        updateParameter(key, value: 0)
    }

    func applyFilter(_ preset: FilterPreset) {
        preFilterParameters = currentParameters
        currentParameters = bridge.applyPreset(preset, current: currentParameters)
        currentParameters.cropRect = preFilterParameters?.cropRect
        currentParameters.rotationCount = preFilterParameters?.rotationCount ?? 0
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
        if let restored = bridge.undo() {
            currentParameters = restored
            refreshPreview()
            onHistoryChanged?()
        }
    }

    func redo() {
        if let restored = bridge.redo() {
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
        bridge.pushHistory(currentParameters)
        onHistoryChanged?()
        refreshPreview()
    }

    private func refreshPreview() {
        guard let source = sourceImage else { return }
        let preview = filterEngine.generatePreview(parameters: currentParameters, source: source, targetSize: previewSize)
        onPreviewUpdated?(preview)
    }
}
