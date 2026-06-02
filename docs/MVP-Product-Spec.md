# Picko 拾影 MVP 产品方案

版本：v0.1  
日期：2026-05-31  
项目目录：`/Users/tanzz/workspaces/picko`

## 1. 产品定位

Picko 拾影是一款面向 iOS、iPadOS 和 macOS 的相册整理应用，核心目标是帮助用户从大量重复、相似、连拍、截图和事件照片中快速挑出值得保留的内容，并以低风险方式标记和复核待删除项目。

产品不应只被理解为“清理空间工具”，而应定位为“照片选择与回忆整理工具”。用户真正需要的不是删除照片本身，而是在不误删重要回忆的前提下，减少相册噪音，留下更好的照片。

一句话定位：

> Picko 拾影：帮你从重复和相似照片里，快速留下真正值得保留的那几张。

## 2. 目标用户

### 2.1 核心用户

1. iPhone 重度拍摄用户：经常连拍、旅行、拍孩子、拍宠物、拍食物，照片数量快速增长。
2. iCloud Photos 用户：多设备同步照片，担心误删后影响所有设备。
3. Mac 用户：希望在大屏上批量复核、整理和筛选照片。
4. 注重隐私的 Apple 生态用户：希望照片分析尽量在本地完成。

### 2.2 MVP 优先服务的场景

1. 用户有一组相似照片，希望快速选出 1 张或多张保留。
2. 用户想按某一天、某个地点、某个旅行片段整理照片。
3. 用户想用滑动手势快速判断单张照片是保留还是预删除。
4. 用户希望所有删除动作先进入预删除队列，最后统一确认。

## 3. 产品原则

1. 保留优先：界面文案和默认动作强调“保留好照片”，而不是“删除垃圾”。
2. 低风险：任何删除操作都先进入预删除篮，最终确认后才交给系统删除。
3. 本地优先：照片内容、特征提取和评分尽量在设备本地完成。
4. 快速决策：主流程必须支持单手滑动、撤销、跳过和批量确认。
5. 跨端互补：iPhone 做快速判断，Mac 做大规模复核和批量整理。

## 4. MVP 范围

### 4.1 MVP 必须包含

1. Photos Library 授权与读取。
2. 照片资产索引：读取照片、视频、截图、Live Photo 的基础元数据。
3. 单张整理模式：上滑保留、下滑预删除、左右切换、撤销、跳过。
4. 相似照片组模式：按时间窗口和基础视觉相似度生成分组。
5. 每组保留 1 张或保留 N 张。
6. 预删除篮：展示所有待删除项目，支持恢复和最终确认。
7. 释放空间估算：基于资源大小估算可释放容量。
8. iOS 与 macOS 共用核心整理逻辑。

### 4.2 MVP 暂不包含

1. 云端 AI 识别。
2. 用户账号系统。
3. 家庭共享整理。
4. NAS、外接硬盘、Google Photos、Lightroom 导入。
5. 自动永久删除。
6. 社交分享和相册故事生成。
7. 复杂付费体系。

### 4.3 当前实现状态

截至 2026-05-31，仓库已经从 docs-first 进入 Swift Package MVP core + Photos adapter + iOS/macOS app shell 阶段：

