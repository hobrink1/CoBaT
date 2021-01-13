//
//  Hash.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 13.01.21.
//

import Foundation


/*
 https://stackoverflow.com/questions/52440502/string-hashvalue-not-unique-after-reset-app-when-build-in-xcode-10
 
 Swift 4.2 has implemented SE-0206: Hashable Enhancements. This introduces a new Hasher struct that provides a randomly seeded hash function.

 That's why the hashing results differ everytime (since the seed is random).
 
 You can find the implementation of the Hasher struct, with the generation of a random seed, here.

 If you want a stable hash value associated to a String, accross devices and app lauches, you could use this solution by Warren Stringer:
 */

/**
 -----------------------------------------------------------------------------------------------
 
 
 
 -----------------------------------------------------------------------------------------------
 
 - Parameters:
    - str: tzhe string to hash
 
 - Returns: hash value
 
 */
func strHash(_ str: String) -> UInt64 {
    var result = UInt64 (5381)
    let buf = [UInt8](str.utf8)
    for b in buf {
        result = 127 * (result & 0x00ffffffffffffff) + UInt64(b)
    }
    return result
}


func CoBaTHash(data: Data) -> UInt64 {
    
    var result: UInt64 = 5381
    
    if let stringToHash = String(data: data, encoding: .utf8) {
        
        let buffer = [UInt8](stringToHash.utf8)
        for item in buffer {
            result = 127 * (result & 0x00ffffffffffffff) + UInt64(item)
        }
    }
    
    return result
}
