import XCTest

final class PickoUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-library"]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }

    func testSampleReviewUsesGestureFirstChrome() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-review"]
        app.launch()

        XCTAssertTrue(app.staticTexts["向上保留"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["向下预删除"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["上一张"].exists)
        XCTAssertTrue(app.buttons["设置"].exists)
        XCTAssertFalse(app.buttons["跳过"].exists)
        XCTAssertFalse(app.buttons["保留"].exists)
        XCTAssertFalse(app.buttons["预删除"].exists)
    }

    func testEmptySampleReviewKeepsUnifiedHeaderChrome() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-empty-review"]
        app.launch()

        XCTAssertTrue(app.staticTexts["top-level-title-复核"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["暂无待复核照片"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["设置"].exists)
        XCTAssertTrue(app.buttons["返回首页"].exists)

        app.buttons["返回首页"].tap()

        XCTAssertTrue(app.staticTexts["top-level-title-拾影"].waitForExistence(timeout: 5))
    }

    func testSampleSimilarUsesInlineSelectionControls() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-similar"]
        app.launch()

        XCTAssertTrue(app.staticTexts["相似组整理"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["其他相似照片"].waitForExistence(timeout: 5))

        let firstSimilarPhoto = app.buttons["选择相似照片 preview-1"]
        let secondSimilarPhoto = app.buttons["选择相似照片 preview-2"]
        XCTAssertTrue(firstSimilarPhoto.waitForExistence(timeout: 5))
        XCTAssertTrue(secondSimilarPhoto.waitForExistence(timeout: 5))
        XCTAssertEqual(firstSimilarPhoto.value as? String, "已选择")
        XCTAssertEqual(secondSimilarPhoto.value as? String, "未选择")
        XCTAssertTrue(app.buttons["全选"].exists)
        XCTAssertFalse(app.buttons["取消全选"].exists)

        secondSimilarPhoto.tap()

        XCTAssertEqual(firstSimilarPhoto.value as? String, "已选择")
        XCTAssertEqual(secondSimilarPhoto.value as? String, "已选择")
        XCTAssertTrue(app.buttons["恢复推荐"].exists)
        XCTAssertFalse(app.buttons["取消全选"].exists)

        app.scrollViews.firstMatch.swipeUp()

        XCTAssertTrue(app.staticTexts["已选择 2 张 · 其余将进入预删除篮"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["确认选择"].exists)
        XCTAssertTrue(app.buttons["恢复推荐"].exists)
        XCTAssertFalse(app.staticTexts["选择确认"].exists)
        XCTAssertFalse(app.buttons["保留推荐"].exists)
        XCTAssertFalse(app.buttons["保留所选"].exists)
    }

    func testMetadataBenchmarkSyntheticLaunches() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--picko-run-metadata-benchmark",
            "--picko-benchmark-synthetic",
            "--picko-benchmark-counts=10"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Metadata Benchmark"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["metadata-benchmark-result-10"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["metadata-benchmark-summary"].waitForExistence(timeout: 5))
    }

    func testSampleBasketShowsReviewedItemsWithoutPhotosConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-basket"]
        app.launch()

        XCTAssertTrue(app.staticTexts["最终确认"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 项等待最终复核"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["预计可节省：3.7 MB"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["在系统照片中确认删除"].isEnabled)
        XCTAssertTrue(app.staticTexts["当前为样例图库，无法调用系统照片确认。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["全部移出预删除篮"].isEnabled)
        XCTAssertFalse(app.staticTexts["空间预估"].exists)
        XCTAssertFalse(app.buttons["交由系统照片确认"].exists)
        XCTAssertFalse(app.buttons["清空预删除篮"].exists)
        XCTAssertTrue(app.staticTexts["待确认项目"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["相似组"].exists)
        XCTAssertFalse(app.staticTexts["单张复核"].exists)
    }

    func testEmptySampleBasketLaunchesDirectlyToEmptyBasketState() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-empty-basket"]
        app.launch()

        XCTAssertTrue(app.staticTexts["top-level-title-预删除篮"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["预删除篮为空"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["复核时放入预删除篮的照片会先在这里等待最终确认。"].exists)
        XCTAssertFalse(app.buttons["在系统照片中确认删除"].exists)
        XCTAssertFalse(app.buttons["全部移出预删除篮"].exists)
    }

    func testSampleBasketConfirmsBeforeClearingQueue() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-basket"]
        app.launch()

        XCTAssertTrue(app.buttons["全部移出预删除篮"].waitForExistence(timeout: 5))
        app.buttons["全部移出预删除篮"].tap()

        XCTAssertTrue(app.staticTexts["全部移出预删除篮？"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["这不会删除系统照片，只会清空 Picko 本地预删除队列。"].exists)
        XCTAssertTrue(app.buttons["移出全部"].exists)
    }

    func testSampleBasketOpensRestoreOnlyPreview() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-basket"]
        app.launch()

        XCTAssertTrue(app.buttons["查看预删除项目 preview-1"].waitForExistence(timeout: 5))
        app.buttons["查看预删除项目 preview-1"].tap()

        XCTAssertTrue(app.navigationBars["预删除项预览"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["恢复此项"].exists)
        XCTAssertTrue(app.buttons["关闭"].exists)
        XCTAssertFalse(app.buttons["放入预删除篮"].exists)
    }

    func testSampleBasketDoesNotExposeGlobalClearStateAction() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-basket"]
        app.launch()

        XCTAssertTrue(app.staticTexts["最终确认"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["clear-picko-state-toolbar-button"].exists)
    }

    func testDeniedLibraryShowsFallbackAction() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-denied-library"]
        app.launch()

        XCTAssertTrue(app.staticTexts["需要照片图库权限才能开始整理。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["先查看样例图库"].waitForExistence(timeout: 5))
    }
}