1. 已新增 `Package.swift`，提供 `PickoCore` library target 和 `PickoCoreTests` test target。
2. 已实现共享核心模型：`PhotoAsset`、`ReviewSession`、`SimilarGroup`、`DeletionQueue`、`ReviewStateStore`、`SimilarityEngine`。
3. 已新增 `PickoPhotos` library target，用于封装 Photos 授权、资产 snapshot 映射、资产索引和删除请求协议。
4. 已新增 `PickoApp` library target 和 XcodeGen 管理的 `Picko` iOS app target，用模拟数据驱动 Home、单张整理、相似组整理和预删除篮。
5. 已新增 `PickoMacApp` library target 和 XcodeGen 管理的 `PickoMac` macOS app target，用模拟数据驱动 Sidebar、网格复核、inspector、相似组、时间/地点占位和预删除篮。
6. 第一版本地持久化已确认使用 SwiftData；当前已提供 review decision、session、group decision 和 ordered basket records，并在整理动作后自动保存本地状态；Photos bootstrap 重新加载时会恢复已保存的 asset 状态、最近未完成 session、相似组决策和预删除篮顺序。
7. 已覆盖确定性单元测试：预删除队列、释放空间估算、撤销、相似组保留选择、时间窗口 + hash 分组、地点阈值分组、媒体类型边界、推荐保留评分、Photos adapter snapshot 映射、SwiftData persistence、current session persistence/restoration、Photos bootstrap group decision restoration、预删除篮顺序恢复、删除成功/失败后的 basket 持久化边界、清空 Picko 本地整理状态、SwiftUI root view construction、iOS/macOS similar/basket thumbnail provider coverage、macOS workbench selection/action/delete confirmation、metadata benchmark fixture、benchmark launch configuration、benchmark summary/error formatting、benchmark JSON reporting。
8. 已在 `AGENTS.md` 中记录当前真实测试命令：`swift test`。
9. 当前通过验证：`swift test` 覆盖 SwiftPM test targets 的 70 个 XCTest case 全部通过；iOS simulator `PickoUITests` 5 个 test 通过，包括 sample basket 清空 Picko 本地整理状态且不触发 Photos 确认；iOS simulator build 通过；macOS `PickoMac` app target test 通过；`swift run PickoBenchmarks` 已采集 synthetic controlled 1k、10k、50k baseline，iOS Simulator Photos-backed 1k/10k/50k in-app benchmark evidence 已采集，`.build/debug/PickoBenchmarks --json 10` 已验证机器可读输出；静态隐私日志审计和 iOS runtime privacy log 审计通过；`scripts/verify-phase-5-local.sh` 和 `scripts/verify-phase-5-platform.sh` 通过；Phase 5 evidence 模板生成脚本、baseline JSON 填充、manual evidence checklist 和 iOS 手工证据写回链路已验证。
10. Phase 5 集成已推进：iOS/macOS app 入口接入真实 Photos 授权/索引 bootstrap，SwiftData review decision、session、group decision 和 ordered basket records 可持久化，UI action 会自动写入 SwiftData，Photos bootstrap 会恢复最近未完成 session、已保存的相似组决策和预删除篮顺序，删除成功后 basket 清空会落盘，删除请求失败会保留 queued 状态，用户可从 iOS Home/全局 toolbar 和 macOS toolbar 清空 Picko 本地整理状态且不触发 Photos 删除，iOS 单张整理、iOS 相似组、iOS 预删除篮、macOS 网格、macOS 相似组和 macOS 预删除篮可通过内存 thumbnail provider 显示真实缩略图，最终删除请求只能从预删除篮确认后调用 Photos 删除协议，并新增 metadata indexing benchmark harness、synthetic fixture、Photos fetch-limit runner、baseline JSON capture 脚本、manual evidence checklist、simulator fixture seeding 脚本和 iOS in-app benchmark trigger；50k simulator fixture 已完整生成、导入并采集 benchmark evidence；iOS 首次授权、limited library、系统 Photos 删除确认和 Recently Deleted recovery 文案已用非生产 simulator fixture 采集 evidence。

当前 Phase 5 剩余外部证据：

1. macOS Photos 权限链路和系统删除确认的手动截图/录屏 evidence。
2. host macOS 大图库 metadata indexing Photos-backed 真实基线。

不纳入当前 MVP 收口的候补项：

1. iPadOS 专用适配。
2. 磁盘级缩略图缓存或跨进程缓存策略；第一版缩略图缓存保持进程内存优先。

## 5. 核心功能设计

### 5.1 首页

首页展示用户当前可整理的任务，而不是传统相册网格。

推荐模块：

