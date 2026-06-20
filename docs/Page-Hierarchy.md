# Picko 页面层级结构

更新日期：2026-06-21

本文档梳理 Picko 当前代码中的真实页面层级，覆盖 iOS 主应用、辅助启动页面、弹层页面和 macOS workbench。它用于后续做 UI 统一、功能补齐和回归测试时判断页面归属，避免每个页面各自形成一套交互规则。

## 1. 页面分层原则

Picko 当前页面可以分为五层：

1. App 启动层：决定进入真实相册加载、样例图库、权限失败页或 benchmark 页面。
2. 主导航层：iOS 使用底部 Tab，macOS 使用侧边栏 + detail + inspector。
3. 一级任务页：首页、复核、相似、预删除篮。
4. 二级整理页：时间合集、地点合集、地图聚合详情。
5. 临时操作层：照片预览、复核手势设置、系统删除确认、清空确认。

核心规则：

- 一级任务页必须保留统一顶部标题结构。
- 用户能长期停留的页面使用完整页面背景，不把整页放进悬浮卡片。
- 临时操作才使用 sheet、confirmation dialog 或系统弹层。
- 删除相关动作只允许在预删除篮最终确认后触发系统 Photos 删除能力。

## 2. iOS 启动入口

入口文件：`Apps/Picko/iOS/PickoApp.swift`

```text
PickoIOSApp
├─ BenchmarkLaunchConfiguration.parse(...)
│  └─ MetadataBenchmarkView
├─ --picko-use-denied-library
│  └─ PickoLibraryBootstrapView(denied bootstrapper)
├─ --picko-use-sample-review
│  └─ PickoRootView(selectedTab: review)
├─ --picko-use-empty-review
│  └─ PickoRootView(selectedTab: review, empty assets)
├─ --picko-use-sample-similar
│  └─ PickoRootView(selectedTab: similar)
├─ --picko-use-sample-basket
│  └─ PickoRootView(selectedTab: basket)
├─ --picko-use-sample-library
│  └─ PickoRootView(preview model)
└─ default
   └─ PickoLibraryBootstrapView(real Photos bootstrap)
```

### 2.1 相册加载页

实现文件：`Sources/PickoApp/Views/PickoLibraryBootstrapView.swift`

```text
PickoLibraryBootstrapView
├─ loading
│  ├─ OnboardingView
│  └─ 正在准备本地相册索引
├─ loaded(model)
│  └─ PickoRootView(model)
└─ failed
   ├─ OnboardingView
   └─ 权限失败说明 + 样例图库入口
```

该层负责 Photos 授权、资产索引、缩略图 provider 和 SwiftData review state 初始化。进入 `PickoRootView` 后，页面不再关心加载来源是样例图库还是真实图库。

## 3. iOS 主导航层

实现文件：`Sources/PickoApp/Views/PickoRootView.swift`

```text
PickoRootView
└─ TabView(selection: PickoAppModel.selectedTab)
   ├─ 首页 home
   │  └─ NavigationStack → HomeView
   ├─ 复核 review
   │  └─ NavigationStack → SingleReviewView
   ├─ 相似 similar
   │  └─ NavigationStack → SimilarGroupReviewView
   └─ 预删除篮 basket
      └─ NavigationStack → PreDeleteBasketView
```

底部 Tab 当前固定为：

- `首页`：任务聚合与入口分发。
- `复核`：单张照片手势复核。
- `相似`：相似照片组整理。
- `预删除篮`：所有预删除项的恢复与最终确认。

## 4. 首页层级

实现文件：`Sources/PickoApp/Views/HomeView.swift`

```text
HomeView
├─ PickoTopLevelHeader(home)
├─ 今日建议
├─ 指标条
│  ├─ 点击图库指标 → selectedTab = review
│  ├─ 点击相似组指标 → selectedTab = similar
│  └─ 点击预删除指标 → selectedTab = basket
├─ 快速开始
│  ├─ 单张整理 → selectedTab = review
│  ├─ 相似照片 → selectedTab = similar
│  ├─ 预删除篮 → selectedTab = basket
│  └─ 时间整理 → CollectionReviewView(time)
├─ 探索合集
│  ├─ 时间 → NavigationLink → CollectionReviewView(time)
│  └─ 地点 → NavigationLink → CollectionReviewView(place)
└─ 浮动预删除篮入口 → selectedTab = basket
```

首页承担“任务分发”职责，不直接承载具体复核动作。时间和地点是首页的二级整理入口，不作为底部 Tab。

## 5. 时间与地点合集层级

实现文件：`Sources/PickoApp/Views/CollectionReviewView.swift`

```text
CollectionReviewView(mode: time)
├─ 标题：时间 / 按拍摄日期整理
├─ 固定筛选 chips
│  ├─ 今天
│  ├─ 昨天
│  ├─ 本周早些
│  ├─ 上个月
│  └─ 按月归档
├─ 空状态：暂无可按时间整理的照片
└─ 合集列表
   └─ 点击整理 → model.startReview(scope) → selectedTab = review
```

