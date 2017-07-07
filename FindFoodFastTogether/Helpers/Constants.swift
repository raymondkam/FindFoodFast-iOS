//
//  Constants.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-14.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

struct FindFoodFastService {
    static let ServiceUUID = CBUUID.init(string: "83488d8d-667c-4ba0-8f52-0d8e61e772f6")
    static let CharacteristicUUIDHostName = CBUUID.init(string: "70f6be9d-a964-440e-9ede-f4ce1df66fc3")
    static let CharacteristicUUIDJoinSession = CBUUID.init(string: "b4cfdcf5-06ed-41c9-a188-bbb9aa95c0c4")
}

struct FindFoodFastColor {
    static let MainColor = UIColor.init(red: 29/255, green: 188/255, blue: 213/255, alpha: 1)
    static let DisabledColor = UIColor.init(red: 203/255, green: 198/255, blue: 185/255, alpha: 1)
}

struct Segues {
    static let Search = "search"
    static let Host = "host"
    static let HostSession = "hostSession"
    static let EmbedBrowseHostCollection = "embedBrowseHostCollection"
    static let EmbedUserCollection = "embedUserCollection"
    static let JoinHost = "joinHost"
}

struct NotificationNames {
    static let CentralBluetoothPoweredOn = Notification.Name.init("centralBluetoothPoweredOn")
    static let PeripheralBluetoothPoweredOn = Notification.Name.init("peripheralBluetoothPoweredOn")
    static let BluetoothDiscoveredNewPeripheral = Notification.Name.init("bluetoothDiscoveredNewPeripheral")
}

let browseHostReuseIdentifier = "BrowseHostCell"
let suggestionReuseIdentifier = "SuggestionCell"

struct UserDefaultsKeys {
    static let Username = "username"
}

struct Bluetooth {
    static let deviceUuidString = UIDevice.current.identifierForVendor?.uuidString
}
