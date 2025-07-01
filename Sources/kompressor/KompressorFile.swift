//
//  KompressorFile.swift
//  kompressor
//
//  Created by Mia Koring on 21.06.25.
//
import Foundation

struct KompressorFile: Codable {
    ///header
    let h: Header
    ///body
    let b: Data
    struct Header: Codable {
        ///padding
        let p: Int
        ///huffman root node
        let t: Data
    }
}
