//
//  BluetoothPeripheralManager.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-27.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

protocol BluetoothPeripheralManagerDelegate : class {
    func bluetoothPeripheralManagerDidBecomeReadyToAdvertise(_: BluetoothPeripheralManager)
    func bluetoothPeripheralManagerDidConnectWith(_: BluetoothPeripheralManager, newUser: User)
    func bluetoothPeripheralManagerDidDisconnectWith(_: BluetoothPeripheralManager, user: User)
    func bluetoothPeripheralManagerDidReceiveNewSuggestion(_: BluetoothPeripheralManager, suggestion: Suggestion)
}

final class BluetoothPeripheralManager : NSObject {
    
    fileprivate var peripheralManager: CBPeripheralManager!
    fileprivate let findFoodFastMutableService = CBMutableService(type: FindFoodFastService.ServiceUUID, primary: true)
    fileprivate let joinSessionCharacteristic = CBMutableCharacteristic.init(
        type: FindFoodFastService.CharacteristicUUIDJoinSession,
        properties: [.read,
                     .writeWithoutResponse,
                     .notify],
        value: nil,
        permissions: [.readable,
                      .writeable]
    )
    fileprivate let suggestionCharacteristic = CBMutableCharacteristic(
        type: FindFoodFastService.CharacteristicUUIDSuggestion,
        properties: [.read,
                     .writeWithoutResponse,
                     .notify],
        value: nil,
        permissions: [.readable,
                      .writeable]
    )
    fileprivate var uuidStringToUsername = [String: String]()
    
    // Variables related to sending data
    fileprivate var dataToSend: Data?
    fileprivate var sendDataIndex: Int?
    fileprivate var maximumBytesInPayload = 512 // 512 bytes is the theoretical maximum
    fileprivate var currentCharacteristic: CBMutableCharacteristic?
    fileprivate var sendingEOM = false
    
    // public
    weak var delegate: BluetoothPeripheralManagerDelegate?
    var isReadyToAdvertise = false
    var subscribedCentrals = [CBCentral]()
    var suggestions = [[String: String]]()
    
    // private hidden initializer
    private override init() {}
    
    static let sharedInstance: BluetoothPeripheralManager = {
        let instance = BluetoothPeripheralManager()
        instance.peripheralManager = CBPeripheralManager(delegate: instance, queue: nil)
        return instance
    }()
    
    internal func setupPeripheral() {
        
        let userDescriptionUuid:CBUUID = CBUUID(string:CBUUIDCharacteristicUserDescriptionString)
        let joinSessionDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Know who is connected via subscription to this characteristic")
        joinSessionCharacteristic.descriptors = [joinSessionDescriptor]
        
        let suggestionsDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Know what suggestions there are in the session")
        suggestionCharacteristic.descriptors = [suggestionsDescriptor]
        
        findFoodFastMutableService.characteristics = [joinSessionCharacteristic, suggestionCharacteristic]
        
        peripheralManager.add(findFoodFastMutableService)
    }
    
