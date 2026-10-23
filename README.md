# FolioPDF

<!-- languages:start -->
**简体中文** · [English](docs/readme/README.en.md) · [繁體中文](docs/readme/README.zh-Hant.md) · [日本語](docs/readme/README.ja.md) · [한국어](docs/readme/README.ko.md) · [Français](docs/readme/README.fr.md) · [Deutsch](docs/readme/README.de.md) · [Español](docs/readme/README.es.md) · [Italiano](docs/readme/README.it.md) · [Português (Brasil)](docs/readme/README.pt-BR.md) · [Русский](docs/readme/README.ru.md) · [العربية](docs/readme/README.ar.md) · [हिन्दी](docs/readme/README.hi.md) · [Türkçe](docs/readme/README.tr.md) · [Nederlands](docs/readme/README.nl.md) · [Polski](docs/readme/README.pl.md)
<!-- languages:end -->

一款原生 macOS 图片制书与 PDF 书签编辑应用。根据 FreePic2Pdf 的产品需求重新实现，采用独立的 SwiftUI 界面设计和 Apple 系统框架，无第三方运行时、无网络上传、无需配置 API Key。

## 使用

从 [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest) 下载 `FolioPDF-1.3-macOS.zip`，解压后打开 `FolioPDF.app`，也可将它拖到“应用程序”文件夹。系统要求 **macOS 14 或以上**。本地构建的应用位于 `dist/FolioPDF.app`。

1.3 版打包产物为 `FolioPDF-1.3-macOS.zip` 与 `FolioPDF-1.3-source.zip`，ZIP 内的应用始终命名为 `FolioPDF.app`。[验证记录](docs/VALIDATION.md)列出了验证状态、运行环境和实际界面截图。源码仓库不包含构建缓存或应用二进制，安装包在 Releases 中提供。

1. 在“制作 PDF”中添加图片、拖入文件，或添加一个/多个文件夹。文件夹递归选项位于右侧设置中，须在导入前选择。
2. 单击选择图片，Command 单击多选；拖拽到另一张图片上重新排序，或使用底部前移/后移按钮。双击图片预览。可切换缩略图与列表。
3. 右侧选择合并、逐源文件、逐文件夹输出，调整纸张/边距/DPI、压缩、OCR 与文档信息。
4. 如需密码保护，向下滚动右侧设置面板，展开“文档信息”后的“PDF 加密”区域。该区域默认折叠，展开后直接显示设置。“打开密码”和“编辑密码”各有独立开关；启用后填写相应密码及确认密码，具体权限见下表。批量输出的每个 PDF 都使用本次设置。
5. 点击“制作 PDF”。已有输出文件不会被覆盖，发生重名时自动创建带编号的新文件。多页 TIFF/GIF 的每页/帧依次成为 PDF 页；“每个图像文件一个 PDF”不会把同一源文件拆成多个 PDF。
6. “书签”工作区可打开未加密 PDF，增加/编辑/移动/缩进目录项，预览跳转，导入导出 TXT、JSON 或兼容接口文件，最后另存副本。

“文档信息”“PDF 加密”“页边距与分辨率”等折叠区域的整行标题都可点击，包含标题旁的空白处；左侧工作区导航也支持整行点击。“PDF 加密”默认折叠，展开后随右侧设置面板一起滚动。

⌘N 显示主窗口，⌘O 添加图片，⌘⇧O 添加文件夹，⌘E 导出，⌘, 打开设置。关闭后重开主窗口保留当前会话；退出应用不会自动保存书签草稿，请先另存副本。

### 打开密码与编辑密码

| 启用方式 | 密码长度 | 阅读与操作权限 |
|---|---|---|
| 只启用打开密码 | 打开密码 1–32 字符 | 打开 PDF 时需要密码；使用正确密码打开后，全部操作权限开放 |
| 只启用编辑密码 | 编辑密码 1–32 字符 | 无需密码即可阅读；普通阅读者的内容修改、批注、表单填写和页面插入/删除/旋转受到限制。输入编辑密码可取得全部权限 |
| 同时启用两种密码 | 打开密码 1–16 字符，编辑密码 1–32 字符 | 打开密码提供受限的阅读权限；编辑密码提供全部权限，也可直接用于打开 PDF |

