# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · **繁體中文** · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- languages:end -->

一款原生 macOS 圖片製書與 PDF 書籤編輯應用程式。FolioPDF 採用獨立設計的 SwiftUI 介面和 Apple 系統框架，無第三方執行環境、無網路上傳、不需設定 API Key。

## 使用

從 [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest) 下載 `FolioPDF-1.4-macOS.zip`，解壓後開啟 `FolioPDF.app`，也可將它拖到“應用程式”資料夾。系統要求 **macOS 14 或以上**。本機建置的應用程式位於 `dist/FolioPDF.app`。

1.4 版封裝產物為 `FolioPDF-1.4-macOS.zip` 與 `FolioPDF-1.4-source.zip`，ZIP 內的應用程式始終命名為 `FolioPDF.app`。[驗證記錄](../validation/VALIDATION.zh-Hant.md)列出了驗證狀態、執行環境和實際介面截圖。原始碼儲存庫不包含建置快取或應用程式二進位檔，安裝包在 Releases 中提供。

1. 在“製作 PDF”中加入圖片、拖入檔案，或加入一個/多個資料夾。資料夾遞迴選項位於右側設定中，須在匯入前選擇。
2. 按一下選擇圖片，Command 按一下多選；拖曳到另一張圖片上重新排序，或使用底部前移/後移按鈕。按兩下圖片預覽。可切換縮圖與清單。
3. 右側選擇合併、逐來源檔案、逐資料夾輸出，調整紙張/邊界/DPI、壓縮、OCR 與文件資訊。
4. 如需密碼保護，向下滾動右側設定面板，展開“文件資訊”後的“PDF加密”區域。該區域預設折疊，展開後直接顯示設定。“開啟密碼”和“編輯密碼”各有獨立開關；啟用後輸入相應密碼及確認密碼，具體權限見下表。批次輸出的每個 PDF 都使用本次設定。
5. 點選“製作 PDF”。已有輸出檔案不會被覆蓋，發生重名時自動建立帶編號的新檔案。多頁 TIFF/GIF 的每頁/影格依次成為 PDF 頁；“每個圖片檔案一個 PDF”不會把同一來源檔案拆成多個 PDF。
6. “書籤”工作區可開啟未加密 PDF，增加/編輯/移動/縮排目錄項，預覽跳轉，匯入匯出 TXT、JSON 或相容介接檔案，最後另存副本。

“文件資訊”“PDF加密”“邊界與解析度”等折疊區域的整行標題都可點選，包含標題旁的空白處；左側工作區導覽也支援整行點選。“PDF加密”預設折疊，展開後隨右側設定面板一起滾動。

⌘N 顯示主視窗，⌘O 加入圖片，⌘⇧O 加入資料夾，⌘E 匯出，⌘, 開啟設定。關閉後重開主視窗保留目前工作階段；結束應用程式不會自動儲存書籤草稿，請先另存副本。

### 開啟密碼與編輯密碼

| 啟用方式 | 密碼長度 | 閱讀與操作權限 |
|---|---|---|
| 只啟用開啟密碼 | 開啟密碼 1–32 字元 | 開啟 PDF 時需要密碼；使用正確密碼開啟後，全部操作權限開放 |
| 只啟用編輯密碼 | 編輯密碼 1–32 字元 | 不需密碼即可閱讀；一般閱讀者的內容修改、註解、表單填寫和頁面插入/刪除/旋轉受到限制。輸入編輯密碼可取得全部權限 |
| 同時啟用兩種密碼 | 開啟密碼 1–16 字元，編輯密碼 1–32 字元 | 開啟密碼提供受限的閱讀權限；編輯密碼提供全部權限，也可直接用於開啟 PDF |

兩種密碼同時啟用時必須不同。列印、複製和輔助使用始終允許；編輯限制需要 PDF 閱讀器遵守權限設定，不代表內容絕對無法被修改。

密碼只接受可列印 ASCII 字元（英文、數字、符號和空格），長度按上表限制。介面會在同時啟用兩種密碼時提示開啟密碼的 16 字元上限；超出限制會在匯出前拒絕，不截斷密碼，也不自動去除首尾空格。

