import UIKit

/// Extension connecting undo/redo buttons to KMP EditHistory via KMPPhotoEditorViewModel.
extension KMPPhotoEditorViewModel {
    func updateHistoryButtonStates(undoButton: UIButton, redoButton: UIButton) {
        undoButton.isEnabled = canUndo
        redoButton.isEnabled = canRedo
    }
}
