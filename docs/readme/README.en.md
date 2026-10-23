# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · **English** · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- languages:end -->

A native macOS application for turning images into books and editing PDF bookmarks. FolioPDF uses an independently designed SwiftUI interface and Apple system frameworks, with no third-party runtime, no network uploads, and no API Key configuration.

## Getting started

Download `FolioPDF-1.4-macOS.zip` from [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest), extract it, and open `FolioPDF.app`. You can also drag it into the Applications folder. Requires **macOS 14 or later**. A locally built application is available at `dist/FolioPDF.app`.

The 1.4 release packages are `FolioPDF-1.4-macOS.zip` and `FolioPDF-1.4-source.zip`; the application inside the ZIP is always named `FolioPDF.app`. The [validation report](../validation/VALIDATION.en.md) lists the verification status, runtime environment, and actual interface screenshots. The source repository does not contain build caches or application binaries; installation packages are provided in Releases.

1. In “Create PDF,” add images, drag in files, or add one or more folders. Choose the folder recursion options in the settings on the right before importing.
2. Click to select an image, or Command-click to select several. Drag an image onto another to reorder it, or use the move-forward/move-backward buttons at the bottom. Double-click an image to preview it. Thumbnail and list views are available.
3. On the right, choose a combined PDF, one PDF per source file, or one PDF per folder. Adjust paper size, margins, DPI, compression, OCR, and document information.
4. To use password protection, scroll down the settings panel on the right and expand “PDF encryption” after “Document details.” This section is collapsed by default and displays its settings directly when expanded. “Opening password” and “Editing password” have independent switches. Enable the required switches and enter each password and its confirmation; permissions are described in the table below. Every PDF in a batch uses the settings for that export.
5. Click “Create PDF.” Existing output files are never overwritten; a numbered filename is generated when a name is already in use. Each page/frame of a multipage TIFF/GIF becomes a PDF page in sequence. “One PDF per image file” does not split a single source file into several PDFs.
6. In the “Bookmarks” workspace, open an unencrypted PDF to add, edit, move, and indent outline entries, preview their destinations, import or export TXT, JSON, or compatible interface files, and save a separate copy.

The entire header row of collapsible sections such as “Document details,” “PDF encryption,” and “Margins & resolution” is clickable, including the blank space beside the title. Workspace navigation on the left also supports clicking the entire row. “PDF encryption” is collapsed by default and scrolls with the settings panel when expanded.

⌘N shows the main window, ⌘O adds images, ⌘⇧O adds folders, ⌘E exports, and ⌘, opens Settings. Closing and reopening the main window preserves the current session. Quitting the application does not automatically save bookmark drafts; save a separate copy first.

### Opening and editing passwords

| Enabled protection | Password length | Reading and operation permissions |
|---|---|---|
| Opening password only | Opening password: 1–32 characters | A password is required to open the PDF; the correct password grants all operation permissions |
| Editing password only | Editing password: 1–32 characters | Reading requires no password. Content changes, annotations, form filling, and page insertion/deletion/rotation are restricted for ordinary readers. The editing password grants all permissions |
| Both passwords | Opening password: 1–16 characters; editing password: 1–32 characters | The opening password grants restricted reading permissions. The editing password grants all permissions and can also open the PDF directly |

When both passwords are enabled, they must differ. Printing, copying, and accessibility access are always allowed. Editing restrictions rely on the PDF reader honoring permission settings and do not guarantee that the content can never be modified.

Passwords accept printable ASCII characters only: English letters, digits, symbols, and spaces, subject to the lengths in the table. When both passwords are enabled, the interface explains the 16-character opening-password limit. Out-of-range passwords are rejected before export; passwords are neither truncated nor automatically stripped of leading or trailing spaces.

Passwords remain only in the current application session and are not written to settings, history, or logs. Turning off a password switch clears that password and its confirmation; resetting settings clears both pairs. Invalid passwords or confirmation values block export. With both switches off, the application exports an ordinary PDF.

The interface language in Settings follows the system by default. You can manually switch among these **16 languages** at any time without restarting:

**简体中文** · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · Polski

Arabic uses a right-to-left interface layout. Images and PDF content remain unchanged, and the TAB-separated bookmark text editor retains its left-to-right structure. Appearance can follow the system or use light or dark mode. macOS controls such as system file pickers use the system-configured language. Interface language and OCR recognition language are configured separately; available OCR languages depend on Vision support on the local machine.

## Implemented features

