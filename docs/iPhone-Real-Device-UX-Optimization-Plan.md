# Picko iPhone 真机反馈优化方案

日期：2026-06-13
来源：用户在真机 `TZZ's iPhone 6s` 上运行 Picko 后的口述反馈
状态：已实现并完成本地/模拟器验证；等待 `TZZ's iPhone 6s` 真机复验

## 1. 目标

本轮优化目标是把 Picko 从“功能骨架可跑”推进到“真机首轮体验可信”。重点不是新增大功能，而是修复当前 iPhone 真机上暴露的体验断点：

1. 移除或收敛开发期入口，避免用户误触危险操作。
2. 让真实图库中的相似照片能被识别，或至少给出可解释的“未发现原因”。
3. 统一中文界面、本地化、空状态和按钮可读性。
4. 修复照片预览页无法交互的严重可用性问题。
5. 让首页、Similar、Basket 三个核心入口的视觉关系更自然。

## 1.1 当前进度

更新日期：2026-06-20

整体结论：上述 10 个反馈项均已在 `codex/iphone-real-device-ux-fixes` 分支实现，对应 PR 为 `#5 fix(ios): polish iPhone real-device UX`。代码侧已通过自动测试、隐私日志审计、Phase 5 本地验证、iOS 模拟器 UI 测试和平台验证；由于 Codex 无法直接读取用户真机屏幕，最后一步仍需要在 `TZZ's iPhone 6s` 上按本文真机验收清单复验。

| 问题 | 进度 | 实现摘要 |
| --- | --- | --- |
| 2.1 预览页不可用 | 已修复 | 新增 `PhotoPreviewView`，接入单张整理、相似组和预删除篮，支持完整显示、缩放、拖动、关闭和复核动作。 |
| 2.2 相似照片未检出 | 已修复 | `SimilarityEngine` 新增真实图库默认配置，在 hash 缺失时使用时间、尺寸、文件大小和地点的保守 metadata fallback 分组。 |
| 2.3 首页清除状态入口 | 已修复 | 移除 tab toolbar 中的全局清除状态按钮，避免普通用户误触调试入口。 |
| 2.4 首页三项指标突兀 | 已修复 | 将“图库 / 相似组 / 预删除篮”改为更轻量的紧凑状态区，并保留跳转语义。 |
| 2.5 Basket 禁用态不可读 | 已修复 | 禁用按钮改为可读样式，并补充“空篮 / 样例图库”的中文禁用原因。 |
| 2.6 Basket 英文与 Zero KB | 已修复 | 新增 `PickoCopy` 和中文空间格式化，替换 `Savings Overview`、`Confirm with Photos`、`Clear Basket`、`Zero KB` 等文案。 |
| 2.7 Basket 空设置图标 | 已修复 | 移除右上角无响应设置图标，不保留空 action 控件。 |
| 2.8 Similar 空态背景不一致 | 已修复 | 新增页面级空状态样式，背景与 app 页面背景一致，并提供下一步动作。 |
| 2.9 首页时间/地点无法点击 | 已修复 | 时间和地点入口改为 `NavigationLink`，进入可用的合集占位页面。 |
| 2.10 Tab 和主流程英文 | 已修复 | Tab 和首页、复核、相似、预删除篮、授权失败等主流程文案已中文化。 |

已完成验证：

1. `swift test`
2. `scripts/audit-privacy-logging.sh`
3. `scripts/verify-phase-5-local.sh`
4. XcodeBuildMCP `test_sim` on `Picko` / `iPhone 17 Pro`：6 passed, 0 failed
5. XcodeBuildMCP `build_run_sim` + 截图烟测
6. `scripts/verify-phase-5-platform.sh` 使用新的临时 DerivedData 路径通过

待复验：

1. 在 `TZZ's iPhone 6s` 上安装最新 PR 构建。
2. 按本文“真机验收”清单确认真实 Photos 授权、6 张相似照片检出、预览缩放/退出、Basket 禁用态和系统 Photos 确认前取消。

## 2. 问题清单与优先级

### P0: 阻断体验或严重误导

#### 2.1 预览页只显示放大的图片局部，无法点击、缩放或退出

