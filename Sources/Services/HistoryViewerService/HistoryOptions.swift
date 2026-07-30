import Foundation

public struct HistoryOptions: Sendable {
    public let limit: Int
    public let todayOnly: Bool
    public let category: String?
    public let fileExtension: String?

    public init(
        limit: Int = 50,
        todayOnly: Bool = false,
        category: String? = nil,
        fileExtension: String? = nil
    ) {
        self.limit = limit
        self.todayOnly = todayOnly
        self.category = category
        self.fileExtension = fileExtension
    }

    public static func parse(from arguments: [String]) -> HistoryOptions {
        var limit = 50
        var todayOnly = false
        var category: String? = nil
        var fileExtension: String? = nil

        var index = 0

        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--today":
                todayOnly = true

            case "--limit":
                if index + 1 < arguments.count,
                   let value = Int(arguments[index + 1]),
                   value > 0 {
                    limit = value
                    index += 1
                }

            case "--category":
                if index + 1 < arguments.count {
                    category = arguments[index + 1]
                    index += 1
                }

            case "--extension":
                if index + 1 < arguments.count {
                    fileExtension = arguments[index + 1]
                        .trimmingCharacters(in: CharacterSet(charactersIn: "."))
                        .lowercased()
                    index += 1
                }

            default:
                break
            }

            index += 1
        }

        return HistoryOptions(
            limit: limit,
            todayOnly: todayOnly,
            category: category,
            fileExtension: fileExtension
        )
    }
}