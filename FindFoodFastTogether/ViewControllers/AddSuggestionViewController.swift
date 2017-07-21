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
    func isUniqueSuggestion(suggestion: Suggestion) -> Bool
}

class AddSuggestionViewController: UIViewController {

    @IBOutlet weak var addSuggestionButton: UIButton!
    @IBOutlet weak var suggestionTextField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    weak var delegate: AddSuggestionDelegate?
    
    let SuggestionTextFieldMinCharacterCount = 2
    let SuggestionTextFieldMaxCharacterCount = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()

        suggestionTextField.delegate = self
        suggestionTextField.becomeFirstResponder()
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
    
    private func disableButtons() {
        DispatchQueue.main.async { [weak self] in
            self?.addSuggestionButton.isEnabled = false
            self?.addSuggestionButton.backgroundColor = FindFoodFastColor.DisabledColor
        }
    }
    
    private func enableButtons() {
        DispatchQueue.main.async { [weak self] in
            self?.addSuggestionButton.isEnabled = true
            self?.addSuggestionButton.backgroundColor = FindFoodFastColor.MainColor
        }
    }
    
    private func showError(message: String) {
        suggestionTextField.borderWidth = 1
        suggestionTextField.borderColor = FindFoodFastColor.ErrorColor
        errorMessageLabel.text = message
        errorMessageLabel.isHidden = false
    }
    
    fileprivate func hideError() {
        suggestionTextField.borderWidth = 0
        suggestionTextField.borderColor = UIColor.clear
        errorMessageLabel.text = ""
        errorMessageLabel.isHidden = true
    }
    
    @IBAction func handleSuggestionTextFieldChanged(_ sender: Any) {
        guard let textField = sender as? UITextField else {
            print("sender not a textfield")
            return
        }
        
        if let count = textField.text?.characters.count, count > SuggestionTextFieldMinCharacterCount && count <= SuggestionTextFieldMaxCharacterCount {
            
            guard let suggestionName = textField.text?.trimmingCharacters(in: .whitespaces) else {
                print("no suggestion name in text field")
                return
            }
            
            let suggestion = Suggestion(name: suggestionName, rating: 0)
            guard let isUniqueSuggestion = delegate?.isUniqueSuggestion(suggestion: suggestion) else {
                print("add suggestion delegate is nil")
                return
            }
            
            if isUniqueSuggestion {
                hideError()
                enableButtons()
            } else {
                showError(message: "Suggestion has already been added")
                disableButtons()
            }
            
        } else {
            disableButtons()
        }
    }
    
    @IBAction func handleAddSuggestion(_ sender: Any) {
        guard let suggestionText = suggestionTextField.text?.trimmingCharacters(in: .whitespaces) else {
            print("invalid suggestion")
            return
        }
        
        let suggestion = Suggestion(name: suggestionText, rating: 0)
        delegate?.didAddSuggestion(suggestion: suggestion)
        navigationController?.popViewController(animated: true)
    }
}

extension AddSuggestionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        hideError()
        return true
    }
}