用户反馈：跳转到 Preview 页面后，整个页面只是一张被放大的图片局部内容，不能点击，不能缩放，几乎不可用。

初步判断：

1. 当前仓库中 iOS 侧没有独立、完整的照片详情预览视图；`SingleReviewView` 和 `SimilarGroupReviewView` 直接使用 `PickoThumbnailView` 以 `.fill` 裁切显示缩略图。
2. 如果用户看到的 “Preview” 是系统/导航中某个默认预览入口，当前实现没有提供可退出、可缩放、可恢复导航的真实照片预览体验。
3. 这是严重体验缺陷，因为照片整理产品必须允许用户检查原图细节。

优化方案：

1. 新增 `PhotoPreviewView`，使用 `NavigationStack` 内的全屏或 sheet 预览。
2. 图片默认使用 `.fit` 完整显示，不应默认裁切成局部。
3. 支持双指缩放、拖动平移、双击恢复到 1x。
4. 顶部提供明确关闭按钮，底部保留“保留 / 放入预删除篮 / 取消”动作。
5. 从单张整理、相似组、预删除篮图片点击进入同一预览视图。

涉及文件：

1. 新增 `Sources/PickoApp/Views/PhotoPreviewView.swift`
2. 修改 `Sources/PickoApp/Views/SingleReviewView.swift`
3. 修改 `Sources/PickoApp/Views/SimilarGroupReviewView.swift`
4. 修改 `Sources/PickoApp/Views/PreDeleteBasketView.swift`
5. 补充 `Tests/PickoAppTests/PickoAppTests.swift`
6. 补充 `Tests/PickoUITests/PickoUITests.swift`

验收标准：

1. 任意图片进入预览后默认完整显示。
2. 可以缩放、拖动、关闭。
3. 预览页上的保留/预删除操作会回写到当前 model。
4. iPhone 6s 小屏幕上按钮不遮挡图片核心内容。

#### 2.2 选择 6 张相似照片后没有检测出相似组

用户反馈：在图库中选择了 6 张相似图片，但 Similar tab 没有检测出来。

初步判断：

1. 当前 `SimilarityEngine` 只在媒体类型相同、时间窗口内、地点阈值允许，并且 `thumbnailHash` 或 `perceptualHash` 完全相等时才会分组。
2. 真机 Photos adapter 目前主要读取 Photos 元数据和缩略图数据，但 `PhotoAssetSnapshot` 中的 `thumbnailHash` / `perceptualHash` 在真实 Photos 路径下很可能为空。
3. 因此真实图片即使肉眼相似，只要没有 hash，就不会进入相似组。
4. 仅靠 90 秒时间窗口也不足以覆盖用户手动选择的 6 张相似图，尤其是截图、转存图、编辑图或不同时间保存的相似图。

优化方案：

1. 近期修复：对真实图库添加 metadata fallback 分组规则。
   - 同一媒体类型。
   - 创建时间在较宽窗口内，例如 5 分钟或可配置。
   - 分辨率接近，例如宽高差异不超过 8%。
   - 文件大小接近，例如差异不超过 35%。
   - 若地点存在，则地点距离不超过配置阈值；地点缺失不阻断。
2. 中期修复：为缩略图生成轻量本地指纹。
   - 从 `PhotoThumbnailProviding` 获取低分辨率 thumbnail。
   - 计算平均哈希或感知哈希。
   - 只保存派生 hash，不保存照片内容。
3. UX 修复：Similar 空状态必须解释“为什么暂无相似照片组”，并提供“重新扫描图库”入口。

涉及文件：

1. 修改 `Sources/PickoCore/SimilarityEngine.swift`
2. 修改 `Sources/PickoPhotos/PhotosLibraryAdapter.swift`
3. 修改 `Sources/PickoPhotos/PhotoAssetSnapshot.swift`
4. 修改 `Sources/PickoApp/PhotoLibraryBootstrapper.swift`
5. 修改 `Sources/PickoApp/Views/SimilarGroupReviewView.swift`
6. 补充 `Tests/PickoCoreTests/PickoCoreTests.swift`
7. 补充 `Tests/PickoPhotosTests/PickoPhotosTests.swift`

验收标准：

