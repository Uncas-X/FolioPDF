import XCTest
import FolioCore
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import PDFKit
@testable import FolioPDF

final class EncryptionSettingsTests: XCTestCase {
    @MainActor
    func testEncryptedExportKeepsAccurateHistoryWithoutSavingPassword() async throws {
        let name = "FolioPDFTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: directory) }
        let imageURL = directory.appendingPathComponent("test.png")
        let context = try XCTUnwrap(CGContext(data: nil, width: 40, height: 30, bitsPerComponent: 8, bytesPerRow: 0,
                                              space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        let writer = try XCTUnwrap(CGImageDestinationCreateWithURL(imageURL as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(writer, try XCTUnwrap(context.makeImage()), nil)
        XCTAssertTrue(CGImageDestinationFinalize(writer))
        for (index, mode) in [(true, false), (false, true), (true, true)].enumerated() {
        let model = AppModel(defaults: defaults)
        model.assets = [try ImagePipeline.inspect(imageURL)]
        model.settings.useInterfaceFile = false
        model.openingPasswordEnabled = mode.0
        model.editingPasswordEnabled = mode.1
        if mode.0 {
            model.openingPassword = mode.1 ? "Reader-secret!" : "Session-test-secret!"
            model.openingPasswordConfirmation = model.openingPassword
        }
        if mode.1 {
            model.editingPassword = "Owner-test-secret!"
            model.editingPasswordConfirmation = model.editingPassword
        }
        let output = directory.appendingPathComponent("test-\(index).pdf")
        model.startConversion(to: output)
        let deadline = Date().addingTimeInterval(15)
        while model.running && Date() < deadline { try await Task.sleep(for: .milliseconds(30)) }
        XCTAssertFalse(model.running)
        if model.running { model.cancel() }
        XCTAssertNil(model.errorMessage)
        XCTAssertTrue(model.showResults)
        XCTAssertEqual(model.exports.first?.pageCount, 1)
        let document = try XCTUnwrap(PDFDocument(url: output))
        XCTAssertEqual(document.isLocked, mode.0)
        if mode.0 { XCTAssertTrue(document.unlock(withPassword: model.openingPassword)) }
        XCTAssertEqual(document.allowsDocumentChanges, !mode.1)
        let savedHistory = try XCTUnwrap(defaults.data(forKey: "recentExports"))
        XCTAssertEqual(try JSONDecoder().decode([ExportRecord].self, from: savedHistory).first?.pageCount, 1)
        let savedSettings = try XCTUnwrap(defaults.data(forKey: "conversionSettings"))
        let persisted = try PropertyListSerialization.data(fromPropertyList: defaults.persistentDomain(forName: name) ?? [:], format: .xml, options: 0)
        for password in [model.openingPassword, model.editingPassword] where !password.isEmpty {
            XCTAssertFalse(String(decoding: savedHistory, as: UTF8.self).contains(password))
            XCTAssertFalse(String(decoding: savedSettings, as: UTF8.self).contains(password))
            XCTAssertFalse(String(decoding: persisted, as: UTF8.self).contains(password))
            XCTAssertFalse(model.logs.joined().contains(password))
        }
        }
    }

    @MainActor
    func testPasswordsAreSessionOnlyAndResetClearsThem() throws {
        let name = "FolioPDFTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = AppModel(defaults: defaults)
        model.settings.author = "Test author"
        let persistedBefore = defaults.persistentDomain(forName: name)
        model.openingPasswordEnabled = true
        model.openingPassword = "Reader-session!"
        model.openingPasswordConfirmation = model.openingPassword
        model.editingPasswordEnabled = true
        model.editingPassword = "Owner-session-secret!"
        model.editingPasswordConfirmation = model.editingPassword
        XCTAssertEqual(try model.encryptionOptions()?.openPassword, "Reader-session!")
        XCTAssertEqual(try model.encryptionOptions()?.editingPassword, "Owner-session-secret!")
        XCTAssertEqual(defaults.persistentDomain(forName: name) as NSDictionary?, persistedBefore as NSDictionary?)
        let fresh = AppModel(defaults: defaults)
        XCTAssertFalse(fresh.openingPasswordEnabled)
        XCTAssertTrue(fresh.openingPassword.isEmpty)
        XCTAssertTrue(fresh.openingPasswordConfirmation.isEmpty)
        XCTAssertFalse(fresh.editingPasswordEnabled)
        XCTAssertTrue(fresh.editingPassword.isEmpty)
        XCTAssertTrue(fresh.editingPasswordConfirmation.isEmpty)
        XCTAssertEqual(fresh.settings.author, "Test author")
        model.resetSettings()
        XCTAssertFalse(model.openingPasswordEnabled)
        XCTAssertTrue(model.openingPassword.isEmpty)
        XCTAssertTrue(model.openingPasswordConfirmation.isEmpty)
        XCTAssertFalse(model.editingPasswordEnabled)
        XCTAssertTrue(model.editingPassword.isEmpty)
        XCTAssertTrue(model.editingPasswordConfirmation.isEmpty)
    }

    @MainActor
    func testInvalidPasswordAndMismatchCannotStartAnExport() throws {
        let name = "FolioPDFTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = AppModel(defaults: defaults)
        XCTAssertNil(try model.encryptionOptions())
        model.openingPasswordEnabled = true
        XCTAssertThrowsError(try model.encryptionOptions())
        model.openingPassword = "Valid-password"
        model.openingPasswordConfirmation = "Different-password"
        XCTAssertThrowsError(try model.encryptionOptions())
        model.startConversion(to: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf"))
        XCTAssertFalse(model.running)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.logs.isEmpty)
        model.openingPasswordConfirmation = model.openingPassword
        XCTAssertNotNil(try model.encryptionOptions())
        model.openingPasswordEnabled = false
        XCTAssertNil(try model.encryptionOptions())
    }

    @MainActor
    func testEditingPasswordConfirmationAndPasswordSeparation() throws {
        let name = "FolioPDFTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = AppModel(defaults: defaults)
        model.editingPasswordEnabled = true
        XCTAssertThrowsError(try model.encryptionOptions())
        model.editingPassword = "Owner-password"
        model.editingPasswordConfirmation = "Wrong-confirmation"
        XCTAssertThrowsError(try model.encryptionOptions())
        model.editingPasswordConfirmation = model.editingPassword
        XCTAssertEqual(try model.encryptionOptions(), PDFEncryptionOptions(editingPassword: "Owner-password"))
        model.openingPasswordEnabled = true
        model.openingPassword = model.editingPassword
        model.openingPasswordConfirmation = model.openingPassword
        XCTAssertThrowsError(try model.encryptionOptions()) {
            XCTAssertEqual($0 as? PDFEncryptionError, .identicalPasswords)
        }
        model.openingPassword = "Reader-password"
        model.openingPasswordConfirmation = model.openingPassword
        XCTAssertEqual(try model.encryptionOptions(), PDFEncryptionOptions(openPassword: "Reader-password", editingPassword: "Owner-password"))
    }

    @MainActor
    func testDisablingEachPasswordClearsOnlyItsOwnFields() throws {
        let name = "FolioPDFTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = AppModel(defaults: defaults)
        model.openingPasswordEnabled = true
        model.editingPasswordEnabled = true
        model.openingPassword = "Reader-password"
        model.openingPasswordConfirmation = model.openingPassword
        model.editingPassword = "Owner-password"
        model.editingPasswordConfirmation = model.editingPassword
        model.openingPasswordEnabled = false
        XCTAssertTrue(model.encryptionEnabled)
        XCTAssertTrue(model.openingPassword.isEmpty)
        XCTAssertTrue(model.openingPasswordConfirmation.isEmpty)
        XCTAssertEqual(try model.encryptionOptions(), PDFEncryptionOptions(editingPassword: "Owner-password"))
        model.editingPasswordEnabled = false
        XCTAssertTrue(model.editingPassword.isEmpty)
        XCTAssertTrue(model.editingPasswordConfirmation.isEmpty)
        XCTAssertFalse(model.encryptionEnabled)
        XCTAssertNil(try model.encryptionOptions())
    }
}
