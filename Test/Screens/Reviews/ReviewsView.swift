import UIKit

final class ReviewsView: UIView {

	let tableView = UITableView()
	private let activityIndicator = UIActivityIndicatorView(style: .large)
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupView()
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		tableView.frame = bounds.inset(by: safeAreaInsets)
		activityIndicator.center = center
	}

}

// MARK: - Private

/*private */extension ReviewsView {
	
	func setupView() {
		backgroundColor = .systemBackground
		setupTableView()
		setupActivityIndicator()
		
	}
	
	func setupTableView() {
		addSubview(tableView)
		tableView.separatorStyle = .none
		tableView.allowsSelection = false
		tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCellConfig.reuseId)
		tableView.register(ReviewCountCell.self, forCellReuseIdentifier: ReviewCountCellConfig.reuseId)
	}
	func setupActivityIndicator() {
		addSubview(activityIndicator)
		activityIndicator.hidesWhenStopped = true
	}
	
	func startLoading() {
		activityIndicator.startAnimating()
		tableView.isHidden = true
	}


	func stopLoading() {
		activityIndicator.stopAnimating()
		tableView.isHidden = false
	}
	
}
