import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

	/// Замыкание, вызываемое при изменении `state`.
	var onStateChange: ((State) -> Void)?

	private var state: State
	private let reviewsProvider: ReviewsProvider
	private let ratingRenderer: RatingRenderer
	private let decoder: JSONDecoder
	private let networkManager: INetworkManager

	init(
		state: State = State(),
		reviewsProvider: ReviewsProvider = ReviewsProvider(),
		ratingRenderer: RatingRenderer = RatingRenderer(),
		decoder: JSONDecoder = JSONDecoder(),
		networkManager: INetworkManager = NetworkManager.shared
	) {
		self.state = state
		self.reviewsProvider = reviewsProvider
		self.ratingRenderer = ratingRenderer
		self.decoder = decoder
		self.networkManager = networkManager
	}
}

// MARK: - Internal

extension ReviewsViewModel {
	typealias State = ReviewsViewModelState

	func refreshReviews() {
		state.shouldLoad = true
		state.isLoading = false
		state.items.removeAll()
		getReviews()
	}

	/// Метод получения отзывов.
	func getReviews() {
		guard state.shouldLoad, !state.isLoading else { return }
		state.shouldLoad = false
		state.isLoading.toggle()

		DispatchQueue.main.async {
			self.onStateChange?(self.state)
		}
		DispatchQueue.global().async { [weak self] in
			guard let self = self else { return }
			self.reviewsProvider.getReviews(offset: self.state.offset) { result in
				DispatchQueue.main.async {
					self.gotReviews(result)
				}
			}
		}
	}
}

// MARK: - Private

private extension ReviewsViewModel {

	/// Метод обработки получения отзывов.
	func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
		do {
			let data = try result.get()
			let reviews = try decoder.decode(Reviews.self, from: data)
			state.items.removeAll { $0 is ReviewCountCellConfig }
			processReviews(reviews.items, currentIndex: 0, totalCount: reviews.count)
		} catch {
			state.shouldLoad = true
			state.isLoading = false
			onStateChange?(state)
		}
	}

	func processReviews(_ reviews: [Review], currentIndex: Int, totalCount: Int) {
		guard currentIndex < reviews.count, state.items.count < totalCount else {
			state.shouldLoad = state.items.count < totalCount
			state.isLoading = false
			state.areImagesLoaded = true
			if state.isInitialLoad {
				state.isInitialLoad = false
			}
			let countConfig = ReviewCountCellConfig(reviewCount: state.items.count)
			state.items.append(countConfig)
			
			onStateChange?(state)
			return
		}
	
		let review = reviews[currentIndex]
		makeReviewItem(review) { item in
			self.state.items.append(item)
			self.processReviews(reviews, currentIndex: currentIndex + 1, totalCount: totalCount)
		}
	}

	/// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
	/// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
	func showMoreReview(with id: UUID) {
		guard
			let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
			var item = state.items[index] as? ReviewItem
		else { return }
		item.maxLines = .zero
		state.items[index] = item
		onStateChange?(state)
	}

	func loadImages(avatarURL: URL?, photoURLs: [URL]?, completion: @escaping (UIImage, [UIImage]?) -> Void) {
		let placeholderAvatar = UIImage(named: "l5w5aIHioYc") ?? UIImage()
		let defaultPhoto1 = UIImage(named: "IMG_0001") ?? UIImage()

		var avatarImage = placeholderAvatar
		var loadedPhotos: [UIImage] = []

		var pendingTasks = 0

		if avatarURL != nil { pendingTasks += 1 }
		if let photoURLs = photoURLs, !photoURLs.isEmpty { pendingTasks += photoURLs.count }

		if pendingTasks == 0 {
			completion(avatarImage, nil)
			return
		}

		if let avatarURL = avatarURL {
			networkManager.fetchImage(from: avatarURL) { result in
				switch result {
				case .success(let image):
					avatarImage = image
				case .failure(_):
					avatarImage = placeholderAvatar
				}
				pendingTasks -= 1
				if pendingTasks == 0 {
					DispatchQueue.main.async {
						completion(avatarImage, loadedPhotos.isEmpty ? nil : loadedPhotos)
					}
				}
			}
		}

		if let photoURLs = photoURLs, !photoURLs.isEmpty {
			for url in photoURLs {
				networkManager.fetchImage(from: url) { result in
					switch result {
					case .success(let image):
						loadedPhotos.append(image)
					case .failure(_):
						loadedPhotos.append(defaultPhoto1)
					}
					pendingTasks -= 1
					if pendingTasks == 0 {
						DispatchQueue.main.async {
							completion(avatarImage, loadedPhotos.isEmpty ? nil : loadedPhotos)
						}
					}
				}
			}
		}
	}
}

// MARK: - Items

private extension ReviewsViewModel {

	typealias ReviewItem = ReviewCellConfig

	func makeReviewItem(_ review: Review, completion: @escaping (ReviewItem) -> Void) {
		loadImages(avatarURL: review.avatarURL, photoURLs: review.photoURLs) { avatarImage, loadedPhotos in
			let reviewItem = ReviewItem(
				review: review,
				onTapShowMore: self.showMoreReview,
				avatarImage: avatarImage,
				photos: loadedPhotos
			)
			completion(reviewItem)
		}
	}
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		state.items.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let config = state.items[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
		config.update(cell: cell)
		return cell
	}
}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		state.items[indexPath.row].height(with: tableView.bounds.size)
	}

	/// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
	func scrollViewWillEndDragging(
		_ scrollView: UIScrollView,
		withVelocity velocity: CGPoint,
		targetContentOffset: UnsafeMutablePointer<CGPoint>
	) {
		if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
			getReviews()
		}
	}

	private func shouldLoadNextPage(
		scrollView: UIScrollView,
		targetOffsetY: CGFloat,
		screensToLoadNextPage: Double = 2.5
	) -> Bool {
		let viewHeight = scrollView.bounds.height
		let contentHeight = scrollView.contentSize.height
		let triggerDistance = viewHeight * screensToLoadNextPage
		let remainingDistance = contentHeight - viewHeight - targetOffsetY
		return remainingDistance <= triggerDistance
	}
}
