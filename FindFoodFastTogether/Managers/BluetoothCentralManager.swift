//
//  BluetoothCentralManager.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-21.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

protocol BluetoothCentralManagerDelegate : class {
    func bluetoothCentralManagerDidDiscoverHost(_: BluetoothCentralManager, host: Host)
    func bluetoothCentralManagerDidConnectToHost(_: BluetoothCentralManager, users: [User])
    func bluetoothCentralManagerDidReceiveSuggestions(_: BluetoothCentralManager, suggestions: [Suggestion])
    func bluetoothCentralManagerDidStartVoting(_: BluetoothCentralManager)
    func bluetoothCentralManagerDidReceiveHighestRatedSuggestion(_: BluetoothCentralManager, highestRatedSuggestion: Suggestion)
}

final class BluetoothCentralManager : NSObject {
    
    private var scanTimer = Timer()

    fileprivate var centralManager: CBCentralManager!
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var subscribedCharacteristics = [CBCharacteristic]()
    fileprivate var suggestionCharacteristic: CBCharacteristic?
    fileprivate var votingCharacteristic: CBCharacteristic?
    fileprivate var receivedData: Data?
    
    // for writing large payloads to characteristic
    fileprivate var dataToSend: Data?
    fileprivate var sendDataIndex: Int?
    fileprivate var sendingEOM = false
    fileprivate var sendToCharacteristic: CBCharacteristic?
    fileprivate let BLEWriteToCharacteristicMaxSize = 20
    fileprivate var retryNumber = 0
    fileprivate let maxRetryNumber = 5
    
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
        guard let connectedPeripheral = connectedPeripheral else {
            print("cannot disconnect if no peripheral is connected")
            return
        }
        
        clearDataTransferParameters()
        
        subscribedCharacteristics.forEach { (characteristic) in
            connectedPeripheral.setNotifyValue(false, for: characteristic)
        }
        subscribedCharacteristics.removeAll()
        centralManager.cancelPeripheralConnection(connectedPeripheral)
        print("successfully disconnected from peripheral")
    }

    
    func clearSavedPeripherals() {
        uuidToHosts.removeAll()
    }
    
    func clearDataTransferParameters() {
        receivedData = nil
        dataToSend = nil
        sendDataIndex = 0
        sendingEOM = false
    }
    
    func sendHostNewSuggestion(suggestion: Suggestion) {
        guard let suggestionCharacteristic = suggestionCharacteristic else {
            print("suggestion characteristic not saved")
            return
        }
        
        dataToSend  = NSKeyedArchiver.archivedData(withRootObject: suggestion)
        sendDataIndex = 0
        sendToCharacteristic = suggestionCharacteristic
        sendData()
    }
    
    func sendHostVotedSuggestions(votedSuggestions: [Suggestion]) {
        guard let votingCharacteristic = votingCharacteristic else {
            print("voting characteristic not saved, cannot send voted suggestions")
            return
        }
        
        dataToSend = NSKeyedArchiver.archivedData(withRootObject: votedSuggestions)
        sendDataIndex = 0
        sendToCharacteristic = votingCharacteristic
        sendData()
    }
    
    func sendData() {
        guard sendToCharacteristic != nil else {
            print("no specified characteristic to send to")
            return
        }
        
        if sendingEOM {
            connectedPeripheral?.writeValue("EOM".data(using: .utf8)!, for: sendToCharacteristic!, type: .withResponse)
        } else {
            // Make the next chunk
            
            // Work out how big it should be
            var amountToSend = dataToSend!.count - sendDataIndex!;
            
            // Can only send maximum of 20 bytes
            if (amountToSend > BLEWriteToCharacteristicMaxSize) {
                amountToSend = BLEWriteToCharacteristicMaxSize
            }
            
            // Copy out the data we want
            let chunk = dataToSend!.withUnsafeBytes{(body: UnsafePointer<UInt8>) in
                return Data(
                    bytes: body + sendDataIndex!,
                    count: amountToSend
                )
            }
            
            connectedPeripheral?.writeValue(chunk, for: sendToCharacteristic!, type: .withResponse)
        }
        
    }
}


extension BluetoothCentralManager : CBCentralManagerDelegate {
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("bluetooth powered on, preparing to scan for peripherals")
            NotificationCenter.default.post(name: NotificationNames.CentralBluetoothPoweredOn, object: nil)
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
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as! String
        print("did discover peripheral name: \(name), uuid: \(uuidString)")
        peripheral.delegate = self
        let newHost = Host(peripheral: peripheral, name: name)
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
        guard let findFoodFastService = services.first(where: { (service) -> Bool in
            return service.uuid == FindFoodFastService.ServiceUUID
        }) else {
            print("did not find FindFoodFast service")
            return
        }
        peripheral.discoverCharacteristics([FindFoodFastService.CharacteristicUUIDJoinSession, FindFoodFastService.CharacteristicUUIDSuggestion, FindFoodFastService.CharacteristicUUIDVoting, FindFoodFastService.CharacteristicUUIDHighestRatedSuggestion], for: findFoodFastService)
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
        
