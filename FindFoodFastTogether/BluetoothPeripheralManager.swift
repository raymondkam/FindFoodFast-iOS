//
//  BluetoothPeripheralManager.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-27.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BluetoothPeripheralManager : NSObject {
    
    fileprivate var peripheralManager: CBPeripheralManager!
    fileprivate let findFoodFastMutableService = CBMutableService.init(type: FindFoodFastService.ServiceUUID, primary: true)
    fileprivate var hostname: String?
    
    private override init() {}
    private var deferPeripheralSetup = false
    
    static let sharedInstance: BluetoothPeripheralManager = {
        let instance = BluetoothPeripheralManager()
        instance.peripheralManager = CBPeripheralManager(delegate: instance, queue: nil)
        return instance
    }()
    
    deinit {
        
    }
    
    func hostSession(name: String) {
        self.hostname = name
        if (peripheralManager.state == CBManagerState.poweredOn) {
            deferPeripheralSetup = false
            setupPeripheral()
        } else {
            // observe when the peripheral powers on and start setup
            deferPeripheralSetup = true
            NotificationCenter.default.addObserver(self, selector: #selector(setupPeripheral), name: NotificationNames.PeripheralBluetoothPoweredOn, object: nil)
        }
    }
    
    func setupPeripheral() {
        if (deferPeripheralSetup) {
            // can remove the observer for powering on
            NotificationCenter.default.removeObserver(self, name: NotificationNames.PeripheralBluetoothPoweredOn, object: nil)
        }
        
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
}

extension BluetoothPeripheralManager : CBPeripheralManagerDelegate {
    // MARK: - CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            NotificationCenter.default.post(name: NotificationNames.PeripheralBluetoothPoweredOn, object: nil)
        default:
            print("default")
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard error == nil else {
            print("error during did start service")
            print(error!)
            return
        }
        print("Started advertising")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            print("error adding the service to peripheral manager")
            print(error!)
            return
        }
        if service == findFoodFastMutableService {
            print("starting advertising")
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.uuid], CBAdvertisementDataLocalNameKey: hostname!])
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
    }
}
