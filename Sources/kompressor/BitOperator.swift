//
//  BitOperator.swift
//  kompressor
//
//  Created by Mia Koring on 21.06.25.
//

import Foundation

// MARK: - BitWriter

/// A utility to write individual bits or sequences of bits to a Data buffer.
/// It handles the packing of bits into bytes.
struct BitWriter {
    // MARK: - Properties

    /// The underlying buffer where bits are being accumulated.
    private var data: Data

    /// The current byte being filled with bits.
    private var currentByte: UInt8

    /// The number of bits already written into `currentByte`.
    /// Ranges from 0 to 7.
    private var bitsInCurrentByte: Int

    // MARK: - Initialization

    /// Initializes a new `BitWriter`.
    init() {
        self.data = Data()
        self.currentByte = 0
        self.bitsInCurrentByte = 0
    }

    // MARK: - Public Methods

    /**
     Appends a single bit to the buffer.

     - Parameter bit: The bit to append (true for 1, false for 0).
     */
    mutating func write(bit: Bool) {
        // Shift the current byte to the left to make space for the new bit
        currentByte <<= 1

        // If the bit is true (1), set the least significant bit
        if bit {
            currentByte |= 1
        }

        bitsInCurrentByte += 1

        // If the current byte is full (8 bits), append it to the data buffer
        // and reset for the next byte.
        if bitsInCurrentByte == 8 {
            data.append(currentByte)
            currentByte = 0
            bitsInCurrentByte = 0
        }
    }

    /**
     Appends a sequence of bits from a given `UInt` value.
     The bits are taken from the least significant side of the value.

     - Parameters:
       - value: The `UInt` value containing the bits.
       - count: The number of bits to take from the `value` (starting from LSB).
                Must be between 0 and `UInt.bitWidth`.
     */
    mutating func write(bits value: UInt, count: Int) {
        // Input validation
        precondition(
            count >= 0 && count <= UInt.bitWidth,
            "Count must be between 0 and \(UInt.bitWidth)."
        )

        // Iterate from the most significant bit of the 'count' bits down to the least significant.
        // This ensures bits are written in the correct order (MSB first).
        for i in (0 ..< count).reversed() {
            // Check if the i-th bit (from right) is set in the value.
            let bit = (value >> i) & 1 == 1
            write(bit: bit)
        }
    }

    /**
     Returns the accumulated `Data` buffer.

     - Returns: The `Data` object containing the packed bits.
                This method also handles any remaining bits in `currentByte`
                by padding with zeros.
     */
    mutating func getData() -> (data: Data, padding: Int) {
        // If there are any remaining bits in currentByte,
        // we need to pad it with zeros to fill the byte
        // and append it to the data buffer.
        if bitsInCurrentByte > 0 {
            // Shift remaining bits to the left to align them to MSB of the byte
            // and effectively pad with zeros from the right.
            currentByte <<= (8 - bitsInCurrentByte)
            data.append(currentByte)
            currentByte = 0
            bitsInCurrentByte = 0
        }
        return (data: data, padding: (8 - bitsInCurrentByte))
    }
}
struct BitReader {
    private let data: Data
    private var byteIndex: Int
    private var bitPosition: Int// 0-7, from MSB to LSB
    var remainingBits: Int
    
    init(data: Data) {
        self.data = data
        self.byteIndex = 0
        self.bitPosition = 0
        self.remainingBits = data.count * 8
    }
    
    /// Reads a single bit from the buffer.
    /// Returns nil if no more bits are available.
    mutating func readBit() -> Bool? {
        guard byteIndex < data.count else { return nil }
        
        let currentByte = data[byteIndex]
        // Read bit from left (MSB) to right (LSB)
        let bit = (currentByte >> (7 - bitPosition)) & 1 == 1
        
        bitPosition += 1
        remainingBits -= 1
        if bitPosition == 8 {
            bitPosition = 0
            byteIndex += 1
        }
        
        return bit
    }
    
    /// Reads a full 8-bit byte from the buffer.
    /// This is the inverse of `BitWriter.write(bits:count:8)`.
    mutating func readByte() -> UInt8? {
        var byte: UInt8 = 0
        // We need to read 8 bits to form a byte.
        // The first bit read corresponds to the MSB of the original byte.
        for i in (0..<8).reversed() {
            guard let bit = readBit() else {
                // Not enough bits left to form a full byte
                return nil
            }
            if bit {
                byte |= (1 << i)
            }
        }
        return byte
    }
}
