import Foundation
import CoreGraphics
import PDFKit
import Security

/// Kept only in memory for the current export; deliberately not Codable.
public struct PDFEncryptionOptions: Sendable, Equatable {
    public let openPassword: String?
    public let editingPassword: String?
    public init(openPassword: String? = nil, editingPassword: String? = nil) {
        self.openPassword = openPassword
        self.editingPassword = editingPassword
    }
    /// Compatibility initializer for opening-password-only exports.
    public init(password: String) { self.init(openPassword: password) }
}

public enum PDFEncryptionError: LocalizedError, Equatable {
    case invalidPassword, missingPassword, identicalPasswords, openingPasswordTooLongForEditing, invalidSource, sourceAlreadyEncrypted, unsupportedPageLabels
    case writeFailed, verificationFailed, randomGenerationFailed, destinationExists, sourceEqualsDestination

    public var errorDescription: String? {
        switch self {
        case .invalidPassword: return "Use 1–32 printable ASCII characters for the PDF password."
        case .missingPassword: return "Set an opening password or an editing password."
        case .identicalPasswords: return "Use different passwords for opening and editing."
        case .openingPasswordTooLongForEditing: return "Use 1–16 printable ASCII characters for the opening password when an editing password is set."
        case .invalidSource: return "The source PDF could not be opened for encryption."
        case .sourceAlreadyEncrypted: return "The source PDF is already encrypted. Export an unencrypted copy first."
        case .unsupportedPageLabels: return "Password protection cannot preserve page labels with custom text prefixes. Remove the prefixes or turn off password protection."
        case .writeFailed: return "The password-protected PDF could not be written. No unencrypted PDF was exported."
        case .verificationFailed: return "The password-protected PDF failed verification. No output file was saved."
        case .randomGenerationFailed: return "A secure owner password could not be generated. Try again."
        case .destinationExists: return "A file already exists at this destination. Choose a new filename."
        case .sourceEqualsDestination: return "Choose a new filename. The original PDF will not be overwritten."
        }
    }
}

public enum PDFEncryption {
    public static func validate(options: PDFEncryptionOptions) throws {
        // CoreGraphics uses only the first 32 ASCII bytes. Reject truncation, Unicode,
        // and control characters rather than silently accepting a different password.
        guard options.openPassword != nil || options.editingPassword != nil else { throw PDFEncryptionError.missingPassword }
        for password in [options.openPassword, options.editingPassword].compactMap({ $0 }) {
            guard (1...32).contains(password.utf8.count), password.utf8.allSatisfy({ (32...126).contains($0) }) else {
                throw PDFEncryptionError.invalidPassword
            }
        }
        if let open = options.openPassword, let editing = options.editingPassword {
            // The macOS PDF writer produces unusable owner credentials for some user
            // passwords longer than 16 bytes. Use one predictable supported range for
            // combined protection; never truncate, pad or otherwise change a password.
            guard open.utf8.count <= 16 else { throw PDFEncryptionError.openingPasswordTooLongForEditing }
            guard open != editing else { throw PDFEncryptionError.identicalPasswords }
        }
    }

