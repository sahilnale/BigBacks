//
//  CustomPopUpViewController.swift
//  FindMyFood
//
//  Created by Rishik Durvasula on 11/18/24.
//

import SwiftUI

import UIKit

class CustomPopUpViewController: UIViewController {
    var titleText: String?
    var subtitleText: String?
    var annotationImage: UIImage?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Populate the popup with data
        titleLabel.text = titleText
        subtitleLabel.text = subtitleText
        imageView.image = annotationImage
        
        // Style the popup (optional)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }
    
    @IBAction func closePopup(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

//#Preview {
//    CustomPopUpViewController()
//}
