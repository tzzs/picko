import XCTest

final class PickoUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-library"]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
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

        XCTAssertTrue(app.navigationBars["预删除篮"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 项等待最终复核"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["交由系统照片确认"].isEnabled)
        XCTAssertTrue(app.staticTexts["当前为样例图库，无法调用系统照片确认。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["清空预删除篮"].isEnabled)
    }

    func testSampleBasketDoesNotExposeGlobalClearStateAction() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-basket"]
        app.launch()

        XCTAssertTrue(app.navigationBars["预删除篮"].waitForExistence(timeout: 5))
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