        guard let characteristics = service.characteristics else {
            print("no characteristics discovered")
            return
        }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            case FindFoodFastService.CharacteristicUUIDJoinSession:
                // subscribe to characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                subscribedCharacteristics.append(characteristic)
                print("subscribed to join session characteristic")
                
                let userDefaults = UserDefaults.standard
                if let username  = userDefaults.string(forKey: UserDefaultsKeys.Username) {
                    print("retrieved username from user defaults: \(username)")
                    peripheral.writeValue(username.data(using: .utf8)!, for: characteristic, type: .withoutResponse)
                }
            case FindFoodFastService.CharacteristicUUIDSuggestion:
                print("subscribed to suggestions characteristic")
                peripheral.setNotifyValue(true, for: characteristic)
                subscribedCharacteristics.append(characteristic)
                // hold onto the suggestion characteristic so it is easier to
                // send suggestions later
                suggestionCharacteristic = characteristic
            case FindFoodFastService.CharacteristicUUIDVoting:
                peripheral.setNotifyValue(true, for: characteristic)
                subscribedCharacteristics.append(characteristic)
                // hold onto the voting characteristic to send the host their votes
                votingCharacteristic = characteristic
            case FindFoodFastService.CharacteristicUUIDHighestRatedSuggestion:
                peripheral.setNotifyValue(true, for: characteristic)
                subscribedCharacteristics.append(characteristic)
            default:
                print("characteristic not recognized")
            }
        }
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
    
    /*
     * Callback for successful write to characteristic, used for writing large
     * payloads to a characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            if (retryNumber < maxRetryNumber) {
                // retry packet if there is an error
                print("peripheral did write value failed, error: \(String(describing: error?.localizedDescription)), retry number \(retryNumber) in 1 second...")
                // retry after 1 second
                DispatchQueue.global().asyncAfter(deadline: .now() + 1 , execute: { [weak self] () in
                    print("retry sending data")
                    self?.sendData()
                })
                retryNumber += 1
            }
            return
        }
        
        // success, reset retry number
        retryNumber = 0
        
        if (sendingEOM) {
            // finished sending EOM, can clean up
            sendingEOM = false
            print("EOM successfully sent")
            dataToSend = nil
            sendToCharacteristic = nil
        } else {
            // update the index if it was sent
            sendDataIndex! += BLEWriteToCharacteristicMaxSize
            
            print("Sent: \(sendDataIndex!)/\(dataToSend!.count) bytes")
            
            if (sendDataIndex! >= dataToSend!.count) {
                sendingEOM = true
            }
            
            sendData()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("error receiving update for characteristic: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if characteristic.uuid == FindFoodFastService.CharacteristicUUIDVoting {
            // received the start of voting
            delegate?.bluetoothCentralManagerDidStartVoting(self)
        } else {
            
            // This block can handle data transfer for the join 
            // session characteristic, suggestion characteristic, 
            // and the highest rated suggestion characteristic
            
            guard receivedData != nil else {
                // if receivedData is nil, then we are receiving the first chunk
                receivedData = characteristic.value!
                return
            }
            
            let stringFromData = String.init(data: characteristic.value!, encoding: .utf8)
            if stringFromData == "EOM" {
                // handle data received from different characteristics differently
                switch characteristic.uuid {
                case FindFoodFastService.CharacteristicUUIDJoinSession:
                    print("received list of connected users")
                    // received all data
                    guard let uuidStringToUsername = NSKeyedUnarchiver.unarchiveObject(with: receivedData!) as? [String: String] else {
                        print("was not able to unarchive list of connected users")
                        return
                    }
                    let connectedUsers = uuidStringToUsername.map({ (uuidString, username) -> User in
                        let user = User(name: username, uuidString: uuidString)
                        return user
                    })
                    delegate?.bluetoothCentralManagerDidConnectToHost(self, users: connectedUsers)
                case FindFoodFastService.CharacteristicUUIDSuggestion:
                    print("received list of suggestions")
                    guard let suggestions = NSKeyedUnarchiver.unarchiveObject(with: receivedData!) as? [Suggestion] else {
                        print("was not able to unarchive list of suggestions")
                        return
                    }
                    delegate?.bluetoothCentralManagerDidReceiveSuggestions(self, suggestions: suggestions)
                case FindFoodFastService.CharacteristicUUIDHighestRatedSuggestion:
                    guard let highestRatedSuggestion = NSKeyedUnarchiver.unarchiveObject(with: receivedData!) as? Suggestion else {
                        print("was not able to unarchive highest rated suggestion")
                        return
                    }
                    print("received highest rated suggestion: \(highestRatedSuggestion)")
                    delegate?.bluetoothCentralManagerDidReceiveHighestRatedSuggestion(self, highestRatedSuggestion: highestRatedSuggestion)
                default:
                    print("characteristic uuid not recognized")
                }
                
                // clear received data for next transmission
                receivedData = nil
            } else {
                // append the data
                receivedData!.append(characteristic.value!)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}
