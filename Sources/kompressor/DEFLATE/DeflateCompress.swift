//
//  DEFLATE_Encoding.swift
//  kompressor
//
//  Created by Mia Koring on 02.07.25.
//
/*
import ArgumentParser
import Foundation

struct DeflateCompress: ParsableCommand {
    typealias E = CompressionError
    typealias LZ77 = Self
    
    @Argument(help: "Path to the file to compress.")
    var originPath: String
    
    @Option(name: .shortAndLong, help: "The output file destination.")
    var destination: String?
    
    mutating func run() throws {
        guard let data = FileManager.default.contents(atPath: originPath) else {
            throw E.invalidOriginPath
        }
        
        let compressedOutput = try compress(data)
        
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
    
    func compress(_ data: Data) throws -> Data {
        
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
*/
