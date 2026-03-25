import UIKit

class PhotoEditorViewController: UIViewController {

    private let viewModel: PhotoEditorViewModel
    private let previewView = ImagePreviewView()
    private let toolTabBar = ToolTabBarView()
    private let adjustmentPanel = AdjustmentPanelView()
    private let filterPresetView = FilterPresetView()
    private let cropOverlayView = CropOverlayView()
    private var pendingSourceImage: UIImage?
    private var activeExportManager: ExportManager?
    private lazy var cropViewModel = CropViewModel(imageBounds: .zero)

    private let backButton = UIButton(type: .system)
    private let undoButton = UIButton(type: .system)
    private let redoButton = UIButton(type: .system)
    private let exportButton = UIButton(type: .system)
    private let navBar = UIView()

    private let bgColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0)
    private let textColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
    private let disabledColor = UIColor(white: 0.35, alpha: 1.0)

    init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupNavBar()
        setupSubviews()
        bindViewModel()
        adjustmentPanel.switchToTab(.light, parameters: viewModel.currentParameters, animated: false)
        updateHistoryButtons()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let image = pendingSourceImage {
            pendingSourceImage = nil
            applySourceImage(image)
        }
    }

    private func setupNavBar() {
        navBar.backgroundColor = bgColor
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        configureNavButton(backButton, systemName: "chevron.left", config: symbolConfig)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        configureNavButton(undoButton, systemName: "arrow.uturn.backward", config: symbolConfig)
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        configureNavButton(redoButton, systemName: "arrow.uturn.forward", config: symbolConfig)
        redoButton.addTarget(self, action: #selector(redoTapped), for: .touchUpInside)
        configureNavButton(exportButton, systemName: "square.and.arrow.up", config: symbolConfig)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        [backButton, undoButton, redoButton, exportButton].forEach { navBar.addSubview($0) }
        view.addSubview(navBar)
    }

    private func configureNavButton(_ button: UIButton, systemName: String, config: UIImage.SymbolConfiguration) {
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = textColor
    }

    private func setupSubviews() {
        [previewView, toolTabBar, adjustmentPanel, filterPresetView, cropOverlayView].forEach { view.addSubview($0) }
        toolTabBar.delegate = self
        adjustmentPanel.delegate = self
        filterPresetView.delegate = self
        cropOverlayView.delegate = self
        filterPresetView.isHidden = true
        cropOverlayView.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let w = view.bounds.width
        let navHeight: CGFloat = 44
        navBar.frame = CGRect(x: 0, y: safeTop, width: w, height: navHeight)
        let btnSize: CGFloat = 44
        backButton.frame = CGRect(x: 8, y: 0, width: btnSize, height: navHeight)
        exportButton.frame = CGRect(x: w - btnSize - 8, y: 0, width: btnSize, height: navHeight)
        redoButton.frame = CGRect(x: exportButton.frame.minX - btnSize - 4, y: 0, width: btnSize, height: navHeight)
        undoButton.frame = CGRect(x: redoButton.frame.minX - btnSize - 4, y: 0, width: btnSize, height: navHeight)
        let tabBarHeight: CGFloat = 44
        let panelHeight: CGFloat = 200
        let previewTop = navBar.frame.maxY
        let previewHeight = view.bounds.height - previewTop - tabBarHeight - panelHeight - safeBottom
        previewView.frame = CGRect(x: 0, y: previewTop, width: w, height: previewHeight)
        toolTabBar.frame = CGRect(x: 0, y: previewView.frame.maxY, width: w, height: tabBarHeight)
        adjustmentPanel.frame = CGRect(x: 0, y: toolTabBar.frame.maxY, width: w, height: panelHeight + safeBottom)
        filterPresetView.frame = adjustmentPanel.frame
    }

    private func bindViewModel() {
        viewModel.onPreviewUpdated = { [weak self] image in
            DispatchQueue.main.async { self?.previewView.updateImage(image) }
        }
        viewModel.onHistoryChanged = { [weak self] in
            DispatchQueue.main.async { self?.updateHistoryButtons() }
        }
    }

    private func updateHistoryButtons() {
        undoButton.isEnabled = viewModel.canUndo
        undoButton.tintColor = viewModel.canUndo ? textColor : disabledColor
        redoButton.isEnabled = viewModel.canRedo
        redoButton.tintColor = viewModel.canRedo ? textColor : disabledColor
    }

    @objc private func backTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func undoTapped() {
        viewModel.undo()
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }

    @objc private func redoTapped() {
        viewModel.redo()
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }

    @objc private func exportTapped() {
        let alert = UIAlertController(title: "导出照片", message: "选择导出格式", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "JPEG（高质量）", style: .default) { [weak self] _ in self?.performExport(format: .jpeg, quality: 90) })
        alert.addAction(UIAlertAction(title: "PNG（无损）", style: .default) { [weak self] _ in self?.performExport(format: .png, quality: 100) })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = exportButton
            popover.sourceRect = exportButton.bounds
        }
        present(alert, animated: true)
    }

    private func performExport(format: ExportFormat, quality: Int) {
        guard let source = viewModel.sourceImage else { return }
        let exportManager = ExportManager(filterEngine: viewModel.filterEngine)
        activeExportManager = exportManager
        let progressAlert = UIAlertController(title: "导出中…", message: "\n", preferredStyle: .alert)
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 20, y: 60, width: 230, height: 2)
        progressAlert.view.addSubview(progressView)
        present(progressAlert, animated: true)
        exportManager.onProgress = { progress in
            DispatchQueue.main.async { progressView.setProgress(progress, animated: true) }
        }
        exportManager.export(source: source, parameters: viewModel.currentParameters, format: format, quality: quality) { [weak self] result in
            progressAlert.dismiss(animated: true) {
                switch result {
                case .success: self?.showAlert(title: "导出成功", message: "照片已保存到相册")
                case .failure(let error): self?.showExportError(error)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

    private func showExportError(_ error: Error) {
        let alert = UIAlertController(title: "导出失败", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in self?.exportTapped() })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    func setSourceImage(_ image: UIImage) {
        if previewView.bounds.width == 0 { pendingSourceImage = image; return }
        applySourceImage(image)
    }

    private func applySourceImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        viewModel.sourceImage = ciImage
        viewModel.previewSize = CGSize(width: previewView.bounds.width * UIScreen.main.scale,
                                       height: previewView.bounds.height * UIScreen.main.scale)
        let preview = viewModel.filterEngine.generatePreview(parameters: viewModel.currentParameters, source: ciImage, targetSize: viewModel.previewSize)
        previewView.updateImage(preview)
        let thumbSize = CGSize(width: 144, height: 144)
        let thumb = viewModel.filterEngine.generatePreview(parameters: .default, source: ciImage, targetSize: thumbSize)
        filterPresetView.updateThumbnail(thumb)
    }

    func setFilterPresets(_ presets: [FilterPreset]) {
        filterPresetView.configure(presets: presets, thumbnailImage: nil)
    }

    func enterCropMode() {
        if let source = viewModel.sourceImage {
            var noCropParams = viewModel.currentParameters
            noCropParams.cropRect = nil
            let uncropped = viewModel.filterEngine.generatePreview(parameters: noCropParams, source: source, targetSize: viewModel.previewSize)
            previewView.updateImage(uncropped)
        }
        let imageDisplayRect = calculateImageDisplayRect(rotationCount: viewModel.currentParameters.rotationCount)
        cropViewModel = CropViewModel(imageBounds: imageDisplayRect)
        cropViewModel.saveState()
        var initialViewCropRect: CGRect? = nil
        if let codableRect = viewModel.currentParameters.cropRect {
            initialViewCropRect = convertImageRectToViewRect(codableRect.cgRect)
        }
        cropViewModel.rotationCount = viewModel.currentParameters.rotationCount
        cropOverlayView.frame = CGRect(x: previewView.frame.origin.x, y: previewView.frame.origin.y,
                                       width: previewView.frame.width, height: view.bounds.height - previewView.frame.origin.y)
        cropOverlayView.configure(imageBounds: imageDisplayRect, initialCropRect: initialViewCropRect, rotationCount: cropViewModel.rotationCount)
        cropOverlayView.isHidden = false
        toolTabBar.isHidden = true; adjustmentPanel.isHidden = true; filterPresetView.isHidden = true; navBar.isHidden = true
    }

    private func calculateImageDisplayRect(rotationCount: Int = 0) -> CGRect {
        guard let sourceImage = viewModel.sourceImage else { return previewView.bounds }
        let imageExtent = sourceImage.extent
        let viewSize = previewView.bounds.size
        guard viewSize.width > 0, viewSize.height > 0, imageExtent.width > 0, imageExtent.height > 0 else { return previewView.bounds }
        let imageW: CGFloat = rotationCount % 2 == 0 ? imageExtent.width : imageExtent.height
        let imageH: CGFloat = rotationCount % 2 == 0 ? imageExtent.height : imageExtent.width
        let imageAspect = imageW / imageH
        let viewAspect = viewSize.width / viewSize.height
        if imageAspect > viewAspect {
            let displayWidth = viewSize.width
            let displayHeight = viewSize.width / imageAspect
            return CGRect(x: 0, y: (viewSize.height - displayHeight) / 2, width: displayWidth, height: displayHeight)
        } else {
            let displayHeight = viewSize.height
            let displayWidth = viewSize.height * imageAspect
            return CGRect(x: (viewSize.width - displayWidth) / 2, y: 0, width: displayWidth, height: displayHeight)
        }
    }

    private func convertImageRectToViewRect(_ imageRect: CGRect) -> CGRect {
        guard let sourceImage = viewModel.sourceImage else { return imageRect }
        let viewSize = previewView.bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return imageRect }
        let originalExtent = sourceImage.extent
        let rotationCount = viewModel.currentParameters.rotationCount
        let rotatedWidth: CGFloat = rotationCount % 2 == 0 ? originalExtent.width : originalExtent.height
        let rotatedHeight: CGFloat = rotationCount % 2 == 0 ? originalExtent.height : originalExtent.width
        let imageAspect = rotatedWidth / rotatedHeight
        let viewAspect = viewSize.width / viewSize.height
        var displayRect: CGRect
        if imageAspect > viewAspect {
            let displayWidth = viewSize.width
            let displayHeight = viewSize.width / imageAspect
            displayRect = CGRect(x: 0, y: (viewSize.height - displayHeight) / 2, width: displayWidth, height: displayHeight)
        } else {
            let displayHeight = viewSize.height
            let displayWidth = viewSize.height * imageAspect
            displayRect = CGRect(x: (viewSize.width - displayWidth) / 2, y: 0, width: displayWidth, height: displayHeight)
        }
        let scaleX = displayRect.width / rotatedWidth
        let scaleY = displayRect.height / rotatedHeight
        let viewX = imageRect.origin.x * scaleX + displayRect.origin.x
        let viewY = displayRect.maxY - (imageRect.origin.y + imageRect.height) * scaleY
        return CGRect(x: viewX, y: viewY, width: imageRect.width * scaleX, height: imageRect.height * scaleY)
    }

    private func exitCropMode() {
        cropOverlayView.isHidden = true
        navBar.isHidden = false; toolTabBar.isHidden = false
        let currentTab = toolTabBar.selectedTab
        if currentTab == .effects {
            filterPresetView.isHidden = false
        } else {
            adjustmentPanel.isHidden = false
            adjustmentPanel.switchToTab(currentTab, parameters: viewModel.currentParameters, animated: false)
        }
    }
}

