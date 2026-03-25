package com.example.photoeditor

class EditHistory {
    private val undoStack = ArrayDeque<EditParameters>()
    private val redoStack = ArrayDeque<EditParameters>()

    val canUndo: Boolean get() = undoStack.isNotEmpty()
    val canRedo: Boolean get() = redoStack.isNotEmpty()

    fun push(parameters: EditParameters) {
        undoStack.addLast(parameters)
        redoStack.clear()
    }

    fun undo(): EditParameters? {
        if (undoStack.isEmpty()) return null
        val current = undoStack.removeLast()
        redoStack.addLast(current)
        return undoStack.lastOrNull()
    }

    fun redo(): EditParameters? {
        if (redoStack.isEmpty()) return null
        val next = redoStack.removeLast()
        undoStack.addLast(next)
        return next
    }

    fun clear() {
        undoStack.clear()
        redoStack.clear()
    }
}
