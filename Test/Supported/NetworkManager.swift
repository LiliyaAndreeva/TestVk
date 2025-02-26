//
//  NetworkManager.swift
//  Test
//
//  Created by Лилия Андреева on 26.02.2025.
//

import UIKit

enum ProductsErrors: Error {
	case invalidURL
	case noData
	case decodingError
	case networkError(Error)
	case noMoreData
	
	var localizedDescription: String {
		switch self {
		case .invalidURL:
			return "Invalid URL."
		case .noData:
			return "No data received."
		case .decodingError:
			return "Failed to decode data."
		case .networkError(let error):
			return "Network error: \(error.localizedDescription)"
		case .noMoreData:
			return	"⚠️ Данные закончились"
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
		imageCache.countLimit = 100 // Максимальное количество объектов в кэше
		imageCache.totalCostLimit = 50 * 1024 * 1024
	}

//	func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
//		if let cachedImage = imageCache.object(forKey: url as NSURL) {
//			completion(cachedImage)
//			return
//		}
//		
//		//		let task = URLSession.shared.dataTask(with: url) { data, _, _ in
//		//			if let data = data, let image = UIImage(data: data) {
//		//				completion(image)
//		//			} else {
//		//				completion(nil)
//		//			}
//		//		}
//		let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
//		let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//			// Проверяем ошибки
//			if let error = error {
//				print("Ошибка загрузки \(url): \(error.localizedDescription)")
//				DispatchQueue.main.async {
//					completion(nil)
//				}
//				return
//			}
//			
//			// Проверяем HTTP-статус (опционально)
//			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
//				print("Ошибка HTTP \(httpResponse.statusCode) для \(url)")
//				DispatchQueue.main.async {
//					completion(nil)
//				}
//				return
//			}
//			
//			// Преобразуем данные в изображение
//			guard let data = data, let image = UIImage(data: data) else {
//				print("Не удалось создать изображение из данных для \(url)")
//				DispatchQueue.main.async {
//					completion(nil)
//				}
//				return
//			}
//			
//			// 3. Сохраняем в кэш
//			self?.imageCache.setObject(image, forKey: url as NSURL)
//			print("Изображение загружено и добавлено в кэш: \(url)")
//			
//			// 4. Возвращаем результат на главной очереди
//			DispatchQueue.main.async {
//				completion(image)
//			}
//		}
//		task.resume()
//	}
	func fetchImage(from url: URL, completion: @escaping (Result<UIImage, ProductsErrors>) -> Void) {
		
		// Проверка кэша
		if let cachedImage = imageCache.object(forKey: url as NSURL) {
			print("Изображение взято из кэша: \(url)")
			DispatchQueue.main.async {
				completion(.success(cachedImage))
			}
			return
		}
		
		// Создание запроса
		var request = URLRequest(url: url)
		request.cachePolicy = .useProtocolCachePolicy
		request.timeoutInterval = 10.0
		
		// Выполнение сетевого запроса
		let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
			guard let self = self else { return }
			
			// Обработка ошибок сети
			if let error = error as NSError? {
				print("Ошибка загрузки \(url): \(error.localizedDescription)")
				DispatchQueue.main.async {
					completion(.failure(.networkError(error)))
				}
				return
			}
			
			
			// Проверка наличия данных
			guard let data = data, !data.isEmpty else {
				print("Нет данных для \(url)")
				DispatchQueue.main.async {
					completion(.failure(.noData))
				}
				return
			}
			
			// Преобразование данных в изображение
			guard let image = UIImage(data: data) else {
				print("Ошибка декодирования изображения для \(url)")
				DispatchQueue.main.async {
					completion(.failure(.decodingError))
				}
				return
			}
			
			// Кэширование изображения
			self.imageCache.setObject(image, forKey: url as NSURL)
			print("Изображение загружено и добавлено в кэш: \(url)")
			
			// Возвращение результата на главном потоке
			DispatchQueue.main.async {
				completion(.success(image))
			}
		}
		
		task.resume()
	}
}
