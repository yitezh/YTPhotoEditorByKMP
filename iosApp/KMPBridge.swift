import UIKit
import shared

/// Bridge class that wires KMP shared module instances into the iOS app.
/// Uses module prefix "shared." to distinguish KMP types from native Swift types.
class KMPBridge {

    // MARK: - KMP Instances
    private let kmpEditHistory = shared.EditHistory()
    private let kmpFilterEngine = shared.FilterEngineLogic()
    private let kmpSerializer = shared.EditParametersSerializer.shared

    // MARK: - EditHistory Bridge

    var canUndo: Bool { kmpEditHistory.canUndo }
    var canRedo: Bool { kmpEditHistory.canRedo }

    func pushHistory(_ params: EditParameters) {
        kmpEditHistory.push(parameters: params.toKMP())
    }

    func undo() -> EditParameters? {
        guard let kmpParams = kmpEditHistory.undo() else { return nil }
        return EditParameters.fromKMP(kmpParams)
    }

    func redo() -> EditParameters? {
        guard let kmpParams = kmpEditHistory.redo() else { return nil }
        return EditParameters.fromKMP(kmpParams)
    }

    func clearHistory() {
        kmpEditHistory.clear()
    }

    // MARK: - FilterEngineLogic Bridge

    var builtinPresets: [FilterPreset] {
        kmpFilterEngine.builtinPresets.compactMap { obj -> FilterPreset? in
            guard let kmpPreset = obj as? shared.FilterPreset else { return nil }
            return FilterPreset(
                id: kmpPreset.id,
                name: kmpPreset.name,
                icon: iconForPresetId(kmpPreset.id),
                parameters: EditParameters.fromKMP(kmpPreset.parameters)
            )
        }
    }

    func applyPreset(_ preset: FilterPreset, current: EditParameters) -> EditParameters {
        let kmpPreset = shared.FilterPreset(
            id: preset.id,
            name: preset.name,
            parameters: preset.parameters.toKMP()
        )
        let result = kmpFilterEngine.applyPreset(preset: kmpPreset, current: current.toKMP())
        return EditParameters.fromKMP(result)
    }

    func removePreset(base: EditParameters) -> EditParameters {
        let result = kmpFilterEngine.removePreset(base: base.toKMP())
        return EditParameters.fromKMP(result)
    }

    // MARK: - Serialization Bridge

    func serialize(_ params: EditParameters) -> String {
        return kmpSerializer.serialize(parameters: params.toKMP())
    }

    func deserialize(_ json: String) -> EditParameters? {
        guard let kmpParams = kmpSerializer.deserialize(jsonString: json) as? shared.EditParameters else { return nil }
        return EditParameters.fromKMP(kmpParams)
    }

    // MARK: - Helpers

    private func iconForPresetId(_ id: String) -> String {
        switch id {
        case "vivid": return "sparkles"
        case "warm": return "sun.max.fill"
        case "cool": return "snowflake"
        case "bw": return "circle.lefthalf.filled"
        case "vintage": return "camera.filters"
        case "fade": return "cloud.fill"
        case "cinematic": return "theatermasks.fill"
        case "fresh": return "leaf.fill"
        case "sunset": return "sunset.fill"
        case "film": return "film"
        default: return "sparkles"
        }
    }
}

// MARK: - Type Conversion Extensions

extension EditParameters {
    func toKMP() -> shared.EditParameters {
        return shared.EditParameters(
            exposure: exposure,
            contrast: contrast,
            highlights: highlights,
            shadows: shadows,
            saturation: saturation,
            vibrance: vibrance,
            warmth: warmth,
            sharpness: sharpness,
            texture: texture,
            clarity: clarity,
            dehaze: dehaze,
            cropRect: cropRect.map { shared.CropRect(x: Float($0.x), y: Float($0.y), width: Float($0.width), height: Float($0.height)) },
            rotationCount: Int32(rotationCount)
        )
    }

    static func fromKMP(_ kmp: shared.EditParameters) -> EditParameters {
        var params = EditParameters()
        params.exposure = kmp.exposure
        params.contrast = kmp.contrast
        params.highlights = kmp.highlights
        params.shadows = kmp.shadows
        params.saturation = kmp.saturation
        params.vibrance = kmp.vibrance
        params.warmth = kmp.warmth
        params.sharpness = kmp.sharpness
        params.texture = kmp.texture
        params.clarity = kmp.clarity
        params.dehaze = kmp.dehaze
        if let kmpCrop = kmp.cropRect {
            params.cropRect = CodableCGRect(CGRect(
                x: CGFloat(kmpCrop.x),
                y: CGFloat(kmpCrop.y),
                width: CGFloat(kmpCrop.width),
                height: CGFloat(kmpCrop.height)
            ))
        }
        params.rotationCount = Int(kmp.rotationCount)
        return params
    }
}
