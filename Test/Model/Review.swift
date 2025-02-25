/// Модель отзыва.
struct Review: Decodable {
	
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
	var avatarImageName: String = "l5w5aIHioYc"
	/// URLs фотографий (опционально).
	var photoImageNames: [String]? = nil
	
	enum CodingKeys: String, CodingKey {
			case firstName = "first_name"
			case lastName = "last_name"
			case rating
			case text
			case created
		}
}