    /// Uses Apple's PDF writer for all encryption. Publishes only a verified encrypted file.
    /// Call off the main actor: PDFKit serialization is synchronous.
    public static func encrypt(source: URL, destination: URL, options: PDFEncryptionOptions) throws {
        try validate(options: options)
        try Task.checkCancellation()
        let manager = FileManager.default
        guard source.resolvingSymlinksInPath().standardizedFileURL != destination.resolvingSymlinksInPath().standardizedFileURL else {
            throw PDFEncryptionError.sourceEqualsDestination
        }
        guard !manager.fileExists(atPath: destination.path) else { throw PDFEncryptionError.destinationExists }
        guard let document = PDFDocument(url: source) else { throw PDFEncryptionError.invalidSource }
        guard !document.isEncrypted else { throw PDFEncryptionError.sourceAlreadyEncrypted }
        guard document.pageCount > 0, let original = CGPDFDocument(source as CFURL), let catalog = original.catalog else {
            throw PDFEncryptionError.invalidSource
        }
        let pageCount = document.pageCount
        let labels = (0..<pageCount).map { document.page(at: $0)?.label }
        var additions: [String: String] = [:]
        var labelsObject: CGPDFObjectRef?
        if CGPDFDictionaryGetObject(catalog, "PageLabels", &labelsObject), let labelsObject {
            // PDFKit drops PageLabels when rewriting. Numeric/name-only number trees
            // can be restored without inventing encrypted strings or streams.
            guard CGPDFObjectGetType(labelsObject) == .dictionary else { throw PDFEncryptionError.verificationFailed }
            additions["PageLabels"] = try EncryptionSafeValue.serialize(labelsObject)
        }
        for key in ["PageLayout", "PageMode"] {
            var value: UnsafePointer<CChar>?
            if CGPDFDictionaryGetName(catalog, key, &value), let value {
                additions[key] = "/" + EncryptionSafeValue.name(String(cString: value))
            }
        }
        let user = options.openPassword ?? ""
        let owner = try options.editingPassword ?? randomPassword(excluding: [user])
        let wrong = try randomPassword(excluding: [user, owner])
        // Bits 0, 1, 4, 5 permit printing (including high quality), copying and
        // accessibility. All modification, assembly, commenting and form bits are off.
        let readerPermissions = options.editingPassword == nil ? 255 : 51
        let writerOptions: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: user,
            .ownerPasswordOption: owner,
            .accessPermissionsOption: readerPermissions,
            PDFDocumentWriteOption(rawValue: kCGPDFContextEncryptionKeyLength as String): 128
        ]
        guard var data = document.dataRepresentation(options: writerOptions) else { throw PDFEncryptionError.writeFailed }
        try Task.checkCancellation()
        let native = try EncryptedPDFCatalog(data: data)
        try native.verifyAES128()
        if !additions.isEmpty { data = try native.appending(values: additions) }
        let protected = try verifyPasswords(data: data, openPassword: options.openPassword, ownerPassword: options.editingPassword,
                                            wrongPassword: wrong, readerPermissions: UInt(readerPermissions))
        guard protected.pageCount == pageCount,
              (0..<pageCount).map({ protected.page(at: $0)?.label }) == labels,
              let provider = CGDataProvider(data: data as CFData), let encryptedCG = CGPDFDocument(provider),
              encryptedCG.isEncrypted, encryptedCG.unlockWithPassword(user), let finalCatalog = encryptedCG.catalog else {
            throw PDFEncryptionError.verificationFailed
        }
        // Verify the final trailer still advertises the native encryption dictionary.
        try EncryptedPDFCatalog(data: data).verifyAES128()
        for key in ["PageLayout", "PageMode"] where additions[key] != nil {
            var value: UnsafePointer<CChar>?
            guard CGPDFDictionaryGetName(finalCatalog, key, &value), let value,
                  "/" + EncryptionSafeValue.name(String(cString: value)) == additions[key] else {
                throw PDFEncryptionError.verificationFailed
            }
        }
        try Task.checkCancellation()
        let temporary = destination.deletingLastPathComponent().appendingPathComponent(".foliopdf-encrypted-\(UUID().uuidString).partial")
        defer { try? manager.removeItem(at: temporary) }
        do {
            try data.write(to: temporary, options: .withoutOverwriting)
            try Task.checkCancellation()
            // moveItem refuses an existing destination, including a file created during encryption.
            try manager.moveItem(at: temporary, to: destination)
        } catch is CancellationError { throw CancellationError() }
        catch {
            if manager.fileExists(atPath: destination.path) { throw PDFEncryptionError.destinationExists }
            throw PDFEncryptionError.writeFailed
        }
    }

    private static func verifyPasswords(data: Data, openPassword: String?, ownerPassword: String?,
                                        wrongPassword: String, readerPermissions: UInt) throws -> PDFDocument {
        guard let reader = PDFDocument(data: data), reader.isEncrypted else { throw PDFEncryptionError.verificationFailed }
        if let openPassword {
            guard reader.isLocked, reader.permissionsStatus == .none,
                  !reader.unlock(withPassword: ""), reader.isLocked, reader.permissionsStatus == .none,
                  !reader.unlock(withPassword: wrongPassword), reader.isLocked, reader.permissionsStatus == .none,
                  reader.unlock(withPassword: openPassword) else { throw PDFEncryptionError.verificationFailed }
        } else {
            // An empty user password gives anyone reading access while retaining owner protection.
            guard !reader.isLocked, reader.unlock(withPassword: "") else { throw PDFEncryptionError.verificationFailed }
        }
        try verifyPermissions(reader, expected: readerPermissions, status: .user)
        // On an already readable PDF, unlock returns true even for a wrong password.
        // Check authority and permission bits, never interpret this Boolean as owner authentication.
        _ = reader.unlock(withPassword: wrongPassword)
        try verifyPermissions(reader, expected: readerPermissions, status: .user)
        if let ownerPassword {
            guard let owner = PDFDocument(data: data), owner.isEncrypted,
                  owner.unlock(withPassword: ownerPassword), owner.pageCount == reader.pageCount else {
                throw PDFEncryptionError.verificationFailed
            }
            try verifyPermissions(owner, expected: 255, status: .owner)
        }
        // Without editing protection the user already has every permission. The
        // random, undisclosed owner credential is not a product authentication path:
        // macOS may make it unusable with a longer opening password. Opening remains
        // verified exactly, including rejection of empty and incorrect passwords.
        return reader
    }

    private static func verifyPermissions(_ document: PDFDocument, expected: UInt, status: PDFDocumentPermissions) throws {
        let mayEdit = expected == 255
        guard !document.isLocked, document.permissionsStatus == status, document.accessPermissions.rawValue == expected,
              document.allowsPrinting, document.allowsCopying, document.allowsContentAccessibility,
              document.allowsDocumentChanges == mayEdit, document.allowsDocumentAssembly == mayEdit,
              document.allowsCommenting == mayEdit, document.allowsFormFieldEntry == mayEdit else {
            throw PDFEncryptionError.verificationFailed
        }
    }

    private static func randomPassword(excluding: Set<String>) throws -> String {
        for _ in 0..<8 {
            var bytes = [UInt8](repeating: 0, count: 16)
            guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
                throw PDFEncryptionError.randomGenerationFailed
            }
            let value = bytes.map { String(format: "%02x", $0) }.joined()
            if !excluding.contains(value) { return value }
        }
        throw PDFEncryptionError.randomGenerationFailed
    }
}

