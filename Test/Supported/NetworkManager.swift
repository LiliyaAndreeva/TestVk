//
//  NetworkManager.swift
//  Test
//
//  Created by Лилия Андреева on 26.02.2025.
//

import UIKit

protocol INetworkManager {
	func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void)
}

final class NetworkManager: INetworkManager {
	static let shared = NetworkManager()
	private init() {}

	func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
		let task = URLSession.shared.dataTask(with: url) { data, _, _ in
			if let data = data, let image = UIImage(data: data) {
				completion(image)
			} else {
				completion(nil)
			}
		}
		task.resume()
	}
}