1. 今日建议：例如“本周新增 382 张，发现 47 组相似照片”。
2. 快速开始：进入单张整理。
3. 相似照片：按组整理相似照片。
4. 按时间整理：今天、本周、上个月、某一天。
5. 按地点整理：附近地点、旅行地点、城市集合。
6. 预删除篮：显示待确认删除数量和预计释放空间。

### 5.2 单张整理模式

这是 iPhone 端最重要的高频流程。

交互：

1. 上滑：保留。
2. 下滑：标记预删除。
3. 左滑：下一张。
4. 右滑：上一张。
5. 点击收藏按钮：加入系统收藏或 Picko 内部精选。
6. 撤销按钮：撤销上一步动作。
7. 跳过按钮：暂不处理。

显示信息：

1. 拍摄日期。
2. 拍摄地点。
3. 文件大小。
4. 媒体类型：照片、视频、Live Photo、截图。
5. 所属分组：例如“上海旅行”“周六下午”“相似组 3/8”。

### 5.3 相似照片组模式

相似组是 Picko 的核心差异化能力。

分组依据：

1. 拍摄时间接近。
2. 地理位置接近。
3. 图像内容相似。
4. 文件来源和媒体类型接近。

交互：

1. 默认显示一个相似组的全部照片。
2. 用户可以选择“保留 1 张”或“保留 N 张”。
3. 系统给出推荐保留项，但用户可以手动改选。
4. 未选中的照片进入预删除篮。
5. 支持整组跳过。

推荐保留评分：

1. 清晰度。
2. 曝光。
3. 人脸是否睁眼。
4. 表情质量。
5. 构图完整度。
6. 分辨率和文件质量。
7. 是否已经收藏或编辑过。

MVP 阶段可以先实现基础评分：清晰度、曝光、分辨率、收藏状态、编辑状态。人脸表情评分可以放到第二阶段。

### 5.4 时间与地点批量整理

MVP 需要支持基础时间段整理，地点整理可以先做轻量版本。

时间整理：

1. 今天。
2. 昨天。
3. 本周。
4. 上个月。
5. 自定义日期范围。

地点整理：

1. 按城市或地点聚合。
2. 展示某地点内的相似照片组。
3. 支持用户从地点集合进入单张或相似组模式。

### 5.5 预删除篮

预删除篮是降低误删焦虑的关键。

功能：

1. 展示全部待删除照片和视频。
2. 按来源分组：单张整理、相似组、时间整理、地点整理。
3. 支持恢复单张、恢复整组、全部清空。
4. 显示预计释放空间。
5. 最终确认时调用系统 Photos 删除能力。
6. 删除后提醒用户系统仍会保留在“最近删除”中，可在系统相册内恢复。

## 6. iOS、iPadOS、macOS 端差异

### 6.1 iOS

定位：快速整理、碎片时间决策。

重点：

1. 手势优先。
2. 单手可用。
3. haptic feedback。
4. 卡片式照片浏览。
5. 快速撤销。

### 6.2 iPadOS

定位：大屏选择和对比。

重点：

1. 分屏对比相似照片。
2. 支持 Apple Pencil 标记或快速点选。
3. 网格和大图并列。

MVP 可先复用 iOS 逻辑，界面做响应式适配。

### 6.3 macOS

定位：批量复核和专业整理。

重点：

1. 网格视图。
2. 键盘快捷键。
3. 多选。
4. 大屏对比。
5. 批量确认。
6. 更适合处理上万张照片的库。

建议快捷键：

1. `K`：保留。
2. `D`：预删除。
3. `Space`：预览。
4. `Z`：撤销。
5. `1-9`：设置当前组保留数量。

## 7. 信息架构

MVP 页面：

1. Onboarding / 权限说明。
2. 首页。
3. 单张整理。
4. 相似组整理。
5. 时间整理。
6. 地点整理。
7. 预删除篮。
8. 设置。

设置项：

1. 照片权限状态。
2. 是否显示系统收藏。
3. 是否跳过已收藏照片。
4. 是否跳过已编辑照片。
5. 分组敏感度：严格、均衡、宽松。
6. 默认每组保留数量。
7. 隐私说明。

