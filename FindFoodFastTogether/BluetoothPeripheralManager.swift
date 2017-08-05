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
    func bluetoothPeripheralManagerDidReceiveNewSuggestion(_: BluetoothPeripheralManager, suggestion: Suggestion)
    func bluetoothPeripheralManagerDidReceiveSuggestionIdsToRemove(_: BluetoothPeripheralManager, suggestionIds: [String])
    func bluetoothPeripheralManagerDidReceiveVotes(_: BluetoothPeripheralManager, votes: [Vote], from central: CBCentral)
}

final class BluetoothPeripheralManager : NSObject {
    
    fileprivate var peripheralManager: CBPeripheralManager!
    fileprivate let findFoodFastMutableService = CBMutableService(type: FindFoodFastService.ServiceUUID, primary: true)
    fileprivate let joinSessionCharacteristic = CBMutableCharacteristic.init(
        type: FindFoodFastService.CharacteristicUUIDJoinSession,
        properties: [.read,
                     .writeWithoutResponse,
                     .notify],
        value: nil,
        permissions: [.readable,
                      .writeable]
    )
    fileprivate let suggestionCharacteristic = CBMutableCharacteristic(
        type: FindFoodFastService.CharacteristicUUIDSuggestion,
        properties: [.read,
                     .write,
                     .notify],
        value: nil,
        permissions: [.readable,
                      .writeable]
    )
    fileprivate let votingCharacteristic = CBMutableCharacteristic(
        type: FindFoodFastService.CharacteristicUUIDVoting,
        properties: [.read,
                     .write,
                     .notify],
        value: nil,
        permissions: [.readable,
                      .writeable])
    fileprivate let highestRatedSuggestionCharacteristic = CBMutableCharacteristic(
        type: FindFoodFastService.CharacteristicUUIDHighestRatedSuggestion,
        properties: [.read,
                     .write,
                     .notify],
        value: nil,
        permissions: [.readable,
                      .writeable])
    fileprivate var uuidStringToUsername = [String: String]()
    
    // For convenience when a new user joins and wants to receive
    // the current list of suggestions, gets updated from time to 
    // time by the suggestions collection view controller.
    var suggestions = [Suggestion]()
    
    // Variables related to sending data
    fileprivate var dataToSend: Data?
    fileprivate var sendDataIndex: Int?
    fileprivate var maximumBytesInPayload = 512 // 512 bytes is the theoretical maximum
    fileprivate var sendToCharacteristic: CBMutableCharacteristic?
    fileprivate var sendingEOM = false
    
    // Variables related to receiving data
    fileprivate var receivedData = [String: Data]()
    
    // public
    weak var delegate: BluetoothPeripheralManagerDelegate?
    var isReadyToAdvertise = false
    var subscribedCentrals = [CBCentral]()
    
    // private hidden initializer
    private override init() {}
    
    static let sharedInstance: BluetoothPeripheralManager = {
        let instance = BluetoothPeripheralManager()
        instance.peripheralManager = CBPeripheralManager(delegate: instance, queue: nil)
        return instance
    }()
    
    // MARK: - Peripheral Control
    
