import UIKit
// MARK: - class ReviewsViewController
final class ReviewsViewController: UIViewController {

	private lazy var reviewsView = makeReviewsView()
	private let viewModel: ReviewsViewModel

	init(viewModel: ReviewsViewModel) {
		self.viewModel = viewModel
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		view = reviewsView
		title = "Отзывы"
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		viewModel.getReviews()
		setupViewModel()
	}

}

// MARK: - Private

private extension ReviewsViewController {

	func makeReviewsView() -> ReviewsView {
		let reviewsView = ReviewsView()
		reviewsView.tableView.delegate = viewModel
		reviewsView.tableView.dataSource = viewModel

		let refreshControl = UIRefreshControl()
				refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
				reviewsView.tableView.refreshControl = refreshControl
		
		return reviewsView
	}

	func setupViewModel() {
		viewModel.onStateChange = { [weak self] state in
			DispatchQueue.main.async {
				guard let self = self else { return }
				if state.isLoading && state.isInitialLoad {
					self.reviewsView.startLoading()
				} else if !state.isLoading {
					self.reviewsView.stopLoading()
					self.reviewsView.tableView.reloadData()
					if let refreshControl = self.reviewsView.tableView.refreshControl, state.isInitialLoad == false {
						refreshControl.endRefreshing()
					}
				}
			}
		}
	}

	@objc func handleRefresh() {
		viewModel.refreshReviews()
		reviewsView.tableView.reloadData()
		reviewsView.tableView.refreshControl?.endRefreshing()
	}
}
