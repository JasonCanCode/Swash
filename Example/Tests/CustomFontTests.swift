//
//  CustomFontTests.swift
//  Swash_Tests
//
//  Created by Sam Francis on 7/21/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import Swash

class CustomFontTests: XCTestCase {
    
    //MARK: - Of Size
    
    func testOfSize() {
        guard let font = Avenir.roman.of(size: 23) else {
            return XCTFail("Avenir font failed to initialize.")
        }
        XCTAssertEqual(font.pointSize, 23)
        XCTAssertEqual(font.fontName, "Avenir-Roman")
    }
    
    func testInvalidOfSize() {
        XCTAssertNil(InvalidFont.doesNotExist.of(size: 12))
    }
    
    //MARK: - Dynamic Type
    
    func testOfTextStyle() {
        XCTAssertNotNil(Avenir.blackOblique.of(textStyle: .title1))
    }
    
    func testOfTextStyleMax() {
        XCTAssertNotNil(Avenir.light.of(textStyle: .title2, maxSize: 30))
    }
    
    func testOfTextStyleMaxDefault() {
        XCTAssertNotNil(Futura.condensedMedium.of(textStyle: .body, maxSize: 30, defaultSize: 17))
    }
    
    func testInvalidOfTextStyle() {
        XCTAssertNil(InvalidFont.doesNotExist.of(textStyle: .footnote))
    }
    
    //MARK: - Dynamic Type - Deprecated in iOS 11
    
    func testOfStyle() {
        XCTAssertNotNil(Futura.medium.of(style: .title3))
    }
    
    func testOfStyleMax() {
        XCTAssertNotNil(Futura.medium.of(style: .title3, maxSize: 10))
    }
    
    func testInvalidOfStyle() {
        XCTAssertNil(InvalidFont.doesNotExist.of(style: .caption1))
    }
    
    //MARK: - Log Boilerplate
    
    func testLogBoilerplate() {
        Swash.logBoilerplate()
    }
    
}
