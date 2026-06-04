# Picko MVP Next Development Plan

版本：v0.1
日期：2026-05-31
状态：进行中；PR #1 已打开，Phase 5 仍待外部 Photos evidence
工作目录：`/Users/tanzz/workspaces/picko/.worktrees/mvp-core`

## 1. 当前基线

当前已经完成第一版可测试 MVP 骨架：

1. Swift Package 已创建，包含 `PickoCore`、`PickoPhotos`、`PickoApp`、`PickoMacApp`。
2. 共享模型和状态逻辑已实现：`PhotoAsset`、`ReviewSession`、`SimilarGroup`、`DeletionQueue`、`ReviewStateStore`、`SimilarityEngine`、`RecommendationEngine`。
3. Photos adapter 已封装授权、资产 snapshot 映射、索引和删除请求协议。
4. iOS 与 macOS 初版 SwiftUI shell 已接入模拟数据和核心状态。
5. 第一版持久化决策已确认使用 SwiftData，并已提供 review decision、session、group decision 和 ordered basket records；Photos bootstrap 重新加载时会恢复已保存的 asset 状态、最近未完成 session、相似组决策和预删除篮顺序。
6. `swift test` 已通过 SwiftPM test targets 的 70 个 XCTest case；Xcode 平台 gate 另覆盖 iOS app/UI tests 和 macOS app target tests。
7. `AGENTS.md` 已记录真实测试命令。

下一步不应扩张新平台功能，而应进入真实 Photos 数据接入、SwiftData 状态绑定、删除确认链路和集成验证。原因是 Picko 的核心风险不是页面能否画出来，而是照片授权、元数据读取、预删除确认、隐私边界和大图库性能是否可靠。

当前同步状态（2026-06-03）：

1. PR #1 已打开：`https://github.com/tzzs/picko/pull/1`，head 为 `codex/mvp-core`，base 为 `main`。
2. Active external evidence handoff 已同步到 `docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md`，host baseline timestamp 为 `20260603-photos-baseline`；正式 evidence artifacts 目录已解除忽略并应随 PR 提交，保证 fresh checkout 可复现当前 status gates。
3. `scripts/report-mvp-next-development-status.sh --fail-on-incomplete` 和 `scripts/audit-mvp-next-completion.sh` 仍按预期非零退出；本地 package、文档、runbook、handoff、readiness、evidence template 和 evidence directory cleanliness gates 均为 ready。
4. 当前不能标记 MVP Next 完成；剩余证明项仍是 host Mac Photos-backed 1k/10k/50k metadata baseline JSON，以及 macOS 首次 Photos 授权和预删除篮触发 Photos 系统删除确认两项手动截图/录屏 evidence。

## 2. 已确认开发顺序

确认结果：

1. 先完成 Photos Adapter。
2. 再完成 Core Hardening。
3. 然后进入 iOS MVP App。
4. 最后补 macOS MVP App。
5. 后续执行方式优先使用 Subagent-Driven，并行拆分互不冲突的任务；涉及共享接口或同一文件的任务按顺序串行执行，避免并行写入冲突。

### Phase 2: Photos Access Adapter

状态：已完成并通过 `swift test` 验证。

目标：新增 Apple 平台专用 adapter，负责 Photos 授权、资产读取、资源大小估算和删除请求封装。

交付物：

1. 新增 `PickoPhotos` target，仅在 Apple 平台编译。
2. 定义 `PhotoLibraryAuthorizing`、`PhotoAssetIndexing`、`PhotoDeleting` 等协议。
3. 实现 Photos framework adapter，将 `PHAsset` 映射为 `PickoCore.PhotoAsset`。
4. 明确权限状态：notDetermined、limited、authorized、denied、restricted。
5. 删除动作只封装系统请求，不绕过系统确认，也不做自动永久删除。

验收标准：

1. `swift test` 仍通过。
2. core target 不直接 import Photos。
3. adapter 可以在 Apple 平台编译。
4. 单元测试覆盖 PHAsset 映射边界；无法直接构造 PHAsset 的部分用协议 fake 覆盖。

### Phase 2.5: Core Follow-up Hardening

状态：已完成并通过 `swift test` 验证。

目标：补齐 Phase 1 留下的确定性边界，降低后续 UI 接入时的状态风险。

交付物：