```text
CollectionReviewView(mode: place)
├─ 标题：地点 / 按城市与地点聚合
├─ loading：正在聚合地点
├─ 空状态：暂无带地点信息的照片
├─ 地图聚合面板
│  ├─ 小地图
│  ├─ 点击地图或放大按钮
│  └─ sheet → PlaceMapDetailView
└─ 地点合集列表
   └─ 点击整理 → model.startReview(scope) → selectedTab = review
```

合集页只负责“选定范围”。真正的 keep、pre-delete、skip、undo 仍然复用 `SingleReviewView` 的单张复核流，并通过 `PickoAppModel.reviewScope` 限定当前合集内照片。

## 6. 复核页层级

实现文件：`Sources/PickoApp/Views/SingleReviewView.swift`

```text
SingleReviewView
├─ scoped completion state
│  ├─ PickoTopLevelHeader(review)
│  ├─ 本合集已整理完成
│  ├─ 返回首页 → clearReviewScope + selectedTab = home
│  └─ 查看预删除篮 → clearReviewScope + selectedTab = basket
├─ active asset state
│  ├─ PickoTopLevelHeader(review)
│  │  ├─ 进度：第 X / N 张
│  │  ├─ 上一张
│  │  └─ 设置
│  ├─ 上方手势提示
│  ├─ 照片堆叠舞台
│  │  ├─ 后续照片堆叠预览
│  │  ├─ 当前照片卡片
│  │  └─ 拖动动作 badge
│  └─ 下方手势提示
└─ empty state
   ├─ PickoTopLevelHeader(review)
   ├─ 暂无待复核照片
   └─ 主行动
      ├─ 有相似组 → 去相似整理 → selectedTab = similar
      ├─ 有预删除项 → 查看预删除篮 → selectedTab = basket
      └─ 无剩余任务 → 返回首页 → selectedTab = home
```

复核页的临时页面：

- 点击照片卡片 → `PhotoPreviewView(context: review)`。
- 点击设置 → `ReviewGestureSettingsView`。

手势语义由 `ReviewGesturePreference` 决定：

- 默认：上滑保留、下滑预删除、左滑上一张、右滑跳过。
- 设置页可切换：上滑预删除、下滑保留。

## 7. 相似页层级

实现文件：`Sources/PickoApp/Views/SimilarGroupReviewView.swift`

```text
SimilarGroupReviewView
├─ active group state
│  ├─ PickoTopLevelHeader(similar)
│  ├─ 相似组整理 header
│  ├─ 保留模式控制
│  ├─ 推荐主图
│  ├─ 其他相似照片网格
│  │  ├─ 点击照片 → 选择 / 取消选择
│  │  └─ 预览 → PhotoPreviewView(context: review)
│  └─ inline confirmation footer
│     ├─ 恢复推荐
│     └─ 确认选择
└─ empty state
   ├─ PickoTopLevelHeader(similar)
   ├─ 暂无相似照片组
   └─ 去单张整理 → selectedTab = review
```

相似页负责成组选择。确认后，保留项写入 keep，未选项进入预删除篮。它不负责最终删除。

## 8. 预删除篮层级

实现文件：`Sources/PickoApp/Views/PreDeleteBasketView.swift`

```text
PreDeleteBasketView
├─ PickoTopLevelHeader(basket)
├─ 最终确认区
│  ├─ 等待最终复核数量
│  ├─ 预计可节省空间
│  ├─ 最近删除恢复提醒
│  ├─ 在系统照片中确认删除
│  └─ 全部移出预删除篮
├─ 待确认项目
│  ├─ empty state：预删除篮为空
│  └─ item grid
│     ├─ 点击缩略图 → PhotoPreviewView(context: basket)
│     └─ 恢复
├─ 删除错误提示
└─ 最近删除恢复文案
```

预删除篮的临时操作：

- `PhotoPreviewView(context: basket)`：只提供恢复和关闭，不再提供“放入预删除篮”。
- `confirmationDialog`：系统 Photos 删除最终确认。
- `confirmationDialog`：全部移出预删除篮确认。

## 9. 共享弹层与工具页

### 9.1 照片预览

实现文件：`Sources/PickoApp/Views/PhotoPreviewView.swift`

```text
PhotoPreviewView
├─ NavigationStack
├─ 可缩放 / 可拖动照片
├─ context: review
│  ├─ 保留
│  └─ 放入预删除篮
└─ context: basket
   ├─ 恢复此项
   └─ 关闭
```

### 9.2 复核手势设置

实现文件：`Sources/PickoApp/Views/ReviewGestureSettingsView.swift`

```text
ReviewGestureSettingsView
├─ NavigationStack
├─ 复核手势说明
├─ 上滑保留 / 下滑预删除
├─ 上滑预删除 / 下滑保留
└─ 完成
```

### 9.3 地图聚合详情

实现文件：`Sources/PickoApp/Views/CollectionReviewView.swift`

```text
PlaceMapDetailView
├─ NavigationStack
├─ 全屏地图
├─ 地点标记
└─ 关闭
```

