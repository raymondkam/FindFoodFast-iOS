//
//  HostViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-14.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreBluetooth

class HostViewController: UIViewController {

    var peripheralManager : CBPeripheralManager!
    var findFoodFastMutableService : CBMutableService!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager.init(delegate: self, queue: nil)
    }
}

extension HostViewController : CBPeripheralManagerDelegate {
    func setupPeripheral() {
        findFoodFastMutableService = CBMutableService.init(type: FindFoodFastService.ServiceUUID, primary: true)
        
        let hostNameCharacteristic = CBMutableCharacteristic.init(type: FindFoodFastService.CharacteristicUUIDHostName, properties: [CBCharacteristicProperties.read, CBCharacteristicProperties.writeWithoutResponse], value: nil, permissions: [CBAttributePermissions.readable, CBAttributePermissions.writeable])
        let userDescriptionUuid:CBUUID = CBUUID(string:CBUUIDCharacteristicUserDescriptionString)
        let myDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Host name of FindFoodFast session")
        hostNameCharacteristic.descriptors = [myDescriptor]
        findFoodFastMutableService.characteristics = [hostNameCharacteristic]
        
        peripheralManager.add(findFoodFastMutableService)
    }
    
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
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [service.uuid]])
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
    }
}