## 8. 数据模型草案

### 8.1 PhotoAsset

字段：

1. `localIdentifier`
2. `mediaType`
3. `creationDate`
4. `location`
5. `pixelWidth`
6. `pixelHeight`
7. `fileSize`
8. `isFavorite`
9. `isEdited`
10. `isScreenshot`
11. `duration`
12. `thumbnailHash`
13. `perceptualHash`
14. `status`

状态：

1. `unreviewed`
2. `kept`
3. `preDeleted`
4. `skipped`

### 8.2 SimilarGroup

字段：

1. `id`
2. `assetIds`
3. `groupType`
4. `timeRange`
5. `locationSummary`
6. `recommendedKeepIds`
7. `keepCount`
8. `confidenceScore`
9. `status`

### 8.3 ReviewSession

字段：

1. `id`
2. `mode`
3. `filter`
4. `startedAt`
5. `completedAt`
6. `reviewedCount`
7. `keptCount`
8. `preDeletedCount`
9. `freedBytesEstimate`

## 9. 技术方向

### 9.1 推荐技术栈

1. Swift + SwiftUI。
2. Photos framework 读取和修改系统相册。
3. Vision framework 做基础图像质量分析和相似度辅助。
4. SwiftData 存储本地整理状态。
5. CloudKit 后续用于跨设备同步整理状态，不在 MVP 强依赖。

### 9.1.1 第一版本地持久化决策

第一版确认使用 SwiftData，不采用纯 JSON 轻量文件作为主存储。

原因：

1. Picko 的本地状态不是单一配置文件，而是围绕照片资产、review decision、review session、group decision 和预删除篮顺序持续变化的结构化数据。
2. SwiftData 更适合按 asset id、session、group 和 basket item 做查询、更新与测试隔离，避免 JSON 文件在局部更新、并发写入和迁移时变成手写存储层。
3. SwiftData 与 SwiftUI、iOS/macOS Apple 平台生命周期更贴近，后续接 CloudKit 或做 schema migration 时路径更清晰。
4. JSON 仍可用于 benchmark report、evidence、导入导出或调试快照，但不作为第一版用户整理状态的权威存储。

第一版边界：

1. 只持久化用户整理状态，不持久化照片内容本身。
2. 不缓存完整图片、不记录敏感照片内容或可还原照片内容的日志。
3. 缩略图缓存保持进程内存优先；磁盘级缩略图缓存或跨进程缓存策略不纳入当前 MVP。
4. 如未来需要跨设备同步，先评估 SwiftData schema 与 CloudKit 同步边界，再进入实现。

### 9.2 架构建议

共享核心模块：

1. `PhotoLibraryService`：封装 Photos 权限、读取、删除。
2. `AssetIndexService`：建立照片索引。
3. `SimilarityEngine`：相似度计算和分组。
4. `ReviewStateStore`：整理状态存储。
5. `DeletionQueue`：预删除篮逻辑。
6. `RecommendationEngine`：推荐保留照片。

平台 UI：

1. `Picko iOS`
2. `Picko iPadOS`
3. `Picko macOS`

核心逻辑尽量放在 Swift Package 中，让多端复用。

## 10. 隐私与安全

MVP 必须明确：

1. 默认不上传照片原图。
2. 相似度分析尽量在设备本地完成。
3. 删除前必须有二次确认。
4. 删除后进入系统“最近删除”，仍可恢复。
5. 用户可以随时清空 Picko 内部整理状态。
6. 仅请求必要的 Photos 权限。

## 11. 竞品对标

### 11.1 Apple Photos

优势：

1. 系统级信任。
2. 内置重复照片合并。
3. iCloud Photos 深度集成。

不足：

1. 更偏重复项，不够关注相似照片筛选。
2. 缺少“保留 N 张”的批量决策。
3. 批量复核效率有限。

### 11.2 SwipeWipe

优势：

1. 滑动清理体验轻量。
2. 用户理解成本低。
3. 覆盖相似照片、截图、大视频等场景。

