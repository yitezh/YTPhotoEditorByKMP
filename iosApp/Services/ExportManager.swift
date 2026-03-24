import UIKit
import Photos
import CoreImage

class ExportManager {

    enum ExportError: LocalizedError {
        case renderFailed
        case encodingFailed
        case saveFailed(Error)
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .renderFailed:      return "Failed to render the full resolution image."
            case .encodingFailed:    return "Failed to encode the image data."
            case .saveFailed(let e): return "Failed to save to photo library: \(e.localizedDescription)"
            case .permissionDenied:  return "Photo library access is required. Please enable it in Settings."
            }
        }
    }

    private let filterEngine: FilterEngine
    var onProgress: ((Float) -> Void)?

    init(filterEngine: FilterEngine) {
        self.filterEngine = filterEngine
    }

    func export(
        source: CIImage,
        parameters: EditParameters,
        format: ExportFormat,
        quality: Int = 90,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let clampedQuality = min(100, max(1, quality))
        onProgress?(0.1)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            guard let cgImage = self.filterEngine.renderFullResolution(parameters: parameters, source: source) else {
                DispatchQueue.main.async { self.onProgress?(0); completion(.failure(ExportError.renderFailed)) }
                return
            }

            DispatchQueue.main.async { self.onProgress?(0.4) }

            let uiImage = UIImage(cgImage: cgImage)
            let imageData: Data?
            switch format {
            case .jpeg: imageData = uiImage.jpegData(compressionQuality: CGFloat(clampedQuality) / 100.0)
            case .png:  imageData = uiImage.pngData()
            }

            guard let data = imageData else {
                DispatchQueue.main.async { self.onProgress?(0); completion(.failure(ExportError.encodingFailed)) }
                return
            }

            DispatchQueue.main.async { self.onProgress?(0.7) }

            self.saveToPhotoLibrary(data: data) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.onProgress?(1.0)
                        completion(.success(()))
                    case .failure(let error):
                        self.onProgress?(0)
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private func saveToPhotoLibrary(data: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(.failure(ExportError.permissionDenied))
                return
            }
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }, completionHandler: { success, error in
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(ExportError.saveFailed(
                        error ?? NSError(domain: "ExportManager", code: -1)
                    )))
                }
            })
        }
    }
}
