# FolioPDF 1.3 Validation Report

<!-- languages:start -->
[简体中文](../VALIDATION.md) · **English** · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · [Français](VALIDATION.fr.md) · [Deutsch](VALIDATION.de.md) · [Español](VALIDATION.es.md) · [Italiano](VALIDATION.it.md) · [Português (Brasil)](VALIDATION.pt-BR.md) · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · [Türkçe](VALIDATION.tr.md) · [Nederlands](VALIDATION.nl.md) · [Polski](VALIDATION.pl.md)
<!-- languages:end -->

Status: **tests and builds passed**. Recorded on: 2026-10-23. Verification environment: Intel Mac, macOS 15.7.9, Swift 6.2.4 / Xcode. Minimum deployment version: macOS 14.

This update adds independent opening and editing passwords and moves encryption settings into a section inside the right-hand panel that is collapsed by default and clickable across its entire header row. All 50 XCTest cases passed in the complete run, with 0 failures and 0 skipped tests. The local native PDF writer was confirmed to potentially produce unusable owner passwords when the opening password is 17–31 characters long. The application avoids this with length validation in dual-password mode; the safety boundaries are described below. See `test-results.txt` for this run's log.

## Deliverables

- `dist/FolioPDF.app`: a native AppKit window, SwiftUI interface, and system PDFKit / Vision / ImageIO frameworks. The application filename has no version number; the version is recorded in its metadata.
- `dist/FolioPDF-1.3-macOS.zip`: a universal application package containing x86_64 and arm64, verified with `lipo -archs`.
- `dist/FolioPDF-1.3-source.zip`: Swift Package source that opens in Xcode, including tests, scripts, usage documentation, and interface screenshots.
- The packaging script uses a local ad-hoc signature and passed `codesign --verify --deep --strict`; Developer ID notarization is not included. The internal version is 1.3 (build 4), and the application filename remains `FolioPDF.app`.

## Functional tests

`bash scripts/test.sh` was run, and all 50 XCTest cases passed. Detailed output is saved in `test-results.txt`. The real Vision OCR tests also ran, with none skipped.

| Area | Count | Verified behavior |
|---|---:|---|
| Asset discovery and sorting | 3 | Numeric sorting, ebook prefixes, subdirectories and top-level exclusion, duplicate paths |
| PDF conversion | 10 | Page geometry and invalid parameters, EXIF orientation, multipage TIFF/GIF, metadata and bookmarks, grouping by directory, no file overwriting, partial batch failure, actual JPEG encoding, original JPEG stream preservation, Vision hidden text and searchability, cancellation cleanup |
| Bookmarks and interface files | 8 | Multilevel bookmarks, BasePage conversion, invalid destinations, standard actions and JSON, explicit rejection of external destinations, UTF-16 interfaces and segmented page numbering, saving separate copies, searchable text pages, preservation of existing page labels |
| Localization | 3 | The 16 languages and their order, complete resource loading, 18 regional-language mappings, fallback for unknown languages, manual-selection priority, RTL only for Arabic |
| Native PDF encryption | 14 | Actual AESV2/128-bit dictionary, opening-only/editing-only/dual passwords, separate reader and owner permissions, no privilege escalation with incorrect passwords, distinct-password requirement, random owner password, single- and dual-password length boundaries, rejection of excessive opening-password length before writing, leading/trailing spaces, Chinese metadata, bookmarks, hidden text, ordinary segmented page labels and layouts, explicit rejection of text prefixes, no overwriting, and failure cleanup |
| Encrypted conversion integration | 7 | Combined, per-file, and per-directory encryption, automatic numbering, unchanged source files, no output for invalid passwords, preservation of dual-password permissions and metadata, real Vision OCR searchability and visual preservation, deterministic cancellation during conversion and directory cleanup |
| Encryption interface state | 5 | Both password/confirmation pairs, independent clearing by switches, session isolation and reset, complete exports in all three modes and page counts in history, no passwords in settings/history/logs |

OCR tests use actual generated text images, verify that text can be extracted from the output PDF, and confirm that the hidden text does not alter page rendering. Tests must run in an environment with access to macOS system services; CoreVideo errors in a restricted execution sandbox are not counted as a pass.

### Dual-password acceptance criteria

| Mode | Ordinary reader | Editing-password holder |
|---|---|---|
| Opening password only | Empty and incorrect passwords cannot open the file; the correct opening password grants all operation permissions | No independent editing password is set |
| Editing password only | Reading requires no password; content changes, annotations, form filling, and page organization are prohibited | The editing password grants full owner permissions |
| Both passwords | The opening password grants restricted user permissions | The editing password opens the file directly and grants full owner permissions |

When both passwords are enabled, they must differ. All three modes allow printing, copying, and accessibility access. Restricted modes disable content changes, annotations, form filling, and page insertion/deletion/rotation. Readers must honor these restrictions; they are not a guarantee that the file is “impossible to modify.”

Only printable ASCII characters are accepted. The safely supported lengths are: opening-password-only, 1–32 characters; editing-password-only, 1–32 characters; dual-password mode, 1–16 characters for the opening password and 1–32 for the editing password. The conditional limit for dual-password mode is clearly shown in the interface and enforced during export validation. Out-of-range input is rejected without truncation, changes to leading/trailing spaces, or a downgraded output.

