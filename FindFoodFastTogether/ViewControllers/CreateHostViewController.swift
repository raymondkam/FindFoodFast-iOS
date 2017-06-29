//
//  CreateHostViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-20.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class CreateHostViewController: UIViewController {

    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var goButton: UIButton!

    var username: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (hostnameTextField.text == nil || hostnameTextField.text == "") {
            disableButtons()
        } else {
            enableButtons()
        }

        hostnameTextField.delegate = self
        navigationItem.title = username
    }
    
    func disableButtons() {
        DispatchQueue.main.async {
            self.goButton.isEnabled = false
            self.goButton.backgroundColor = FindFoodFastColor.DisabledColor
        }
    }
    
    func enableButtons() {
        DispatchQueue.main.async {
            self.goButton.isEnabled = true
            self.goButton.backgroundColor = FindFoodFastColor.MainColor
        }
    }

    @IBAction func handleHostNameTextFieldEditingChanged(_ sender: Any) {
        if let count = (sender as! UITextField).text?.characters.count, count > 2 && count <= 29 {
            enableButtons()
        } else {
            disableButtons()
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Segues.HostSession:
            let hostname = hostnameTextField.text!
            (segue.destination as! HostViewController).hostname = hostname
            BluetoothPeripheralManager.sharedInstance.hostSession(name: hostname)
        default:
            print("no such segue")
        }
    }

}

extension CreateHostViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