1. `SimilarityEngine.Configuration` 增加地点距离阈值。
2. 相似分组同时考虑媒体类型、时间窗口、可选地点距离、thumbnail/perceptual hash。
3. `ReviewStateStore` 增加 skip、keep、restore/clear、重复操作的测试覆盖。
4. 推荐保留评分拆出为可测试的小函数或独立 `RecommendationEngine`。

验收标准：

1. 覆盖跨媒体不分组、超出时间窗口不分组、地点距离过远不分组。
2. 覆盖 favorite、edited、分辨率、文件大小的推荐优先级。
3. 所有测试通过。

### Phase 3: iOS MVP App

状态：初版可运行 iOS shell 已完成，已通过 SwiftPM tests、iOS simulator build、unit test、UI launch test 和截图验证。

目标：建立第一版可操作 iOS SwiftUI app，用模拟数据或真实 Photos adapter 驱动核心流程。

交付物：

1. iOS app target。
2. Onboarding / 权限说明页。
3. Home 页面：快速开始、相似照片、预删除篮入口。
4. 单张整理页：保留、预删除、跳过、撤销。
5. 相似组整理页：保留 1 张 / 保留 N 张。
6. 预删除篮页面：展示、恢复、清空、最终确认入口。

设计约束：

1. 使用系统 `TabView` 或平台原生导航，不手写自定义底部 tab bar。
2. 文案强调“保留”和“复核”，避免激进删除语言。
3. 真实删除前必须二次确认，并说明系统“最近删除”仍可恢复。

验收标准：

1. iOS simulator 可启动。
2. 不授权时显示清晰的权限状态和下一步。
3. 模拟数据下完整跑通单张整理、相似组整理、预删除篮恢复。
4. 真机或 simulator 可验证 Photos 权限链路。

### Phase 4: macOS MVP App

状态：初版可运行 macOS workbench 已完成，已通过 SwiftPM tests、macOS Xcode build/test 验证。

目标：建立 Mac 批量复核工作台，复用 `PickoCore` 和 Photos adapter。

交付物：

1. macOS app target。
2. Sidebar 导航：首页、相似照片、时间整理、地点整理、预删除篮。
3. 网格复核视图。
4. 右侧 inspector：日期、地点、大小、状态、推荐原因。
5. 键盘命令：`K` 保留、`D` 预删除、`Z` 撤销、`Space` 预览、`1-9` 设置保留数量。

验收标准：

1. macOS app 可构建并通过 app target smoke test。
2. 网格可展示模拟资产摘要。
3. 键盘命令和预删除篮状态已接入共享模型。
4. 不记录照片内容或敏感 metadata 到日志。

备注：当前已完成构建与测试验证，尚未做人工交互式 launch 截图验收；这会并入 Phase 5 集成验证。

### Phase 5: Integration Verification

状态：进行中。已完成 iOS/macOS 真实 Photos bootstrap、SwiftData review decision/session/group/ordered basket 持久化、真实 persistent SwiftData container reopen 恢复测试、最近未完成 session 恢复、Photos bootstrap group decision restoration、预删除篮顺序恢复、UI action 自动保存、删除成功/失败后的 basket 持久化边界、SwiftData persistent 初始化失败进入现有 failed UI 而不是静默无持久化、清空 Picko 本地整理状态、真实缩略图加载与内存缓存、iOS/macOS 相似组和预删除篮缩略图覆盖、预删除篮删除确认边界、metadata indexing benchmark harness、baseline JSON capture、manual evidence checklist、evidence 生成链路、Phase 5 status report、iOS 手工授权/limited/delete confirmation evidence、runtime privacy log evidence、active evidence deterministic host capture 指令同步、macOS manual capture helper-first 指令同步、external readiness 无副作用预检加固，并通过 SwiftPM/iOS/macOS 构建测试验证。

目标：把真实 Photos 数据、core 状态、iOS/macOS UI 和删除确认串起来。

交付物：

