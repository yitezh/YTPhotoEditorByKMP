import UIKit

protocol FilterPresetViewDelegate: AnyObject {
    func filterPresetView(_ view: FilterPresetView, didSelectPreset preset: FilterPreset)
    func filterPresetViewDidRemoveFilter(_ view: FilterPresetView)
}

class FilterPresetView: UIView {

    weak var delegate: FilterPresetViewDelegate?

    private var presets: [FilterPreset] = []
    private var activePresetId: String?
    private var thumbnailImage: UIImage?

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 72, height: 92)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(FilterPresetCell.self, forCellWithReuseIdentifier: FilterPresetCell.reuseId)
        return cv
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
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }

    func configure(presets: [FilterPreset], thumbnailImage: UIImage?) {
        self.presets = presets
        self.thumbnailImage = thumbnailImage
        collectionView.reloadData()
    }

    func setActivePreset(_ presetId: String?) {
        activePresetId = presetId
        collectionView.reloadData()
    }

    func updateThumbnail(_ image: UIImage?) {
        thumbnailImage = image
        collectionView.reloadData()
    }
}

extension FilterPresetView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        presets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterPresetCell.reuseId, for: indexPath) as! FilterPresetCell
        let preset = presets[indexPath.item]
        cell.configure(preset: preset, thumbnail: thumbnailImage, isActive: preset.id == activePresetId)
        return cell
    }
}

extension FilterPresetView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let preset = presets[indexPath.item]
        if preset.id == activePresetId {
            delegate?.filterPresetViewDidRemoveFilter(self)
        } else {
            delegate?.filterPresetView(self, didSelectPreset: preset)
        }
    }
}
