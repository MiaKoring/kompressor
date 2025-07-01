// The Swift Programming Language
// https://docs.swift.org/swift-book
import ArgumentParser
import Foundation

@main
struct Kompressor: ParsableCommand {
    static let configuration: CommandConfiguration = CommandConfiguration(commandName: "kompressor", abstract: "Tool for file compression and decompression", subcommands: [Compress.self, Decompress.self, LZ77Compress.self, LZ77Decompress.self])
}
