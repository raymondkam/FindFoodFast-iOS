//
//  Host.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-25.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Host {
    let peripheral: CBPeripheral
    let name: String
    
    init(peripheral: CBPeripheral, name: String) {
        self.peripheral = peripheral
        self.name = name
    }
}