/// PDF encryption leaves numbers, names, arrays, and dictionaries unencrypted.
/// Strings (including page-label /P prefixes) and streams MUST NOT be inserted here.
private enum EncryptionSafeValue {
    private final class Collector { var entries: [(String, CGPDFObjectRef)] = [] }
    static func name(_ value: String) -> String {
        value.utf8.map { byte in
            if (33...126).contains(byte) && ![35,37,40,41,47,60,62,91,93,123,125].contains(byte) { return String(UnicodeScalar(byte)) }
            return String(format: "#%02X", byte)
        }.joined()
    }
    static func serialize(_ value: CGPDFObjectRef, depth: Int = 0) throws -> String {
        guard depth < 32 else { throw PDFEncryptionError.verificationFailed }
        switch CGPDFObjectGetType(value) {
        case .null: return "null"
        case .boolean:
            var result: CGPDFBoolean = 0
            guard CGPDFObjectGetValue(value, .boolean, &result) else { throw PDFEncryptionError.verificationFailed }
            return result == 0 ? "false" : "true"
        case .integer:
            var result: CGPDFInteger = 0
            guard CGPDFObjectGetValue(value, .integer, &result) else { throw PDFEncryptionError.verificationFailed }; return String(result)
        case .real:
            var result: CGPDFReal = 0
            guard CGPDFObjectGetValue(value, .real, &result), result.isFinite else { throw PDFEncryptionError.verificationFailed }; return String(Double(result))
        case .name:
            var result: UnsafePointer<CChar>?
            guard CGPDFObjectGetValue(value, .name, &result), let result else { throw PDFEncryptionError.verificationFailed }; return "/" + name(String(cString: result))
        case .array:
            var result: CGPDFArrayRef?
            guard CGPDFObjectGetValue(value, .array, &result), let result else { throw PDFEncryptionError.verificationFailed }
            let values = try (0..<CGPDFArrayGetCount(result)).map { index -> String in
                var child: CGPDFObjectRef?
                guard CGPDFArrayGetObject(result, index, &child), let child else { throw PDFEncryptionError.verificationFailed }
                return try serialize(child, depth: depth + 1)
            }
            return "[ " + values.joined(separator: " ") + " ]"
        case .dictionary:
            var result: CGPDFDictionaryRef?
            guard CGPDFObjectGetValue(value, .dictionary, &result), let result else { throw PDFEncryptionError.verificationFailed }
            let collected = Collector()
            CGPDFDictionaryApplyFunction(result, { key, value, context in
                guard let context else { return }
                Unmanaged<Collector>.fromOpaque(context).takeUnretainedValue().entries.append((String(cString: key), value))
            }, Unmanaged.passUnretained(collected).toOpaque())
            let pairs = try collected.entries.map { "/" + name($0.0) + " " + (try serialize($0.1, depth: depth + 1)) }
            return "<< " + pairs.joined(separator: " ") + " >>"
        case .string: throw PDFEncryptionError.unsupportedPageLabels
        default: throw PDFEncryptionError.verificationFailed
        }
    }
}

