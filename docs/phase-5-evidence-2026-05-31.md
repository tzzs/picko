# Picko Phase 5 证据

日期：2026-05-31
工作目录：`/Users/tanzz/workspaces/picko/.worktrees/mvp-core`

## 环境

| 字段 | 值 |
| --- | --- |
| macOS | 26.4, build 25E246 |
| Xcode | Xcode 26.5 Build version 17F42 |
| 架构 | arm64 |
| iOS 模拟器 | iPhone 17 Pro，iOS 26.5 模拟器，id 0CF79391-989B-47A5-B853-1422340684F8；已完成平台与 UI 冒烟验证；已采集 Photos-backed 1k/10k/50k 基准测试证据 |
| 测试照片图库 | 非生产 iOS 模拟器生成 fixture，运行于 iPhone 17 Pro 模拟器；主机 Mac Photos 基线仍需要单独准备非生产 Mac Photos 图库 |

## 自动化门禁

自动化门禁记录。

| 门禁 | 命令 | 结果 | 证据 |
| --- | --- | --- | --- |
| 本地 Phase 5 | `scripts/verify-phase-5-local.sh` | 通过 | 2026-05-31 20:03 CST 终端运行：scripts/verify-phase-5-local.sh |
| 平台 Phase 5 | `scripts/verify-phase-5-platform.sh` | 通过 | 2026-05-31 21:46 CST 终端运行：scripts/verify-phase-5-platform.sh；PickoUITests 5 个用例通过，包括 Clear Picko State sample basket flow |
| 隐私日志 | `scripts/audit-privacy-logging.sh` | 通过 | 2026-05-31 20:03 CST 终端运行：scripts/verify-phase-5-local.sh 内部调用 scripts/audit-privacy-logging.sh |
| 证据完整性 | `scripts/check-phase-5-evidence.sh docs/phase-5-evidence-YYYY-MM-DD.md` | 待补充 | 待补充 |
| 手工证据完整性 | `scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-2026-05-31` | 待补充 | `docs/phase-5-evidence/manual-2026-05-31/README.md` |

## 主机 Photos 支撑的元数据基线

命令：

```sh
scripts/prepare-phase-5-host-baseline-capture.sh
scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-2026-05-31.md --label "Non-production Mac Photos test library" --timestamp 20260603-photos-baseline --date 2026-06-03
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --timestamp 20260603-photos-baseline 1000 10000 50000
```

预检状态：通过。2026-06-03 已在本地使用 `--validate-only`
完成预检；该预检确认了 non-production label、正式 1k/10k/50k counts
以及项目 evidence 输出目录，不会构建项目，也不会读取当前 Mac Photos library。

| 资产数量 | 耗时秒数 | 每秒资产数 | 备注 |
| ---: | ---: | ---: | --- |
| 1,000 | 待补充 | 待补充 | 待补充 |
| 10,000 | 待补充 | 待补充 | 待补充 |
| 50,000 | 待补充 | 待补充 | 待补充 |

原始 JSON 证据路径：`待补充`

## iOS 模拟器 Photos 支撑的基准测试

Fixture 准备：

```sh
scripts/seed-simulator-photos-fixture.sh --count 1000 --simulator booted
scripts/seed-simulator-photos-fixture.sh --count 10000 --simulator booted
scripts/seed-simulator-photos-fixture.sh --count 50000 --simulator booted
```

App 启动参数：

```text
--picko-run-metadata-benchmark --picko-benchmark-counts=1000,10000,50000
```

| 资产数量 | 耗时秒数 | 每秒资产数 | 证据 |
| ---: | ---: | ---: | --- |
| 1,000 | 58.9891 | 16.9523 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg` |
| 10,000 | 26.3797 | 379.0787 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-10000-2026-05-31.jpg` |
| 50,000 | 331.2685 | 150.9350 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-50000-2026-05-31.jpg` |

截图或录屏路径：见上方 1,000 / 10,000 / 50,000 三行证据。

## 手工 Photos 验证

准备 evidence 文件夹：

```sh
scripts/prepare-phase-5-manual-evidence.sh
scripts/prepare-phase-5-macos-manual-capture.sh
scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-2026-05-31 --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03
screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-03.png
screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-03.png
scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-2026-05-31
```

| 场景 | 平台 | 结果 | 证据路径 | 备注 |
| --- | --- | --- | --- | --- |
| 首次 Photos 授权 | iOS | 通过 | `docs/phase-5-evidence/manual-2026-05-31/ios/authorization/ios-first-photos-authorization-2026-05-31.jpg` | 非生产 iOS Simulator Photos fixture；在授予 limited access 之前已捕获系统首次授权弹窗 |
| 受限图库状态 | iOS | 通过 | `docs/phase-5-evidence/manual-2026-05-31/ios/limited-library/ios-limited-library-picker-2026-05-31.jpg` | 非生产 iOS 模拟器生成 fixture；已捕获受限图库 picker，其中选择了一个生成资产 |
| 预删除篮触发 Photos 确认 | iOS | 通过 | `docs/phase-5-evidence/manual-2026-05-31/ios/delete-confirmation/ios-system-photos-delete-confirmation-2026-05-31.jpg` | 非生产 iOS 模拟器生成 fixture；Picko 预删除篮确认继续进入系统 Photos 删除确认，但未点击 Delete |
| 首次 Photos 授权 | macOS | 待补充 | 待补充 | 待补充 |
| 预删除篮触发 Photos 确认 | macOS | 待补充 | 待补充 | 待补充 |
| “最近删除”恢复说明 | iOS/macOS | 通过 | `docs/phase-5-evidence/manual-2026-05-31/ios/delete-confirmation/ios-picko-confirmation-recently-deleted-2026-05-31.jpg` | 共享 Picko 确认文案会在系统确认前说明 Photos“最近删除”可恢复 |

## 隐私审查

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 产品代码没有宽泛日志调用 | 通过 | 2026-05-31 20:03 CST 终端运行：scripts/verify-phase-5-local.sh 内部调用 scripts/audit-privacy-logging.sh |
| 运行时日志已检查照片内容或敏感元数据 | 通过 | scripts/audit-runtime-privacy-logs.sh docs/phase-5-evidence/privacy/ios-runtime-2026-05-31.log |
| 缩略图缓存仅保留在进程内存中 | 通过 | 代码审查：Sources/PickoPhotos/PhotoThumbnailProvider.swift、Sources/PickoApp/Views/PickoThumbnailView.swift、Tests/PickoPhotosTests/PickoPhotosTests.swift |