Calling `unlock(withPassword:)` on an already open PDF can return `true` even when the owner password is wrong. Acceptance checks therefore inspect `permissionsStatus` and every permission bit: a restricted reader is user/51, an owner is owner/255, and an opening-password-only reader is user/255. Editing-password-only files open automatically, so reading their page count for history does not require owner authentication.

## Interface and languages

- The current resources contain 292 strings × 16 languages, with 281 actual interface strings. `check-localization.py` passed; packaged language resources are byte-for-byte identical to the source files.
- The default follows the system. The order matches the user's specification: 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- Both the Arabic main window and Settings window use RTL layouts. Filenames, images, and PDF content remain unchanged. The TAB-separated bookmark text editor retains its LTR structure so that interface-file editing semantics do not change.
- The application was restarted and actual NSViews were rendered to inspect Chinese light mode with encryption collapsed and both passwords expanded, long German text in dark mode, Arabic RTL, and editing-password-only mode. Fields and descriptions wrap normally, with no observed overlaps or missing characters. Content beyond the viewport scrolls with the right-hand panel. Screenshots are listed below.
- Collapsible headers such as “Document details,” “PDF encryption,” and “Margins & resolution” use full-row Buttons, with labels filling the width and a rectangular hit area. Left-hand workspace navigation and the Settings entry at the bottom also have enlarged hit areas. Source review covered blank areas and RTL semantic direction; no separate automated mouse test was performed. The final release app was verified to launch and reopen its main window after closing it, with `reopen verified: true` recorded in the log.
- Closing the window and quitting are disabled during conversion. Unsaved bookmarks prompt before closing/quitting. Reopening a closed window retains the current session's draft.
- The Settings button and ⌘, open the same native Settings window. ⌘N shows the main window, ⌘O adds images, ⌘⇧O adds folders, and ⌘E exports.
- “PDF encryption” is a separate section after “Document details” in the right-hand settings panel. It is collapsed by default and scrolls with the panel. Expanding it directly displays both password groups, without a popover. Opening and editing passwords each have an independent switch, masked password field, and confirmation field.
- Turning off one switch clears only that password and its confirmation; resetting settings clears both pairs. Invalid passwords, mismatched confirmations, or identical passwords in dual-password mode block export. Turning off both groups exports an ordinary PDF. Collapsing or expanding the section does not change protection settings.
- Both passwords are stored only in the current process and never written to persistent settings, history, or logs. Plaintext temporary files during encrypted export are kept in a directory with 0700 permissions and cleaned up on normal cancellation and error paths. Only encrypted files that pass the selected mode's checks are published; failure cannot fall back to an unencrypted file.
- OCR language availability still depends on local Vision support; the number of interface languages does not imply the number of OCR languages.

## Verification boundaries

- Verification took place on an Intel Mac. Both architectures of the 1.3 universal package compiled successfully, but the application has not yet been tested on physical Apple Silicon hardware.
- The minimum deployment target is macOS 14; this verification ran on macOS 15.7.9.
- No large-scale scanned-book performance benchmark was conducted. Compatibility with every camera RAW format or every nonstandard PDF destination is not promised.
- Encryption uses Apple PDFKit, requires AESV2/128-bit output, and checks passwords and permissions for the selected mode. The local native writer's issue with opening passwords of 17–31 characters affects owner authentication, so dual-password mode consistently limits opening passwords to 1–16 characters. Editing passwords and both single-password modes support 1–32 characters. The application does not repair cryptographic results itself. It rejects Unicode, control characters, and input beyond the selected mode's length limits. Actual-file tests cover boundary validation, owner permissions, and preservation of leading/trailing spaces; opening-password lengths of 17, 31, and 32 are rejected before writing in dual-password mode.
- Page labels with custom text prefixes cannot be reliably preserved through the current native path and explicitly cause an error when encryption is enabled. Ordinary alphabetic/Roman/numeric segmented labels, reading layouts, and metadata have round-trip tests. Files requiring an opening password can be unlocked in the in-app preview; editing-password-only files can be previewed directly. Encrypted files still do not support bookmark editing.
- Differences from the original software, including JBIG2/G4 encoding, original OCR proofreading, multilayer interface files, and some special bookmark destinations, are detailed in “Explicit differences from the original application” in the project README.

## Interface captures for this release

| State | Actual window screenshot |
|---|---|
| Chinese, encryption collapsed by default | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Chinese, both passwords expanded | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| German, dark mode, both passwords expanded | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Arabic, RTL, both passwords expanded | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| Final universal app, Chinese, editing-password-only and window reopening | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

Screenshots were captured by rendering the application's own `NSView` and contain no other application content. `build-results.txt` records the production builds for both architectures; `SHA256SUMS-1.3.txt` in [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.3.0) records checksums for the distribution ZIPs. Old-layout screenshots were moved to `screenshots/previous-layout/` and are not evidence for this version's interface acceptance.

Raw test, build, and screenshot logs are generated by tools. Their original output is retained, with local project paths replaced by `<project>`; translated logs are not presented as original evidence. All 16 language versions of this report explain the same results, environment, and boundaries. The source version contains neither build caches nor release binaries; download release packages from the private repository's Releases.
