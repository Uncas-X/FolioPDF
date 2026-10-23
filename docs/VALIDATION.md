# FolioPDF 1.4 验证记录

<!-- languages:start -->
**简体中文** · [English](validation/VALIDATION.en.md) · [繁體中文](validation/VALIDATION.zh-Hant.md) · [日本語](validation/VALIDATION.ja.md) · [한국어](validation/VALIDATION.ko.md) · [Français](validation/VALIDATION.fr.md) · [Deutsch](validation/VALIDATION.de.md) · [Español](validation/VALIDATION.es.md) · [Italiano](validation/VALIDATION.it.md) · [Português (Brasil)](validation/VALIDATION.pt-BR.md) · [Русский](validation/VALIDATION.ru.md) · [العربية](validation/VALIDATION.ar.md) · [हिन्दी](validation/VALIDATION.hi.md) · [Türkçe](validation/VALIDATION.tr.md) · [Nederlands](validation/VALIDATION.nl.md) · [Polski](validation/VALIDATION.pl.md)
<!-- languages:end -->

状态：**测试与构建通过**。记录日期：2026-10-23。验证环境：Intel Mac、macOS 15.7.9、Swift 6.2.4 / Xcode。最低部署版本 macOS 14。

本版新增 JPEG XL 输入，使用 macOS 14 及以上的原生 ImageIO 解码，并保留独立打开密码与编辑密码。加密设置位于右侧面板内，默认折叠，整行可点击。本次完整运行 58 项 XCTest，全部通过，0 失败、0 跳过。已确认本机原生 PDF 写入接口在打开密码为 17–31 字符时可能使 owner 密码失效；应用通过双密码模式的长度预检规避此问题，相关安全边界见下文。本次日志见 `test-results.txt`。

## 交付物

- `dist/FolioPDF.app`：原生 AppKit 窗口、SwiftUI 界面、系统 PDFKit / Vision / ImageIO。应用文件名不带版本号，版本记录在应用元数据内。
- `dist/FolioPDF-1.4-macOS.zip`：包含 x86_64 与 arm64 的通用应用包，已用 `lipo -archs` 核验。
- `dist/FolioPDF-1.4-source.zip`：可在 Xcode 打开的 Swift Package 源码，包含测试、脚本、使用说明和界面截图。
- 打包脚本使用本地 ad-hoc 签名，`codesign --verify --deep --strict` 通过；不包含 Developer ID 公证。内部版本为 1.4（build 5），应用文件名仍为 `FolioPDF.app`。

## 功能测试

已运行 `bash scripts/test.sh`，58 项 XCTest 全部通过，详细输出保存在 `test-results.txt`。实际 Vision OCR 测试也已执行，无跳过。

| 范围 | 数量 | 验证内容 |
|---|---:|---|
| 素材发现与排序 | 3 | 数字排序、电子书前缀、子目录与顶层排除、重复路径 |
| PDF 转换 | 10 | 页面几何和非法参数、EXIF 方向、多页 TIFF/GIF、元数据和书签、逐目录分组、不覆盖文件、批次部分失败、真实 JPEG 编码、原 JPEG 码流保留、Vision 隐藏文本及可搜索性、取消清理 |
| JPEG XL 输入 | 8 | 原生类型及扩展名映射、文件夹发现、有损/无损 RGB、RGBA 透明、16 位灰度、缩略图及预览、PDF 尺寸及渲染、透明/白底输出、动画按系统可见帧输出、损坏及缺失文件拒绝 |
| 书签及接口文件 | 8 | 多级书签、BasePage 换算、无效目标、标准动作和 JSON、外部目标明确拒绝、UTF-16 接口及分段页码、另存副本、可搜索文本页、既有页码标签保留 |
| 本地化 | 3 | 16 种语言及顺序、完整资源加载、18 个地域语言映射、未知语言回退、手动选择优先级、仅阿拉伯语采用 RTL |
| 原生 PDF 加密 | 14 | 实际 AESV2/128 位字典、只打开/只编辑/双密码、reader 与 owner 权限分离、错误密码不提权、不同密码要求、随机 owner、单密码与双密码的长度边界、超长打开密码在写入前拒绝、首尾空格、中文元数据、书签、隐藏文字、普通分段页码与布局、文字前缀明确拒绝、不覆盖和失败清理 |
| 加密转换集成 | 7 | 合并、逐文件和逐目录加密、自动编号、源文件不变、非法密码不输出、双密码权限及元数据保留、真实 Vision OCR 搜索与视觉保持、转换中确定性取消和目录清理 |
| 加密界面状态 | 5 | 两组密码与确认校验、开关独立清空、会话隔离和重置、三种模式完整导出及历史页数、密码不进入设置/历史/日志 |

