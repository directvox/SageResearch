//
//  CodableTrackedDataTests.swift
//  ResearchTests_iOS
//
//  Copyright © 2017-2018 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import XCTest
@testable import Research

class CodableTrackedDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // Cohort
    
    func testCohortNavigationRuleObject_Codable() {
        let json = """
        {
            "requiredCohorts": ["foo","goo"],
            "operator": "all",
            "skipToIdentifier": "end"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(RSDCohortNavigationRuleObject.self, from: json)
            
            XCTAssertEqual(object.requiredCohorts, ["foo","goo"])
            XCTAssertEqual(object.cohortOperator, .all)
            XCTAssertEqual(object.skipToIdentifier, "end")
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["operator"] as? String, "all")
            XCTAssertEqual(dictionary["skipToIdentifier"] as? String, "end")
            if let requiredCohorts = dictionary["requiredCohorts"] as? [String] {
                XCTAssertEqual(Set(requiredCohorts), Set(["foo","goo"]))
            } else {
                XCTFail("Failed to encode the required cohorts: \(String(describing: dictionary["requiredCohorts"]))")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testCohortNavigationRuleObject_Codable_Default() {
        let json = """
        {
            "requiredCohorts": ["foo","goo"],
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(RSDCohortNavigationRuleObject.self, from: json)
            
            XCTAssertEqual(object.requiredCohorts, ["foo","goo"])
            XCTAssertNil(object.cohortOperator)
            XCTAssertNil(object.skipToIdentifier)
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    // WeeklyScheduleItem
    
    func testWeeklyScheduleItem_Codable() {
        let json = """
        {
            "daysOfWeek": [1,3,5],
            "timeOfDay": "08:15"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDWeeklyScheduleObject.self, from: json)
            
            XCTAssertEqual(object.daysOfWeek, [.sunday, .tuesday, .thursday])
            XCTAssertEqual(object.timeComponents?.hour, 8)
            XCTAssertEqual(object.timeComponents?.minute, 15)
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["timeOfDay"] as? String, "08:15")
            if let daysOfWeek = dictionary["daysOfWeek"] as? [Int] {
                XCTAssertEqual(Set(daysOfWeek), Set([1,3,5]))
            } else {
                XCTFail("Failed to encode the daysOfWeek: \(String(describing: dictionary["daysOfWeek"]))")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testWeeklyScheduleItem_Codable_HourOnly() {
        let json = """
        {
            "daysOfWeek": [1,3,5],
            "timeOfDay": "08:00"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDWeeklyScheduleObject.self, from: json)
            
            XCTAssertEqual(object.daysOfWeek, [.sunday, .tuesday, .thursday])
            XCTAssertEqual(object.timeComponents?.hour, 8)
            XCTAssertEqual(object.timeComponents?.minute, 0)
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["timeOfDay"] as? String, "08:00")
            if let daysOfWeek = dictionary["daysOfWeek"] as? [Int] {
                XCTAssertEqual(Set(daysOfWeek), Set([1,3,5]))
            } else {
                XCTFail("Failed to encode the daysOfWeek: \(String(describing: dictionary["daysOfWeek"]))")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testWeeklyScheduleItem_Codable_Default() {
        let json = """
        {
            "daysOfWeek": [1,3,5]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(RSDWeeklyScheduleObject.self, from: json)
            
            XCTAssertEqual(object.daysOfWeek, [.sunday, .tuesday, .thursday])
            XCTAssertNil(object.timeOfDay)
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
}
