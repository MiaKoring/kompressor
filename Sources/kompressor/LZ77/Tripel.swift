//
//  Untitled.swift
//  kompressor
//
//  Created by Mia Koring on 01.07.25.
//

import Foundation

struct Tripel: Equatable {
    static func == (lhs: Tripel, rhs: Tripel) -> Bool {
        lhs.length == rhs.length && lhs.offset == rhs.offset && lhs.nextByte == rhs.nextByte
    }
    
    let offset: UInt16?
    let length: UInt8?
    let nextByte: UInt8?
    
    init(_ offset: UInt16?, _ length: UInt8?, _ nextByte: UInt8?) {
        self.offset = offset
        self.length = length
        self.nextByte = nextByte
    }
    
    init(offset: UInt16?, length: UInt8?, nextByte: UInt8?) {
        self.offset = offset
        self.length = length
        self.nextByte = nextByte
    }
    
    init(offset: Int, length: Int, nextByte: UInt8?) {
        let offset = UInt16(offset)
        self.offset = offset
        let length = UInt8(length)
        self.length = length
        self.nextByte = nextByte
    }
}
