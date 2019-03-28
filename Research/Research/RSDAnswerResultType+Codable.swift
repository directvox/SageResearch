//
//  RSDAnswerResultType+Codable.swift
//  Research
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

import Foundation

// MARK: Value Decoding
extension RSDAnswerResultType {
    
    /// Decode a `RSDJSONValue` from the given decoder.
    ///
    /// - parameter decoder: The decoder that holds the value.
    /// - returns: The decoded value or `nil` if the value is not present.
    /// - throws: `DecodingError` if the encountered stored value cannot be decoded.
    public func decodeValue(from decoder:Decoder) throws -> RSDJSONValue? {
        // Look to see if the decoded value is nil and exit early if that is the case.
        if let nilContainer = try? decoder.singleValueContainer(), nilContainer.decodeNil() {
            return nil
        }
        
        if let sType = sequenceType {
            switch sType {
            case .array:
                do {
                    var values: [RSDJSONValue] = []
                    var container = try decoder.unkeyedContainer()
                    while !container.isAtEnd {
                        let value = try _decodeSingleValue(from: container.superDecoder())
                        values.append(value)
                    }
                    return values
                } catch DecodingError.typeMismatch(let type, let context) {
                    // If attempting to get an array fails, then look to see if this is a single String value
                    if sType == .array, let separator = self.sequenceSeparator {
                        let container = try decoder.singleValueContainer()
                        let strings = try container.decode(String.self).components(separatedBy: separator)
                        return try strings.map { try _decodeStringValue(from: $0, decoder: decoder) }
                    }
                    else {
                        throw DecodingError.typeMismatch(type, context)
                    }
                }
                
            case .dictionary:
                var values: [String : RSDJSONValue] = [:]
                let container = try decoder.container(keyedBy: AnyCodingKey.self)
                for key in container.allKeys {
                    let nestedDecoder = try container.superDecoder(forKey: key)
                    let value = try _decodeSingleValue(from: nestedDecoder)
                    values[key.stringValue] = value
                }
                return values
            }
        }
        else {
            return try _decodeSingleValue(from: decoder)
        }
    }
    
    private func _decodeStringValue(from string: String, decoder: Decoder) throws -> RSDJSONValue {
        switch baseType {
        case .boolean:
            return (string as NSString).boolValue
            
        case .data:
            guard let data = Data(base64Encoded: string) else {
                throw DecodingError.typeMismatch(Data.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(string) is not a valid base64 encoded string."))
            }
            return data
            
        case .decimal:
            return (string as NSString).doubleValue
            
        case .integer:
            return (string as NSString).integerValue
            
        case .string, .codable:
            return string
            
        case .date:
            return try decoder.factory.decodeDate(from: string, formatter: self.dateFormatter, codingPath: decoder.codingPath)
        }
    }
    
    private func _decodeSingleValue(from decoder: Decoder) throws -> RSDJSONValue {
        
        // special-case the ".codable" type to return a dictionary
        if baseType == .codable {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            return try container.rsd_decode(Dictionary<String, Any>.self)
        }
        
        // all other types are single value
        let container = try decoder.singleValueContainer()
        switch baseType {
        case .boolean:
            return try container.decode(Bool.self)
            
        case .data:
            return try container.decode(Data.self)
            
        case .decimal:
            return try container.decode(Double.self)
            
        case .integer:
            return try container.decode(Int.self)
            
        case .string:
            return try container.decode(String.self)
            
        case .date:
            if self.dateFormat != nil {
                let string = try container.decode(String.self)
                return try decoder.factory.decodeDate(from: string, formatter: dateFormatter, codingPath: decoder.codingPath)
            }
            else {
                return try container.decode(Date.self)
            }
        case .codable:
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not decode a Codable to a single value container.")
            throw DecodingError.typeMismatch(Dictionary<String, Any>.self, context)
        }
    }
    
    private func _decodeDate(from string: String, codingPath: [CodingKey]) throws -> Date {
        guard let date = decodeDate(from: string) else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Could not decode \(string) as a Date.")
            throw DecodingError.typeMismatch(Date.self, context)
        }
        return date
    }
    
    public func decodeDate(from string: String) -> Date? {
        guard let format = self.dateFormat else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: string)
    }
}

// MARK: Value Encoding
extension RSDAnswerResultType {
    
    /// Encode a value to the given encoder.
    ///
    /// - parameters:
    ///     - value: The value to encode.
    ///     - encoder: The encoder to mutate.
    /// - throws: `EncodingError` if the value cannot be encoded.
    public func encode(_ value: Any?, to encoder: Encoder) throws {
        guard let obj = value, !(obj is NSNull) else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            return
        }
        