1. iOS 主流程 smoke test：已提供样本库 launch argument，真实 Photos 授权/索引 bootstrap 已接入；iOS 首次 Photos 授权、limited library picker、预删除篮触发系统 Photos 删除确认和 Recently Deleted recovery 文案已用非生产 simulator fixture 采集 evidence，未点击系统 Delete。
2. macOS 主流程 smoke test：真实 Photos bootstrap 与预删除篮确认入口已接入，已通过 SwiftPM macOS tests 与 `PickoMac` app target test；manual evidence 目录和 checklist 已准备，macOS 人工交互截图仍待补。
3. 大图库性能基线：已提供 `AssetIndexingBenchmark`、synthetic fixture、`PickoBenchmarks` runner、JSON report、host macOS Photos fetch-limit runner、baseline JSON capture 脚本、host baseline evidence updater、simulator fixture seeding 脚本、checkpointed chunk importer、evidence completeness checker、Phase 5 status report、external evidence checklist、environment evidence updater、iOS benchmark evidence updater、Automated Gates updater、Privacy Review updater、runtime privacy evidence recorder、manual verification evidence updater、final completeness gate recorder 和 iOS in-app benchmark trigger；status report 会按实际缺口输出下一步，external evidence checklist 会跳过已完成的 host baseline、iOS benchmark、environment、manual 和 runtime privacy 写回步骤，并在完整证据通过时停止提示外部证据；synthetic controlled 1k、10k、50k baseline 已采集，iOS Simulator Photos-backed 1k/10k/50k 结果已采集，host Photos-backed 真实基线仍待采集。
4. Evidence 模板与 active evidence 操作流安全：`scripts/check-phase-5-evidence-template.sh` 已接入 local verifier、whole-plan audit 和 MVP status report，用于确保 `docs/Phase-5-Evidence-Template.md` 保持 default helper 优先、explicit reproducibility 次之，且正式 host Photos capture 必须带 deterministic timestamp；`docs/phase-5-evidence-2026-05-31.md` 已同步 active-package host baseline helper、deterministic `20260603-photos-baseline` capture、macOS manual capture helper、date-specific `screencapture` 路径和 manual checker 顺序；external readiness 会拒绝 legacy host capture 和缺失 macOS helper 的 evidence 文档，并使用 macOS helper 的 `--validate-only` 模式避免预检创建截图目录。
5. 隐私检查清单：删除确认已限制为预删除篮触发；缩略图缓存仅在进程内存中保存，不由 Picko 写入磁盘；用户可清空 Picko 本地 review decision、session、group decision 和 basket records，且该操作不触发 Photos 删除；iOS 单张整理/相似组/预删除篮和 macOS 网格/相似组/预删除篮已接入同一内存 thumbnail provider；manual evidence checklist 与 manual evidence checker 已列出并检查运行时日志和真实设备行为证据目录，`docs/phase-5-evidence/manual-2026-05-31` 骨架已准备，iOS 授权/limited/delete confirmation 截图和 runtime privacy log 已采集，macOS 手工截图仍待采集。

验收标准：

1. 核心单元测试通过：当前 `swift test` 覆盖 SwiftPM test targets 的 70 个 XCTest 全部通过；iOS app/UI tests 和 macOS app target tests 由平台 gate 覆盖。
2. 平台 build/test 命令通过：iOS simulator build、iOS unit/UI tests、macOS app target test 已通过。
3. 大图库 indexing 不阻塞主线程：已有 benchmark harness、synthetic controlled 1k/10k/50k baseline、iOS in-app benchmark trigger 和 iOS Simulator Photos-backed 1k/10k/50k 截图证据，仍需 host Photos-backed 1k/10k/50k 数据验证。
4. 删除请求只在用户确认后触发：已通过 model test 覆盖只发送预删除篮 queued ids，UI 已加确认入口。

## 3. 决策结果

已确认：

1. 开发顺序：先 Phase 2 Photos adapter，再 Phase 2.5 core hardening，然后 iOS，最后 macOS。
2. 首个 UI 目标：先 iOS，因为单张滑动整理是最高频路径；macOS 作为候补平台，在 core、Photos adapter 和 iOS 主流程稳定后补。
3. 执行方式：进入实现阶段后优先启动 Subagent-Driven 开发；可并行的任务并行执行，不可并行的共享接口任务先落接口再分派。
4. UI 阶段：先做 iOS UI，macOS 后补。
5. 相似度第一版：继续使用 metadata-first，不引入云端 AI；Vision 特征放到 adapter 或后续 `RecommendationEngine`。
6. 地点距离分组：纳入 Core Hardening。
7. 删除策略：永远先进入 Picko 预删除篮，最终调用 Photos 系统删除确认。
8. 持久化第一版：使用 SwiftData 保存 review 状态、session、group 决策和预删除篮状态。