1. 6 张同一场景、同一时间附近、尺寸接近的照片能产生至少 1 个相似组。
2. hash 缺失时仍有 fallback 结果。
3. fallback 分组不能把明显不同媒体类型或间隔很久的照片误合并。
4. 空状态显示中文解释，并提供重新扫描入口。

### P1: 高频界面质量问题

#### 2.3 首页右上角不应暴露单独“清除状态”功能

用户反馈：首页右上角为什么有一个单独清除状态功能。

初步判断：

1. `PickoRootView` 在每个 tab 的 toolbar 都挂了 `clearReviewStateButton`。
2. 该功能更像开发期/调试期入口，普通用户在首页看到会困惑，也可能误以为会删除照片。

优化方案：

1. 从首页、Review、Similar、Basket 的右上角移除全局清除状态按钮。
2. 将“清除 Picko 本地整理状态”移动到设置页或调试页。
3. 设置页文案必须明确：“只清除 Picko 本地整理进度，不会删除或修改系统照片。”
4. 若当前版本还没有设置页，则先隐藏此入口；保留测试可通过 model 方法覆盖。

涉及文件：

1. 修改 `Sources/PickoApp/Views/PickoRootView.swift`
2. 可能新增 `Sources/PickoApp/Views/SettingsView.swift`
3. 修改 `Tests/PickoUITests/PickoUITests.swift`

验收标准：

1. 首页右上角不再出现清除状态按钮。
2. 真实用户路径不会误触清除状态。
3. 本地清理能力仍可从设置或测试入口触达。

#### 2.4 首页“图库 / 相似组 / 预删除篮”三项在中间突兀

用户反馈：首页 UI 中“图库、相似组、预删除栏”三个东西显示在中间，感觉很突兀。

初步判断：

1. `HomeView` 使用 `LazyVGrid` 展示三个 metric capsule，视觉上像孤立的仪表盘。
2. 它们夹在 hero 和快速开始之间，缺少层级解释。

优化方案：

1. 把三项从独立中间模块改为 hero 下方的紧凑状态条，弱化视觉重量。
2. 或改成“今日整理状态”列表，放在快速开始之后。
3. 推荐方案：采用一行横向紧凑 summary，内容为“图库 N 张 / 相似组 N 组 / 预删除 N 项”，点击各项可跳转。
4. 与 Picko 的 keep-first 方向一致，首页主视觉应优先突出“继续整理”和“相似照片待复核”，而不是数据卡片。

涉及文件：

1. 修改 `Sources/PickoApp/Views/HomeView.swift`
2. 修改 `Sources/PickoApp/PickoUIPresentation.swift`
3. 补充 `Tests/PickoAppTests/PickoAppTests.swift`

验收标准：

1. 三项状态不再作为突兀的中间卡片出现。
2. iPhone 6s 上首页首屏可同时看到 hero 和主要行动入口。
3. 三项状态可点击或语义明确。

#### 2.5 Basket 页禁用态 Confirm with Photos 可读性太差

用户反馈：Basket 页 `Confirm with photos` 不能点击时，颜色和字体颜色基本看不清。

初步判断：

1. 当前 disabled 用整体 `.opacity(0.45)` 处理，按钮背景仍是深色 primary，文字是浅色 primarySoft，半透明后对比度不足。
2. 禁用原因没有直接说明，用户不知道是因为篮子为空，还是因为当前没有真实 Photos deleter。

优化方案：

1. 不再用整按钮透明度表达禁用态。
2. 使用明确禁用样式：浅灰背景、深灰文字、低对比但仍可读。
3. 在按钮下方加一行中文原因。
   - 篮子为空：`预删除篮为空，暂无需要确认的项目。`
   - 没有 Photos 删除能力：`当前为样例图库，无法调用系统照片确认。`
4. 按钮文案本地化为 `用“照片”确认` 或 `交由系统照片确认`。

涉及文件：

1. 修改 `Sources/PickoApp/Views/PreDeleteBasketView.swift`
2. 修改 `Sources/PickoApp/PickoUIPresentation.swift`
3. 修改 `Tests/PickoAppTests/PickoAppTests.swift`
4. 修改 `Tests/PickoUITests/PickoUITests.swift`

验收标准：

1. 禁用按钮在 iPhone 6s 上仍清晰可读。
2. 用户能知道为什么不能点。
3. 所有按钮文案为中文。