    internal func setupPeripheral() {
        
        let userDescriptionUuid:CBUUID = CBUUID(string:CBUUIDCharacteristicUserDescriptionString)
        let joinSessionDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Know who is connected via subscription to this characteristic")
        joinSessionCharacteristic.descriptors = [joinSessionDescriptor]
        
        let suggestionsDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Know what suggestions there are in the session")
        suggestionCharacteristic.descriptors = [suggestionsDescriptor]
        
        let votingDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Know when voting begins and where voting results are sent to")
        votingCharacteristic.descriptors = [votingDescriptor]
        
        let highestRatedSuggestionDescriptor = CBMutableDescriptor(type:userDescriptionUuid, value:"Find out what the highest rated suggestion was at the end of voting")
        highestRatedSuggestionCharacteristic.descriptors = [highestRatedSuggestionDescriptor]
        
        findFoodFastMutableService.characteristics = [joinSessionCharacteristic, suggestionCharacteristic, votingCharacteristic, highestRatedSuggestionCharacteristic]
        
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
    
    func clearPeripheralData() {
        uuidStringToUsername.removeAll()
        suggestions.removeAll()
        subscribedCentrals.removeAll()
    }
    
    func resetPeripheral() {
        clearPeripheralData()
        peripheralManager.removeAllServices()
        setupPeripheral()
    }
    
    // MARK: - Characteristic Data Transfer
    
    /* 
     * Sends to subscribers the updated list of users in the host's session
     */
    fileprivate func sendConnectedUsersList() {
        guard subscribedCentrals.count > 0 else {
            print("no subscribed centrals to send connected users list")
            return
        }
        print("sending list of connected users to clients")
        // make sure uuid string and username are not empty or incomplete
        let filteredUuidStringToUsernameArray = uuidStringToUsername.filter { (uuidString, username) -> Bool in
            return uuidString.characters.count > 0 && username.characters.count > 0
        }
        var filteredUuidStringToUsername = [String:String]()
        for result in filteredUuidStringToUsernameArray {
            filteredUuidStringToUsername[result.0] = result.1
        }
        // add self to the list of users
        let userDefaults = UserDefaults.standard
        if let hostUsername  = userDefaults.string(forKey: UserDefaultsKeys.Username) {
            filteredUuidStringToUsername.updateValue(hostUsername, forKey: Bluetooth.deviceUuidString!)
        }

        send(filteredUuidStringToUsername, for: joinSessionCharacteristic)
    }
    
    fileprivate func sendSuggestions() {
        guard subscribedCentrals.count > 0 else {
            print("no subscribed centrals to send suggestions to")
            return
        }
        print("sending suggestions to clients")
        let suggestionsData = NSKeyedArchiver.archivedData(withRootObject: suggestions)
        let suggestionOperation = SuggestionOperation(type: SuggestionOperationType.All, data: suggestionsData)
        send(suggestionOperation, for: suggestionCharacteristic)
    }
    
    func sendAddedNewSuggestion(_ suggestion: Suggestion) {
        guard subscribedCentrals.count > 0 else {
            print("no subscribed centrals to send added suggestion to")
            return
        }
        let suggestionData = NSKeyedArchiver.archivedData(withRootObject: suggestion)
        let suggestionOperation = SuggestionOperation(type: SuggestionOperationType.Add, data: suggestionData)
        send(suggestionOperation, for: suggestionCharacteristic)
    }
    
    func sendRemoveSuggestionsIds(_ suggestionIds: [String]) {
        guard subscribedCentrals.count > 0 else {
            print("no subscribed centrals to send removed suggestion ids to")
            return
        }
        let suggestionIdsData = NSKeyedArchiver.archivedData(withRootObject: suggestionIds)
        let suggestionOperation = SuggestionOperation(type: SuggestionOperationType.Remove, data: suggestionIdsData)
        send(suggestionOperation, for: suggestionCharacteristic)
    }
    
    func startVoting() {
        guard subscribedCentrals.count > 0 else {
            print("no subscribed centrals to send start voting message to")
            return
        }
        peripheralManager.updateValue("start".data(using: .utf8)!, for: votingCharacteristic, onSubscribedCentrals: nil)
    }
    
    func sendHighestRatedSuggestion(highestRatedSuggestion: Suggestion) {
        guard subscribedCentrals.count > 0 else {
            print("no subscribed centrals to send highest rated suggestion to")
            return
        }
        print("sending highest rated suggestion to clients")
        send(highestRatedSuggestion, for: highestRatedSuggestionCharacteristic)
    }
    
    fileprivate func send(_ object: Any, for characteristic: CBMutableCharacteristic) {
        dataToSend = NSKeyedArchiver.archivedData(withRootObject: object)
        sendDataIndex = 0
        sendToCharacteristic = characteristic
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
        guard sendToCharacteristic != nil else {
            print("no specified characteristic to send to")
            return
        }
        
        if sendingEOM {
            // send it
            let didSend = peripheralManager?.updateValue(
                "EOM".data(using: String.Encoding.utf8)!,
                for: sendToCharacteristic!,
                onSubscribedCentrals: nil
            )
            
            // Did it send?
            if (didSend == true) {
                
                // It did, so mark it as sent
                sendingEOM = false
                
                print("Sent: EOM")
                
                // remove data stored in variable
                dataToSend = nil
                sendToCharacteristic = nil
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
                for: sendToCharacteristic!,
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
                    for: sendToCharacteristic!,
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
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
    }
    
    // MARK: Receiving data from clients
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("peripheral manager: did receive write request")
        requests.forEach { (request) in
            let centralUuidString = request.central.identifier.uuidString
            switch request.characteristic.uuid {
            case FindFoodFastService.CharacteristicUUIDJoinSession:
                // MARK: Handle new user joining
                print("received write to join session characteristic")
                
                if let name = uuidStringToUsername[centralUuidString], name == "" {
                    if let data = request.value {
                        let username = String.init(data: data, encoding: String.Encoding.utf8)!
                        
                        // update internal dictionary of users
                        uuidStringToUsername.updateValue(username, forKey: centralUuidString)
                        
                        // update UI
                        let newUser = User(name: username, uuidString: centralUuidString)
                        print("peripheral manager: new user connected: \(newUser)")
                        delegate?.bluetoothPeripheralManagerDidConnectWith(self, newUser: newUser)
                        
                        // send new list of connected users to everyone
                        sendConnectedUsersList()
                    }
                }
            case FindFoodFastService.CharacteristicUUIDSuggestion:
                // MARK: Handle suggestion operation sent by user
                print("received write for suggestion")
                guard let data = request.value else {
                    print("request for suggestion has nil data")
                    peripheral.respond(to: request, withResult: .requestNotSupported)
                    return
                }
                guard receivedData[centralUuidString] != nil else {
                    // if receivedData is nil, then this is the first chunk
                    receivedData[centralUuidString] = data
                    peripheral.respond(to: request, withResult: .success)
                    return
                }
                
                let stringFromData = String.init(data: data, encoding: .utf8)
                if stringFromData == "EOM" {
                    guard let suggestionOperation = NSKeyedUnarchiver.unarchiveObject(with: receivedData[centralUuidString]!) as? SuggestionOperation else {
                        print("invalid suggestion unarchived")
                        peripheral.respond(to: request, withResult: .requestNotSupported)
                        clearReceivedData(fromCentralUuid: centralUuidString)
                        return
                    }
                    switch suggestionOperation.type {
                    case SuggestionOperationType.Add:
                        guard let suggestion = NSKeyedUnarchiver.unarchiveObject(with: suggestionOperation.data) as? Suggestion else {
                            print("could not unarchive added suggestion data")
                            clearReceivedData(fromCentralUuid: centralUuidString)
                            return
                        }
                        delegate?.bluetoothPeripheralManagerDidReceiveNewSuggestion(self, suggestion: suggestion)
                    case SuggestionOperationType.Remove:
                        guard let suggestionIds = NSKeyedUnarchiver.unarchiveObject(with: suggestionOperation.data) as? [String] else {
                            print("could not unarchive suggestion ids to remove")
                            clearReceivedData(fromCentralUuid: centralUuidString)
                            return
                        }
                        delegate?.bluetoothPeripheralManagerDidReceiveSuggestionIdsToRemove(self, suggestionIds: suggestionIds)
                    default:
                        assert(false, "unexpected suggestion operation received from user")
                    }
                    
                    // clear received data for next transmission
                    clearReceivedData(fromCentralUuid: centralUuidString)
                } else {
                    // not done receiving all data, append the data
                    receivedData[centralUuidString]!.append(data)
                }
                peripheral.respond(to: request, withResult: .success)
            case FindFoodFastService.CharacteristicUUIDVoting:
                // MARK: Handle votes received from user
                guard let data = request.value else {
                    print("voting request has nil data")
                    return
                }
                guard receivedData[centralUuidString] != nil else {
                    // if received data is nil, then is first chunk
                    receivedData[centralUuidString] = data
                    peripheral.respond(to: request, withResult: .success)
                    return
                }
                let stringFromData = String.init(data: data, encoding: .utf8)
                if stringFromData == "EOM" {
                    guard let votes = NSKeyedUnarchiver.unarchiveObject(with: receivedData[centralUuidString]!) as? [Vote] else {
                        print("invalid voted suggestions unarchived")
                        peripheral.respond(to: request, withResult: .requestNotSupported)
                        return
                    }
                    delegate?.bluetoothPeripheralManagerDidReceiveVotes(self, votes: votes, from: request.central)
                    
                    // clear received data for next transmission
                    receivedData[centralUuidString] = nil
                } else {
                    // not done receiving all data, append the data
                    receivedData[centralUuidString]!.append(data)
                }
                peripheral.respond(to: request, withResult: .success)
            default:
                print("write to unknown characteristic")
            }
        }
    }
    
    func clearReceivedData(fromCentralUuid centralUuid: String) {
        // clear received data for next transmission
        receivedData[centralUuid] = nil
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
        case FindFoodFastService.CharacteristicUUIDSuggestion:
            // send central the list of current suggestions
            if (suggestions.count > 0) {
                sendSuggestions()
            } else {
                print("session has no suggestions, nothing to send")
            }
        case FindFoodFastService.CharacteristicUUIDVoting:
            print("user subscribed to voting characteristic")
        case FindFoodFastService.CharacteristicUUIDHighestRatedSuggestion:
            print("user subscribed to highest rated suggestion characteristic")
        default:
            print("characteristic subscribed to not recognized")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case FindFoodFastService.CharacteristicUUIDJoinSession:
            guard let index = subscribedCentrals.index(of: central) else {
                print("index of disconnected central not found")
                return
            }
            subscribedCentrals.remove(at: index)
            let disconnectedUserUuidString = central.identifier.uuidString
            if let username = uuidStringToUsername[disconnectedUserUuidString] {
                // remove from internal user dictionary
                uuidStringToUsername[disconnectedUserUuidString] = nil
                
                // create a new user with the username and uuid, would work since
                // User is a struct and update UI
                let disconnectedUser = User(name: username, uuidString: disconnectedUserUuidString)
                delegate?.bluetoothPeripheralManagerDidDisconnectWith(self, user: disconnectedUser)
                
                // send new list of connected users to everyone
                sendConnectedUsersList()
            }
        default:
            print("nothing to clean up for unsubscribing characteristic")
        }
    }
}
