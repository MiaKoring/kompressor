import Testing
import Foundation
@testable import kompressor

@Test func testTripelGeneration() {
    let data: [UInt8] = [
        65, // 'A'
        66, // 'B'
        65, // 'A'
        66, // 'B'
        65, // 'A'
        66, // 'B'
        67, // 'C'
        65  // 'A'
    ]
    let compressor = LZ77Compress()
    
    let result = compressor.generateTripel(data: data)
    
    let expected = [
        Tripel(nil, nil, 65), // 'A'
        Tripel(nil, nil, 66), // 'B'
        Tripel(2, 2, 65), // 'A B' wiederholt, dann 'A'
        Tripel(nil, nil, 66), // 'B'
        Tripel(nil, nil, 67), // 'C'
        Tripel(nil, nil, 65)  // 'A'
    ]
    
    #expect(result == expected)
}

@Test func testEncoding() throws {
    let compressor = LZ77Compress()
    let tripel = [
        Tripel(nil, nil, 65), // 'A'
        Tripel(nil, nil, 66), // 'B'
        Tripel(2, 2, 65), // 'A B' repeats, then 'A'
        Tripel(nil, nil, 66), // 'B'
        Tripel(nil, nil, 67), // 'C'
        Tripel(nil, nil, 65)  // 'A'
    ]
    /*
     0 = literal + 65 as byte
     0 = literal + 66 as byte
     1 = tripel + 12 bit offset 2 + 4 bit length 2 + 1 = byte after exists + 65 as byte
     0 = literal + 66 as byte
     0 = literal + 67 as byte
     0 = literal + 65 as byte
    */
    let expectedResult = "001000001 001000010 [1 000000000010 0010 101000001] 001000010 001000011 001000001"
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "[", with: "")
        .replacingOccurrences(of: "]", with: "")
    
    var bitWriter = BitWriter()
    
    for char in expectedResult {
        bitWriter.write(bit: char == "1")
    }
    
    let expectedData = bitWriter.getData().data
    
    let outputData = try compressor.encodeTripel(tripel)

    #expect(outputData == expectedData)
}


@Test func testDecodingWithTripelBiggerThanWrittenData() throws {
    let data: [UInt8] = [65, 66, 67, 65, 66, 67, 65, 66, 67]
    let originalData = Data(data)
    
    let encodedData = try LZ77Compress().compressV3(originalData)
    
    let decodedData = try LZ77Decompress().decompress(encodedData)
    
    #expect(originalData == decodedData)
}

@Test func testDecoding() throws {
    let data: [UInt8] = [
        65, // 'A'
        66, // 'B'
        65, // 'A'
        66, // 'B'
        65, // 'A'
        66, // 'B'
        67, // 'C'
        65  // 'A'
    ]
    let originalData = Data(data)
    
    let encodedData = try LZ77Compress().compressV3(originalData)
    
    let decodedData = try LZ77Decompress().decompress(encodedData)
    
    #expect(originalData == decodedData)
}
