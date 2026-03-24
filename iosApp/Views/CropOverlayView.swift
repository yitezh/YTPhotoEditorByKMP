import UIKit

protocol CropOverlayViewDelegate: AnyObject {
    func cropOverlayViewDidConfirm(_ view: CropOverlayView, cropRect: CGRect, rotationCount: Int)
    func cropOverlayViewDidCancel(_ view: CropOverlayView)
    func cropOverlayViewDidRotate(_ view: CropOverlayView)
}

class CropOverlayView: UIView {

    weak var delegate: CropOverlayViewDelegate?
    private(set) var cropRect: CGRect = .zero
    private var imageBounds: CGRect = .zero
    var rotationCount: Int = 0
    private let minCropSize: CGFloat = 60
    private let handleSize: CGFloat = 44

    private enum DragEdge {
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
        case move, none
    }
    private var activeDrag: DragEdge = .none
    private var dragStartPoint: CGPoint = .zero
    private var dragStartRect: CGRect = .zero
    private var selectedAspectRatio: AspectRatio = .free

    private let maskLayer = CAShapeLayer()
    private let cropBorderView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderColor = UIColor.white.cgColor
        v.layer.borderWidth = 1.5
        v.isUserInteractionEnabled = false
        return v
    }()
    private let gridLayer = CAShapeLayer()
    private var cornerHandles: [UIView] = []
    private let toolbarView = UIView()
    private let cancelButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let rotateButton = UIButton(type: .system)
    private let aspectRatioBar = UIScrollView()
    private var aspectRatioButtons: [UIButton] = []
    private let accentColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = UIColor.black.withAlphaComponent(0.6).cgColor
        layer.addSublayer(maskLayer)
        addSubview(cropBorderView)
        gridLayer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.fillColor = nil
        cropBorderView.layer.addSublayer(gridLayer)
        for _ in 0..<4 {
            let handle = UIView()
            handle.backgroundColor = .clear
            handle.isUserInteractionEnabled = false
            addSubview(handle)
            cornerHandles.append(handle)
        }
        setupToolbar()
        setupAspectRatioBar()
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    private func setupToolbar() {
        toolbarView.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 0.95)
        addSubview(toolbarView)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        cancelButton.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig), for: .normal)
        cancelButton.tintColor = accentColor
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        confirmButton.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig), for: .normal)
        confirmButton.tintColor = accentColor
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        rotateButton.setImage(UIImage(systemName: "rotate.right", withConfiguration: symbolConfig), for: .normal)
        rotateButton.tintColor = accentColor
        rotateButton.addTarget(self, action: #selector(rotateTapped), for: .touchUpInside)
        toolbarView.addSubview(cancelButton)
        toolbarView.addSubview(confirmButton)
        toolbarView.addSubview(rotateButton)
    }

    private func setupAspectRatioBar() {
        aspectRatioBar.backgroundColor = .clear
        aspectRatioBar.showsHorizontalScrollIndicator = false
        addSubview(aspectRatioBar)
        for (index, ratio) in AspectRatio.allCases.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(ratio.displayName, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.tintColor = ratio == .free ? accentColor : UIColor(white: 0.5, alpha: 1.0)
            button.tag = index
            button.addTarget(self, action: #selector(aspectRatioTapped(_:)), for: .touchUpInside)
            aspectRatioBar.addSubview(button)
            aspectRatioButtons.append(button)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        let h = bounds.height
        let safeBottom = safeAreaInsets.bottom
        let toolbarHeight: CGFloat = 50
        toolbarView.frame = CGRect(x: 0, y: h - toolbarHeight - safeBottom, width: w, height: toolbarHeight + safeBottom)
        let btnSize: CGFloat = 50
        cancelButton.frame = CGRect(x: 16, y: 0, width: btnSize, height: toolbarHeight)
        rotateButton.frame = CGRect(x: (w - btnSize) / 2, y: 0, width: btnSize, height: toolbarHeight)
        confirmButton.frame = CGRect(x: w - btnSize - 16, y: 0, width: btnSize, height: toolbarHeight)
        let ratioBarHeight: CGFloat = 36
        aspectRatioBar.frame = CGRect(x: 0, y: toolbarView.frame.minY - ratioBarHeight, width: w, height: ratioBarHeight)
        layoutAspectRatioButtons()
        updateMask(); updateCropBorder(); updateCornerHandles(); updateGridLines()
    }

    private func layoutAspectRatioButtons() {
        let buttonWidth: CGFloat = 56
        let spacing: CGFloat = 8
        let totalWidth = CGFloat(aspectRatioButtons.count) * buttonWidth + CGFloat(aspectRatioButtons.count - 1) * spacing
        let startX = max(12, (aspectRatioBar.bounds.width - totalWidth) / 2)
        for (index, button) in aspectRatioButtons.enumerated() {
            button.frame = CGRect(x: startX + CGFloat(index) * (buttonWidth + spacing), y: 0, width: buttonWidth, height: aspectRatioBar.bounds.height)
        }
        aspectRatioBar.contentSize = CGSize(width: startX + totalWidth + 12, height: aspectRatioBar.bounds.height)
    }

    func configure(imageBounds: CGRect, initialCropRect: CGRect?, rotationCount: Int) {
        self.imageBounds = imageBounds
        self.rotationCount = rotationCount
        self.cropRect = initialCropRect ?? imageBounds
        setNeedsLayout()
    }

    private func updateMask() {
        let fullPath = UIBezierPath(rect: bounds)
        fullPath.append(UIBezierPath(rect: cropRect))
        maskLayer.path = fullPath.cgPath
    }

    private func updateCropBorder() { cropBorderView.frame = cropRect }

    private func updateGridLines() {
        let w = cropRect.width; let h = cropRect.height
        let path = UIBezierPath()
        for i in 1...2 {
            let x = w * CGFloat(i) / 3.0
            path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: h))
            let y = h * CGFloat(i) / 3.0
            path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: w, y: y))
        }
        gridLayer.path = path.cgPath
        gridLayer.frame = cropBorderView.bounds
    }

    private func updateCornerHandles() {
        let handleLength: CGFloat = 20; let handleThickness: CGFloat = 3
        let r = cropRect
        let positions: [CGPoint] = [
            CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
            CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY)
        ]
        for (index, pos) in positions.enumerated() {
            let handle = cornerHandles[index]
            let offsetX: CGFloat = (index % 2 == 0) ? -handleThickness / 2 : -handleLength + handleThickness / 2
            let offsetY: CGFloat = (index < 2) ? -handleThickness / 2 : -handleLength + handleThickness / 2
            handle.frame = CGRect(x: pos.x + offsetX, y: pos.y + offsetY, width: handleLength, height: handleLength)
            handle.backgroundColor = .clear
            handle.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            let hBar = CALayer()
            hBar.frame = CGRect(x: (index % 2 == 0) ? 0 : 0, y: (index < 2) ? 0 : handleLength - handleThickness, width: handleLength, height: handleThickness)
            hBar.backgroundColor = UIColor.white.cgColor
            handle.layer.addSublayer(hBar)
            let vBar = CALayer()
            vBar.frame = CGRect(x: (index % 2 == 0) ? 0 : handleLength - handleThickness, y: 0, width: handleThickness, height: handleLength)
            vBar.backgroundColor = UIColor.white.cgColor
            handle.layer.addSublayer(vBar)
        }
    }

    @objc private func cancelTapped() { delegate?.cropOverlayViewDidCancel(self) }
    @objc private func confirmTapped() { delegate?.cropOverlayViewDidConfirm(self, cropRect: cropRect, rotationCount: rotationCount) }
    @objc private func rotateTapped() { delegate?.cropOverlayViewDidRotate(self) }

    @objc private func aspectRatioTapped(_ sender: UIButton) {
        selectedAspectRatio = AspectRatio.allCases[sender.tag]
        for (i, btn) in aspectRatioButtons.enumerated() {
            btn.tintColor = AspectRatio.allCases[i] == selectedAspectRatio ? accentColor : UIColor(white: 0.5, alpha: 1.0)
        }
        applyAspectRatioConstraint()
    }

    private func applyAspectRatioConstraint() {
        guard let targetRatio = selectedAspectRatio.ratioValue else { return }
        let centerX = cropRect.midX; let centerY = cropRect.midY
        var newWidth = cropRect.width; var newHeight = cropRect.height
        if newWidth / newHeight > targetRatio { newWidth = newHeight * targetRatio } else { newHeight = newWidth / targetRatio }
        newWidth = min(newWidth, imageBounds.width); newHeight = min(newHeight, imageBounds.height)
        let originX = max(imageBounds.minX, min(centerX - newWidth / 2, imageBounds.maxX - newWidth))
        let originY = max(imageBounds.minY, min(centerY - newHeight / 2, imageBounds.maxY - newHeight))
        cropRect = CGRect(x: originX, y: originY, width: newWidth, height: newHeight)
        UIView.animate(withDuration: 0.2) { self.updateMask(); self.updateCropBorder(); self.updateCornerHandles(); self.updateGridLines() }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        switch gesture.state {
        case .began:
            activeDrag = detectDragEdge(at: point)
            dragStartPoint = point; dragStartRect = cropRect
        case .changed:
            let dx = point.x - dragStartPoint.x; let dy = point.y - dragStartPoint.y
            applyCropDrag(dx: dx, dy: dy)
            updateMask(); updateCropBorder(); updateCornerHandles(); updateGridLines()
        case .ended, .cancelled: activeDrag = .none
        default: break
        }
    }

    private func detectDragEdge(at point: CGPoint) -> DragEdge {
        let r = cropRect; let margin = handleSize / 2
        let nearLeft = abs(point.x - r.minX) < margin; let nearRight = abs(point.x - r.maxX) < margin
        let nearTop = abs(point.y - r.minY) < margin; let nearBottom = abs(point.y - r.maxY) < margin
        if nearTop && nearLeft { return .topLeft }; if nearTop && nearRight { return .topRight }
        if nearBottom && nearLeft { return .bottomLeft }; if nearBottom && nearRight { return .bottomRight }
        if nearTop { return .top }; if nearBottom { return .bottom }
        if nearLeft { return .left }; if nearRight { return .right }
        if r.contains(point) { return .move }
        return .none
    }

    private func applyCropDrag(dx: CGFloat, dy: CGFloat) {
        var r = dragStartRect
        switch activeDrag {
        case .move:
            r.origin.x = max(imageBounds.minX, min(r.origin.x + dx, imageBounds.maxX - r.width))
            r.origin.y = max(imageBounds.minY, min(r.origin.y + dy, imageBounds.maxY - r.height))
        case .topLeft:     r = adjustEdge(rect: r, dMinX: dx, dMinY: dy, dMaxX: 0, dMaxY: 0)
        case .topRight:    r = adjustEdge(rect: r, dMinX: 0, dMinY: dy, dMaxX: dx, dMaxY: 0)
        case .bottomLeft:  r = adjustEdge(rect: r, dMinX: dx, dMinY: 0, dMaxX: 0, dMaxY: dy)
        case .bottomRight: r = adjustEdge(rect: r, dMinX: 0, dMinY: 0, dMaxX: dx, dMaxY: dy)
        case .top:         r = adjustEdge(rect: r, dMinX: 0, dMinY: dy, dMaxX: 0, dMaxY: 0)
        case .bottom:      r = adjustEdge(rect: r, dMinX: 0, dMinY: 0, dMaxX: 0, dMaxY: dy)
        case .left:        r = adjustEdge(rect: r, dMinX: dx, dMinY: 0, dMaxX: 0, dMaxY: 0)
        case .right:       r = adjustEdge(rect: r, dMinX: 0, dMinY: 0, dMaxX: dx, dMaxY: 0)
        case .none: return
        }
        cropRect = r
        if selectedAspectRatio != .free { applyAspectRatioConstraint() }
    }

    private func adjustEdge(rect: CGRect, dMinX: CGFloat, dMinY: CGFloat, dMaxX: CGFloat, dMaxY: CGFloat) -> CGRect {
        var minX = max(imageBounds.minX, rect.minX + dMinX)
        var minY = max(imageBounds.minY, rect.minY + dMinY)
        var maxX = min(imageBounds.maxX, rect.maxX + dMaxX)
        var maxY = min(imageBounds.maxY, rect.maxY + dMaxY)
        if maxX - minX < minCropSize { if dMinX != 0 { minX = maxX - minCropSize } else { maxX = minX + minCropSize } }
        if maxY - minY < minCropSize { if dMinY != 0 { minY = maxY - minCropSize } else { maxY = minY + minCropSize } }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.contains(point)
    }
}
