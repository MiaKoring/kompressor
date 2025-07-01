//
//  Compress.swift
//  kompressor
//
//  Created by Mia Koring on 01.07.25.
//


import ArgumentParser
import Foundation

struct LZ77Compress: ParsableCommand {
    typealias E = CompressionError
    typealias LZ77 = Self
    
    @Argument(help: "Path to the file to compress.")
    var originPath: String
    
    @Option(name: .shortAndLong, help: "The output file destination.")
    var destination: String?
    
    static let searchBufferSize = 32768
    static let previewBufferSize = 255 + Self.minMatchLength
    static let minMatchLength = 3
    
    static let offsetBits = 15
    static let lengthBits = 8
    
    static let maxChainLength = 256 //prevent iterating over too long chains
    
    mutating func run() throws {
        guard let data = FileManager.default.contents(atPath: originPath) else {
            throw E.invalidOriginPath
        }
        
        let compressedOutput = try compressV3(data)
        
        // If compression was aborted, the output will be the same as the input.
        // We can avoid writing the file in that case.
        guard compressedOutput.count < data.count else {
            print("Compression would not reduce file size. No output file was written.")
            return
        }
        
        let originURL = URL(fileURLWithPath: originPath)
        let pathWithoutExtension = originURL.deletingPathExtension().path
        let destinationPath = destination ?? pathWithoutExtension + ".lzkompressor"
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        do {
            try compressedOutput.write(to: destinationURL)
            print("Successfully compressed file to \(destinationPath)")
        } catch {
            throw E.writeFailed(path: destinationPath, underlyingError: error)
        }
    }
    
    func compressV3(_ data: Data) throws -> Data {
        guard data.count > 6 else { throw E.tooFewCharacters }
        let data = [UInt8](data)
        var index = 0
        var bitWriter = BitWriter()
        
        //stores last index for a given hash
        var head = [Int?](repeating: nil, count: 65537)
        //stores previous index for every index
        var prevChain = [Int?](repeating: nil, count: data.count)
        
        while index < data.count - LZ77.minMatchLength {
            
            let chainHeadIndex = updateChain(index: index, head: &head, prevChain: &prevChain)
                        
            //find best match
            var bestMatchOffset = 0
            var bestMatchLength = 0
            
            //start search at chain head
            var currentChainNodeIndex: Int? = chainHeadIndex
            var chainDepth = 0
            
            while let currentChainIndex = currentChainNodeIndex,
                  chainDepth < LZ77.maxChainLength {
                
                //check if candidate is in valid search window, defined by LZ77.searchBufferSize
                let offset = index - currentChainIndex
                if offset > LZ77.searchBufferSize { break } //would be too big for our offset limit
                
                //byte by byte comparison to find actual match length
                var currentMatchLength = 0
                while currentMatchLength < LZ77.previewBufferSize,  //ensure we stay in bit limit
                      index + currentMatchLength < data.count,      //ensure we stay in bounds of data
                      currentChainIndex + currentMatchLength < data.count,
                      data[currentChainIndex + currentMatchLength] == data[index + currentMatchLength] { //compare slice from "preview buffer" to slice from "search buffer"
                    currentMatchLength += 1
                }
                
                //check if this match is better than our previous best
                if currentMatchLength > bestMatchLength {
                    bestMatchLength = currentMatchLength
                    bestMatchOffset = offset
                }
                
                //jump to next node in chain
                currentChainNodeIndex = prevChain[currentChainIndex]
                chainDepth += 1
            }
            
            //process result
            if bestMatchLength >= LZ77.minMatchLength && bestMatchOffset != 0 {
                for i in 1..<bestMatchLength {
                    let hashStartIndex = index + i
                    if hashStartIndex <= data.count - LZ77.minMatchLength {
                        _ = updateChain(index: hashStartIndex, head: &head, prevChain: &prevChain)
                    }
                }
                
                bitWriter.write(bit: true)
                bitWriter.write(bits: UInt(bestMatchOffset - 1), count: LZ77.offsetBits)
                bitWriter.write(bits: UInt(bestMatchLength - Self.minMatchLength), count: LZ77.lengthBits)
                
                index += bestMatchLength
            } else {
                try writeLiteral(index: index, data: data, bitWriter: &bitWriter)
                index += 1
            }
        }
        
        while index < data.count {
            try writeLiteral(index: index, data: data, bitWriter: &bitWriter)
            index += 1
        }
        
        return bitWriter.getData().data
        
        func writeLiteral(index: Int, data: [UInt8], bitWriter: inout BitWriter) throws {
            guard let byte = data[index, default: nil] else { throw E.internalError(description: "Unexpectedly found empty literal")}
            bitWriter.write(bit: false)
            bitWriter.write(bits: UInt(byte), count: 8)
        }
        
        func calculateHash(for bytes: ArraySlice<UInt8>) -> Int {
            if bytes.count < 3 { return 0 }
            let val = (UInt(bytes[bytes.startIndex]) << 16) | (UInt(bytes[bytes.startIndex + 1]) << 8) | UInt(bytes[bytes.startIndex + 2])
            return Int(val % UInt(65537))
        }
        
        func updateChain(index: Int, head: inout [Int?], prevChain: inout [Int?]) -> Int? {
            guard index + 3 < data.count else { return nil }
            let sequenceToHash = data[index ..< index + 3]
            let hash = calculateHash(for: sequenceToHash)
            
            //get chain head for hash
            let chainHeadIndex = head[hash]
            
            //connext current position with old head
            prevChain[index] = chainHeadIndex
            
            //make current position new head of chain
            head[hash] = index
            
            return chainHeadIndex
        }
    }
    
    
    func compressV2(_ data: Data) throws -> Data {
        let data = [UInt8](data)
        var index = 0
        var bitWriter = BitWriter()
        while index < data.count {
            let searchBufferStart = max(0, index - LZ77.searchBufferSize)
            let searchBufferEnd = index
            let searchBuffer = data[searchBufferStart..<searchBufferEnd]
            
            let lookaheadBufferEnd = min(data.count, index + LZ77.previewBufferSize)
            let lookaheadBuffer = data[index..<lookaheadBufferEnd]
            
            var bestMatchOffset = 0
            var bestMatchLength = 0
            
            for matchLength in stride(from: lookaheadBuffer.count, through: 1, by: -1) {
                let prefix = lookaheadBuffer.prefix(matchLength)
                if let match = searchBuffer.lastRange(of: prefix) {
                    bestMatchOffset = searchBuffer.endIndex  - match.lowerBound
                    bestMatchLength = matchLength
                    break
                }
            }
            if bestMatchLength >= LZ77.minMatchLength && bestMatchOffset != 0 {
                let nextByte = data[index + bestMatchLength, default: nil]
                
                bitWriter.write(bit: true)
                bitWriter.write(bits: UInt(bestMatchOffset - 1), count: LZ77.offsetBits)
                bitWriter.write(bits: UInt(bestMatchLength - Self.minMatchLength), count: LZ77.lengthBits)
                
                if let nextByte {
                    bitWriter.write(bit: true)
                    bitWriter.write(bits: UInt(nextByte), count: 8)
                } else {
                    bitWriter.write(bit: false)
                }
                index += bestMatchLength + (nextByte.isNil ? 0: 1)
            } else {
                guard let byte = data[index, default: nil] else {
                    throw E.internalError(description: "Unexpectedly found empty literal")
                }
                bitWriter.write(bit: false)
                bitWriter.write(bits: UInt(byte), count: 8)
                index += 1
            }
        }
        
        return bitWriter.getData().data
    }
    
