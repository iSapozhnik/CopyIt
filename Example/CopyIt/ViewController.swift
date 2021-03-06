//
//  ViewController.swift
//  CopyIt
//
//  Created by isapozhnik on 11/11/2018.
//  Copyright (c) 2018 isapozhnik. All rights reserved.
//

import UIKit
import CopyIt

class MyView: UIView {}
extension UIView: Copiable {}

class ViewController: UIViewController {
    @IBOutlet weak var someView: MyView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        someView.enableCopying { view -> String? in
            return "Hello world!"
        }
        
        label.enableCopying { label -> String? in
            return label?.text
        }

        imageView.enableCopying { imageView -> UIImage? in
            return imageView?.image
        }

//        view.enableCopying { [weak self] _ in
//            return self?.view
//        }
    }
}

