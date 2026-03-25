import Foundation

class EditHistory {

    private var undoStack: [EditParameters] = []
    private var redoStack: [EditParameters] = []

    var canUndo: Bool { undoStack.count > 1 }
    var canRedo: Bool { !redoStack.isEmpty }
    var undoCount: Int { undoStack.count }
    var redoCount: Int { redoStack.count }

    func push(_ parameters: EditParameters) {
        undoStack.append(parameters)
        redoStack.removeAll()
    }

    @discardableResult
    func undo() -> EditParameters? {
        guard undoStack.count > 1, let last = undoStack.popLast() else { return nil }
        redoStack.append(last)
        return undoStack.last
    }

    @discardableResult
    func redo() -> EditParameters? {
        guard let last = redoStack.popLast() else { return nil }
        undoStack.append(last)
        return last
    }
}
