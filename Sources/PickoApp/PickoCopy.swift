import Foundation

public enum PickoCopy {
    public enum Tabs {
        public static let home = "首页"
        public static let review = "复核"
        public static let similar = "相似"
        public static let basket = "预删除篮"
    }

    public enum Home {
        public static let heroTitle = "继续整理珍贵回忆"
        public static let privacyFootnote = "复核时不会删除照片。Picko 只会在预删除篮最终确认后交由系统“照片”处理。"
        public static let libraryMetric = "图库"
        public static let similarMetric = "相似组"
        public static let basketMetric = "预删除篮"
        public static let reviewOneByOne = "单张整理"
        public static let reviewOneByOneSubtitle = "逐一筛选珍贵回忆"
        public static let reviewSimilar = "相似照片"
        public static let reviewSimilarSubtitle = "每组保留 1 张或多张"
        public static let reviewBasket = "预删除篮复核"
        public static let reviewBasketSubtitle = "最终确认前可随时恢复"
        public static let timeAndPlace = "时间与地点"
        public static let timeAndPlaceSubtitle = "从日期和地点继续整理"
    }

    public enum Review {
        public static let decisionHint = "向上保留，向下放入预删除篮。"
        public static let keep = "保留"
        public static let preDelete = "放入预删除篮"
        public static let skip = "跳过"
        public static let metadataNoGroup = "无"
        public static let noLocation = "无地点"
        public static let nearbyPlace = "附近地点"
        public static func similarGroupPosition(_ position: String) -> String {
            "相似组 \(position)"
        }
    }

    public enum Similar {
        public static let keepOne = "保留 1 张"
        public static let keepMany = "保留多张"
        public static let suggestedKeep = "推荐保留"
        public static let footerExplanation = "未选照片会进入预删除篮，最终确认前仍可恢复。"
        public static let emptyTitle = "暂无相似照片组"
        public static let emptyMessage = "Picko 还没有发现需要成组复核的相似照片。你可以重新扫描图库，或先进行单张整理。"
        public static let rescan = "重新扫描图库"
        public static let goReview = "去单张整理"
    }

    public enum Basket {
        public static let savingsOverview = "空间预估"
        public static let totalSavings = "总计节省"
        public static let review = "复核"
        public static let similarGroup = "相似组"
        public static let singleReview = "单张复核"
        public static let itemSectionTitle = "待确认项目"
        public static let itemSectionSubtitle = "这些照片仍在系统相册中，只是被 Picko 标记为等待最终确认。"
        public static let emptyTitle = "预删除篮为空"
        public static let emptyMessage = "复核时放入预删除篮的照片会先在这里等待最终确认。"
        public static let primaryAction = "在系统照片中确认删除"
        public static let secondaryAction = "最终确认前可恢复或全部移出"
        public static let clear = "全部移出预删除篮"
        public static let restore = "恢复"
        public static let restoreItem = "恢复此项"
        public static let closePreview = "关闭"
        public static let previewTitle = "预删除项预览"
        public static let fromReviewFlow = "来自整理流程"
        public static let sampleLibraryDisabledReason = "当前为样例图库，无法调用系统照片确认。"
        public static let emptyDisabledReason = "预删除篮为空，暂无需要确认的项目。"
        public static let confirmingDisabledReason = "正在等待系统照片确认。"
        public static let confirmationTitle = "交由系统照片确认？"
        public static let finalActionTitle = "最终确认"
        public static let finalActionMessage = "确认前可以继续恢复单张照片，或把全部项目移出预删除篮。"
        public static let clearConfirmationTitle = "全部移出预删除篮？"
        public static let clearConfirmationMessage = "这不会删除系统照片，只会清空 Picko 本地预删除队列。"
        public static let clearConfirmationAction = "移出全部"
        public static let continueAction = "继续"
        public static let cancelAction = "取消"

        public static func summaryTitle(count: Int) -> String {
            "\(count) 项等待最终复核"
        }

        public static func summarySubtitle(bytes: Int64) -> String {
            "预计可节省：\(byteText(bytes))"
        }
    }

    public enum LibraryAccess {
        public static let deniedTitle = "需要照片图库权限才能开始整理。"
        public static let deniedMessage = "你仍然可以先进入样例图库，查看完整复核流程和预删除篮确认边界。"
        public static let sampleLibrary = "先查看样例图库"
    }

    public static func byteText(_ bytes: Int64) -> String {
        guard bytes > 0 else {
            return "0 字节"
        }

        if bytes < 1024 {
            return "\(bytes) 字节"
        }

        let units = ["KB", "MB", "GB", "TB"]
        var value = Double(bytes) / 1024
        var unitIndex = 0

        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        let rounded = (value * 10).rounded() / 10
        if rounded.rounded() == rounded {
            return "\(Int(rounded)) \(units[unitIndex])"
        }
        return String(format: "%.1f %@", rounded, units[unitIndex])
    }
}