/// Reads only Apple's newly emitted classic-xref PDF and appends catalog entries.
/// Existing encrypted bytes keep their object number/generation; /Encrypt and /ID
/// are copied unchanged. This code never encrypts or decrypts bytes itself.
private struct EncryptedPDFCatalog {
    let data: Data
    let previous: Int
    let trailer: [String: Range<Int>]
    let rootNumber: Int
    let rootGeneration: Int
    let size: Int
    let catalog: [String: Range<Int>]

    init(data: Data) throws {
        self.data = data
        let tailStart = max(0, data.count - 1_048_576)
        guard let tail = String(data: data[tailStart...], encoding: .isoLatin1),
              let regex = try? NSRegularExpression(pattern: "startxref\\s+(\\d+)\\s+%%EOF\\s*$"),
              let match = regex.firstMatch(in: tail, range: NSRange(location: 0, length: (tail as NSString).length)),
              let offset = Int((tail as NSString).substring(with: match.range(at: 1))), offset >= 0, offset < data.count,
              data[offset...].starts(with: Data("xref".utf8)),
              let trailerMarker = data.range(of: Data("trailer".utf8), options: .backwards, in: offset..<data.count) else {
            throw PDFEncryptionError.verificationFailed
        }
        previous = offset
        trailer = try Self.entries(data: data, at: trailerMarker.upperBound)
        guard let root = trailer["Root"], let reference = Self.reference(data: data, range: root),
              let count = trailer["Size"], let size = Int(Self.text(data, count)), size > reference.0,
              let encrypt = trailer["Encrypt"], Self.reference(data: data, range: encrypt) != nil,
              let id = trailer["ID"], Self.text(data, id).hasPrefix("[") else {
            throw PDFEncryptionError.verificationFailed
        }
        rootNumber = reference.0; rootGeneration = reference.1; self.size = size
        catalog = try Self.objectEntries(data: data, number: reference.0, generation: reference.1)
    }

    func verifyAES128() throws {
        guard let encrypt = trailer["Encrypt"], let ref = Self.reference(data: data, range: encrypt) else { throw PDFEncryptionError.verificationFailed }
        let entries = try Self.objectEntries(data: data, number: ref.0, generation: ref.1)
        func has(_ key: String, _ expected: String) -> Bool { entries[key].map { Self.text(data, $0) == expected } == true }
        guard has("Filter", "/Standard"), has("V", "4"), has("R", "4"), has("Length", "128"),
              has("EncryptMetadata", "true"), let cf = entries["CF"] else { throw PDFEncryptionError.verificationFailed }
        let filters = try Self.entries(data: data, at: cf.lowerBound)
        for key in ["StmF", "StrF"] {
            guard let selected = entries[key], Self.text(data, selected).hasPrefix("/"),
                  let filter = filters[String(Self.text(data, selected).dropFirst())] else { throw PDFEncryptionError.verificationFailed }
            let values = try Self.entries(data: data, at: filter.lowerBound)
            guard let method = values["CFM"], Self.text(data, method) == "/AESV2" else { throw PDFEncryptionError.verificationFailed }
        }
    }

    func appending(values: [String: String]) throws -> Data {
        guard Set(values.keys).isSubset(of: ["PageLabels", "PageLayout", "PageMode"]) else { throw PDFEncryptionError.verificationFailed }
        var dictionary = Data("<<\n".utf8)
        for key in catalog.keys.sorted() where values[key] == nil {
            dictionary.append(Data("/\(key) ".utf8)); dictionary.append(data.subdata(in: catalog[key]!)); dictionary.append(10)
        }
        for key in values.keys.sorted() { dictionary.append(Data("/\(key) \(values[key]!)\n".utf8)) }
        dictionary.append(Data(">>".utf8))
        var result = data; result.append(10); let offset = result.count
        result.append(Data("\(rootNumber) \(rootGeneration) obj\n".utf8)); result.append(dictionary); result.append(Data("\nendobj\n".utf8))
        let xref = result.count
        var trailerEntries = "/Size \(size) /Root \(rootNumber) \(rootGeneration) R /Prev \(previous)"
        for key in ["Info", "Encrypt", "ID"] {
            if let range = trailer[key] { trailerEntries += " /\(key) " + Self.text(data, range) }
        }
        result.append(Data("xref\n\(rootNumber) 1\n\(String(format: "%010ld %05ld n \n", offset, rootGeneration))trailer\n<< \(trailerEntries) >>\nstartxref\n\(xref)\n%%EOF\n".utf8))
        return result
    }

