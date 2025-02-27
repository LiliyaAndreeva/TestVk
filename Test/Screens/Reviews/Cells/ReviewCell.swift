import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

	/// Идентификатор для переиспользования ячейки.
	static let reuseId = String(describing: ReviewCellConfig.self)

	/// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
	let id = UUID()
	/// Текст отзыва.
	let reviewText: NSAttributedString
	/// Максимальное отображаемое количество строк текста. По умолчанию 3.
	var maxLines = 3
	/// Время создания отзыва.
	let created: NSAttributedString
	/// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
	let onTapShowMore: (UUID) -> Void
	/// Имя пользователя (firstName + lastName).
	let username: NSAttributedString
	/// Аватар пользователя
	let avatarImage: UIImage
	/// Рейтинг (1–5).
	let rating: Int
	/// Массив фотографий (опционально).
	let photos: [UIImage]?

	/// Объект, хранящий посчитанные фреймы для ячейки отзыва.
	fileprivate let layout = ReviewCellLayout()

	init(
		review: Review,
		onTapShowMore: @escaping (UUID) -> Void,
		avatarImage: UIImage,
		photos: [UIImage]?
	) {
		self.reviewText = review.text.attributed(font: .text)
		self.created = review.created.attributed(font: .created, color: .created)
		self.username = (review.firstName + " " + review.lastName).attributed(font: .username)
		self.rating = review.rating
		self.avatarImage = avatarImage
		self.photos = photos
		self.onTapShowMore = onTapShowMore
	}
}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

	/// Метод обновления ячейки.
	/// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
	func update(cell: UITableViewCell) {
		guard let cell = cell as? ReviewCell else { return }
		cell.configure(with: self)
	}

	/// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
	/// Вызывается из `heightForRowAt:` делегата таблицы.
	func height(with size: CGSize) -> CGFloat {
		layout.height(config: self, maxWidth: size.width)
	}
}

// MARK: - Private

private extension ReviewCellConfig {

	/// Текст кнопки "Показать полностью...".
	static let showMoreText = "Показать полностью..."
		.attributed(font: .showMore, color: .showMore)

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {
	fileprivate var config: Config?

	fileprivate let avatarImageView = UIImageView()
	fileprivate let ratingImageView = UIImageView()
	fileprivate let usernameLabel = UILabel()
	fileprivate let reviewTextLabel = UILabel()
	fileprivate let createdLabel = UILabel()
	fileprivate let showMoreButton = UIButton()
	fileprivate let photosStackView = UIStackView()

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupCell()
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		guard let layout = config?.layout else { return }
		avatarImageView.frame = layout.avatarFrame
		ratingImageView.frame = layout.ratingFrame
		usernameLabel.frame = layout.usernameFrame
		reviewTextLabel.frame = layout.reviewTextLabelFrame
		createdLabel.frame = layout.createdLabelFrame
		showMoreButton.frame = layout.showMoreButtonFrame
		photosStackView.frame = layout.photosFrame
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		avatarImageView.image = nil
		ratingImageView.image = nil
		usernameLabel.attributedText = nil
		reviewTextLabel.attributedText = nil
		createdLabel.attributedText = nil
		showMoreButton.isHidden = false
		photosStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
	}

	fileprivate func configure(with config: Config) {
		self.config = config
		reviewTextLabel.attributedText = config.reviewText
		reviewTextLabel.numberOfLines = config.maxLines
		usernameLabel.attributedText = config.username
		createdLabel.attributedText = config.created
		avatarImageView.image = config.avatarImage
		ratingImageView.image = RatingRenderer(config: .default()).ratingImage(config.rating)
		avatarImageView.layer.cornerRadius = config.layout.avatarCornerRadius
		photosStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		photosStackView.spacing = config.layout.photosSpacing
		if let photos = config.photos {
			photos.forEach { photo in
				let imageView = UIImageView(image: photo)
				imageView.contentMode = .scaleAspectFill
				imageView.clipsToBounds = true
				imageView.layer.cornerRadius = config.layout.photoCornerRadius
				photosStackView.addArrangedSubview(imageView)
			}
		}
	}
}

// MARK: - Private

private extension ReviewCell {

	func setupCell() {
		setupAvatarImageView()
		setupRatingImageView()
		setupUsernameLabel()
		setupReviewTextLabel()
		setupCreatedLabel()
		setupShowMoreButton()
		setupPhotosStackView()
	}

	func setupAvatarImageView() {
		avatarImageView.contentMode = .scaleAspectFill
		avatarImageView.clipsToBounds = true
		contentView.addSubview(avatarImageView)
	}

	func setupRatingImageView() {
		ratingImageView.contentMode = .scaleAspectFit
		contentView.addSubview(ratingImageView)
	}

	func setupReviewTextLabel() {
		reviewTextLabel.lineBreakMode = .byWordWrapping
		reviewTextLabel.numberOfLines = 0
		contentView.addSubview(reviewTextLabel)
	}

	func setupUsernameLabel() {
		contentView.addSubview(usernameLabel)
	}

