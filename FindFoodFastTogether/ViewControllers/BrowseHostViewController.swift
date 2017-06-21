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
    
    fileprivate var bluetoothCentralManager: CBCentralManager!
    fileprivate var bluetoothDevices: Set<String> = []
    fileprivate var connectedPeripheral: CBPeripheral!
    fileprivate var discoveredPeripherals: Set<CBPeripheral> = []
    
    var username: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = username
        
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
            print("bluetooth powered on, preparing to scan for peripherals")
            central.scanForPeripherals(withServices: [FindFoodFastService.ServiceUUID], options: nil)
            DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
                print("30 seconds has passed, stop scanning for peripherals")
                central.stopScan()
            }
        default:
            print("default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        central.stopScan()
        // discover what services are available
        peripheral.discoverServices([FindFoodFastService.ServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard !discoveredPeripherals.contains(peripheral) else {
            print("peripheral uuid already exists")
            return
        }
        print("did discover peripheral uuid: \(peripheral.identifier.uuidString)")
        peripheral.delegate = self
        discoveredPeripherals.insert(peripheral)
//        bluetoothCentralManager.connect(peripheral, options: nil)
    }
}

extension BrowseHostViewController : CBPeripheralDelegate {
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("did discover services \(peripheral)")
        guard error == nil else {
            print("error discovering services: \(String(describing: error?.localizedDescription))")
            return
        }
        guard let services = peripheral.services, services.count > 0 else {
            print("peripheral services nil or has no services")
            return
        }
        peripheral.discoverCharacteristics([FindFoodFastService.CharacteristicUUIDHostName], for: services.first!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("error discovering characteristic: \(String(describing: error?.localizedDescription))")
            return
        }
        guard (service.characteristics?.count)! > 0 else {
            print("no characteristics found for service")
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