        if let sType = self.sequenceType {
            switch sType {
            case .array:
                guard let array = obj as? [Any] else {
                    throw EncodingError.invalidValue(obj, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "\(obj) is not expected type. Expecting an Array."))
                }
                
                if let separator = self.sequenceSeparator {
                    let strings = try array.map { (object) -> String in
                        guard let string = try _encodableString(object, encoder: encoder) else {
                            throw EncodingError.invalidValue(object, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "\(object) cannot be converted to a \(self.baseType) encoded value."))
                        }
                        return string
                    }
                    let encodable = strings.joined(separator: separator)
                    try encodable.encode(to: encoder)
                }
                else {
                    var nestedContainer = encoder.unkeyedContainer()
                    for object in array {
                        let nestedEncoder = nestedContainer.superEncoder()
                        try _encode(object, to: nestedEncoder)
                    }
                }
                
            case .dictionary:
                guard let dictionary = obj as? NSDictionary else {
                    throw EncodingError.invalidValue(obj, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "\(obj) is not expected type. Expecting a Dictionary."))
                }
                
                var nestedContainer = encoder.container(keyedBy: AnyCodingKey.self)
                for (key, object) in dictionary {
                    let nestedEncoder = nestedContainer.superEncoder(forKey: AnyCodingKey(stringValue: "\(key)")!)
                    try _encode(object, to: nestedEncoder)
                }
            }
        }
        else {
            try _encode(obj, to: encoder)
        }
    }
    
    private func _encodableString(_ value: Any, encoder: Encoder) throws -> String? {
        if let date = try _convertDate(value: value, codingPath: encoder.codingPath) {
            return _convertDateToString(date: date, encoder: encoder)
        }
        else if baseType == .data, let data = value as? Data {
            return RSDFactory.shared.encodeString(from: data, codingPath: encoder.codingPath)
        }
        else {
            return "\(value)"
        }
    }
    
    private func _encode(_ value: Any, to encoder: Encoder) throws {
        
        if baseType == .codable {
            guard let encodable = value as? Encodable else {
                let context = EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "\(value) does not conform to the encodable protocol.")
                throw EncodingError.invalidValue(value, context)
            }
            try encodable.encode(to: encoder)
        }
        else if baseType == .data, let data = value as? Data {
            var container = encoder.singleValueContainer()
            try container.encode(data)
        }
        else if let obj = value as? NSNumber {
            var container = encoder.singleValueContainer()
            switch baseType {
            case .boolean:
                try container.encode(obj.boolValue)
            case .decimal:
                try container.encode(obj.doubleValue)
            case .integer:
                try container.encode(obj.intValue)
            case .string:
                try container.encode("\(obj)")
            default:
                let context = EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "\(value) cannot be converted from a number to \(baseType).")
                throw EncodingError.invalidValue(value, context)
            }
        }
        else if let obj = value as? NSString {
            var container = encoder.singleValueContainer()
            switch baseType {
            case .boolean:
                try container.encode(obj.boolValue)
            case .decimal:
                try container.encode(obj.doubleValue)
            case .integer:
                try container.encode(obj.intValue)
            default:
                try container.encode(obj as String)
            }
        }
        else if let date = try _convertDate(value: value, codingPath: encoder.codingPath) {
            var container = encoder.singleValueContainer()
            if dateFormat != nil ||  baseType == .string {
                let str = _convertDateToString(date: date, encoder: encoder)
                try container.encode(str)
            } else {
                try container.encode(date)
            }
        }
        else if baseType == .string {
            var container = encoder.singleValueContainer()
            try container.encode("\(value)")
        }
        else {
            let context = EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "\(value) cannot be converted to a codable of \(baseType).")
            throw EncodingError.invalidValue(value, context)
        }
    }
    
    func _convertDate(value: Any, codingPath: [CodingKey]) throws -> Date? {
        // This method is only used to convert dates and date components. Exit early if that does not apply.
        guard (value is Date) || (value is DateComponents),
            let date = (value as? Date) ?? Calendar(identifier: .iso8601).date(from: (value as! DateComponents))
            else {
                return nil
        }
        
        // If a date is found, need to convert to a string or date. Otherwise, that is an error.
        guard baseType == .date || baseType == .string else {
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: "\(value) cannot be converted from a date to \(baseType).")
            throw EncodingError.invalidValue(value, context)
        }
        
        return date
    }
    
    func _convertDateToString(date: Date, encoder: Encoder) -> String {
        if let format = dateFormat {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: date)
        } else {
            return RSDFactory.shared.encodeString(from: date, codingPath: encoder.codingPath)
        }
    }
}