#### 2.6 Basket 页仍有英文和不自然文案

用户反馈：`Savings Overview`、`Confirm with photos`、`Clear Basket` 等都是英文；`总计节省 Zero KB` 中的 `Zero` 不自然。

初步判断：

1. `PickoUIPresentation` 仍输出英文 presentation copy。
2. `ByteCountFormatter.string` 在当前 locale 下返回 `Zero KB`。
3. `PreDeleteBasketView` 只做了局部中文替换，未建立统一中文 copy 层。

优化方案：

1. 新增或整理 `PickoCopy` / `PickoLocalization`，统一中文文案。
2. 封装空间大小格式化。
   - 0 bytes 显示为 `0 KB` 或 `0 字节`。
   - 非 0 显示遵循中文格式，例如 `约 2.4 MB`。
3. Basket 文案替换：
   - `Savings Overview` -> `空间预估`
   - `Confirm with Photos` -> `交由系统照片确认`
   - `Clear basket` -> `清空预删除篮`
   - `Restore` -> `恢复`
   - `From review flow` -> `来自整理流程`
   - `ITEMS / PHOTOS` -> `项 / 张`

涉及文件：

1. 新增 `Sources/PickoApp/PickoCopy.swift`
2. 修改 `Sources/PickoApp/PickoUIPresentation.swift`
3. 修改 `Sources/PickoApp/ReviewCopy.swift`
4. 修改 `Sources/PickoApp/Views/PreDeleteBasketView.swift`
5. 补充 `Tests/PickoAppTests/PickoAppTests.swift`

验收标准：

1. Basket 页没有用户可见英文。
2. `0` 空间显示为中文或数字格式，不再显示 `Zero KB`。
3. 测试覆盖 0 bytes、KB、MB 三类空间文案。

#### 2.7 Basket 页右上角设置图标点击无反应

用户反馈：Basket 页右上角设置图标点击没有反应。

初步判断：

1. `PreDeleteBasketView` 中 `PickoBrandHeader(title: "拾影", trailingSystemImage: "gearshape") {}` 传入的是空 action。
2. 这是一个显式假入口，应删除或接入真实设置页。

优化方案：

1. 若本轮不做设置页：移除 Basket 页右上角设置按钮。
2. 若做设置页：所有设置入口统一跳转到同一个 `SettingsView`。
3. 不允许保留空 action 的可点击控件。

涉及文件：

1. 修改 `Sources/PickoApp/Views/PreDeleteBasketView.swift`
2. 可能新增 `Sources/PickoApp/Views/SettingsView.swift`
3. 补充 UI test：点击设置入口后必须有可见结果；若移除入口，则验证按钮不存在。

验收标准：

1. 不存在点击无反应的设置图标。
2. 所有可点击控件都有真实反馈。

#### 2.8 Similar tab 空状态背景与应用背景不一致

用户反馈：第三个 tab `Similar` 上“暂无相似照片组”的背景和应用背景不是一个颜色。

初步判断：

1. `SimilarGroupReviewView` 空状态分支直接返回 `PickoEmptyStateView`。
2. `PickoEmptyStateView` 自带 `.background(surface)` 和 `.padding(page)`，外层虽然有 `.pickoScreenBackground()`，但视觉上像一张漂浮卡片，和 full-screen 空态预期不一致。

优化方案：

1. 为页面级空状态新增 `PickoPageEmptyStateView`。
2. 页面级空状态背景使用 `PickoDesign.ColorToken.background`，内容居中或上中部排布，不再放在孤立白卡中。
3. Similar 空态加入操作按钮：`重新扫描图库`、`去单张整理`。

涉及文件：

1. 修改 `Sources/PickoApp/PickoDesignTokens.swift`
2. 修改 `Sources/PickoApp/Views/SimilarGroupReviewView.swift`
3. 可能新增 `Sources/PickoApp/Views/PickoEmptyStates.swift`

验收标准：

1. Similar 空状态背景与应用背景一致。
2. 空状态不是“死胡同”，至少提供一个下一步动作。

#### 2.9 首页“探索合集”的时间和地点无法点击

用户反馈：首页下面探索合集的时间和地点无法点击。

