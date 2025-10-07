//
//  TetrisAppUITests.swift
//  TetrisAppUITests
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//

import XCTest

final class TetrisAppUITests: XCTestCase {
    
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
        app.activate()
        app.buttons["New Game"].firstMatch.tap()
        
        app.buttons["arrow.right"].firstMatch.tap()
        app.buttons["arrow.down"].firstMatch.tap()
        
        app.buttons["arrow.left"].firstMatch.tap()
        
        app.buttons["arrow.clockwise"].firstMatch.tap()
        
        app.buttons["Pause"].firstMatch.tap()
        app.buttons["Resume"].firstMatch.tap()
        app.buttons["Toggle sound"].firstMatch.tap()
        app.buttons["arrow.down"].firstMatch.tap()
                    
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
