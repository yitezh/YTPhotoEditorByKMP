import UIKit
import CoreImage
// import shared  // Uncomment after XCFramework is integrated

/// KMP-backed ViewModel that replaces the native Swift PhotoEditorViewModel.
/// Delegates all business logic to the KMP shared module.
///
/// This class bridges the KMP Kotlin API to the Swift UIKit layer,
/// maintaining the same interface as the original PhotoEditorViewModel.
class KMPPhotoEditorViewModel {

    // MARK: - KMP Dependencies (uncomment after XCFramework integration)
    // private let editHistory: EditHistory
    // private let filterEngine: FilterEngineLogic
    // private let imageRenderer: ImageRenderer
    // private let exporter: PhotoLibraryExporter

    // MARK: - State
    var sourceImage: CIImage?
    var previewSize: CGSize = CGSize(width: 1080, height: 1920)

    // MARK: - Computed Properties (delegated to KMP)
    // var canUndo: Bool { editHistory.canUndo }
    // var canRedo: Bool { editHistory.canRedo }

    // MARK: - Callbacks
    var onPreviewUpdated: ((UIImage?) -> Void)?
    var onHistoryChanged: (() -> Void)?

    // MARK: - Parameter Updates

    /// Update a single adjustment parameter and push to KMP EditHistory.
    func updateParameter(_ key: String, value: Float) {
        // KMP integration:
        // var params = currentParameters.copy(...)
        // editHistory.push(params)
        // refreshPreview()
    }

    // MARK: - Undo / Redo (delegated to KMP EditHistory)

    func undo() {
        // if let restored = editHistory.undo() {
        //     currentParameters = restored
        //     refreshPreview()
        //     onHistoryChanged?()
        // }
    }

    func redo() {
        // if let restored = editHistory.redo() {
        //     currentParameters = restored
        //     refreshPreview()
        //     onHistoryChanged?()
        // }
    }

    // MARK: - Filter Presets (delegated to KMP FilterEngineLogic)

    func applyPreset(_ presetId: String) {
        // let preset = filterEngine.builtinPresets.first { $0.id == presetId }
        // guard let preset = preset else { return }
        // currentParameters = filterEngine.applyPreset(preset: preset, current: currentParameters)
        // editHistory.push(currentParameters)
        // refreshPreview()
    }

    func removePreset() {
        // currentParameters = filterEngine.removePreset(base: baseParameters)
        // editHistory.push(currentParameters)
        // refreshPreview()
    }

    // MARK: - Serialization (delegated to KMP EditParametersSerializer)

    func serializeCurrentParameters() -> String {
        // return EditParametersSerializer().serialize(parameters: currentParameters)
        return "{}"
    }
}
