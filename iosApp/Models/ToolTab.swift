import Foundation

enum ToolTab: String, CaseIterable {
    case light
    case color
    case effects
    case detail
    case crop

    var displayName: String {
        switch self {
        case .light:   return "光效"
        case .color:   return "颜色"
        case .effects: return "效果"
        case .detail:  return "细节"
        case .crop:    return "裁剪"
        }
    }

    var iconName: String {
        switch self {
        case .light:   return "sun.max"
        case .color:   return "paintpalette"
        case .effects: return "sparkles"
        case .detail:  return "triangle"
        case .crop:    return "crop"
        }
    }

    var adjustmentKeys: [AdjustmentKey] {
        AdjustmentKey.allCases.filter { $0.tabGroup == self }
    }
}