| Capability | Implementation |
|---|---|
| Image input | JPEG, PNG, TIFF, GIF, BMP, HEIC/HEIF, JPEG 2000, JPEG XL (`.jxl`), and other formats decodable by ImageIO. JPEG XL uses native ImageIO decoding on macOS 14 or later. Additional supported extensions are discovered dynamically on the current system. RAW support depends on the local system decoder; not all camera models are guaranteed |
| File organization | Deduplication, filename/trailing-number sorting, manual order, common ebook-prefix sorting, folder recursion, and optional inclusion of the top-level directory |
| Batch output | One combined PDF, one PDF per source file, or one PDF per immediate parent directory. Deeper directories form separate groups; descendant images are not counted again in their parent directory |
| Pages | Original image size, fixed width, A3/A4/A5/B5/Letter/Legal, custom dimensions in millimeters, landscape orientation, four margins, enlargement of small images, and priority for image DPI metadata |
| Compression | Lossless processing and JPEG quality control. Upright source JPEGs can retain their original DCT-encoded stream. Other formats/orientations are correctly decoded and laid out through ImageIO; byte-for-byte stream preservation is not promised for every source format |
| Transparency | Preserve transparency or use a white background. JPEG cannot store alpha; preserving transparency automatically selects lossless encoding and reports the reason |
| OCR | Accurate local recognition with Apple Vision, automatic or manually selected locally supported languages, and hidden text that can be searched and copied. CPU processing is attempted if the GPU path fails. Pages with recognition failures retain their images and are explicitly reported |
| Document properties | Title, author, subject, keywords, and single-page/continuous/two-page reading layouts |
| PDF encryption | Native PDFKit AES-128 with independent opening-password, editing-password, and dual-password modes. Opening-password-only mode generates a random owner password; an editing password grants full owner permissions. Files are published only after mode-specific checks of lock state, passwords, reader/owner permissions, and page count. Failures never produce an unencrypted substitute. In-app preview accepts passwords |
| Bookmarks | Automatic source-file bookmarks, multilevel outlines, page numbers, base-page conversion, editable text and JSON, and native PDF destination previews |
| Bookmark interface files | Generic ITF (`.itf`) and `TXT` bookmark interface files, UTF-8/UTF-16LE and relevant legacy encodings, segmented page numbering for contents/body text, metadata, appended searchable text pages, and bookmark display settings |
| Reliability | Background tasks, per-page image release, progress, cancellation, logs, temporary files and atomic publication, automatic numbering for name conflicts, and preservation and listing of completed outputs when a batch fails partway through |

JPEG XL supports importing static lossy, lossless, transparent, and 16-bit grayscale images, generating thumbnails, previewing them, and converting them to PDF. For animated JXL, only the first frame decodable by the system is guaranteed; full frame-by-frame import is not guaranteed. ImageIO in the current validation environment returns only the first frame. The application does not encode JXL output and does not promise to preserve the original JXL bitstream, HDR, or high-bit-depth information unchanged in the PDF.

### Current limitations

- OCR uses local Apple Vision and does not require Office or Windows. Chart cleanup, dedicated CJK-font controls, and word-by-word/line-by-line switches are not available.
- Compression currently offers lossless and JPEG options. JBIG2, CCITT G4, and JPEG 2000 encoding is not available. The core workflow is available, but large black-and-white books may produce larger files than dedicated JBIG2 tools.
- Proofreading tools for showing/hiding OCR text and physically deleting scanned images are not included. Neither image restoration nor a full PDF content editor is provided.
- `[Images]` multilayer assembly and `MinWidth` in compatible interface files are not implemented. They are reported when detected, without claiming that they were applied. If manual file order differs from absolute page numbers in an interface file, users must verify bookmark destinations.
- Ordinary local page numbers, some standard named actions, and URL destinations are supported. External PDF destinations that PDFKit cannot reliably save, and unresolved named/special destinations, are clearly flagged and prevent silent saving. They can be changed to valid local page numbers in the editor. JSON/TXT can preserve destination data. Bookmark editing is unavailable for encrypted PDFs.
- Encryption preserves bookmarks, OCR text, metadata, reading layouts, and ordinary segmented page numbers. Native PDFKit does not retain page labels, so the application safely restores only labels without text prefixes. Interface files with custom text prefixes explicitly block encrypted export; remove the prefixes or turn off encryption.
- “Ebook order” uses common prefix groups: cov, bok, leg, fow, !, toc, numbered body text, att, ins, bac, followed by everything else.
- If a batch is cancelled or fails, completed PDFs remain available and the current unfinished temporary PDF is removed. Resuming from a checkpoint is not supported.

## Development and building

The source is a Swift Package; open `Package.swift` in Xcode. Xcode with the macOS SDK and Swift 5.9 or later is required. The verification environment was macOS 15.7.9 / Xcode Swift 6.2.4, with macOS 14 as the deployment target.

```sh
# Run a debug build
swift run FolioPDF

# Run tests and check all 16 interface languages
bash scripts/test.sh

# Build a universal Intel + Apple Silicon .app and ZIP
bash scripts/build-app.sh

# Build only for the current machine's architecture
bash scripts/build-app.sh --host-only
```

The real OCR tests in `scripts/test.sh` require normal access to macOS services such as Vision and CoreVideo. Execution sandboxes that restrict hardware/system services may cause CVPixelBuffer creation errors. Tests should run and pass in a normal system environment; skipping them is not a substitute for verification.

Packaging uses a local ad-hoc signature and does not include Developer ID notarization. The application can run locally; formal distribution to other Macs requires a developer certificate and notarization.

### Source layout

```text
Sources/FolioCore/       Images, geometry, conversion, OCR, bookmarks, interface files
Sources/FolioPDF/        SwiftUI workspaces, state management, native previews, localization
Tests/FolioCoreTests/    Real image/PDF/OCR/bookmark round-trip and boundary tests
scripts/                Tests, packaging, icon and sample-image generation
packaging/Info.plist     macOS application information
docs/                   Validation reports and actual window renders
dist/                   Runnable .app and distribution ZIPs (generated by builds)
```

## Documentation languages

The README and validation report are available in the same 16 languages as the interface. Use the language links at the top of each document to switch. Features, password limits, known limitations, and build steps are consistent across language versions. Test, build, and window-capture logs are machine-generated original evidence and retain their tools' original output; the validation reports provide multilingual explanations.

## Technical references

The implementation uses Apple's [Vision language-detection API](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), [PDFKit document attributes](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes), and [ImageIO JPEG quality parameter](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality), with local SDK declarations and actual file tests used to verify behavior. FolioPDF combines an independently designed interface with native system frameworks.
