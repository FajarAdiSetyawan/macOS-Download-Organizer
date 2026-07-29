import Foundation

public struct MoveRecord: Sendable {
    public let id: UUID
    public let filename: String
    public let originalPath: String
    public let destinationPath: String
    public let category: String
    public let fileExtension: String
    public let fileSize: Int64
    public let createdAt: Date
    public let movedAt: Date
    public let status: String

    public init(
        id: UUID = UUID(),
        filename: String,
        originalPath: String,
        destinationPath: String,
        category: String,
        fileExtension: String,
        fileSize: Int64,
        createdAt: Date,
        movedAt: Date,
        status: String
    ) {
        self.id = id
        self.filename = filename
        self.originalPath = originalPath
        self.destinationPath = destinationPath
        self.category = category
        self.fileExtension = fileExtension
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.movedAt = movedAt
        self.status = status
    }
}