//
//  UploadPhotoViewController.swift
//  MobileBackendIOS
//


import Foundation
import UIKit
import MobileCoreServices

class UploadPhotoViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate  {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    private let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    private let fileManager = FileManager.default
    var imagePickerController:UIImagePickerController?
    
    override func viewDidLoad() {
        MobileBackendApi.sharedInstance.configureS3TransferManager()
        uploadButton.isEnabled = false
    }
    
    @IBAction func uploadImageButtonPressed(sender: UIButton) {
        let imgDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileName = ProcessInfo.processInfo.globallyUniqueString.appendingFormat(".png")
        let fullyQualifiedPath = "\(imgDirectoryPath)/\(fileName)"
            
        self.saveFileAndUpload(imagePath: fullyQualifiedPath, imageName: fileName)
    
    }
    
    @IBAction func cameraButtonPressed(sender: UIBarButtonItem) {
        imagePickerController = UIImagePickerController()
        if let imageController = imagePickerController {
            imageController.mediaTypes = [kUTTypeImage as String]
            imageController.allowsEditing = true
            imageController.delegate = self
            
            if isPhotoCameraAvailable() {
                imageController.sourceType = .camera
            } else {
                imageController.sourceType = UIImagePickerControllerSourceType.photoLibrary
            }
            present( imageController, animated: true, completion: nil)
        }
    }


    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
            
            let mediaType = info[UIImagePickerControllerMediaType]
            
            if let currentMediaType = mediaType {
                if currentMediaType is String {
                    let imageType = currentMediaType as! String
                    if imageType == (kUTTypeImage as NSString) as String {
                        let image = info[ UIImagePickerControllerOriginalImage] as? UIImage
                        if let currentImage = image{
                            //Process Image
                            let size = currentImage.size.applying(CGAffineTransform(scaleX: 0.25, y: 0.25))
                            let hasAlpha = false
                            let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
                            
                            UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
                            currentImage.draw(in: CGRect(origin: .zero, size: size))
                            
                            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                            
                            //Save Image
                            self.photoImageView.image = scaledImage
                            self.uploadButton.isEnabled = true

                        }
                    }
                }
            }
            
        picker.dismiss( animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print(" Picker was cancelled")
        picker.dismiss( animated: true, completion: nil)
    }
    
    func saveFileAndUpload(imagePath:String, imageName:String) {
        guard let data = UIImageJPEGRepresentation(self.photoImageView.image!, 1.0) else {
            print("Error: Converting Image To Data")
            return
        }
        if fileManager.createFile(atPath: imagePath, contents: data, attributes: nil){
            MobileBackendApi.sharedInstance.uploadImageToS3(localFilePath: imagePath,localFileName: imageName)
        }
    }
    
    private func isPhotoCameraAvailable() -> Bool{
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
}