    private func compress(_ data: Data) throws -> Data {
        let data = [UInt8](data)
        let tripel = generateTripel(data: data)
        let encoded = try encodeTripel(tripel)
        
        return encoded
    }
    
    func encodeTripel(_ tripel: [Tripel]) throws -> Data {
        var bitWriter = BitWriter()
        
        for item in tripel {
            if let offset = item.offset, let length = item.length {
                bitWriter.write(bit: true)
                bitWriter.write(bits: UInt(offset - 1), count: LZ77.offsetBits)
                bitWriter.write(bits: UInt(length - 1), count: LZ77.lengthBits)
                
                if let byte = item.nextByte {
                    bitWriter.write(bit: true)
                    bitWriter.write(bits: UInt(byte), count: 8)
                } else {
                    bitWriter.write(bit: false)
                }
            } else {
                bitWriter.write(bit: false)
                guard let byte = item.nextByte else {
                    throw E.internalError(description: "Unexpectedly found empty literal")
                }
                bitWriter.write(bits: UInt(byte), count: 8)
            }
        }
        
        return bitWriter.getData().data
    }
    
    func generateTripel(data: [UInt8]) -> [Tripel] {
        var tripel = [Tripel]()
        var index = 0
        while index < data.count {
            let searchBufferStart = max(0, index - LZ77.searchBufferSize)
            let searchBufferEnd = index
            let searchBuffer = data[searchBufferStart..<searchBufferEnd]
            
            let lookaheadBufferEnd = min(data.count, index + LZ77.previewBufferSize)
            let lookaheadBuffer = data[index..<lookaheadBufferEnd]
            
            var bestMatchOffset = 0
            var bestMatchLength = 0

            for matchLength in stride(from: lookaheadBuffer.count, through: 1, by: -1) {
                let prefix = lookaheadBuffer.prefix(matchLength)
                if let match = searchBuffer.lastRange(of: prefix) {
                    bestMatchOffset = searchBuffer.endIndex  - match.lowerBound
                    bestMatchLength = matchLength
                    break
                }
            }
            if bestMatchLength >= LZ77.minMatchLength && bestMatchOffset != 0 {
                let nextByte = data[index + bestMatchLength, default: nil]
                tripel.append(Tripel(offset: bestMatchOffset, length: bestMatchLength, nextByte: nextByte))
                index += bestMatchLength + (nextByte.isNil ? 0: 1)
            } else {
                tripel.append(Tripel(offset: nil, length: nil, nextByte: data[index]))
                index += 1
            }
        }
        return tripel
    }
    
    enum CompressionError: Error, CustomStringConvertible {
        case invalidOriginPath
        case tooFewCharacters
        case internalError(description: String)
        case writeFailed(path: String, underlyingError: Error)
        
        var description: String {
            switch self {
            case .invalidOriginPath:
                "The provided 'origin-path' argument is not a valid path."
            case .writeFailed(let path, let error):
                "Failed to write to destination path '\(path)'. Reason: \(error.localizedDescription)"
            case .tooFewCharacters:
                "File must contain at least 6 bytes"
            case .internalError(let description):
                "An internal Error occured: \(description)"
            }
        }
        
        var localizedDescription: String {
            return self.description
        }
    }
}