初步判断：

1. `HomeView.collectionRow` 当前只是 `HStack`，不是 `Button` 或 `NavigationLink`。
2. UI 上有 chevron，但没有行为，属于误导。

优化方案：

1. 将 `时间`、`地点` rows 改成 Button。
2. 若 iOS 当前没有独立时间/地点页面，点击后进入可用的占位页面，解释该能力将在真实索引完成后开放。
3. 更推荐直接新增 `CollectionsView`，按 `time` 和 `place` 两种 mode 复用。

涉及文件：

1. 修改 `Sources/PickoApp/Views/HomeView.swift`
2. 新增 `Sources/PickoApp/Views/CollectionReviewView.swift`
3. 扩展 `PickoAppModel.Tab` 或使用 NavigationLink
4. 补充 UI tests

验收标准：

1. 有 chevron 的 row 都可点击。
2. 点击后有明确页面或明确提示。
3. 不再出现视觉上可点但实际无反应的入口。

### P2: 本地化与信息架构一致性

#### 2.10 Tab 名称和大量文案仍是英文

用户反馈：当前应用应该是中文模式，但 Tab 名称还是英文，例如 `Home / Review / Similar / Basket`；还有 `Savings Overview` 等英文。

初步判断：

1. 当前 app 是硬编码混合中英文，没有系统化 localization。
2. `PickoRootView` 的 tab label 仍是英文。
3. Presentation 层大量英文仍在向 View 泄漏。

优化方案：

1. MVP 阶段先采用中文硬编码集中管理，不立即引入完整 `.strings` 多语言体系。
2. 新增 `PickoCopy`，集中管理所有用户可见中文文案。
3. 当前 UI 全量中文化：
   - `Home` -> `首页`
   - `Review` -> `复核`
   - `Similar` -> `相似`
   - `Basket` -> `预删除篮`
   - `Keep 1` -> `保留 1 张`
   - `Keep N` -> `保留多张`
   - `Suggested keep` -> `推荐保留`
   - `Keep selected` -> `保留所选`
4. `accessibilityLabel` 可以保留英文作为内部测试标识，但用户可见文本必须中文。

涉及文件：

1. 新增 `Sources/PickoApp/PickoCopy.swift`
2. 修改 `Sources/PickoApp/Views/PickoRootView.swift`
3. 修改 `Sources/PickoApp/PickoUIPresentation.swift`
4. 修改 `Sources/PickoApp/Views/HomeView.swift`
5. 修改 `Sources/PickoApp/Views/SingleReviewView.swift`
6. 修改 `Sources/PickoApp/Views/SimilarGroupReviewView.swift`
7. 修改 `Sources/PickoApp/Views/PreDeleteBasketView.swift`
8. 修改 `Sources/PickoApp/Views/PickoLibraryBootstrapView.swift`
9. 修改 `Sources/PickoApp/ReviewCopy.swift`

验收标准：

1. iOS app 主流程用户可见文案全部为中文。
2. 单元测试覆盖关键 copy，防止英文回流。
3. UI test 不依赖用户可见英文按钮名，或同时兼容中文文案。

## 3. Codex 目标模式

### 3.1 最终目标

将 Picko iPhone 真机首轮体验修复到“可持续试用”状态：用户在自己的 iPhone 上打开 app 后，可以用中文界面完成真实图库授权、相似照片发现、单张复核、照片预览、预删除篮复核和系统 Photos 删除确认前取消；过程中不出现明显英文残留、无响应入口、不可读按钮、误导性调试入口或无法退出的页面。

### 3.2 推荐 Goal 描述

在 Codex 目标模式中建议使用以下目标描述：

```text
完成 Picko iPhone 真机首轮体验修复：基于 docs/iPhone-Real-Device-UX-Optimization-Plan.md，修复照片预览不可用、真实图库相似照片无法识别、首页入口突兀和不可点击、Basket 禁用态/英文/Zero KB/空设置入口、Similar 空态背景不一致、Tab 和主要文案未中文化等问题；补充自动测试和真机验收说明，确保 iPhone 6s 上主流程可用。
```

### 3.3 Goal 完成定义

目标只有在以下条件全部满足后才能标记完成：

