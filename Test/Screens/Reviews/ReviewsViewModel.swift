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

	/// Метод получения отзывов.
	func getReviews() {
		guard state.shouldLoad, !state.isLoading else { return }
		state.shouldLoad = false
		state.isLoading = true
		onStateChange?(state)
	
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
			print("Декодировано \(reviews.items.count) отзывов, общее количество: \(reviews.count)")
			
			state.items.removeAll { $0 is ReviewCountCellConfig }

			
			let group = DispatchGroup()
			var reviewItems: [ReviewItem] = []
			
			for review in reviews.items {
				group.enter()
				makeReviewItem(review) { item in
					reviewItems.append(item)
					group.leave()
				}
			}
			
			group.notify(queue: .main) {
				print("group.notify сработал, добавляем \(reviewItems.count) элементов")
				self.state.items += reviewItems
				self.state.offset += self.state.limit
				self.state.shouldLoad = self.state.offset < reviews.count
				self.state.isLoading = false
				self.state.areImagesLoaded = true
				if self.state.isInitialLoad {
					self.state.isInitialLoad = false
				}
				let countConfig = ReviewCountCellConfig(reviewCount: self.state.items.count)
				self.state.items.append(countConfig)
				self.onStateChange?(self.state)
				print("onStateChange вызван")
			}
		} catch {
			state.shouldLoad = true
			state.isLoading = false
			onStateChange?(state)
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
		
		var avatarImage = placeholderAvatar
		var loadedPhotos: [UIImage] = []
		
		let group = DispatchGroup()
		
		if let avatarURL = avatarURL {
			group.enter()
			networkManager.fetchImage(from: avatarURL) { result in
				switch result {
				case .success(let image):
					avatarImage = image
					print("Загружен аватар: \(avatarURL)")
				case .failure(let error):
					avatarImage = placeholderAvatar
					print("Ошибка загрузки аватара: \(avatarURL), ошибка: \(error)")
				}
				group.leave()
			}
		}
		
		if let photoURLs = photoURLs, !photoURLs.isEmpty {
			for url in photoURLs {
				group.enter()
				networkManager.fetchImage(from: url) { result in
					switch result {
					case .success(let image):
						loadedPhotos.append(image)
						print("Загружено фото: \(url)")
					case .failure(let error):
						print("Ошибка загрузки фото: \(url), ошибка: \(error)")
					}
					group.leave()
				}
			}
		}
		
		group.notify(queue: .main) {
			print("Все изображения загружены, photos: \(loadedPhotos.count)")
			self.onStateChange?(self.state)
			completion(avatarImage, loadedPhotos.isEmpty ? nil : loadedPhotos)
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