extension PhotoEditorViewController: ToolTabBarViewDelegate {
    func toolTabBarView(_ tabBar: ToolTabBarView, didSelectTab tab: ToolTab) {
        if tab == .crop {
            enterCropMode()
            toolTabBar.selectTab(.light, animated: false)
        } else if tab == .effects {
            adjustmentPanel.isHidden = true
            filterPresetView.isHidden = false
        } else {
            filterPresetView.isHidden = true
            adjustmentPanel.isHidden = false
            adjustmentPanel.switchToTab(tab, parameters: viewModel.currentParameters, animated: true)
        }
    }
}

extension PhotoEditorViewController: AdjustmentPanelViewDelegate {
    func adjustmentPanelView(_ panel: AdjustmentPanelView, didChangeValue value: Float, forKey key: AdjustmentKey) {
        viewModel.updateParameterPreview(key, value: value)
    }
    func adjustmentPanelView(_ panel: AdjustmentPanelView, didEndChangingValue value: Float, forKey key: AdjustmentKey) {
        viewModel.commitParameterChange()
    }
    func adjustmentPanelView(_ panel: AdjustmentPanelView, didResetKey key: AdjustmentKey) {
        viewModel.resetParameter(key)
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }
}

extension PhotoEditorViewController: FilterPresetViewDelegate {
    func filterPresetView(_ view: FilterPresetView, didSelectPreset preset: FilterPreset) {
        viewModel.applyFilter(preset)
        filterPresetView.setActivePreset(preset.id)
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }
    func filterPresetViewDidRemoveFilter(_ view: FilterPresetView) {
        viewModel.removeFilter()
        filterPresetView.setActivePreset(nil)
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }
}

