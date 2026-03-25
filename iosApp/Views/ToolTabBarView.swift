import UIKit

protocol ToolTabBarViewDelegate: AnyObject {
    func toolTabBarView(_ tabBar: ToolTabBarView, didSelectTab tab: ToolTab)
}

class ToolTabBarView: UIView {

    weak var delegate: ToolTabBarViewDelegate?

    private let tabs = ToolTab.allCases
    private var buttons: [UIButton] = []
    private(set) var selectedTab: ToolTab = .light

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .center
        sv.spacing = 0
        return sv
    }()

    private let selectionIndicator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
        v.layer.cornerRadius = 1.5
        return v
    }()

    private let normalColor = UIColor(white: 0.5, alpha: 1.0)
    private let selectedColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)

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
        addSubview(stackView)
        addSubview(selectionIndicator)

        for (index, tab) in tabs.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            button.setImage(UIImage(systemName: tab.iconName, withConfiguration: config), for: .normal)
            button.setTitle(" \(tab.displayName)", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            button.tintColor = normalColor
            button.setTitleColor(normalColor, for: .normal)
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        updateSelection(animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds
        updateIndicatorPosition(animated: false)
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let tab = tabs[sender.tag]
        guard tab != selectedTab else { return }
        selectedTab = tab
        updateSelection(animated: true)
        delegate?.toolTabBarView(self, didSelectTab: tab)
    }

    func selectTab(_ tab: ToolTab, animated: Bool = false) {
        selectedTab = tab
        updateSelection(animated: animated)
    }

    private func updateSelection(animated: Bool) {
        for (index, button) in buttons.enumerated() {
            let isSelected = tabs[index] == selectedTab
            button.tintColor = isSelected ? selectedColor : normalColor
            button.setTitleColor(isSelected ? selectedColor : normalColor, for: .normal)
        }
        updateIndicatorPosition(animated: animated)
    }

    private func updateIndicatorPosition(animated: Bool) {
        guard let index = tabs.firstIndex(of: selectedTab), index < buttons.count else { return }
        let button = buttons[index]
        let buttonFrame = button.convert(button.bounds, to: self)
        let indicatorWidth = buttonFrame.width * 0.5
        let indicatorFrame = CGRect(
            x: buttonFrame.midX - indicatorWidth / 2,
            y: bounds.height - 3,
            width: indicatorWidth,
            height: 3
        )
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                self.selectionIndicator.frame = indicatorFrame
            }
        } else {
            selectionIndicator.frame = indicatorFrame
        }
    }
}
