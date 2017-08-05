//
//  BluetoothOperation.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-05.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth

struct BluetoothOperation {
    
    var dataToSend: Data
    var targetCharacteristic: CBMutableCharacteristic
    
    init(dataToSend: Data, targetCharacteristic: CBMutableCharacteristic) {
        self.dataToSend = dataToSend
        self.targetCharacteristic = targetCharacteristic
    }
    
}
