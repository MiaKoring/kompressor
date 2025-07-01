//
//  Decompress.swift
//  kompressor
//
//  Created by Mia Koring on 21.06.25.
//

import ArgumentParser
import Foundation

struct Decompress: ParsableCommand {
    typealias E = DecompressionError
    
    @Argument(help: "Path to the file to decompress.")
    var originPath: String
    
    @Option(name: .shortAndLong, help: "The output file destination.")
    var destination: String?
    
    mutating func run() throws {
        guard let data = FileManager.default.contents(atPath: originPath) else {
            throw E.invalidOriginPath
        }
        
        guard let content = try? PropertyListDecoder().decode(KompressorFile.self, from: data) else {
            throw E.notAKompressorFile
        }
        
        let reconstructed = try decompress(content)
        
        let originURL = URL(fileURLWithPath: originPath)
        let pathWithoutExtension = originURL.deletingPathExtension().path
        let destinationPath = destination ?? pathWithoutExtension
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        do {
            try reconstructed.write(to: destinationURL)
            print("Successfully decompressed file to \(destinationPath)")
        } catch {
            throw E.writeFailed(path: destinationPath, underlyingError: error)
        }
    }
    
    private func decompress(_ file: KompressorFile) throws -> Data {
        let tree = HuffmanNode(fromCompactData: file.h.t)
        
        var reader = BitReader(data: file.b)
        
        var reconstructed = [UInt8]()
        
        var currentNode = tree
        
        while reader.remainingBits >= file.h.p {
            if let byte = currentNode?.byte {
                reconstructed.append(byte)
                currentNode = tree
            }
            guard let bit = reader.readBit() else {
                break
            }
            guard let nextNode = bit ? currentNode?.right: currentNode?.left else {
                throw E.internalError(description: "Unexpectedly encountered leaf node")
            }
            currentNode = nextNode
        }
        
        print(tree.debugDescription)
        print(currentNode.debugDescription)
        print(tree == currentNode)
        
        return Data(reconstructed)
    }
    
    enum DecompressionError: Error, CustomStringConvertible {
        case invalidOriginPath
        case internalError(description: String)
        case writeFailed(path: String, underlyingError: Error)
        case notAKompressorFile
        
        var description: String {
            switch self {
            case .invalidOriginPath:
                "The provided 'origin-path' argument is not a valid path."
            case .writeFailed(let path, let error):
                "Failed to write to destination path '\(path)'. Reason: \(error.localizedDescription)"
            case .internalError(let description):
                "An internal Error occured: \(description)"
            case .notAKompressorFile:
                "The file doesn't match kompressor-format"
            }
        }
        
        var localizedDescription: String {
            return self.description
        }
    }
}