不足：

1. 更偏 iPhone 清理工具。
2. Mac 专业整理能力不是主要心智。

### 11.3 SwipePhotos

优势：

1. iPhone 和 Mac 都支持。
2. 强调本地处理。
3. 滑动体验明确。

不足：

1. Picko 可以在事件级整理、多选 N 和 Mac 工作台上形成差异。

### 11.4 Slidebox

优势：

1. 上滑删除的交互简单直接。
2. 老牌用户心智。

不足：

1. AI 推荐、相似组、多端专业整理空间较大。

### 11.5 CleanMyPhone / Gemini Photos

优势：

1. 品牌成熟。
2. AI 清理和存储释放能力强。
3. 相似照片检测成熟。

不足：

1. 更容易被用户理解为清理空间工具。
2. Picko 可以用“照片选择”和“保留优先”建立更温和的产品气质。

## 12. 差异化策略

1. 从“删除垃圾”转向“留下好照片”。
2. 重点打造“保留 N 张”。
3. 按事件整理，而不是只按媒体类型整理。
4. iPhone 轻决策，Mac 深复核。
5. 预删除篮和撤销机制做得足够可信。
6. 隐私本地处理作为长期品牌资产。

## 13. MVP 成功指标

产品指标：

1. 首次授权完成率。
2. 首次整理完成率。
3. 单次 session 平均处理照片数。
4. 相似组确认率。
5. 预删除篮最终确认率。
6. 撤销率和恢复率。
7. 7 日留存。

质量指标：

1. 用户误删投诉数。
2. 相似组推荐被手动修改比例。
3. 扫描耗时。
4. 大图库下的内存占用。
5. 删除操作失败率。

## 14. 版本路线图

### v0.1 原型

1. Photos 权限。
2. 读取照片缩略图。
3. 单张整理流程。
4. 本地整理状态。
5. 预删除篮。

### v0.2 MVP

1. 相似照片分组。
2. 保留 1 张 / 保留 N 张。
3. 基础推荐评分。
4. iOS 与 macOS 基础 UI。
5. 删除确认。

### v0.3 Beta

1. 时间整理。
2. 地点整理。
3. Mac 批量工作台。
4. 性能优化。
5. 基础订阅入口。

### v1.0

1. 稳定跨端体验。
2. 更成熟的照片质量评分。
3. App Store 上线。
4. 完整隐私说明。
5. 付费转化流程。

## 15. 开发建议

第一步不要先做复杂 AI。建议先把系统相册权限、资产读取、整理状态和预删除篮跑通。只要“滑动标记 -> 状态保存 -> 复核 -> 删除确认”链路可靠，产品核心就成立。

已确认开发顺序：

1. 先完成 Photos Adapter，确保 Photos 授权、资产读取、snapshot 映射和删除请求封装稳定。
2. 再完成 Core Hardening，补齐分组、评分、预删除篮、撤销和状态边界。
3. 然后完成 iOS MVP App；首个 UI 目标采用 iOS 先行，因为单张整理和保留优先复核是最高频路径。
4. 最后补 macOS MVP App；macOS 作为候补平台，在共享 core、Photos adapter 和 iOS 主流程稳定后继续推进。
5. 后续执行可使用 Subagent-Driven 并行拆分；涉及共享接口、同一文件或状态模型的任务先串行定接口再分派。

## 16. 未决问题

1. 相似度算法第一版继续使用 metadata-first；Vision 特征是否进入后续版本仍待评估。
2. 预删除状态是否需要通过 CloudKit 跨设备同步。
3. 付费墙应该放在相似组数量限制、处理照片数量限制，还是高级 AI 推荐上。
4. 中文品牌名是否确定为“拾影”，英文名是否确定为 “Picko”。

已决项：

1. 第一版本地持久化使用 SwiftData；JSON 仅用于 benchmark report、evidence、调试快照或未来导入导出。
2. MVP UI 顺序采用 iOS 先行、macOS 候补，不要求第一版同时首发两端。
