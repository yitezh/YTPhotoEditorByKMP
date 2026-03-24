import UIKit

protocol AdjustmentPanelViewDelegate: AnyObject {
    func adjustmentPanelView(_ panel: AdjustmentPanelView, didChangeValue value: Float, forKey key: AdjustmentKey)
    func adjustmentPanelView(_ panel: AdjustmentPanelView, didEndChangingValue value: Float, forKey key: AdjustmentKey)
    func adjustmentPanelView(_ panel: AdjustmentPanelView, didResetKey key: AdjustmentKey)
}

class AdjustmentPanelView: UIView {

    weak var delegate: AdjustmentPanelViewDelegate?

    private var currentTab: ToolTab = .light
    private var sliderCells: [AdjustmentSliderCell] = []
    private let contentView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        clipsToBounds = true
        addSubview(contentView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        layoutSliders()
    }

    private func layoutSliders() {
        let rowHeight: CGFloat = 44
        for (index, cell) in sliderCells.enumerated() {
            cell.frame = CGRect(x: 0, y: CGFloat(index) * rowHeight, width: contentView.bounds.width, height: rowHeight)
        }
    }

    func switchToTab(_ tab: ToolTab, parameters: EditParameters, animated: Bool = true) {
        let isForward = (ToolTab.allCases.firstIndex(of: tab) ?? 0) >=
                        (ToolTab.allCases.firstIndex(of: currentTab) ?? 0)
        currentTab = tab
        let keys = tab.adjustmentKeys

        if animated {
            let slideDistance = bounds.width
            let exitX: CGFloat = isForward ? -slideDistance : slideDistance
            let enterX: CGFloat = isForward ? slideDistance : -slideDistance

            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.contentView.frame.origin.x = exitX
                self.contentView.alpha = 0
            }, completion: { _ in
                self.rebuildSliders(keys: keys, parameters: parameters)
                self.contentView.frame.origin.x = enterX
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                    self.contentView.frame.origin.x = 0
                    self.contentView.alpha = 1
                }
            })
        } else {
            rebuildSliders(keys: keys, parameters: parameters)
        }
    }

    func updateValues(from parameters: EditParameters) {
        for cell in sliderCells {
            cell.updateValue(parameterValue(for: cell.adjustmentKey, in: parameters))
        }
    }

    private func rebuildSliders(keys: [AdjustmentKey], parameters: EditParameters) {
        sliderCells.forEach { $0.removeFromSuperview() }
        sliderCells.removeAll()
        for key in keys {
            let cell = AdjustmentSliderCell()
            cell.delegate = self
            cell.configure(key: key, value: parameterValue(for: key, in: parameters))
            contentView.addSubview(cell)
            sliderCells.append(cell)
        }
        layoutSliders()
    }

    private func parameterValue(for key: AdjustmentKey, in params: EditParameters) -> Float {
        switch key {
        case .exposure:   return params.exposure
        case .contrast:   return params.contrast
        case .highlights: return params.highlights
        case .shadows:    return params.shadows
        case .saturation: return params.saturation
        case .vibrance:   return params.vibrance
        case .warmth:     return params.warmth
        case .sharpness:  return params.sharpness
        case .texture:    return params.texture
        case .clarity:    return params.clarity
        case .dehaze:     return params.dehaze
        }
    }
}

extension AdjustmentPanelView: AdjustmentSliderCellDelegate {
    func adjustmentSliderCell(_ cell: AdjustmentSliderCell, didChangeValue value: Float, forKey key: AdjustmentKey) {
        delegate?.adjustmentPanelView(self, didChangeValue: value, forKey: key)
    }
    func adjustmentSliderCell(_ cell: AdjustmentSliderCell, didEndChangingValue value: Float, forKey key: AdjustmentKey) {
        delegate?.adjustmentPanelView(self, didEndChangingValue: value, forKey: key)
    }
    func adjustmentSliderCell(_ cell: AdjustmentSliderCell, didResetKey key: AdjustmentKey) {
        delegate?.adjustmentPanelView(self, didResetKey: key)
    }
}
