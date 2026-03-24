import UIKit
// import shared  // Uncomment after XCFramework is integrated

/// Bridge class that wires KMP shared module instances into the existing
/// PhotoEditorViewController. This replaces the native Swift implementations
/// with KMP-backed ones.
///
/// Usage:
///   let bridge = KMPBridge()
///   let vc = bridge.makePhotoEditorViewController()
///   navigationController.pushViewController(vc, animated: true)
class KMPBridge {

    // KMP shared module instances
    // private let editHistory = EditHistory()
    // private let filterEngine = FilterEngineLogic()
    // private let serializer = EditParametersSerializer()
    // private let imageRenderer = ImageRenderer()
    // private let exporter = PhotoLibraryExporter()

    /// Creates a PhotoEditorViewController backed by KMP shared logic.
    func makePhotoEditorViewController() -> UIViewController {
        // TODO: Replace with KMP-backed ViewModel once XCFramework is integrated
        // let viewModel = KMPPhotoEditorViewModel(
        //     editHistory: editHistory,
        //     filterEngine: filterEngine,
        //     imageRenderer: imageRenderer,
        //     exporter: exporter
        // )
        // return PhotoEditorViewController(viewModel: viewModel)
        fatalError("Integrate XCFramework first — see iosApp/README.md")
    }
}