持久化决策补充：

1. SwiftData 是第一版用户整理状态的权威本地存储。
2. JSON 只用于 benchmark report、evidence、调试快照或未来导入导出，不作为 review state 主存储。
3. 后续 Phase 5 工作应继续验证 SwiftData 状态恢复和 UI action 自动保存；最近未完成 session 恢复、group decision restoration、预删除篮顺序恢复、真实 persistent SwiftData container reopen 恢复与删除成功/失败后的 basket 持久化边界已有本地单元测试覆盖；iOS/macOS bootstrap 默认 persistent store 创建失败会进入现有 failed UI，不再静默加载无持久化模型。
4. 不扩大到照片内容持久化；缩略图保持进程内存缓存，不在当前 MVP 引入磁盘级缩略图缓存或跨进程缓存策略。

## 4. 下一份可执行计划

下一份执行计划建议集中到 Phase 5：

0. 先按 `docs/Phase-5-External-Evidence-Runbook.md` 执行剩余外部证据采集；该 runbook 已纳入 local verifier，覆盖 host baseline、macOS 手工截图、写回命令和最终 gates。默认优先运行无参数 status、checklist、host baseline helper、macOS capture helper、handoff checker、finalizer 和 whole-plan audit 命令；这些脚本会从最新 `docs/phase-5-evidence-YYYY-MM-DD.md`、匹配的 `manual-YYYY-MM-DD` 目录、最新 handoff 的 Date 和 Host baseline timestamp 自动对齐当前活跃证据包。采集前的 readiness 预检现在还会确认 active evidence 文档未保留无 `--timestamp` 的 legacy host capture，并确认 macOS manual helper、date-specific screenshot 路径和 manual checker 顺序已记录。
1. 交接给人工操作者时，优先运行 `scripts/report-phase-5-status.sh` 和 `scripts/phase-5-external-evidence-checklist.sh` 查看剩余命令；需要重新生成 handoff 时优先运行默认 active-package 命令 `scripts/create-phase-5-external-evidence-handoff.sh --output docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md`，生成后优先运行无参数 `scripts/check-phase-5-external-handoff.sh` 检查最新 handoff 未过期。显式复现时再补充 `--handoff docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md`、`--evidence docs/phase-5-evidence-YYYY-MM-DD.md`、`--manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD`、`--date YYYY-MM-DD` 和 `--host-timestamp YYYYMMDD-HHMMSS`。
2. 使用非生产 Mac Photos 测试图库采集 host Photos-backed metadata indexing 基线；`scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000` 已在 2026-06-03 本地通过且不会读取图库。正式采集前优先运行 `scripts/prepare-phase-5-host-baseline-capture.sh`，它只验证 evidence 中已有 Passed preflight 并输出正式采集、写回和确定日期/timestamp 的 status 复查命令；显式复现时可带 `--evidence`、`--timestamp` 和 `--date`。
3. 做 macOS 真实 Photos 授权和删除确认的手动截图/录屏验收；iOS 授权、有限图库和删除确认 evidence 已完成。采集前先运行 `scripts/prepare-phase-5-macos-manual-capture.sh` 获取安全截图路径和写回命令，再打开相关系统 prompt/confirmation 并只在提示可见时运行 `screencapture -i ...`；该 helper 不会打开 Photos、读取图库或捕获屏幕，readiness 预检会通过 `--validate-only` 调用它以避免创建截图目录。显式复现时可带 `--manual-dir`、`--evidence` 和 `--date`。
4. 外部证据采集前运行 `scripts/check-phase-5-external-evidence-readiness.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD --date YYYY-MM-DD --host-timestamp YYYYMMDD-HHMMSS` 做显式一致性复核；日常执行优先运行 `scripts/phase-5-external-evidence-checklist.sh`，按清单逐项采集并写回 evidence 文档。需要从整份 MVP Next Plan 角度复核时，优先运行 `scripts/report-mvp-next-development-status.sh --fail-on-incomplete` 或 `scripts/audit-mvp-next-completion.sh`；该审计在外部证据未齐时应保持非零退出。最终证据文件生成后优先运行 `scripts/finalize-phase-5-evidence.sh`，该脚本会记录 completeness gates，并连续执行 status report `--fail-on-incomplete` 与最终 evidence checker。
