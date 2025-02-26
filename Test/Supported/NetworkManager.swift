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
	private let imageCache = NSCache<NSURL, UIImage>()
	static let shared = NetworkManager()
	private init() {
		imageCache.countLimit = 100 // Максимальное количество объектов в кэше
		imageCache.totalCostLimit = 50 * 1024 * 1024
	}

	func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
		if let cachedImage = imageCache.object(forKey: url as NSURL) {
			completion(cachedImage)
			return
		}
		
		//		let task = URLSession.shared.dataTask(with: url) { data, _, _ in
		//			if let data = data, let image = UIImage(data: data) {
		//				completion(image)
		//			} else {
		//				completion(nil)
		//			}
		//		}
		let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
		let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
			// Проверяем ошибки
			if let error = error {
				print("Ошибка загрузки \(url): \(error.localizedDescription)")
				DispatchQueue.main.async {
					completion(nil)
				}
				return
			}
			
			// Проверяем HTTP-статус (опционально)
			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
				print("Ошибка HTTP \(httpResponse.statusCode) для \(url)")
				DispatchQueue.main.async {
					completion(nil)
				}
				return
			}
			
			// Преобразуем данные в изображение
			guard let data = data, let image = UIImage(data: data) else {
				print("Не удалось создать изображение из данных для \(url)")
				DispatchQueue.main.async {
					completion(nil)
				}
				return
			}
			
			// 3. Сохраняем в кэш
			self?.imageCache.setObject(image, forKey: url as NSURL)
			print("Изображение загружено и добавлено в кэш: \(url)")
			
			// 4. Возвращаем результат на главной очереди
			DispatchQueue.main.async {
				completion(image)
			}
		}
		task.resume()
	}
}
