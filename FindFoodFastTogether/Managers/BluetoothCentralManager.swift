//
//  BluetoothCentralManager.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-21.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BluetoothCentralManager : NSObject {
    
    private let ScanDuration = 15.0
    
    fileprivate var centralManager: CBCentralManager!
    
    var savedPeripheralWithAdvertisementData = [String : (CBPeripheral, [String : Any])]()
    var scanTimer = Timer()
    
    private override init() {}
    
    static let sharedInstance: BluetoothCentralManager = {
        let instance = BluetoothCentralManager()
        instance.centralManager = CBCentralManager(delegate: instance, queue: nil)
        return instance
    }()
    
    func scanWithAutoStop() {
        guard centralManager.state == CBManagerState.poweredOn else {
            print("bluetooth central manager not powered on")
            return
        }
        
        stopScan()
        clearSavedPeripherals()
        print("starting scan for peripherals")
        scanTimer.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: ScanDuration, repeats: false) { (timer) in
            print("\(self.ScanDuration) seconds has passed, stop scanning for peripherals")
            self.stopScan()
        }
        centralManager.scanForPeripherals(withServices: [FindFoodFastService.ServiceUUID], options: nil)
    }
    
    func stopScan() {
        guard centralManager.state == CBManagerState.poweredOn else {
            print("bluetooth central manager not powered on")
            return
        }
        guard centralManager.isScanning else {
            print("cannot stop scanning if was never scanning to begin with")
            return
        }
        print("stop scanning for peripherals")
        centralManager.stopScan()
    }
    
    func clearSavedPeripherals() {
        savedPeripheralWithAdvertisementData.removeAll()
    }
}


extension BluetoothCentralManager : CBCentralManagerDelegate {
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("bluetooth powered on, preparing to scan for peripherals")
            NotificationCenter.default.post(name: NotificationNames.BluetoothPoweredOn, object: nil)
        default:
            print("bluetooth central state not recognized")
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
        guard savedPeripheralWithAdvertisementData[peripheral.identifier.uuidString] == nil else {
            print("peripheral uuid already exists")
            return
        }
        print("did discover peripheral uuid: \(peripheral.identifier.uuidString)")
        peripheral.delegate = self
        savedPeripheralWithAdvertisementData.updateValue((peripheral, advertisementData), forKey: peripheral.identifier.uuidString)
        NotificationCenter.default.post(name: NotificationNames.BluetoothDiscoveredNewPeripheral, object: nil)
    }
}

extension BluetoothCentralManager : CBPeripheralDelegate {
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
