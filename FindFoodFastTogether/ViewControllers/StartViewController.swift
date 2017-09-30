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
    
    var searchGradientLayer: CAGradientLayer!
    var hostGradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load previously saved username if it exists
        let userDefaults = UserDefaults.standard
        if let savedUsername = userDefaults.string(forKey: UserDefaultsKeys.Username) {
            print("loaded previously saved username")
            nameTextField.text = savedUsername
        }
        
        // setup name textfield
        if nameTextField.text?.characters.count == 0 {
            nameTextField.becomeFirstResponder()
        }
        nameTextField.delegate = self
        if (nameTextField.text == nil || nameTextField.text == "") {
            disableButtons()
        } else {
            enableButtons()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if searchButton.layer.sublayers == nil {
            searchGradientLayer = searchButton.addGradientLayer(colors:FindFoodFastColor.seaweedGradient.reversed(), at: nil)
        }
        if hostButton.layer.sublayers == nil {
            hostGradientLayer = hostButton.addGradientLayer(colors: FindFoodFastColor.roseannaGradient.reversed(), at: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToStart(segue: UIStoryboardSegue) {
        // coming from the highest rated suggestion view controller 
        // where the navigation bar is hidden
        navigationController?.isNavigationBarHidden = false
    }
    
    func disableButtons() {
        DispatchQueue.main.async {
            self.searchButton.isEnabled = false
            self.hostButton.isEnabled = false
            self.searchGradientLayer.removeFromSuperlayer()
            self.searchButton.backgroundColor = FindFoodFastColor.DisabledColor
            self.searchButton.setTitleColor(FindFoodFastColor.DisabledTextColor, for: .normal)
            self.hostGradientLayer.removeFromSuperlayer()
            self.hostButton.backgroundColor = FindFoodFastColor.DisabledColor
            self.hostButton.setTitleColor(FindFoodFastColor.DisabledTextColor, for: .normal)
        }
    }
    
    func enableButtons() {
        DispatchQueue.main.async {
            self.searchButton.isEnabled = true
            self.searchButton.layer.insertSublayer(self.searchGradientLayer, at: 0)
            self.searchButton.setTitleColor(.white, for: .normal)
            self.hostButton.isEnabled = true
            self.hostButton.layer.insertSublayer(self.hostGradientLayer, at: 0)
            self.hostButton.setTitleColor(.white, for: .normal)
        }
    }
    
    @IBAction func handleUsernameTextFieldEditingChanged(_ sender: Any) {
        if let count = (sender as! UITextField).text?.characters.count, count > 0 && count <= 40 {
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
