//
//  BluetoothPeripheralManager.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-27.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothPeripheralManagerDelegate : class {
    func bluetoothPeripheralManagerDidBecomeReadyToAdvertise(_: BluetoothPeripheralManager)
}

final class BluetoothPeripheralManager : NSObject {
    
    fileprivate var peripheralManager: CBPeripheralManager!
    fileprivate let findFoodFastMutableService = CBMutableService.init(type: FindFoodFastService.ServiceUUID, primary: true)
    
    private override init() {}
    
    weak var delegate: BluetoothPeripheralManagerDelegate?
    var isReadyToAdvertise = false
    
    static let sharedInstance: BluetoothPeripheralManager = {
        let instance = BluetoothPeripheralManager()
        instance.peripheralManager = CBPeripheralManager(delegate: instance, queue: nil)
        return instance
    }()
    
    internal func setupPeripheral() {
        let hostNameCharacteristic = CBMutableCharacteristic.init(
                type: FindFoodFastService.CharacteristicUUIDHostName,
                properties: [CBCharacteristicProperties.read,
                             CBCharacteristicProperties.writeWithoutResponse,
                             CBCharacteristicProperties.notify],
                value: nil,
                permissions: [CBAttributePermissions.readable,
                              CBAttributePermissions.writeable]
        )
        let userDescriptionUuid:CBUUID = CBUUID(string:CBUUIDCharacteristicUserDescriptionString)
        let myDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Host name of FindFoodFast session")
        hostNameCharacteristic.descriptors = [myDescriptor]
        findFoodFastMutableService.characteristics = [hostNameCharacteristic]
        
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
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
    }
}
