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
    @IBOutlet weak var goButton: UIBarButtonItem!
    @IBOutlet weak var contentView: UIView!

    var username: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (hostnameTextField.text == nil || hostnameTextField.text == "") {
            disableButtons()
        } else {
            enableButtons()
        }
        
        hostnameTextField.delegate = self
        hostnameTextField.becomeFirstResponder()
        
        contentView.addGradientLayer(colors: FindFoodFastColor.roseannaGradient.reversed(), at: 0)
    }
    
    func disableButtons() {
        goButton.isEnabled = false
    }
    
    func enableButtons() {
        goButton.isEnabled = true
    }

    @IBAction func handleHostNameTextFieldEditingChanged(_ sender: Any) {
        if let count = (sender as! UITextField).text?.characters.count, count > 0 && count <= 40 {
            enableButtons()
        } else {
            disableButtons()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.tintColor = FindFoodFastColor.pinkColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.tintColor = FindFoodFastColor.greenColor
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Segues.HostSession:
            let hostname = hostnameTextField.text!
            let hostViewController = (segue.destination as! HostViewController)
            hostViewController.hostname = hostname
            hostViewController.username = username
            hostViewController.isHosting = true
            BluetoothPeripheralManager.sharedInstance.delegate = hostViewController
        default:
            print("no such segue")
        }
    }

}

extension CreateHostViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        performSegue(withIdentifier: Segues.HostSession, sender: self)
        textField.resignFirstResponder()
        return true
    }
    
}