1. P0 问题全部修复。
   - 照片预览页可以完整显示照片、缩放、拖动、退出。
   - 真实图库中无 hash 的相似照片也能通过本地 fallback 规则产生相似组。
2. P1 问题全部修复。
   - 首页右上角不再暴露全局清除状态入口。
   - 首页“图库 / 相似组 / 预删除篮”不再突兀，并且主要入口层级清晰。
   - Basket 禁用态按钮清晰可读，并解释不能点击的原因。
   - Basket 中 `Savings Overview`、`Confirm with Photos`、`Clear Basket`、`Restore`、`Zero KB` 等用户可见英文或不自然文案已替换。
   - Basket 右上角不再有点击无反应的设置图标。
   - Similar 空状态背景与 app 背景一致，并提供下一步动作。
   - 首页时间/地点入口可点击，或不再用 chevron 暗示可点击。
3. P2 主流程中文化完成。
   - Tab 名称为中文。
   - 首页、复核、相似、预删除篮、授权失败页的主要用户可见文案为中文。
   - 新增用户可见 copy 优先走集中 copy 层，避免英文继续散落在 view 中。
4. 自动验证通过。
   - `swift test`
   - `scripts/audit-privacy-logging.sh`
   - 至少补充覆盖中文 copy、空间格式化、相似 fallback、Basket disabled reason 的单元测试。
5. 真机验收完成或明确记录阻塞。
   - 在 `TZZ's iPhone 6s` 或等价 iOS 17+ 真机上安装运行。
   - 按本文“真机验收”清单验证主流程。
   - 如果无法做真机复验，必须在最终说明中列出未验收项和原因。

### 3.4 阶段性目标

如果一次性目标过大，可以拆成三个连续目标执行。

#### Goal A: P0 真机可用性修复

```text
修复 Picko 的 P0 真机可用性问题：新增可缩放、可退出、可操作的照片预览页；为真实图库相似照片识别增加无 hash fallback 分组；让 Similar 空状态解释未发现原因并提供下一步动作；补充对应 Swift 单元测试和 iOS UI 验收。
```

完成定义：

1. `PhotoPreviewView` 或等价预览能力已接入单张整理、相似组和预删除篮。
2. `SimilarityEngine` 支持真实图库 hash 缺失时的保守 fallback 分组。
3. 6 张同场景、时间接近、尺寸接近的测试数据能形成相似组。
4. Similar 空状态不再是死胡同。
5. `swift test` 通过。

#### Goal B: 首页和 Basket 高频体验修复

```text
修复 Picko 首页与 Basket 高频体验问题：移除开发期清除状态入口，重排首页状态区，让时间/地点入口有真实反馈，修复 Basket 禁用态可读性、中文文案、Zero KB、空设置按钮和恢复/清空动作文案。
```

完成定义：

1. 首页不再出现全局清除状态 toolbar。
2. 首页 metric 区域视觉重量降低，主行动入口更清晰。
3. 时间/地点 row 可点击或取消可点击暗示。
4. Basket disabled primary action 在空篮和样例图库状态下可读，并显示原因。
5. Basket 用户可见文案为中文，不再出现 `Zero KB`。
6. 不存在点击无反应的设置图标。

#### Goal C: 中文化和视觉一致性收尾

```text
完成 Picko iOS 主流程中文化和视觉一致性收尾：集中管理用户可见中文 copy，中文化 Tab 和核心页面文案，统一 Similar 等页面级空状态背景，并补充防止英文回流的测试。
```

完成定义：

1. 主流程 Tab 名称和核心页面文案均为中文。
2. 新增 `PickoCopy` 或等价集中 copy 层。
3. 页面级空状态使用一致背景和下一步动作。
4. 测试覆盖关键中文 copy，避免英文文案回流。

### 3.5 非目标

以下事项不属于本轮 Codex 目标模式的完成条件：

1. 上架 App Store 或 TestFlight。
2. 付费 Apple Developer Program 配置。
3. 云端 AI 或服务器端图片识别。
4. 跨设备同步。
5. macOS 体验整体重做。
6. 完整多语言 `.strings` 体系。

## 4. 推荐实施顺序

### 第一批：P0 可用性修复

