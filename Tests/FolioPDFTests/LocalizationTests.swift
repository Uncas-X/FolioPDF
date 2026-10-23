import XCTest
import SwiftUI
@testable import FolioPDF

final class LocalizationTests: XCTestCase {
    func testRequestedLanguageOrderAndEveryTranslationExists() {
        let requested = ["zh-Hans", "en", "zh-Hant", "ja", "ko", "fr", "de", "es", "it", "pt-BR", "ru", "ar", "hi", "tr", "nl", "pl"]
        XCTAssertEqual(LocalizationCatalog.languages.map(\.id), requested)
        let translations = LocalizationCatalog.translations
        XCTAssertEqual(Set(translations.keys), Set(requested))
        let englishKeys = Set(translations["en", default: [:]].keys)
        XCTAssertGreaterThan(englishKeys.count, 250)
        for language in requested {
            XCTAssertEqual(Set(translations[language, default: [:]].keys), englishKeys, language)
            XCTAssertTrue(translations[language, default: [:]].values.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, language)
        }
    }

    func testSystemRegionalLanguageResolution() {
        let cases = ["zh-CN": "zh-Hans", "zh-HK": "zh-Hant", "zh-Hans-TW": "zh-Hans", "en-GB": "en", "ja-JP": "ja", "ko-KR": "ko", "fr-CA": "fr", "de-AT": "de", "es-MX": "es", "it-IT": "it", "pt-PT": "pt-BR", "ru-RU": "ru", "ar-SA": "ar", "ar_EG": "ar", "hi-IN": "hi", "tr-TR": "tr", "nl-BE": "nl", "pl-PL": "pl"]
        for (preference, expected) in cases {
            XCTAssertEqual(LocalizationCatalog.resolve("system", preferredLanguages: [preference]), expected, preference)
        }
        XCTAssertEqual(LocalizationCatalog.resolve("system", preferredLanguages: ["sv-SE", "nl-NL", "en"]), "nl")
        XCTAssertEqual(LocalizationCatalog.resolve("system", preferredLanguages: ["sv-SE"]), "en")
        XCTAssertEqual(LocalizationCatalog.resolve("system", preferredLanguages: []), "en")
    }

    func testManualChoiceOverridesSystemAndOnlyArabicMirrorsLayout() {
        for language in LocalizationCatalog.languages {
            XCTAssertEqual(LocalizationCatalog.resolve(language.id, preferredLanguages: ["zh-CN"]), language.id)
            XCTAssertEqual(LocalizationCatalog.layoutDirection(for: language.id), language.id == "ar" ? .rightToLeft : .leftToRight)
        }
        XCTAssertEqual(LocalizationCatalog.resolve("obsolete", preferredLanguages: ["pl-PL"]), "pl")
    }
}
