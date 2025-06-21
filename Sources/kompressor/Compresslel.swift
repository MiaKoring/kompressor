//
//  compress.swift
//  kompressor
//
//  Created by Mia Koring on 21.06.25.
//
import ArgumentParser
import Foundation

struct Compress: ParsableCommand {
    typealias E = CompressionError
    
    @Argument(help: "Path to the file to compress.")
    var originPath: String
    
    @Option(name: .shortAndLong, help: "The output file destination.")
    var destination: String?
    
    mutating func run() throws {
        guard let data = FileManager.default.contents(atPath: originPath) else {
            throw E.invalidOriginPath
        }
        
        guard let fileContent = String(data: data, encoding: .utf8) else {
            throw E.invalidEncoding
        }
        
        let compressedOutput = try compress(fileContent)
        
        // If compression was aborted, the output will be the same as the input.
        // We can avoid writing the file in that case.
        guard compressedOutput.count < fileContent.count else {
            print("Compression would not reduce file size. No output file was written.")
            return
        }
        
        let originURL = URL(fileURLWithPath: originPath)
        let pathWithoutExtension = originURL.deletingPathExtension().path
        let destinationPath = destination ?? pathWithoutExtension + ".kompressor"
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        do {
            try compressedOutput.write(to: destinationURL)
            print("Successfully compressed file to \(destinationPath)")
        } catch {
            throw E.writeFailed(path: destinationPath, underlyingError: error)
        }
    }
    
    private func compress(_ data: String) throws -> Data {
        let counts = count(data)
        let treeRoot = try buildTree(counts)
        let map = buildMap(root: treeRoot)
        
        var bitOperator = BitWriter()
        
        for char in data {
            guard let sequence = map["\(char)"] else {
                throw E.internalError(description: "character doesn't exist in map")
            }
            for op in sequence {
                bitOperator.write(bit: op)
            }
        }
        
        let (data, padding) = bitOperator.getData()
        
        return try PropertyListEncoder().encode(KompressorFile(h: .init(p: padding, t: treeRoot.serializeToCompactData()), b: data))
    }
    
    private func count(_ input: String) -> [Character: Int] {
        var counts = [Character: Int]()
        
        input.forEach { char in
            counts[char, default: 0] += 1
        }
        
        return counts
    }
    
    private func buildTree(_ counts: [Character: Int]) throws -> HuffmanNode {
        let heap = Heap<HuffmanNode>{ lhs, rhs in
            lhs.frequency < rhs.frequency
        }
        
        //Convert KV pairs to leaf nodes
        let leafNodes = counts.map { key, value in
            HuffmanNode(character: key, frequency: value)
        }
        
        //initialize the Heap
        for node in leafNodes {
            heap.insert(item: node)
        }
        
        while heap.count > 1 {
            guard let leftNode = heap.popTop(), let rightNode = heap.popTop() else {
                break
            }
            let node = HuffmanNode(left: leftNode, right: rightNode)
            heap.insert(item: node)
        }
        
        guard let top = heap.getTop() else {
            throw E.tooFewCharacters
        }
        
        return top
    }
    
    private func buildMap(root: HuffmanNode) -> [String: [Bool]] {
        var map = [String: [Bool]]()
        
        traverse(node: root, map: &map, currentPath: [])
        
        return map
        
        func traverse(node: HuffmanNode, map: inout [String: [Bool]], currentPath: [Bool]) {
            if let char = node.character {
                map["\(char)"] = currentPath
                return
            }
            
            // If it's an internal node, continue traversal
            // Go left: append 'false' (0) to the path
            if let left = node.left {
                var newPathForLeft = currentPath // Create a copy of the path for this branch
                newPathForLeft.append(false) // 0 for left
                traverse(node: left, map: &map, currentPath: newPathForLeft)
            }

            // Go right: append 'true' (1) to the path
            if let right = node.right {
                var newPathForRight = currentPath // Create a copy of the path for this branch
                newPathForRight.append(true) // 1 for right
                traverse(node: right, map: &map, currentPath: newPathForRight)
            }
            
        }
    }
    
    enum CompressionError: Error, CustomStringConvertible {
        case invalidOriginPath
        case invalidEncoding
        case tooFewCharacters
        case internalError(description: String)
        case writeFailed(path: String, underlyingError: Error)
        
        var description: String {
            switch self {
            case .invalidOriginPath:
                "The provided 'origin-path' argument is not a valid path."
            case .invalidEncoding:
                "The file content could not be read as UTF-8 text."
            case .writeFailed(let path, let error):
                "Failed to write to destination path '\(path)'. Reason: \(error.localizedDescription)"
            case .tooFewCharacters:
                "File must contain at least one character"
            case .internalError(let description):
                "An internal Error occured: \(description)"
            }
        }
        
        var localizedDescription: String {
            return self.description
        }
    }
