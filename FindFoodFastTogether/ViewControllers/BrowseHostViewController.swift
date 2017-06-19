//
//  BrowseHostViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-13.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreBluetooth

class BrowseHostViewController: UIViewController {
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    var bluetoothCentralManager: CBCentralManager!
    var bluetoothDevices: Set<String> = []
    var findFoodFastPeripheral: CBPeripheral!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fake the loading
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (timer) in
            self.loadingView.isHidden = true
            self.containerView.isHidden = false
        }
        
        bluetoothCentralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
}

extension BrowseHostViewController : CBCentralManagerDelegate {
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: [FindFoodFastService.ServiceUUID], options: nil)
        default:
            print("default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // discover what services are available
        peripheral.discoverServices([FindFoodFastService.ServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("did discover")
        if findFoodFastPeripheral != peripheral {
            findFoodFastPeripheral = peripheral
            findFoodFastPeripheral.delegate = self
        }
        bluetoothCentralManager.connect(findFoodFastPeripheral, options: nil)
    }
}

extension BrowseHostViewController : CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("error discovering services: \(String(describing: error?.localizedDescription))")
            return
        }
        guard let services = peripheral.services else {
            print("peripheral services not found")
            return
        }
        peripheral.discoverCharacteristics([FindFoodFastService.CharacteristicUUIDHostName], for: services.first!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("error discovering characteristic: \(String(describing: error?.localizedDescription))")
            return
        }
        print("discovered host name characteristic")
        let name = "RaymondRaymondRaymondRaymondRaymond"
        peripheral.writeValue(name.data(using: String.Encoding.utf8)!, for: service.characteristics!.first!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}
