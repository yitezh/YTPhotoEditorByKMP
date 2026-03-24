import UIKit
// import shared  // Uncomment after XCFramework integration

/// Extension showing how to connect iOS undo/redo buttons to KMP EditHistory.canUndo/canRedo.
/// This replaces the native Swift EditHistory with the KMP shared one.
extension KMPPhotoEditorViewModel {

    /// Update undo/redo button enabled states based on KMP EditHistory state.
    /// Call this after every edit operation.
    func updateHistoryButtonStates(undoButton: UIButton, redoButton: UIButton) {
        // KMP integration:
        // undoButton.isEnabled = editHistory.canUndo
        // redoButton.isEnabled = editHistory.canRedo
        undoButton.isEnabled = false
        redoButton.isEnabled = false
    }
}