	func setupCreatedLabel() {
		contentView.addSubview(createdLabel)
	}

	func setupShowMoreButton() {
		showMoreButton.contentVerticalAlignment = .fill
		showMoreButton.setAttributedTitle(ReviewCellConfig.showMoreText, for: .normal)
		showMoreButton.addAction(UIAction { [weak self] _ in
			guard let self = self, let config = self.config else { return }
			config.onTapShowMore(config.id)
		}, for: .touchUpInside)
		contentView.addSubview(showMoreButton)
	}

	func setupPhotosStackView() {
		photosStackView.axis = .horizontal
		photosStackView.distribution = .fillEqually
		photosStackView.alignment = .center
		contentView.addSubview(photosStackView)
	}
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {

	// MARK: - Размеры
	fileprivate let avatarSize = CGSize(width: 36.0, height: 36.0)
	fileprivate let avatarCornerRadius: CGFloat = 18.0
	fileprivate let photoCornerRadius: CGFloat = 8.0
	fileprivate let photoSize = CGSize(width: 55.0, height: 66.0)
	fileprivate let showMoreButtonSize = Config.showMoreText.size()
	fileprivate let photosSpacing: CGFloat = 8.0

	// MARK: - Фреймы
	private(set) var avatarFrame = CGRect.zero
	private(set) var ratingFrame = CGRect.zero
	private(set) var reviewTextLabelFrame = CGRect.zero
	private(set) var showMoreButtonFrame = CGRect.zero
	private(set) var createdLabelFrame = CGRect.zero
	private(set) var photosFrame = CGRect.zero
	private(set) var usernameFrame = CGRect.zero

	// MARK: - Отступы

	private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

	private let avatarToUsernameSpacing = 10.0
	private let usernameToRatingSpacing = 6.0
	private let ratingToTextSpacing = 6.0
	private let ratingToPhotosSpacing = 10.0

	private let photosToTextSpacing = 10.0
	private let reviewTextToCreatedSpacing = 6.0
	private let showMoreToCreatedSpacing = 6.0
	private let avatarToRatingSpacing = 10.0
	private let ratingToUsernameSpacing = 4.0
	private let usernameToTextSpacing = 6.0

	// MARK: - Расчёт фреймов и высоты ячейки

	/// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
	func height(config: Config, maxWidth: CGFloat) -> CGFloat {
		let width = maxWidth - insets.left - insets.right

		var maxY = insets.top
		var showShowMoreButton = false

		avatarFrame = CGRect(
			origin: CGPoint(x: insets.left, y: maxY),
			size: avatarSize
		)
		let usernameSize = config.username.boundingRect(
			width: width - (
				insets.left + avatarFrame.maxX + avatarToRatingSpacing
			)
		).size

		usernameFrame = CGRect(
			origin: CGPoint(
				x:  avatarFrame.maxX  + avatarToRatingSpacing,
				y: maxY
			),
			size: usernameSize
		)
		let ratingRenderer = RatingRenderer(config: .default())
		let ratingImage = ratingRenderer.ratingImage(config.rating)
		ratingFrame = CGRect(
			origin: CGPoint(x: avatarFrame.maxX + avatarToRatingSpacing, y: usernameFrame.maxY + ratingToUsernameSpacing),
			size: ratingImage.size
		)

		maxY = max(avatarFrame.maxY, usernameFrame.maxY, ratingFrame.maxY) + usernameToTextSpacing
		if let photos = config.photos, !photos.isEmpty {
			let photosWidth = CGFloat(photos.count) * photoSize.width + CGFloat(photos.count - 1) * photosSpacing
			photosFrame = CGRect(
				origin: CGPoint(x: avatarFrame.maxX  + avatarToRatingSpacing, y: maxY),
				size: CGSize(
					width: min(photosWidth, width - (avatarFrame.maxX + avatarToRatingSpacing + insets.right)),
					height: photoSize.height
				)
			)
			maxY = photosFrame.maxY + photosToTextSpacing
		} else {
			photosFrame = .zero
		}

		if !config.reviewText.isEmpty() {
			let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
			let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
			showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight
			reviewTextLabelFrame = CGRect(
				origin: CGPoint(x: avatarFrame.maxX  + avatarToRatingSpacing, y: maxY),
				size: config.reviewText.boundingRect(
					width: width - (
					avatarFrame.maxX + avatarToRatingSpacing + insets.right
					),
					height: currentTextHeight
				).size
			)
			maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
		}

		if showShowMoreButton {
			showMoreButtonFrame = CGRect(
				origin: CGPoint(x: avatarFrame.maxX  + avatarToRatingSpacing, y: maxY),
				size: showMoreButtonSize
			)
			maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
		} else {
			showMoreButtonFrame = .zero
		}

		createdLabelFrame = CGRect(
			origin: CGPoint(x: avatarFrame.maxX  + avatarToRatingSpacing, y: maxY),
			size: config.created.boundingRect(width: width).size
		)
		return createdLabelFrame.maxY + insets.bottom
	}
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