两种密码同时启用时必须不同。打印、复制和辅助访问始终允许；编辑限制需要 PDF 阅读器遵守权限设置，不代表内容绝对无法被修改。

密码只接受可打印 ASCII 字符（英文、数字、符号和空格），长度按上表限制。界面会在同时启用两种密码时提示打开密码的 16 字符上限；超出限制会在导出前拒绝，不截断密码，也不自动去除首尾空格。

密码仅在当前应用会话中保留，不写入设置、历史或日志；关闭某个密码开关会清空该密码及其确认值，重置设置会清空两组。密码或确认值无效时会阻止导出；关闭两种开关后导出普通 PDF。

设置中的界面语言默认跟随系统，可随时手动切换以下 **16 种语言**，无需重启：

**简体中文** · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · Polski

阿拉伯语使用从右向左的界面布局；图片和 PDF 内容保持原样，书签的 TAB 文本编辑器保留从左向右的结构。外观支持系统、浅色和深色。系统文件选择器等 macOS 控件使用系统配置的语言。界面语言与 OCR 识别语言分别设置，OCR 可选项由本机 Vision 支持范围决定。

## 实现范围

| 能力 | 实现说明 |
|---|---|
| 图像输入 | JPEG、PNG、TIFF、GIF、BMP、HEIC/HEIF、JPEG 2000 等 ImageIO 可解码格式；动态发现当前系统其他支持的扩展名。RAW 支持由本机系统解码器决定，不保证所有相机型号 |
| 文件组织 | 去重、文件名/末尾数字排序、手动顺序、常见电子书前缀排序、文件夹递归、是否包括顶级目录 |
| 批量输出 | 合并一个 PDF、每源文件一个 PDF、每直接父目录一个 PDF；深层目录分别分组，不把后代图片重复计入父目录 |
| 页面 | 原图大小、固定宽度、A3/A4/A5/B5/Letter/Legal、自定义毫米尺寸、横向、四边距、小图放大、DPI 元数据优先 |
| 压缩 | 无损路径和 JPEG 质量控制。原始方向为正向的 JPEG 可保留原 DCT 编码流；其他格式/方向通过 ImageIO 正确解码和排版，不承诺每个源格式的码流逐字节保留 |
| 透明 | 保留透明或铺白底；JPEG 不能存 Alpha，保留透明时自动使用无损编码并报告说明 |
| OCR | Apple Vision 本地准确识别，自动或手选本机支持的语言，生成可搜索/复制的隐藏文本；GPU 路径失败时尝试 CPU。识别失败的页保留图像并明确报告 |
| 文档属性 | 标题、作者、主题、关键词；单页/连续/双页阅读布局 |
| PDF 加密 | 原生 PDFKit AES-128，支持独立打开密码、编辑密码及双密码。只设置打开密码时生成随机 owner 密码；设置编辑密码时以该密码授予 owner 全权限。按所选模式核验锁定状态、密码、reader/owner 权限和页数后才发布；失败不输出未加密替代文件。应用内预览支持输入密码 |
| 书签 | 自动源文件书签、多级目录、页码、基准页换算、可编辑文本及 JSON、原生 PDF 跳转预览 |
| 接口兼容 | `FreePic2Pdf.itf` 与 `FreePic2Pdf_bkmk.txt`，UTF-8/UTF-16LE 及相关传统编码；目录/正文分段页码、元数据、追加可搜索文本页、书签显示设置 |
| 稳定性 | 后台任务、逐页释放图像、任务进度、取消、日志、临时文件和原子发布、重名自动编号、批次中途失败保留并列出已完成结果 |