OCR 测试使用真实生成的文字图像，验证输出 PDF 的文本可提取，并核对隐藏文字不改变页面渲染。测试须在可访问 macOS 系统服务的环境运行；受限执行沙盒的 CoreVideo 错误不被当作通过。

### 双密码验收条件

| 模式 | 普通阅读者 | 编辑密码持有者 |
|---|---|---|
| 只启用打开密码 | 空密码和错误密码不能打开；正确打开密码获得全部操作权限 | 未设置独立编辑密码 |
| 只启用编辑密码 | 无需密码即可阅读；禁止修改内容、批注、填写表单和页面整理 | 编辑密码获得 owner 全权限 |
| 同时启用两种密码 | 打开密码获得 user 受限权限 | 编辑密码可直接打开文件并获得 owner 全权限 |

两种密码同时启用时必须不同。三种模式均允许打印、复制和辅助访问；受限模式关闭内容修改、批注、表单填写以及页面插入/删除/旋转。权限限制需要阅读器遵守，不能作为“绝对不可修改”的保证。

密码仅接受可打印 ASCII 字符，安全支持范围为：只打开密码 1–32 字符；只编辑密码 1–32 字符；双密码模式的打开密码 1–16 字符、编辑密码 1–32 字符。双密码模式的条件限制在界面明确提示，并在导出预检中执行；超出范围直接报错，不截断密码、不改变首尾空格、不降级输出。

已打开的 PDF 调用 `unlock(withPassword:)` 时，即使 owner 密码错误也可能返回 `true`，因此验收必须检查 `permissionsStatus` 和全部权限位：受限 reader 为 user/51，owner 为 owner/255；只打开密码的 reader 为 user/255。只编辑密码的文件自动打开，历史页数读取不需要 owner 解锁。

## 界面与语言

- 当前资源为 292 条文案 × 16 种语言，实际界面文案为 281 条。`check-localization.py` 已通过；包内语言资源与源文件逐字节相同。
- 默认跟随系统；顺序与用户指定一致：简体中文、English、繁體中文、日本語、한국어、Français、Deutsch、Español、Italiano、Português (Brasil)、Русский、العربية、हिन्दी、Türkçe、Nederlands、Polski。
- 阿拉伯语的主窗口和设置窗口均采用 RTL 布局；文件名、图像与 PDF 内容保持原样。书签 TAB 文本编辑器保留 LTR 结构，避免改变接口文件的编辑含义。
- 本次重新启动应用并渲染实际 NSView，检查中文浅色默认折叠及双密码展开、德语深色长文案、阿拉伯语 RTL、仅编辑密码。字段与说明正常换行，未见重叠或缺字；超出视窗的内容随右侧面板滚动。截图见下表。
- “文档信息”“PDF 加密”“页边距与分辨率”等折叠标题统一使用整行 Button，标签撑满宽度后以矩形定义点击区域；左侧工作区导航及底部设置入口同样扩大点击区域。源代码审查已覆盖空白区域及 RTL 语义方向；未使用独立鼠标自动化测试。最终发行 app 已验证启动和主窗口关闭后重开，日志记录 `reopen verified: true`。
- 转换进行中禁止关窗和退出；未保存书签在关窗/退出时提示。关闭后再次打开仍保留当前会话草稿。
- 设置按钮与 ⌘, 使用同一原生设置窗口。⌘N 显示主窗口，⌘O 添加图片，⌘⇧O 添加文件夹，⌘E 导出。
- “PDF 加密”独立放在右侧设置面板“文档信息”之后，默认折叠并随面板滚动；点击展开后直接显示两组密码设置，不使用弹出面板。打开密码和编辑密码各有独立开关、遮蔽输入的密码框及确认框。
- 关闭某一开关只清空该组密码及确认值，重置设置清空两组。无效密码、确认不一致或双密码相同时阻止导出；两组都关闭时导出普通 PDF。切换折叠状态不改变保护设置。
- 两种密码仅在当前进程保存，不写入持久化设置、历史或日志。加密导出中的明文临时文件位于 0700 权限目录，正常取消和错误路径清理；最终只发布通过相应模式校验的加密文件，失败不能回退为未加密文件。
- OCR 识别语言仍由本机 Vision 支持范围决定，不以界面语言数量推断 OCR 语言数量。

