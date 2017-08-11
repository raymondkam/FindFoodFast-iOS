//
//  String+Helpers.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-11.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    var htmlAttributedString: NSAttributedString? {
        guard let data = data(using: String.Encoding.utf8) else { return nil }
        return data.attributedString
    }
    
    var htmlString: String {
        return htmlAttributedString?.string ?? ""
    }
    
}
