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
    fileprivate var uuidStringToUsername = [String: String]()
    fileprivate let joinSessionCharacteristic = CBMutableCharacteristic.init(
        type: FindFoodFastService.CharacteristicUUIDJoinSession,
        properties: [CBCharacteristicProperties.read,
                     CBCharacteristicProperties.writeWithoutResponse,
                     CBCharacteristicProperties.notify],
        value: nil,
        permissions: [CBAttributePermissions.readable,
                      CBAttributePermissions.writeable]
    )
    
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
                        uuidStringToUsername.updateValue(username, forKey: uuidString)
                        
                        let newUser = User(name: username, uuidString: uuidString)
                        print("peripheral manager: new user connected: \(newUser)")
                        delegate?.bluetoothPeripheralManagerDidConnectWith(self, newUser: newUser)
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
            subscribedCentrals.append(central)
            uuidStringToUsername.updateValue("", forKey: central.identifier.uuidString)
            let userDefaults = UserDefaults.standard
            if let username  = userDefaults.string(forKey: UserDefaultsKeys.Username) {
                print("retrieved username from user defaults: \(username)")
                peripheralManager.updateValue(username.data(using: .utf8)!, for: joinSessionCharacteristic, onSubscribedCentrals: subscribedCentrals)
            }
        default:
            print("characteristic subscribed to not recognized")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        subscribedCentrals.remove(at: subscribedCentrals.index(of: central)!)
        let disconnectedUserUuidString = central.identifier.uuidString
        let disconnectedUser = User(name: uuidStringToUsername[disconnectedUserUuidString]!, uuidString: disconnectedUserUuidString)
        delegate?.bluetoothPeripheralManagerDidDisconnectWith(self, user: disconnectedUser)
    }
}
