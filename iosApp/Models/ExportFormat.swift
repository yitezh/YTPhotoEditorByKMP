import Foundation

enum ExportFormat {
    case jpeg
    case png

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png:  return "png"
        }
    }
}
