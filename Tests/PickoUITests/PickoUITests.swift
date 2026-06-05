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

        XCTAssertTrue(app.navigationBars["Basket"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 item waiting for final review"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Confirm with Photos"].isEnabled)
        XCTAssertTrue(app.buttons["Clear basket"].isEnabled)
    }

    func testSampleBasketCanClearPickoReviewStateWithoutPhotosConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-sample-basket"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Basket"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 item waiting for final review"].waitForExistence(timeout: 5))

        app.buttons["clear-picko-state-toolbar-button"].tap()
        XCTAssertTrue(app.buttons["Clear Picko state"].waitForExistence(timeout: 5))
        app.buttons["Clear Picko state"].tap()

        XCTAssertTrue(
            app.staticTexts["0 items waiting for final review"].waitForExistence(timeout: 5),
            app.debugDescription
        )
        XCTAssertFalse(app.buttons["Confirm with Photos"].isEnabled)
    }

    func testDeniedLibraryShowsFallbackAction() {
        let app = XCUIApplication()
        app.launchArguments = ["--picko-use-denied-library"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Photo library access is needed to review your library."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Review Sample Library"].waitForExistence(timeout: 5))
    }
}
