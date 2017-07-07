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
}

final class BluetoothPeripheralManager : NSObject {
    
    fileprivate var peripheralManager: CBPeripheralManager!
    fileprivate let findFoodFastMutableService = CBMutableService.init(type: FindFoodFastService.ServiceUUID, primary: true)
    fileprivate let joinSessionCharacteristic = CBMutableCharacteristic.init(
        type: FindFoodFastService.CharacteristicUUIDJoinSession,
        properties: [CBCharacteristicProperties.read,
                     CBCharacteristicProperties.writeWithoutResponse,
                     CBCharacteristicProperties.notify],
        value: nil,
        permissions: [CBAttributePermissions.readable,
                      CBAttributePermissions.writeable]
    )
    fileprivate var uuidStringToUsername = [String: String]()
    
    // Variables related to sending data
    fileprivate var dataToSend: Data?
    fileprivate var sendDataIndex: Int?
    fileprivate var maximumBytesInPayload = 512 // 512 bytes is the theoretical maximum
    fileprivate var sendingEOM = false
    
    private override init() {}
    
    weak var delegate: BluetoothPeripheralManagerDelegate?
    var isReadyToAdvertise = false
    var subscribedCentrals = [CBCentral]()
    let uuidString = UIDevice.current.identifierForVendor?.uuidString
    
    static let sharedInstance: BluetoothPeripheralManager = {
        let instance = BluetoothPeripheralManager()
        instance.peripheralManager = CBPeripheralManager(delegate: instance, queue: nil)
        return instance
    }()
    
    internal func setupPeripheral() {
        
        let userDescriptionUuid:CBUUID = CBUUID(string:CBUUIDCharacteristicUserDescriptionString)
        let myDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Know who is connected via subscription to this characteristic")
        joinSessionCharacteristic.descriptors = [myDescriptor]
        findFoodFastMutableService.characteristics = [joinSessionCharacteristic]
        
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
        // make sure uuid string and username are not empty or incomplete
        let filteredUuidStringToUsernameArray = uuidStringToUsername.filter { (uuidString, username) -> Bool in
            return uuidString.characters.count > 0 && username.characters.count > 0
        }
        var filteredUuidStringToUsername = [String:String]()
        for result in filteredUuidStringToUsernameArray {
            filteredUuidStringToUsername[result.0] = result.1
        }
        dataToSend = NSKeyedArchiver.archivedData(withRootObject: filteredUuidStringToUsername)
        sendDataIndex = 0
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
        
        if sendingEOM {
            // send it
            let didSend = peripheralManager?.updateValue(
                "EOM".data(using: String.Encoding.utf8)!,
                for: joinSessionCharacteristic,
                onSubscribedCentrals: nil
            )
            
            // Did it send?
            if (didSend == true) {
                
                // It did, so mark it as sent
                sendingEOM = false
                
                print("Sent: EOM")
                
                // remove data stored in variable
                dataToSend = nil
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
                for: joinSessionCharacteristic,
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
                    for: joinSessionCharacteristic,
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
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
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
        default:
            print("characteristic subscribed to not recognized")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        subscribedCentrals.remove(at: subscribedCentrals.index(of: central)!)
        let disconnectedUserUuidString = central.identifier.uuidString
        if let username = uuidStringToUsername[disconnectedUserUuidString] {
            // create a new user with the username and uuid, would work since 
            // User is a struct and update UI
            let disconnectedUser = User(name: username, uuidString: disconnectedUserUuidString)
            delegate?.bluetoothPeripheralManagerDidDisconnectWith(self, user: disconnectedUser)
            
            // send new list of connected users to everyone
            sendConnectedUsersList()
        }
    }
}