### 与旧版的明确差异

- OCR 使用 Apple Vision，替代 MODI，不需要 Office/Windows，也不沿用旧版图表清理、CJK 字体或逐字/逐行开关。
- 当前压缩选项为无损与 JPEG；没有复刻 JBIG2、CCITT G4 或 JPEG 2000 编码器。核心功能可用，但黑白大部头的最终体积可能大于专用 JBIG2 工具。
- 不提供原软件的“显示/隐藏 OCR 文字、物理删除扫描图像”校对工具，也不提供图像修复或完整 PDF 内容编辑器。
- 兼容接口中的 `[Images]` 多图层组装、`MinWidth` 尚未实现；检测到时会显示说明，不会声称已经应用。手动文件顺序若与接口绝对页码不一致，用户须核对目录定位。
- 普通本地页码、部分标准命名动作与 URL 目标可用。PDFKit 不能可靠保存的外部 PDF 目标、无法解析的命名/特殊目标会被明确标出并阻止静默保存；可在编辑器中改为有效本地页码。JSON/TXT 可保留目标数据。加密 PDF 不提供书签编辑。
- 加密保留书签、OCR 文字、元数据、阅读布局与普通分段页码。原生 PDFKit 不保留页码标签，本应用仅安全补回不含文字前缀的页码标签；含自定义文字前缀的接口文件会明确阻止加密导出，须去掉前缀或关闭加密。
- “电子书顺序”实现常见前缀组：cov、bok、leg、fow、!、toc、数字正文、att、ins、bac，其余置后；不声称与旧软件未公开规则完全相同。
- 中止或错误时，批次已经生成的 PDF 会保留，当前未完成的临时 PDF 清除；不提供断点续作。

## 开发与构建

源代码为 Swift Package，可用 Xcode 打开 `Package.swift`。需要包含 macOS SDK 的 Xcode，Swift 5.9 或以上。验证环境为 macOS 15.7.9 / Xcode Swift 6.2.4，运行兼容目标为 macOS 14。

```sh
# 调试运行
swift run FolioPDF

# 测试与16种语言文案检查
bash scripts/test.sh

# 构建 Intel + Apple Silicon 通用 .app 和 ZIP
bash scripts/build-app.sh

# 仅构建当前机器架构
bash scripts/build-app.sh --host-only
```

`scripts/test.sh` 中的真实 OCR 测试需要正常访问 macOS Vision、CoreVideo 等系统服务。在限制硬件/系统服务的执行沙盒内，可能报 CVPixelBuffer 创建失败；正常系统环境应运行并通过测试，不以跳过测试替代验证。

打包使用本地 ad-hoc 签名，不包含 Developer ID 公证。可在本机运行；向其他 Mac 分发时，正式发布需要开发者证书及公证流程。

### 代码布局

```text
Sources/FolioCore/       图像、几何、转换、OCR、书签与接口文件
Sources/FolioPDF/        SwiftUI 工作区、状态管理、原生预览和多语言
Tests/FolioCoreTests/    实际图像/PDF/OCR/书签往返与边界测试
scripts/                测试、打包、图标与示例图像生成
packaging/Info.plist     macOS 应用信息
docs/                   验证记录与真实窗口渲染
dist/                   可运行 .app 与分发 ZIP（构建生成）
```

## 文档语言

README 与验证记录均提供与界面一致的 16 种语言，可通过文档顶部的语言链接切换。功能说明、密码限制、已知差异和构建步骤在各语言版本中保持一致。测试、构建和窗口截图日志属于机器生成的原始证据，保留工具原文；对应说明在验证记录中提供多语言版本。

## 技术依据

使用 Apple 的 [Vision 语言检测接口](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage)、[PDFKit 文档属性](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) 和 [ImageIO JPEG 质量参数](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality)，同时以本机 SDK 声明和实际文件测试验证实现。没有复制原 FreePic2Pdf 程序、图标或旧界面。