    func startAdvertising(hostname: String) {
        print("peripheral manager: start advertising of find food fast service")
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [findFoodFastMutableService.uuid], CBAdvertisementDataLocalNameKey: hostname])
    }
    
    func stopAdvertising() {
        print("peripheral manager: stop advertising of find food fast service")
        peripheralManager.stopAdvertising()
    }
    
    func resetPeripheral() {
        uuidStringToUsername.removeAll()
        peripheralManager.removeAllServices()
        setupPeripheral()
    }
    
    /* 
     * Sends to subscribers the updated list of users in the host's session
     */
    fileprivate func sendConnectedUsersList() {
        print("sending list of connected users")
        // make sure uuid string and username are not empty or incomplete
        let filteredUuidStringToUsernameArray = uuidStringToUsername.filter { (uuidString, username) -> Bool in
            return uuidString.characters.count > 0 && username.characters.count > 0
        }
        var filteredUuidStringToUsername = [String:String]()
        for result in filteredUuidStringToUsernameArray {
            filteredUuidStringToUsername[result.0] = result.1
        }
        // add self to the list of users
        let userDefaults = UserDefaults.standard
        if let hostUsername  = userDefaults.string(forKey: UserDefaultsKeys.Username) {
            filteredUuidStringToUsername.updateValue(hostUsername, forKey: Bluetooth.deviceUuidString!)
        }

        send(object: filteredUuidStringToUsername, for: joinSessionCharacteristic)
    }
    
    fileprivate func sendSuggestions() {
        print("sending suggestions")
        send(object: suggestions, for: suggestionCharacteristic)
    }
    
    fileprivate func send(object: Any, for characteristic: CBMutableCharacteristic) {
        dataToSend = NSKeyedArchiver.archivedData(withRootObject: object)
        sendDataIndex = 0
        currentCharacteristic = characteristic
        sendData()
    }
    
    /* 
     * Function modified from https://github.com/0x7fffffff/Core-Bluetooth-Transfer-Demo which is
     * a port of Apple's BTLE Transfer demo project into Swift 3.
     */
    fileprivate func sendData() {
        guard dataToSend != nil else {
            print("peripheral manager: no data to send as it is nil")
            return
        }
        guard currentCharacteristic != nil else {
            print("no specified characteristic to send to")
            return
        }
        
        if sendingEOM {
            // send it
            let didSend = peripheralManager?.updateValue(
                "EOM".data(using: String.Encoding.utf8)!,
                for: currentCharacteristic!,
                onSubscribedCentrals: nil
            )
            
            // Did it send?
            if (didSend == true) {
                
                // It did, so mark it as sent
                sendingEOM = false
                
                print("Sent: EOM")
                
                // remove data stored in variable
                dataToSend = nil
                currentCharacteristic = nil
            }
            
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        
        // Is there any left to send?
        guard sendDataIndex! < (dataToSend?.count)! else {
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        
        while didSend {
            // Make the next chunk
            
            // Work out how big it should be
            var amountToSend = dataToSend!.count - sendDataIndex!;
            
            // Can be 0-512 bytes depending on destination device specs
            if (amountToSend > maximumBytesInPayload) {
                amountToSend = maximumBytesInPayload
            }
            
            // Copy out the data we want
            let chunk = dataToSend!.withUnsafeBytes{(body: UnsafePointer<UInt8>) in
                return Data(
                    bytes: body + sendDataIndex!,
                    count: amountToSend
                )
            }
            
            // Send it
            didSend = peripheralManager!.updateValue(
                chunk as Data,
                for: currentCharacteristic!,
                onSubscribedCentrals: nil
            )
            
            // If it didn't work, drop out and wait for the callback
            if (!didSend) {
                return
            }
            
            print("Sent: \(sendDataIndex! + chunk.count)/\(dataToSend!.count) bytes")
            
            // It did send, so update our index
            sendDataIndex! += amountToSend;
            
            // Was it the last one?
            if (sendDataIndex! >= dataToSend!.count) {
                
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                sendingEOM = true
                
                // Send it
                let eomSent = peripheralManager!.updateValue(
                    "EOM".data(using: String.Encoding.utf8)!,
                    for: currentCharacteristic!,
                    onSubscribedCentrals: nil
                )
                
                if (eomSent) {
                    // It sent, we're all done
                    sendingEOM = false
                    print("Sent: EOM")
                }
                
                return
            }
        }
    }
}

extension BluetoothPeripheralManager : CBPeripheralManagerDelegate {
    // MARK: - CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            setupPeripheral()
        default:
            print("default")
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        sendData()
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard error == nil else {
            print("peripheral manager: error during did start service")
            print(error!)
            return
        }
        print("peripheral manager: did start advertising")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            print("peripheral manager: error adding the service to peripheral manager")
            print(error!)
            return
        }
        if service == findFoodFastMutableService {
            print("peripheral manager: is ready to advertise")
            isReadyToAdvertise = true
            delegate?.bluetoothPeripheralManagerDidBecomeReadyToAdvertise(self)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("peripheral manager: did receive write request")
        requests.forEach { (request) in
            switch request.characteristic.uuid {
            case FindFoodFastService.CharacteristicUUIDJoinSession:
                print("received write to join session characteristic")
                let uuidString = request.central.identifier.uuidString
                
                if let name = uuidStringToUsername[uuidString], name == "" {
                    if let data = request.value {
                        let username = String.init(data: data, encoding: String.Encoding.utf8)!
                        
                        // update internal dictionary of users
                        uuidStringToUsername.updateValue(username, forKey: uuidString)
                        
                        // update UI
                        let newUser = User(name: username, uuidString: uuidString)
                        print("peripheral manager: new user connected: \(newUser)")
                        delegate?.bluetoothPeripheralManagerDidConnectWith(self, newUser: newUser)
                        
                        // send new list of connected users to everyone
                        sendConnectedUsersList()
                    }
                }
            case FindFoodFastService.CharacteristicUUIDSuggestion:
                print("received write for suggestion")
                guard let data = request.value else {
                    print("request has nil data")
                    return
                }
                guard let suggestionDictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: String] else {
                    print("invalid suggestion unarchived")
                    return
                }
                guard let suggestion = Suggestion(dictionary: suggestionDictionary) else {
                    print("could not initialize suggestion with dictionary")
                    return
                }
                delegate?.bluetoothPeripheralManagerDidReceiveNewSuggestion(self, suggestion: suggestion)
            default:
                print("write to unknown characteristic")
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case FindFoodFastService.CharacteristicUUIDJoinSession:
            if central.maximumUpdateValueLength < maximumBytesInPayload {
                maximumBytesInPayload = central.maximumUpdateValueLength
            }
            subscribedCentrals.append(central)
            // add placeholder for when central sends over their username to 
            // internal users dictionary
            uuidStringToUsername.updateValue("", forKey: central.identifier.uuidString)
        case FindFoodFastService.CharacteristicUUIDSuggestion:
            // send central the list of current suggestions
            if (suggestions.count > 0) {
                sendSuggestions()
            } else {
                print("session has no suggestions, nothing to send")
            }
        default:
            print("characteristic subscribed to not recognized")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case FindFoodFastService.CharacteristicUUIDJoinSession:
            guard let index = subscribedCentrals.index(of: central) else {
                print("index of disconnected central not found")
                return
            }
            subscribedCentrals.remove(at: index)
            let disconnectedUserUuidString = central.identifier.uuidString
            if let username = uuidStringToUsername[disconnectedUserUuidString] {
                // remove from internal user dictionary
                uuidStringToUsername[disconnectedUserUuidString] = nil
                
                // create a new user with the username and uuid, would work since
                // User is a struct and update UI
                let disconnectedUser = User(name: username, uuidString: disconnectedUserUuidString)
                delegate?.bluetoothPeripheralManagerDidDisconnectWith(self, user: disconnectedUser)
                
                // send new list of connected users to everyone
                sendConnectedUsersList()
            }
        default:
            print("nothing to clean up for unsubscribing characteristic")
        }
    }
}
