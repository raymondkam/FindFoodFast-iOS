//
//  StartViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-19.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var hostButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        if (nameTextField.text == nil || nameTextField.text == "") {
            disableButtons()
        } else {
            enableButtons()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func disableButtons() {
        DispatchQueue.main.async {
            self.searchButton.isEnabled = false
            self.hostButton.isEnabled = false
            self.searchButton.backgroundColor = FindFoodFastColor.DisabledColor
            self.hostButton.backgroundColor = FindFoodFastColor.DisabledColor
        }
    }
    
    func enableButtons() {
        DispatchQueue.main.async {
            self.searchButton.isEnabled = true
            self.hostButton.isEnabled = true
            self.searchButton.backgroundColor = FindFoodFastColor.MainColor
            self.hostButton.backgroundColor = FindFoodFastColor.MainColor
        }
    }
    
    @IBAction func handleUsernameTextFieldEditingChanged(_ sender: Any) {
        if let count = (sender as! UITextField).text?.characters.count, count > 2 && count <= 29 {
            enableButtons()
        } else {
            disableButtons()
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Segues.Search:
            (segue.destination as! BrowseHostViewController).username = nameTextField.text
        case Segues.Host:
            (segue.destination as! CreateHostViewController).username = nameTextField.text
        default:
            print("segue not identified")
        }
    }

}

extension StartViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard (textField.text?.characters.count)! > 2 else {
            print("don't save name into defaults, nil or too short")
            return
        }
        let userDefaults = UserDefaults.standard
        userDefaults.set(textField.text!, forKey: UserDefaultsKeys.Username)
        print("username saved into user defaults")
    }
}