### 9.4 Metadata Benchmark

实现文件：`Sources/PickoApp/Views/MetadataBenchmarkView.swift`

```text
MetadataBenchmarkView
├─ running：运行 metadata benchmark
├─ finished：summary + results
└─ failed：错误信息
```

该页面由启动参数进入，不属于用户常规整理路径。

## 10. macOS 页面层级

macOS 入口文件：`Apps/Picko/macOS/PickoMacApp.swift`

```text
PickoMacOSApp
├─ --picko-use-sample-library
│  └─ PickoMacRootView(preview workbench)
├─ --picko-use-denied-library
│  └─ PickoMacLibraryBootstrapView(denied bootstrapper)
└─ default
   └─ PickoMacLibraryBootstrapView(real Photos bootstrap)
```

### 10.1 macOS 加载层

实现文件：`Sources/PickoMacApp/Views/PickoMacLibraryBootstrapView.swift`

```text
PickoMacLibraryBootstrapView
├─ loading：Loading photo library...
├─ loaded(model)：PickoMacRootView
└─ failed：权限失败说明 + Review Sample Library
```

### 10.2 macOS 主工作台

实现文件：`Sources/PickoMacApp/Views/PickoMacRootView.swift`

```text
PickoMacRootView
└─ NavigationSplitView
   ├─ sidebar：PickoMacSidebarView
   │  ├─ Review
   │  ├─ Similar
   │  ├─ Time
   │  ├─ Location
   │  └─ Basket
   └─ detail
      ├─ PickoMacGridReviewView
      ├─ PickoMacSimilarGroupsView
      ├─ PickoMacTimeLocationView(Time Review)
      ├─ PickoMacTimeLocationView(Location Review)
      └─ PickoMacBasketView
      └─ right inspector：PickoMacInspectorView
```

macOS toolbar 全局动作：

- Keep
- Review Later
- Undo
- Clear Picko State

App command menu 额外提供：

- `K`：Keep
- `D`：Review Later
- `Z`：Undo
- `Space`：Preview
- `1`：切换到 Similar

### 10.3 macOS detail 页面

```text
PickoMacGridReviewView
├─ Workbench Review header
└─ asset grid
   ├─ 点击资产 → inspector 选中
   └─ context menu：Keep / Review Later
```

```text
PickoMacSimilarGroupsView
├─ Similar Groups header
└─ group list
   ├─ 缩略图条
   ├─ 推荐保留说明
   └─ Keep 1 / Keep N / Manual review 状态提示
```

```text
PickoMacTimeLocationView
└─ 当前为 Time / Location 占位空状态
```

```text
PickoMacBasketView
├─ Pre-delete basket header
├─ 释放空间 pill
├─ basket rows
│  └─ Restore
├─ Confirm with Photos
└─ Clear basket
```

```text
PickoMacInspectorView
├─ 有选中资产
│  ├─ metadata
│  ├─ recommendation
│  ├─ keyboard hints
│  └─ Keep / Review Later
└─ 无选中资产
   └─ No selection empty state
```

## 11. 状态与导航关系

核心状态对象：

- iOS：`PickoAppModel`
- macOS：`PickoMacWorkbenchModel` 包装 `PickoAppModel`
- 共享整理状态：`ReviewStateStore`
- 复核范围：`PickoAppModel.reviewScope`
- 预删除队列：`ReviewStateStore.deletionQueue`

主要状态流：

```text
Home / Collection / Similar / Review / Basket
        │
        ▼
PickoAppModel
        │
        ▼
ReviewStateStore
        │
        ├─ kept
        ├─ preDeleted → deletionQueue
        ├─ skipped
        └─ undo stack
```

关键导航流：

- 首页指标 / 快速开始：通过 `selectedTab` 切换一级 Tab。
- 首页探索合集：通过 `NavigationLink` 进入 `CollectionReviewView`。
- 合集整理：通过 `startReview(scope:)` 写入 scope 并切到复核 Tab。
- 复核结束：scope 完成后可返回首页或进入预删除篮。
- 相似确认：写入 keep / pre-delete 状态，最终删除仍交给预删除篮。
- 预删除篮确认：最终调用 Photos 删除协议。

## 12. 当前需要保持统一的页面规范

后续 UI 开发建议遵守以下规则：

1. 一级 Tab 页面左上角都使用 `PickoTopLevelHeader`。
2. 首页、复核、相似、预删除篮顶部间距保持一致。
3. 空状态应保留所在页面的顶部标题，不应丢失页面身份。
4. 空状态是否使用背景卡片，应以同类页面为基准统一；例如复核空状态需要和相似空状态保持一致。
5. `PhotoPreviewView` 根据 context 决定动作，不应在预删除篮预览里再次出现“放入预删除篮”。
6. 只有预删除篮可以出现最终删除确认。
7. 时间 / 地点页面负责限定整理范围，不复制单张复核逻辑。
8. 任何新增页面都应先明确属于：一级任务页、二级整理页、临时操作层，还是工具页。
