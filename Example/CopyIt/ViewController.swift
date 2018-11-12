//
//  ViewController.swift
//  CopyIt
//
//  Created by isapozhnik on 11/11/2018.
//  Copyright (c) 2018 isapozhnik. All rights reserved.
//

import UIKit
import CopyIt

class MyView: UIView, Copiable {}
extension UILabel: Copiable {}

class ViewController: UIViewController {
    @IBOutlet weak var someView: MyView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        someView.enableCopying { (view) -> String in
            return "Hello world!"
        }
        
        label.enableCopying { (label) -> String in
            return label?.text ?? ""
        }
    }
}

