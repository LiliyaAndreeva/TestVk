//
//  CustomActivityIndicator.swift
//  Test
//
//  Created by Лилия Андреева on 27.02.2025.
//

import UIKit

final class CustomActivityIndicatorView: UIView {
	private let dotLayer = CAReplicatorLayer()
	private let dotSize: CGFloat = 10
	private let dotCount = 8
	private let animationDuration: CFTimeInterval = 1.2
	private let radiusMultiplier: CGFloat = 1.5

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupAnimation()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupAnimation() {
		let radius = dotSize * radiusMultiplier
		let dot = CALayer()
		dot.bounds = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
		dot.position = CGPoint(x: bounds.midX, y: bounds.midY - radius)
		dot.cornerRadius = dotSize / 2
		dot.backgroundColor = UIColor.systemBlue.cgColor
		dot.opacity = 0.8

		dotLayer.addSublayer(dot)
		dotLayer.instanceCount = dotCount
		dotLayer.instanceTransform = CATransform3DMakeRotation((2 * .pi) / CGFloat(dotCount), 0, 0, 1)

		layer.addSublayer(dotLayer)
	}

	private func createAnimation() -> CABasicAnimation {
		let animation = CABasicAnimation(keyPath: "opacity")
		animation.fromValue = 1
		animation.toValue = 0.3
		animation.duration = animationDuration
		animation.repeatCount = .infinity
		animation.autoreverses = true
		return animation
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		dotLayer.bounds = bounds
		dotLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
	}

	func startAnimating() {
		isHidden = false
		if dotLayer.sublayers?.first?.animation(forKey: "fade") == nil {
			dotLayer.sublayers?.first?.add(createAnimation(), forKey: "fade")
		}
	}

	func stopAnimating() {
		isHidden = true
		dotLayer.sublayers?.first?.removeAnimation(forKey: "fade")
	}
}