密碼僅在目前應用程式工作階段中保留，不寫入設定、歷史紀錄或記錄；關閉某個密碼開關會清空該密碼及其確認值，重設設定會清空兩組。密碼或確認值無效時會阻止匯出；關閉兩種開關後匯出一般 PDF。

設定中的介面語言預設跟隨系統，可隨時手動切換以下 **16 種語言**，不需重啟：

**简体中文** · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · Polski

阿拉伯語使用從右向左的介面版面配置；圖片和 PDF 內容保持原樣，書籤的 TAB 文字編輯器保留從左向右的結構。外觀支援系統、淺色和深色。系統檔案選擇器等 macOS 控制項使用系統設定的語言。介面語言與 OCR 識別語言分別設定，OCR 可選項由本機 Vision 支援範圍決定。

## 實作範圍

| 能力 | 實作說明 |
|---|---|
| 影像輸入 | JPEG、PNG、TIFF、GIF、BMP、HEIC/HEIF、JPEG 2000、JPEG XL（`.jxl`）等 ImageIO 可解碼格式；JPEG XL 使用 macOS 14 或以上版本的原生 ImageIO 解碼。動態發現目前系統其他支援的副檔名。RAW 支援由本機系統解碼器決定，不保證所有相機型號 |
| 檔案組織 | 去重、檔名/末尾數字排序、手動順序、常見電子書前綴排序、資料夾遞迴、是否包括最上層目錄 |
| 批次輸出 | 合併一個 PDF、每來源檔案一個 PDF、每直接上層目錄一個 PDF；深層目錄分別分組，不把子目錄中的圖片重複計入上層目錄 |
| 頁面 | 原始圖片大小、固定寬度、A3/A4/A5/B5/Letter/Legal、自訂毫米尺寸、橫向、四邊留白、小圖放大、DPI 中繼資料優先 |
| 壓縮 | 無損路徑和 JPEG 品質控制。原始方向為正向的 JPEG 可保留原 DCT 編碼串流；其他格式/方向透過 ImageIO 正確解碼和排版，不承諾每個來源格式的編碼串流逐位元組保留 |
| 透明 | 保留透明或鋪白底；JPEG 不能存 Alpha，保留透明時自動使用無損編碼並報告說明 |
| OCR | Apple Vision 本機準確識別，自動或手動選擇本機支援的語言，產生可搜尋/複製的隱藏文字；GPU 路徑失敗時嘗試 CPU。識別失敗的頁保留影像並明確報告 |
| 文件屬性 | 標題、作者、主題、關鍵詞；單頁/連續/雙頁閱讀版面配置 |
| PDF加密 | 原生 PDFKit AES-128，支援獨立開啟密碼、編輯密碼及雙密碼。只設定開啟密碼時產生隨機 owner 密碼；設定編輯密碼時以該密碼授予 owner 全權限。按所選模式核驗鎖定狀態、密碼、reader/owner 權限和頁數後才發佈；失敗不輸出未加密替代檔案。應用程式內預覽支援輸入密碼 |
| 書籤 | 自動來源檔案書籤、多級目錄、頁碼、基準頁換算、可編輯文字及 JSON、原生 PDF 跳轉預覽 |
| 書籤介接檔案 | 通用 ITF（`.itf`）與 `TXT` 書籤介接檔案，UTF-8/UTF-16LE 及相關舊式編碼；目錄/正文分段頁碼、中繼資料、追加可搜尋文字頁、書籤顯示設定 |
| 穩定性 | 背景工作、逐頁釋放影像、工作進度、取消、記錄、暫存檔案和原子發佈、重名自動編號、批次中途失敗保留並列出已完成結果 |

JPEG XL 支援靜態有損、無損、透明及 16 位元灰階影像的匯入、縮圖、預覽與 PDF 轉換。動畫 JXL 僅保證系統可解碼的第一影格，不保證完整逐影格匯入；目前驗證環境的 ImageIO 只傳回第一影格。應用程式不提供 JXL 編碼輸出，也不承諾原始 JXL 編碼串流、HDR 或高位元深度資訊在 PDF 中原樣保留。

