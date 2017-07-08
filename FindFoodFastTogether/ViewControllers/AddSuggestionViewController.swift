//
//  AddSuggestionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

protocol AddSuggestionDelegate: class {
    func didAddSuggestion(suggestion: Suggestion)
}

class AddSuggestionViewController: UIViewController {

    @IBOutlet weak var addSuggestionButton: UIButton!
    @IBOutlet weak var suggestionTextField: UITextField!
    
    weak var delegate: AddSuggestionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (suggestionTextField.text == nil || suggestionTextField.text == "") {
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
            self.addSuggestionButton.isEnabled = false
            self.addSuggestionButton.backgroundColor = FindFoodFastColor.DisabledColor
        }
    }
    
    func enableButtons() {
        DispatchQueue.main.async {
            self.addSuggestionButton.isEnabled = true
            self.addSuggestionButton.backgroundColor = FindFoodFastColor.MainColor
        }
    }
    
    @IBAction func handleSuggestionTextFieldChanged(_ sender: Any) {
        if let count = (sender as! UITextField).text?.characters.count, count > 2 && count <= 29 {
            enableButtons()
        } else {
            disableButtons()
        }
    }
    
    @IBAction func handleAddSuggestion(_ sender: Any) {
        guard let suggestionText = suggestionTextField.text else {
            print("invalid suggestion")
            return
        }
        
        let suggestion = Suggestion(name: suggestionText)
        delegate?.didAddSuggestion(suggestion: suggestion)
        navigationController?.popViewController(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AddSuggestionViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
