/// Модель отзыва.
import Foundation
struct Review: Codable {
	
	/// Текст отзыва.
	let text: String
	/// Время создания отзыва.
	let created: String
	/// Имя пользователя.
	let firstName: String
	/// Фамилия пользователя.
	let lastName: String
	/// Рейтинг отзыва (1–5).
	let rating: Int
	/// URL аватара пользователя
	var avatarImageName: String?
	/// URLs фотографий (опционально).
	var photoImageNames: [String]?
	
	enum CodingKeys: String, CodingKey {
		case firstName = "first_name"
		case lastName = "last_name"
		case rating
		case text
		case created
		case avatarImageName = "avatar_url"
		case photoImageNames = "photo_urls"
	}
}
extension Review {
	var avatarURL: URL? {
		guard let avatarImageName = avatarImageName else { return nil }
		return URL(string: avatarImageName)
	}

	var photoURLs: [URL]? {
		photoImageNames?.compactMap { URL(string: $0) }
	}
}