### 目前限制

- OCR 使用本機 Apple Vision，不需要 Office 或 Windows；不提供圖表清理、專用 CJK 字型控制或逐字/逐行開關。
- 目前壓縮選項為無損與 JPEG；不提供 JBIG2、CCITT G4 或 JPEG 2000 編碼。核心功能可用，但大型黑白書籍的最終體積可能大於專用 JBIG2 工具。
- 不提供顯示/隱藏 OCR 文字或實際刪除掃描影像的校對工具，也不提供影像修復或完整 PDF 內容編輯器。
- 相容介接中的 `[Images]` 多圖層組裝、`MinWidth` 尚未實作；偵測到時會顯示說明，不會聲稱已經套用。手動檔案順序若與介接絕對頁碼不一致，使用者須核對目錄定位。
- 一般本文件頁碼、部分標準命名動作與 URL 目標可用。PDFKit 不能可靠儲存的外部 PDF 目標、無法解析的命名/特殊目標會被明確標出並阻止靜默儲存；可在編輯器中改為有效本文件頁碼。JSON/TXT 可保留目標資料。加密 PDF 不提供書籤編輯。
- 加密保留書籤、OCR 文字、中繼資料、閱讀版面配置與一般分段頁碼。原生 PDFKit 不保留頁碼標籤，本應用程式僅安全補回不含文字前綴的頁碼標籤；含自訂文字前綴的介接檔案會明確阻止加密匯出，須去掉前綴或關閉加密。
- “電子書順序”使用常見前綴組：cov、bok、leg、fow、!、toc、數字正文、att、ins、bac，其餘置後。
- 中止或錯誤時，批次已經產生的 PDF 會保留，目前未完成的暫存 PDF 清除；不提供從中斷處續作。

## 開發與建置

原始碼為 Swift Package，可用 Xcode 開啟 `Package.swift`。需要包含 macOS SDK 的 Xcode，Swift 5.9 或以上。驗證環境為 macOS 15.7.9 / Xcode Swift 6.2.4，執行相容目標為 macOS 14。

```sh
# 偵錯執行
swift run FolioPDF

# 測試與16種語言文字檢查
bash scripts/test.sh

# 建置 Intel + Apple Silicon 通用 .app 和 ZIP
bash scripts/build-app.sh

# 僅建置目前機器架構
bash scripts/build-app.sh --host-only
```

`scripts/test.sh` 中的真實 OCR 測試需要正常存取 macOS Vision、CoreVideo 等系統服務。在限制硬體/系統服務的執行沙箱內，可能報 CVPixelBuffer 建立失敗；正常系統環境應執行並通過測試，不以略過測試替代驗證。

封裝使用本機 ad-hoc 簽名，不包含 Developer ID 公證。可在本機執行；向其他 Mac 分發時，正式發佈需要開發人員憑證及公證流程。

### 程式碼結構

```text
Sources/FolioCore/       影像、幾何、轉換、OCR、書籤與介接檔案
Sources/FolioPDF/        SwiftUI 工作區、狀態管理、原生預覽和多語言
Tests/FolioCoreTests/    實際影像/PDF/OCR/書籤往返與邊界測試
scripts/                測試、封裝、圖示與範例影像產生
packaging/Info.plist     macOS 應用程式資訊
docs/                   驗證記錄與真實視窗渲染
dist/                   可執行 .app 與分發 ZIP（建置產生）
```

## 文件語言

README 與驗證記錄均提供與介面一致的 16 種語言，可透過文件頂部的語言連結切換。功能說明、密碼限制、已知限制和建置步驟在各語言版本中保持一致。測試、建置和視窗截圖記錄屬於機器產生的原始證據，保留工具原文；對應說明在驗證記錄中提供多語言版本。

## 技術依據

使用 Apple 的 [Vision 語言偵測介接](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage)、[PDFKit 文件屬性](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) 和 [ImageIO JPEG 品質參數](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality)，同時以本機 SDK 聲明和實際檔案測試驗證實作。FolioPDF 將獨立設計的介面與原生系統框架結合。
