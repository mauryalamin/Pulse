//
//  PulseUITests.swift
//  PulseUITests
//
//  Created by Maury Alamin on 5/7/25.
//

import XCTest

final class PulseUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testFaceIDEnabledShortBackgroundDoesNotGetStuckLocked() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-isOnboarding", "NO",
            "-useBiometrics", "YES",
            "UITEST_BYPASS_BIOMETRICS"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Moments"].waitForExistence(timeout: 5))

        XCUIDevice.shared.press(.home)
        app.activate()

        let lockMessage = app.staticTexts["Unlocking with Face ID..."]
        XCTAssertFalse(lockMessage.waitForExistence(timeout: 2))
        XCTAssertTrue(app.navigationBars["Moments"].waitForExistence(timeout: 5))
    }
}
