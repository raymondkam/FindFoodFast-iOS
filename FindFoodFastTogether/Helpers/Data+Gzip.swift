//
//  Data+Gzip.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import Gzip

extension Data {
    
    /*
     *  Tries to compress data with Gzip and if successful, returns the compressed 
     *  data. If gzip fails, then the original data is returned.
     */
    func tryGzipped() -> Data {
        let oldSize = self.count
        do {
            let tryGzippedData = try self.gzipped(level: .bestCompression)
            let newSize = tryGzippedData.count
            let compressionRatio = (Float(oldSize) - Float(newSize)) / Float(oldSize) * 100
            let compressionRatioString = String(format: "%.2f", compressionRatio)
            print("gzip data: old size: \(oldSize), new size: \(newSize), compression ratio: \(compressionRatioString)%")
            return tryGzippedData
        } catch {
            print("failed to compress data, fallback to sending uncompressed data")
            return self
        }
    }
    
}
