//
//  NetworkManager.swift
//  Test
//
//  Created by Лилия Андреева on 26.02.2025.
//

import UIKit

enum ProductsErrors: Error {
	case noData
	case decodingError
	case networkError(Error)
	
	var localizedDescription: String {
		switch self {
		case .noData:
			return "No data received."
		case .decodingError:
			return "Failed to decode data."
		case .networkError(let error):
			return "Network error: \(error.localizedDescription)"
		}
	}
}

protocol INetworkManager {
	func fetchImage(from url: URL, completion: @escaping (Result<UIImage, ProductsErrors>) -> Void)
}

final class NetworkManager: INetworkManager {
	private let imageCache = NSCache<NSURL, UIImage>()
	static let shared = NetworkManager()
	private init() {
		imageCache.countLimit = 100 
		imageCache.totalCostLimit = 50 * 1024 * 1024
	}
	
	func fetchImage(from url: URL, completion: @escaping (Result<UIImage, ProductsErrors>) -> Void) {
		if let cachedImage = imageCache.object(forKey: url as NSURL) {
			DispatchQueue.main.async {
				completion(.success(cachedImage))
			}
			return
		}
		var request = URLRequest(url: url)
		request.cachePolicy = .useProtocolCachePolicy
		request.timeoutInterval = 10.0
		
		let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
			guard let self = self else {
				DispatchQueue.main.async {
					completion(.failure(.noData))
				}
				return
			}
			if let error = error as NSError? {
				DispatchQueue.main.async {
					completion(.failure(.networkError(error)))
				}
				return
			}
			
			guard let data = data, !data.isEmpty else {
				DispatchQueue.main.async {
					completion(.failure(.noData))
				}
				return
			}
			guard let image = UIImage(data: data) else {
				DispatchQueue.main.async {
					completion(.failure(.decodingError))
				}
				return
			}

			self.imageCache.setObject(image, forKey: url as NSURL)

			DispatchQueue.main.async {
				completion(.success(image))
			}
		}
		task.resume()
	}
}
