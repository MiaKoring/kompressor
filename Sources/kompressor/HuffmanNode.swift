//
//  HuffmanNode.swift
//  kompressor
//
//  Created by Mia Koring on 21.06.25.
//
import Foundation

/// Represents a node in the Huffman tree. It can be either a leaf node
/// (containing a character and its frequency) or an internal node
/// (containing only a frequency and references to its children).
class HuffmanNode: CustomStringConvertible, Comparable, Codable {
    let character: String? // Only set for leaf nodes
    let frequency: Int
    var left: HuffmanNode?
    var right: HuffmanNode?
    
    // MARK: - Initialization
    
    /// Initializes a leaf node.
    init(character: Character, frequency: Int) {
        self.character = "\(character)"
        self.frequency = frequency
        self.left = nil
        self.right = nil
    }
    
    /// Initializes an internal node.
    init(left: HuffmanNode, right: HuffmanNode) {
        self.character = nil // Internal nodes don't represent a single character
        self.frequency = left.frequency + right.frequency
        self.left = left
        self.right = right
    }
    
    // MARK: - CustomStringConvertible
    
    var description: String {
        if let char = character {
            return "Node(\"\(char)\": \(frequency))"
        } else {
            return "Node(Internal: \(frequency))"
        }
    }
    
    // MARK: - Comparable Conformance
    
    /// Compares two HuffmanNodes based on their frequency, then by character for tie-breaking.
    static func < (lhs: HuffmanNode, rhs: HuffmanNode) -> Bool {
        if lhs.frequency != rhs.frequency {
            return lhs.frequency < rhs.frequency
        }
        // Tie-breaking: If frequencies are equal, prioritize leaf nodes, then by character value.
        // This ensures a deterministic tree.
        if lhs.character != nil && rhs.character == nil {
            return true // Leaf node (lhs) is "smaller" than internal node (rhs) for tie-breaking
        } else if lhs.character == nil && rhs.character != nil {
            return false // Internal node (lhs) is "larger" than leaf node (rhs) for tie-breaking
        } else if let lhsChar = lhs.character, let rhsChar = rhs.character {
            return lhsChar < rhsChar // Compare characters for leaf nodes
        }
        return false
    }
    
    static func == (lhs: HuffmanNode, rhs: HuffmanNode) -> Bool {
        return lhs.frequency == rhs.frequency && lhs.character == rhs.character
    }
    
    
}

extension HuffmanNode {
  // MARK: - Compact Binary Serialization

  /// Serializes the tree into a compact binary Data object using  BitWriter.
  func serializeToCompactData() -> Data {
    var writer = BitWriter()
    self.serialize(into: &writer)
    // Use your getData() method to finalize the data buffer
    return writer.getData().data
  }

  /// Private helper for recursive serialization.
  private func serialize(into writer: inout BitWriter) {
    if character != nil {
      // 1. This is a leaf node. Write a '1' bit.
      writer.write(bit: true)

      // 2. Then, write the character's byte value.
        guard let char = self.character?.first, let byte = char.utf8.first else {
        // Fallback for an invalid leaf node.
        writer.write(bits: 0, count: 8)
        return
      }
      // Use the multi-bit write method for efficiency and clarity.
      writer.write(bits: UInt(byte), count: 8)
    } else {
      // 1. This is an internal node. Write a '0' bit.
      writer.write(bit: false)

      // 2. Recursively serialize the left and right children.
      left?.serialize(into: &writer)
      right?.serialize(into: &writer)
    }
  }

  /// Deserializes a HuffmanNode from a compact binary Data object.
  convenience init?(fromCompactData data: Data) {
    guard !data.isEmpty else { return nil }
    var reader = BitReader(data: data)
    // The recursive helper will build the entire tree.
    guard let reconstructedNode = HuffmanNode.build(from: &reader) else {
      return nil
    }
    // Use the reconstructed node's properties to initialize self.
    self.init(
      character: reconstructedNode.character?.first,
      frequency: reconstructedNode.frequency,
      left: reconstructedNode.left,
      right: reconstructedNode.right
    )
  }

  /// Private helper for recursive deserialization.
  private static func build(from reader: inout BitReader) -> HuffmanNode? {
    guard let bit = reader.readBit() else { return nil }

    if bit == true { // Leaf node
      guard let byte = reader.readByte() else { return nil }
      let char = Character(UnicodeScalar(byte))
      // Frequency is not stored, so we use a placeholder.
      return HuffmanNode(character: char, frequency: 0)
    } else { // Internal node
      guard let leftChild = build(from: &reader),
            let rightChild = build(from: &reader)
      else {
        return nil
      }
      return HuffmanNode(left: leftChild, right: rightChild)
    }
  }
    
  // Helper initializer to construct a node from its components.
  private convenience init?(character: Character?, frequency: Int, left: HuffmanNode?, right: HuffmanNode?) {
      if let char = character {
          self.init(character: char, frequency: frequency)
      } else if let l = left, let r = right {
          self.init(left: l, right: r)
      } else {
          return nil
      }
  }
}


