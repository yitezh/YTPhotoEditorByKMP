import UIKit
import CoreImage

/// Protocol that both native and KMP-backed ViewModels conform to.
/// This allows PhotoEditorViewController to work with either implementation.
protocol PhotoEditorViewModelProtocol: AnyObject {
    var filterEngine: FilterEngine { get }
    var currentParameters: EditParameters { get }
    var activeFilter: FilterPreset? { get }
    var sourceImage: CIImage? { get set }
    var previewSize: CGSize { get set }
    var canUndo: Bool { get }
    var canRedo: Bool { get }
    var onPreviewUpdated: ((UIImage?) -> Void)? { get set }
    var onHistoryChanged: (() -> Void)? { get set }

    func updateParameter(_ key: AdjustmentKey, value: Float)
    func updateParameterPreview(_ key: AdjustmentKey, value: Float)
    func commitParameterChange()
    func resetParameter(_ key: AdjustmentKey)
    func applyFilter(_ preset: FilterPreset)
    func removeFilter()
    func applyCrop(_ rect: CGRect, rotation: Int)
    func undo()
    func redo()
}