1. 修复照片预览页，确保可完整查看、缩放、退出。
2. 修复相似照片 fallback 分组，确保用户选择的 6 张相似图能被识别。
3. 为 Similar 空状态增加“重新扫描图库”和原因说明。

建议提交：

1. `fix(preview): add usable photo preview flow`
2. `fix(similarity): group real-library assets without hashes`

### 第二批：首页和 Basket 高频体验

1. 移除全局清除状态 toolbar 入口。
2. 修复 Basket 禁用按钮样式和禁用原因。
3. 修复 Basket 英文文案、`Zero KB`、空 action 设置按钮。
4. 重排首页 metric 区域，并让探索合集入口可点击。

建议提交：

1. `fix(home): remove debug state reset from primary navigation`
2. `fix(basket): improve disabled confirmation and localized copy`
3. `fix(home): make collection rows actionable`

### 第三批：全量中文化和视觉一致性

1. 新增集中 copy 层。
2. 中文化 tab 和主要页面。
3. 统一空状态背景和按钮样式。

建议提交：

1. `feat(localization): centralize chinese app copy`
2. `fix(ui): align empty states with app background`

## 5. 测试计划

### 自动测试

1. `swift test`
   - 覆盖 SimilarityEngine fallback 规则。
   - 覆盖中文空间格式化。
   - 覆盖 Basket presentation 中文文案。
2. `scripts/audit-privacy-logging.sh`
   - 确认新增相似识别逻辑没有打印照片内容或敏感 metadata。
3. iOS UI tests
   - Tab 名称为中文。
   - Basket disabled button 可见且有原因。
   - 首页时间/地点入口可点击。
   - Similar 空状态有下一步动作。

### 真机验收

设备：`TZZ's iPhone 6s`

1. 选择 6 张用户认为相似的非敏感照片，确认 Similar tab 产生相似组。
2. 在单张整理和相似组中点击照片，确认预览页可退出、缩放、拖动。
3. 进入 Basket 空篮状态，确认按钮禁用但文字清楚。
4. 放入一张照片到预删除篮，确认空间文案没有 `Zero KB`、按钮中文、系统 Photos 确认前可取消。
5. 首页确认无右上角清除状态入口。
6. 首页时间/地点 rows 点击后有响应。

## 6. 产品决策建议

### 清除状态入口

建议默认隐藏，不放在首页和 tab toolbar。它是必要的调试/恢复能力，但不是普通用户的高频功能。若保留，应放到设置页的“本地数据”区域，并使用二次确认。

### 相似识别能力边界

短期不要承诺“AI 视觉相似”。当前可以定位为“本地元数据 + 缩略图指纹的相似整理”。这能解释为什么它是隐私友好的，也避免过度承诺。

### 预删除篮语言

所有删除相关动作继续坚持“系统照片确认”和“最近删除可恢复”，但按钮文案必须简短。推荐：

1. 主按钮：`交由系统照片确认`
2. 次按钮：`清空预删除篮`
3. 恢复按钮：`恢复`
4. 说明：`确认后，系统“照片”会再次弹出确认。项目会移至“最近删除”，仍可恢复。`

## 7. 当前代码定位摘要

1. 全局清除状态入口：`Sources/PickoApp/Views/PickoRootView.swift`
2. 首页 metric 和探索合集：`Sources/PickoApp/Views/HomeView.swift`
3. Similar 空状态和相似组操作：`Sources/PickoApp/Views/SimilarGroupReviewView.swift`
4. Basket 文案、按钮、设置空 action：`Sources/PickoApp/Views/PreDeleteBasketView.swift`
5. 英文 presentation copy：`Sources/PickoApp/PickoUIPresentation.swift`
6. 相似识别核心规则：`Sources/PickoCore/SimilarityEngine.swift`
7. Photos adapter 和缩略图来源：`Sources/PickoPhotos/PhotosLibraryAdapter.swift`
8. 设计 token 和空状态组件：`Sources/PickoApp/PickoDesignTokens.swift`

## 8. 暂不纳入本轮的事项

1. App Store / TestFlight 分发。
2. 云端 AI 相似识别。
3. 跨设备同步。
4. 完整多语言 `.strings` 体系。
5. 大规模重做 macOS UI。

这些可以进入后续版本，但不应阻塞本轮真机体验修复。
