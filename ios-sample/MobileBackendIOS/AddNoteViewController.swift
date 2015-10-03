//
//  ViewController.swift
//  MobileBackendIOS
//

import Foundation
import UIKit
import MobileCoreServices

class AddNoteViewController: UIViewController {
    
    @IBOutlet weak var headlineTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MobileBackendApi.sharedInstance.configureNoteApi()
    }
    
    @IBAction func saveNoteButtonPressed(sender: UIButton) {
        if(headlineTextField.text != nil && noteTextField.text != nil) {
            MobileBackendApi.sharedInstance.postNote(headlineTextField.text!, text: noteTextField.text!)
            headlineTextField.text = nil
            noteTextField.text = nil
        } else {
            print("Error text fields are nil")
        }
    }
    
}

