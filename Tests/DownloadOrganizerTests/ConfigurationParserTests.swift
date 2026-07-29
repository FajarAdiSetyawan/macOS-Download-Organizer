import Foundation
import Testing

@testable import DownloadOrganizer

@Suite("ConfigurationParser Tests")
struct ConfigurationParserTests {
    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    // MARK: - Decode

    @Test("Decodes valid full JSON configuration")
    func decodesValidFullJSON() throws {
        let json = """
        {
          "autoCreateFolders": true,
          "delay": 3,
          "duplicateStrategy": "rename",
          "enabled": true,
          "history": true,
          "notifications": true,
          "watchFolder": "~/Downloads"
        }
        """

        let config = try decoder.decode(
            AppConfiguration.self,
            from: Data(json.utf8)
        )

        #expect(config.enabled == true)
        #expect(config.watchFolder == "~/Downloads")
        #expect(config.delay == 3)
        #expect(config.notifications == true)
        #expect(config.autoCreateFolders == true)
        #expect(config.duplicateStrategy == "rename")
        #expect(config.history == true)
    }

    @Test("Decodes configuration with disabled fields")
    func decodesDisabledFields() throws {
        let json = """
        {
          "autoCreateFolders": false,
          "delay": 5,
          "duplicateStrategy": "rename",
          "enabled": false,
          "history": false,
          "notifications": false,
          "watchFolder": "~/Desktop"
        }
        """

        let config = try decoder.decode(
            AppConfiguration.self,
            from: Data(json.utf8)
        )

        #expect(config.enabled == false)
        #expect(config.notifications == false)
        #expect(config.autoCreateFolders == false)
        #expect(config.history == false)
        #expect(config.watchFolder == "~/Desktop")
        #expect(config.delay == 5)
    }

    @Test("Decodes configuration with custom delay")
    func decodesCustomDelay() throws {
        let json = """
        {
          "autoCreateFolders": true,
          "delay": 10.5,
          "duplicateStrategy": "rename",
          "enabled": true,
          "history": true,
          "notifications": true,
          "watchFolder": "~/Downloads"
        }
        """

        let config = try decoder.decode(
            AppConfiguration.self,
            from: Data(json.utf8)
        )

        #expect(config.delay == 10.5)
    }

    @Test("Decodes configuration with custom watch folder")
    func decodesCustomWatchFolder() throws {
        let json = """
        {
          "autoCreateFolders": true,
          "delay": 3,
          "duplicateStrategy": "rename",
          "enabled": true,
          "history": true,
          "notifications": false,
          "watchFolder": "~/Documents/Inbox"
        }
        """

        let config = try decoder.decode(
            AppConfiguration.self,
            from: Data(json.utf8)
        )

        #expect(config.watchFolder == "~/Documents/Inbox")
    }

    // MARK: - Encode

    @Test("Encodes default configuration to JSON")
    func encodesDefaultConfiguration() throws {
        let config = AppConfiguration.default
        let data = try encoder.encode(config)

        #expect(!data.isEmpty)

        let decoded = try decoder.decode(AppConfiguration.self, from: data)
        #expect(decoded.enabled == config.enabled)
        #expect(decoded.watchFolder == config.watchFolder)
        #expect(decoded.delay == config.delay)
        #expect(decoded.notifications == config.notifications)
        #expect(decoded.autoCreateFolders == config.autoCreateFolders)
        #expect(decoded.duplicateStrategy == config.duplicateStrategy)
        #expect(decoded.history == config.history)
    }

    @Test("Encoded JSON contains expected keys")
    func encodedJSONContainsExpectedKeys() throws {
        let config = AppConfiguration.default
        let data = try encoder.encode(config)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["enabled"] != nil)
        #expect(json?["watchFolder"] != nil)
        #expect(json?["delay"] != nil)
        #expect(json?["notifications"] != nil)
        #expect(json?["autoCreateFolders"] != nil)
        #expect(json?["duplicateStrategy"] != nil)
        #expect(json?["history"] != nil)
    }

    // MARK: - Default Values

    @Test("Default configuration has correct values")
    func defaultConfigurationHasCorrectValues() {
        let config = AppConfiguration.default

        #expect(config.enabled == true)
        #expect(config.watchFolder == "~/Downloads")
        #expect(config.delay == 3)
        #expect(config.notifications == true)
        #expect(config.autoCreateFolders == true)
        #expect(config.duplicateStrategy == "rename")
        #expect(config.history == true)
    }

    // MARK: - Invalid JSON

    @Test("Throws on invalid JSON")
    func throwsOnInvalidJSON() {
        let invalidJSON = "{ invalid json }"

        #expect(throws: (any Error).self) {
            try self.decoder.decode(
                AppConfiguration.self,
                from: Data(invalidJSON.utf8)
            )
        }
    }

    @Test("Throws on missing required field")
    func throwsOnMissingField() {
        let json = """
        {
          "enabled": true
        }
        """

        #expect(throws: (any Error).self) {
            try self.decoder.decode(
                AppConfiguration.self,
                from: Data(json.utf8)
            )
        }
    }

    // MARK: - Round Trip

    @Test("Round trip encode decode preserves all values")
    func roundTripPreservesValues() throws {
        let original = AppConfiguration(
            enabled: false,
            watchFolder: "~/Desktop",
            delay: 7.5,
            notifications: false,
            autoCreateFolders: false,
            duplicateStrategy: "rename",
            history: false
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AppConfiguration.self, from: data)

        #expect(decoded.enabled == original.enabled)
        #expect(decoded.watchFolder == original.watchFolder)
        #expect(decoded.delay == original.delay)
        #expect(decoded.notifications == original.notifications)
        #expect(decoded.autoCreateFolders == original.autoCreateFolders)
        #expect(decoded.duplicateStrategy == original.duplicateStrategy)
        #expect(decoded.history == original.history)
    }
}