//
//  ArrayExtension.swift
//  kompressor
//
//  Created by Mia Koring on 21.06.25.
//

extension Array {
    public subscript(index: Int, default defaultValue: @autoclosure () -> Element) -> Element {
        guard index >= startIndex, index < endIndex else {
            return defaultValue()
        }

        return self[index]
    }
    public subscript(index: Int, default defaultValue: @autoclosure () -> Element?) -> Element? {
        guard index >= startIndex, index < endIndex else {
            return defaultValue()
        }

        return self[index]
    }
    
    public subscript(bounds: Range<Int>, default defaultValue: @autoclosure () -> ArraySlice<Element>) -> ArraySlice<Element> {
        guard bounds.startIndex >= startIndex, bounds.endIndex <= endIndex else {
            return defaultValue()
        }
        
        return self[bounds]
    }
    
    public subscript(bounds: Range<Int>, default defaultValue: @autoclosure () -> ArraySlice<Element>?) -> ArraySlice<Element>? {
        guard bounds.startIndex >= startIndex, bounds.endIndex <= endIndex else {
            return defaultValue()
        }
        
        return self[bounds]
    }
}
