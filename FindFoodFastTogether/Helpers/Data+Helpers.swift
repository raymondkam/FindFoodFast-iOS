//
//  Data+Helpers.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-11.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import UIKit

extension Data {
    var attributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options:[NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
}