## 验证边界

- 验证机器为 Intel Mac；1.4 通用包的两种架构均编译成功，尚未在 Apple Silicon 实机测试。
- 最低部署目标是 macOS 14；本次实际运行环境为 macOS 15.7.9。
- JPEG XL 使用原生 ImageIO 解码。5 个自生成测试样本覆盖有损 RGB、无损 RGB、RGBA 透明、16 位灰度和动画；当前系统只返回动画首帧，因此不保证动画逐帧导入。应用不提供 JXL 编码输出，不承诺原始码流、HDR 或高位深信息在 PDF 中原样保留。
- 没有作大规模扫描书籍的性能基准测试，也不承诺任意相机 RAW 格式或任意非标准 PDF 目标的兼容性。
- 加密使用 Apple PDFKit，要求输出 AESV2/128 位，并按所选模式核验密码及权限。本机原生写入接口的 17–31 字符打开密码问题影响 owner 认证，因此双密码模式统一限制打开密码为 1–16 字符；编辑密码及两种单密码模式各支持 1–32 字符。应用不自行修补密码学结果，拒绝 Unicode、控制字符及超出所选模式长度边界的输入；边界预检、owner 权限和首尾空格保留均有实际文件测试；双密码打开密码长度 17、31、32 会在写入前拒绝。
- 带自定义文字前缀的页码标签无法通过当前原生路径可靠保留，开启加密时明确报错；普通字母/罗马/数字分段页码、阅读布局及元数据均有往返测试。需要打开密码的文件在应用内预览时可输入密码；仅编辑密码的文件可直接预览。加密文件仍不支持书签编辑。
- JBIG2/G4 编码、OCR 校对、接口多图层和部分特殊书签目标等功能边界，详见项目 README 的“当前限制”。

## 本次界面记录

| 状态 | 实际窗口截图 |
|---|---|
| 中文、JPEG XL 静态图片导入 | [jpeg-xl-import-zh.png](screenshots/jpeg-xl-import-zh.png) |
| 中文、加密默认折叠 | [encryption-collapsed-zh.png](screenshots/encryption-collapsed-zh.png) |
| 中文、双密码展开 | [encryption-inline-zh.png](screenshots/encryption-inline-zh.png) |
| 德语、深色、双密码展开 | [encryption-inline-de-dark.png](screenshots/encryption-inline-de-dark.png) |
| 阿拉伯语、RTL、双密码展开 | [encryption-inline-ar.png](screenshots/encryption-inline-ar.png) |
| 最终通用 app、中文、仅编辑密码及关窗重开 | [encryption-editing-only-zh.png](screenshots/encryption-editing-only-zh.png) |

截图通过应用自身 `NSView` 渲染获取，不含其他应用内容。`build-results.txt` 记录双架构生产构建；[Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.4.0) 中的 `SHA256SUMS-1.4.txt` 记录分发 ZIP 校验值。旧布局截图移至 `screenshots/previous-layout/`，不作为本版本界面验收依据。

原始测试、构建及截图日志由工具生成，保留原始输出并将本机项目路径替换为 `<project>`；不把日志翻译后冒充原始证据。本说明的 16 种语言版本均解释相同的测试结果、环境与边界。源码版本不包含构建缓存与发行二进制，发行包请从仓库的 Releases 下载。
