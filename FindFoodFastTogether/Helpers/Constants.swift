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
    static let ServiceUUID = CBUUID(string: "83488d8d-667c-4ba0-8f52-0d8e61e772f6")
    static let CharacteristicUUIDJoinSession = CBUUID(string: "b4cfdcf5-06ed-41c9-a188-bbb9aa95c0c4")
    static let CharacteristicUUIDSuggestion = CBUUID(string: "70f6be9d-a964-440e-9ede-f4ce1df66fc3")
    static let CharacteristicUUIDVoting = CBUUID(string: "4e548314-56f2-4975-905c-940bce856bf6")
    static let CharacteristicUUIDHighestRatedSuggestion = CBUUID(string: "35ca4ea5-b008-4d1e-840b-3d6a7e1fa37c")
}

struct FindFoodFastColor {
    static let MainColor = UIColor(red: 29/255, green: 188/255, blue: 213/255, alpha: 1)
    static let DisabledColor = UIColor(red: 203/255, green: 198/255, blue: 185/255, alpha: 1)
    static let ErrorColor = UIColor(red: 255/255, green: 60/255, blue: 60/255, alpha: 1)
}

struct Segues {
    static let Search = "search"
    static let Host = "host"
    static let HostSession = "hostSession"
    static let EmbedBrowseHostCollection = "embedBrowseHostCollection"
    static let EmbedSuggestionCollection = "embedSuggestionCollection"
    static let EmbedUserCollection = "embedUserCollection"
    static let JoinHost = "joinHost"
    static let AddSuggestionFromHostView = "addSuggestionFromHostView"
    static let AddSuggestionFromCellButton = "addSuggestionFromCellButton"
    static let AddSuggestionFromCell = "addSuggestionFromCell"
    static let StartVoting = "startVoting"
    static let ShowHighestRatedSuggestion = "showHighestRatedSuggestion"
    static let UnwindToStart = "unwindToStart"
    static let EmbedSuggestionSearchResults = "embedSuggestionSearchResults"
    static let EmbedSuggestionImages = "embedSuggestionImages"
}

struct StoryboardIds {
    static let SuggestionDetails = "suggestionDetails"
}

struct NotificationNames {
    static let CentralBluetoothPoweredOn = Notification.Name.init("centralBluetoothPoweredOn")
    static let PeripheralBluetoothPoweredOn = Notification.Name.init("peripheralBluetoothPoweredOn")
    static let BluetoothDiscoveredNewPeripheral = Notification.Name.init("bluetoothDiscoveredNewPeripheral")
}

let browseHostReuseIdentifier = "BrowseHostCell"
let suggestionReuseIdentifier = "SuggestionCell"
let addNewSuggestionReuseIdentifier = "AddNewSuggestionCell"
let suggestionSearchResultReuseIdentifier = "suggestionSearchResultCell"
let poweredByGoogleFooterViewReuseIdentifer = "poweredByGoogleFooter"
let imageReuseIdentifier = "ImageCell"

struct UserDefaultsKeys {
    static let Username = "username"
    static let UserLocation = "userLocation"
}

struct Bluetooth {
    static let deviceUuidString = UIDevice.current.identifierForVendor?.uuidString
}
