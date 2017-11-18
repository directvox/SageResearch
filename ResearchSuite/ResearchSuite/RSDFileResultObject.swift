//
//  RSDFileResultObject.swift
//  ResearchSuite
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

import Foundation

/// `RSDFileResultObject` is a concrete implementation of a result that holds a pointer to a file url.
public struct RSDFileResultObject : RSDFileResult, Codable {
    
    /// The identifier associated with the task, step, or asynchronous action.
    public let identifier: String
    
    /// A String that indicates the type of the result. This is used to decode the result using a `RSDFactory`.
    public let type: RSDResultType
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// The system clock uptime when the recorder was started (if applicable).
    public var startUptime: TimeInterval?
    
    /// The URL with the path to the file-based result.
    public var url: URL?
    
    private enum CodingKeys : String, CodingKey {
        case identifier, type, startDate, endDate, startUptime, url
    }
    
    /// Default initializer for this object.
    ///
    /// - parameters:
    ///     - identifier: The identifier string.
    ///     - type: The `RSDResultType` for this result. Default = `.file`.
    public init(identifier: String, type: RSDResultType = .file) {
        self.identifier = identifier
        self.type = type
    }
}

extension RSDFileResultObject : RSDDocumentableDecodableObject {
    
    static func codingMap() -> Array<(CodingKey, Any.Type, String)> {
        let codingKeys: [CodingKeys] = [.identifier, .type, .startDate, .endDate, .startUptime, .url]
        return codingKeys.map {
            switch $0 {
            case .identifier:
                return ($0, String.self, "The identifier associated with the task, step, or asynchronous action.")
            case .type:
                return ($0, RSDResultType.self, "A String that indicates the type of the result. This is used to decode the result using a `RSDFactory`.")
            case .startDate:
                return ($0, Date.self, "The start date timestamp for the result.")
            case .endDate:
                return ($0, Date.self, "The end date timestamp for the result.")
            case .startUptime:
                return ($0, TimeInterval.self, "The system clock uptime when the recorder was started (if applicable).")
            case .url:
                return ($0, URL.self, "The URL with the path to the file-based result.")
            }
        }
    }
    
    static func exampleResult() -> RSDFileResultObject {
        var fileResult = RSDFileResultObject(identifier: "fileResult")
        fileResult.startDate = RSDClassTypeMap.shared.timestampFormatter.date(from: "2017-10-16T22:28:09.000-07:00")!
        fileResult.endDate = fileResult.startDate.addingTimeInterval(5 * 60)
        fileResult.startUptime = 1234.567
        fileResult.url = URL(fileURLWithPath: "temp.json")
        return fileResult
    }
    
    static func examples() -> [Encodable] {
        let fileResult = exampleResult()
        return [fileResult]
    }
}
