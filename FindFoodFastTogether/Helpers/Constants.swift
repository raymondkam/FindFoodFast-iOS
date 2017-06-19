//
//  Constants.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-14.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth

struct FindFoodFastService {
    static let ServiceUUID = CBUUID.init(string: "83488d8d-667c-4ba0-8f52-0d8e61e772f6")
    static let CharacteristicUUIDHostName = CBUUID.init(string: "70f6be9d-a964-440e-9ede-f4ce1df66fc3")
}
