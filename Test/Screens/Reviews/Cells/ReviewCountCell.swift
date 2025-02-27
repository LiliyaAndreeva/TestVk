//
//  Ку.swift
//  Test
//
//  Created by Лилия Андреева on 25.02.2025.
//

import UIKit
// MARK: - ReviewCountCellConfig
struct ReviewCountCellConfig: TableCellConfig {
	static let reuseId = String(describing: ReviewCountCellConfig.self)

	/// Общее количество отзывов.
	let reviewCount: Int

	func update(cell: UITableViewCell) {
		guard let cell = cell as? ReviewCountCell else { return }
		cell.countLabel.text = "\(reviewCount) отзывов"
	}

	func height(with size: CGSize) -> CGFloat {
		return 44
	}
}

final class ReviewCountCell: UITableViewCell {
	let countLabel = UILabel()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		layoutFrames()
	}
}

// MARK: - Layout
private extension ReviewCountCell {
	func setupUI() {
		countLabel.textAlignment = .center
		countLabel.font = .reviewCount
		countLabel.textColor = .reviewCount
		contentView.addSubview(countLabel)
	}

	func layoutFrames() {
		let labelSize = countLabel.intrinsicContentSize
		countLabel.frame = CGRect(
			x: (contentView.bounds.width - labelSize.width) / 2,
			y: (contentView.bounds.height - labelSize.height) / 2,
			width: labelSize.width,
			height: labelSize.height
		)
	}
}
