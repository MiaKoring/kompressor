//
//  Decompress.swift
//  kompressor
//
//  Created by Mia Koring on 01.07.25.
//


import ArgumentParser
import Foundation

struct LZ77Decompress: ParsableCommand {
    typealias E = DecompressionError
    
    @Argument(help: "Path to the file to decompress.")
    var originPath: String
    
    @Option(name: .shortAndLong, help: "The output file destination.")
    var destination: String?
    
    mutating func run() throws {
        guard let data = FileManager.default.contents(atPath: originPath) else {
            throw E.invalidOriginPath
        }
        
        let reconstructed = try decompress(data)
        
        let originURL = URL(fileURLWithPath: originPath)
        let pathWithoutExtension = originURL.deletingPathExtension().path
        let destinationPath = destination ?? pathWithoutExtension + ".lzdekompressort"
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        do {
            try reconstructed.write(to: destinationURL)
            print("Successfully decompressed file to \(destinationPath)")
        } catch {
            throw E.writeFailed(path: destinationPath, underlyingError: error)
        }
    }
    
    func decompress(_ data: Data) throws -> Data {
        var bitReader = BitReader(data: data)
        
        var originalData = [UInt8]()
        
        while bitReader.remainingBits >= 9 {
            guard let isTripel = bitReader.readBit() else { throw E.internalError(description: "Unexpectedly found nil while reading data")}
            if isTripel {
                guard let storedOffset = bitReader.readBits(count: LZ77Compress.offsetBits),
                      let storedLength = bitReader.readBits(count: LZ77Compress.lengthBits) else {
                    throw E.invalidEncoding
                }
                let offset = Int(storedOffset) + 1
                let length = Int(storedLength) + LZ77Compress.minMatchLength
                
                let copyStartIndex = originalData.count - offset
                guard copyStartIndex >= 0 else { throw E.invalidEncoding }
                
                for i in 0..<length {
                    let byteToCopy = originalData[copyStartIndex + i]
                    originalData.append(byteToCopy)
                }
            } else {
                guard let byte = bitReader.readByte() else { throw E.invalidEncoding }
                originalData.append(byte)
            }
        }
        
        return Data(originalData)
    }
    
    enum DecompressionError: Error, CustomStringConvertible {
        case invalidOriginPath
        case invalidEncoding
        case internalError(description: String)
        case writeFailed(path: String, underlyingError: Error)
        
        var description: String {
            switch self {
            case .invalidOriginPath:
                "The provided 'origin-path' argument is not a valid path."
            case .invalidEncoding:
                "The file content is not a valid kompressor lz77 output"
            case .writeFailed(let path, let error):
                "Failed to write to destination path '\(path)'. Reason: \(error.localizedDescription)"
            case .internalError(let description):
                "An internal Error occured: \(description)"
            }
        }
        
        var localizedDescription: String {
            return self.description
        }
    }
}
