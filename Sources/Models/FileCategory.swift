import Foundation

public enum FileCategory: String, Codable, CaseIterable, Sendable {
    case images = "Images"
    case videos = "Videos"
    case audio = "Audio"
    case documents = "Documents"
    case pdf = "PDF"
    case archives = "Archives"
    case applications = "Applications"
    case books = "Books"
    case code = "Code"
    case design = "Design"
    case others = "Others"
}