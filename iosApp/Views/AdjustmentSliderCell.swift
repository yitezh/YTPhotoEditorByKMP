import UIKit

protocol AdjustmentSliderCellDelegate: AnyObject {
    func adjustmentSliderCell(_ cell: AdjustmentSliderCell, didChangeValue value: Float, forKey key: AdjustmentKey)
    func adjustmentSliderCell(_ cell: AdjustmentSliderCell, didEndChangingValue value: Float, forKey key: AdjustmentKey)
    func adjustmentSliderCell(_ cell: AdjustmentSliderCell, didResetKey key: AdjustmentKey)
}

class AdjustmentSliderCell: UIView {

    weak var delegate: AdjustmentSliderCellDelegate?
    private(set) var adjustmentKey: AdjustmentKey = .exposure

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(white: 0.7, alpha: 1.0)
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
        label.textAlignment = .right
        return label
    }()

    private let slider: UISlider = {
        let s = UISlider()
        s.minimumValue = -100
        s.maximumValue = 100
        s.value = 0
        s.minimumTrackTintColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
        s.maximumTrackTintColor = UIColor(white: 0.3, alpha: 1.0)
        s.thumbTintColor = .white
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(iconView)
        addSubview(nameLabel)
        addSubview(slider)
        addSubview(valueLabel)

        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(sliderDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        slider.addGestureRecognizer(doubleTap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        let iconSize: CGFloat = 18
        let padding: CGFloat = 12
        let valueLabelWidth: CGFloat = 36

        iconView.frame = CGRect(x: padding, y: (h - iconSize) / 2, width: iconSize, height: iconSize)
        nameLabel.frame = CGRect(x: iconView.frame.maxX + 8, y: 0, width: 70, height: h)
        valueLabel.frame = CGRect(x: bounds.width - padding - valueLabelWidth, y: 0, width: valueLabelWidth, height: h)
        let sliderX = nameLabel.frame.maxX + 4
        let sliderW = valueLabel.frame.minX - sliderX - 8
        slider.frame = CGRect(x: sliderX, y: (h - 30) / 2, width: sliderW, height: 30)
    }

    func configure(key: AdjustmentKey, value: Float) {
        adjustmentKey = key
        nameLabel.text = key.displayName
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iconView.image = UIImage(systemName: key.iconName, withConfiguration: config)
        slider.value = value
        valueLabel.text = "\(Int(value))"
    }

    func updateValue(_ value: Float) {
        slider.value = value
        valueLabel.text = "\(Int(value))"
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        let rounded = roundf(sender.value)
        sender.value = rounded
        valueLabel.text = "\(Int(rounded))"
        delegate?.adjustmentSliderCell(self, didChangeValue: rounded, forKey: adjustmentKey)
    }

    @objc private func sliderTouchEnded(_ sender: UISlider) {
        delegate?.adjustmentSliderCell(self, didEndChangingValue: roundf(sender.value), forKey: adjustmentKey)
    }

    @objc private func sliderDoubleTapped() {
        slider.value = 0
        valueLabel.text = "0"
        delegate?.adjustmentSliderCell(self, didResetKey: adjustmentKey)
    }
}