extension PhotoEditorViewController: CropOverlayViewDelegate {
    func cropOverlayViewDidConfirm(_ view: CropOverlayView, cropRect: CGRect, rotationCount: Int) {
        let imageCropRect = convertViewRectToImageRect(cropRect, rotationCount: rotationCount)
        viewModel.applyCrop(imageCropRect, rotation: rotationCount)
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
        exitCropMode()
    }

    private func convertViewRectToImageRect(_ viewRect: CGRect, rotationCount: Int) -> CGRect {
        guard let sourceImage = viewModel.sourceImage else { return viewRect }
        let viewSize = previewView.bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return viewRect }
        let originalExtent = sourceImage.extent
        let rotatedWidth: CGFloat = rotationCount % 2 == 0 ? originalExtent.width : originalExtent.height
        let rotatedHeight: CGFloat = rotationCount % 2 == 0 ? originalExtent.height : originalExtent.width
        let imageAspect = rotatedWidth / rotatedHeight
        let viewAspect = viewSize.width / viewSize.height
        var displayRect: CGRect
        if imageAspect > viewAspect {
            let displayWidth = viewSize.width
            let displayHeight = viewSize.width / imageAspect
            displayRect = CGRect(x: 0, y: (viewSize.height - displayHeight) / 2, width: displayWidth, height: displayHeight)
        } else {
            let displayHeight = viewSize.height
            let displayWidth = viewSize.height * imageAspect
            displayRect = CGRect(x: (viewSize.width - displayWidth) / 2, y: 0, width: displayWidth, height: displayHeight)
        }
        let scaleX = rotatedWidth / displayRect.width
        let scaleY = rotatedHeight / displayRect.height
        let imageX = (viewRect.origin.x - displayRect.origin.x) * scaleX
        let imageY = (displayRect.maxY - (viewRect.origin.y + viewRect.height)) * scaleY
        return CGRect(x: imageX, y: imageY, width: viewRect.width * scaleX, height: viewRect.height * scaleY)
    }

    func cropOverlayViewDidCancel(_ view: CropOverlayView) {
        cropViewModel.restoreState()
        exitCropMode()
    }

    func cropOverlayViewDidRotate(_ view: CropOverlayView) {
        cropViewModel.rotate90Clockwise()
        cropOverlayView.rotationCount = cropViewModel.rotationCount
        guard let source = viewModel.sourceImage else { return }
        var rotatedParams = viewModel.currentParameters
        rotatedParams.cropRect = nil
        rotatedParams.rotationCount = cropViewModel.rotationCount
        let rotatedPreview = viewModel.filterEngine.generatePreview(parameters: rotatedParams, source: source, targetSize: viewModel.previewSize)
        previewView.updateImage(rotatedPreview)
        let imageDisplayRect = calculateImageDisplayRect(rotationCount: cropViewModel.rotationCount)
        cropOverlayView.configure(imageBounds: imageDisplayRect, initialCropRect: nil, rotationCount: cropViewModel.rotationCount)
    }
}