    private static func text(_ data: Data, _ range: Range<Int>) -> String { String(data: data.subdata(in: range), encoding: .isoLatin1) ?? "" }
    private static func reference(data: Data, range: Range<Int>) -> (Int, Int)? {
        let parts = text(data, range).split(whereSeparator: { $0.isWhitespace })
        guard parts.count == 3, parts[2] == "R", let number = Int(parts[0]), number > 0,
              let generation = Int(parts[1]), (0...65535).contains(generation) else { return nil }
        return (number, generation)
    }
    private static func objectEntries(data: Data, number: Int, generation: Int) throws -> [String: Range<Int>] {
        let header = Data("\n\(number) \(generation) obj".utf8)
        let alternate = Data("\r\(number) \(generation) obj".utf8)
        guard let range = data.range(of: header, options: .backwards) ?? data.range(of: alternate, options: .backwards) else {
            throw PDFEncryptionError.verificationFailed
        }
        return try entries(data: data, at: range.upperBound)
    }
    private static func entries(data: Data, at offset: Int) throws -> [String: Range<Int>] {
        var reader = EncryptionPDFValueReader(bytes: data, position: offset)
        reader.skipSpace()
        guard reader.position + 1 < data.count, data[reader.position] == 60, data[reader.position + 1] == 60 else { throw PDFEncryptionError.verificationFailed }
        reader.position += 2
        var result: [String: Range<Int>] = [:]
        while true {
            reader.skipSpace()
            guard reader.position + 1 < data.count else { throw PDFEncryptionError.verificationFailed }
            if data[reader.position] == 62, data[reader.position + 1] == 62 { return result }
            let start = reader.position
            guard data[start] == 47 else { throw PDFEncryptionError.verificationFailed }
            let end = try reader.valueEnd()
            let key = String(data: data[(start + 1)..<end], encoding: .ascii) ?? ""
            guard !key.isEmpty, result[key] == nil else { throw PDFEncryptionError.verificationFailed }
            reader.skipSpace(); let valueStart = reader.position; let valueEnd = try reader.valueEnd()
            result[key] = valueStart..<valueEnd
        }
    }
}

private struct EncryptionPDFValueReader {
    let bytes: Data
    var position: Int
    mutating func skipSpace() {
        while position < bytes.count {
            if [0,9,10,12,13,32].contains(bytes[position]) { position += 1 }
            else if bytes[position] == 37 { while position < bytes.count && bytes[position] != 10 && bytes[position] != 13 { position += 1 } }
            else { break }
        }
    }
    private func isDelimiter(_ byte: UInt8) -> Bool { [0,9,10,12,13,32,40,41,60,62,91,93,123,125,47,37].contains(byte) }
    mutating func valueEnd(depth: Int = 0) throws -> Int {
        skipSpace(); guard depth < 32, position < bytes.count else { throw PDFEncryptionError.verificationFailed }
        let first = bytes[position]; position += 1
        if first == 40 {
            var nesting = 1
            while position < bytes.count && nesting > 0 {
                let char = bytes[position]; position += 1
                if char == 92 { if position < bytes.count { position += 1 } }
                else if char == 40 { nesting += 1 } else if char == 41 { nesting -= 1 }
            }
            guard nesting == 0 else { throw PDFEncryptionError.verificationFailed }
        } else if first == 60 && position < bytes.count && bytes[position] == 60 {
            position += 1
            while true {
                skipSpace(); guard position + 1 < bytes.count else { throw PDFEncryptionError.verificationFailed }
                if bytes[position] == 62 && bytes[position + 1] == 62 { position += 2; break }
                _ = try valueEnd(depth: depth + 1)
            }
        } else if first == 60 {
            while position < bytes.count && bytes[position] != 62 { position += 1 }
            guard position < bytes.count else { throw PDFEncryptionError.verificationFailed }; position += 1
        } else if first == 91 {
            while true {
                skipSpace(); guard position < bytes.count else { throw PDFEncryptionError.verificationFailed }
                if bytes[position] == 93 { position += 1; break }
                _ = try valueEnd(depth: depth + 1)
            }
        } else {
            while position < bytes.count && !isDelimiter(bytes[position]) { position += 1 }
            if first >= 48 && first <= 57 {
                let saved = position; skipSpace(); let secondStart = position
                while position < bytes.count && (48...57).contains(bytes[position]) { position += 1 }
                if position > secondStart {
                    skipSpace()
                    if position < bytes.count && bytes[position] == 82 { position += 1 } else { position = saved }
                } else { position = saved }
            }
        }
        return position
    }
}
