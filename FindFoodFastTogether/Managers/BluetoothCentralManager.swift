//
//  BluetoothCentralManager.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-21.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothCentralManagerDelegate : class {
    
    func bluetoothCentralManagerDidDiscoverHost(_: BluetoothCentralManager, host: Host)
    func bluetoothCentralManagerDidConnectToHost(_: BluetoothCentralManager, service: CBService, joinSessionCharacteristic: CBCharacteristic)
}

final class BluetoothCentralManager : NSObject {
    
    private var scanTimer = Timer()

    fileprivate var centralManager: CBCentralManager!
    fileprivate var connectedPeripheral: CBPeripheral?
    
    weak var delegate: BluetoothCentralManagerDelegate?
    var uuidToHosts = [String: Host]()
    
    private override init() {}
    
    static let sharedInstance: BluetoothCentralManager = {
        let instance = BluetoothCentralManager()
        instance.centralManager = CBCentralManager(delegate: instance, queue: nil)
        return instance
    }()
    
    func scanWithAutoStop(for scanDuration: Double) {
        guard centralManager.state == CBManagerState.poweredOn else {
            print("bluetooth central manager not powered on")
            return
        }
        
        stopScan()
        clearSavedPeripherals()
        print("starting scan for peripherals")
        scanTimer.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanDuration, repeats: false) { (timer) in
            print("\(scanDuration) seconds has passed, stop scanning for peripherals")
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
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        print("connecting to peripheral with uuid: \(peripheral.identifier.uuidString)")
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnectFromPeripheral() {
        guard connectedPeripheral != nil else {
            print("cannot disconnect if no peripheral is connected")
            return
        }
        centralManager.cancelPeripheralConnection(connectedPeripheral!)
    }

    
    func clearSavedPeripherals() {
        uuidToHosts.removeAll()
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
        print("connected to peripheral with uuid: \(peripheral.identifier.uuidString)")
        stopScan()
        connectedPeripheral = peripheral
        // discover what services are available
        peripheral.discoverServices([FindFoodFastService.ServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let uuidString = peripheral.identifier.uuidString
        guard uuidToHosts[uuidString] == nil else {
            print("discovered peripheral uuid already exists")
            return
        }
        guard advertisementData[CBAdvertisementDataLocalNameKey] != nil else {
            print("discovered peripheral does not have a name")
            return
        }
        print("did discover peripheral uuid: \(uuidString)")
        peripheral.delegate = self
        let newHost = Host(peripheral: peripheral, name: advertisementData[CBAdvertisementDataLocalNameKey] as! String)
        uuidToHosts.updateValue(newHost, forKey: uuidString)
        delegate?.bluetoothCentralManagerDidDiscoverHost(self, host: newHost)
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
        
        peripheral.setNotifyValue(true, for: service.characteristics!.first!)
        
        let joinSessionCharacteristic = service.characteristics?.first(where: { (characteristic) -> Bool in
            characteristic.uuid == FindFoodFastService.CharacteristicUUIDJoinSession
        })
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
