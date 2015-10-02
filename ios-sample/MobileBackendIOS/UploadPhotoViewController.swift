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
    
    private let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
    private let fileManager = NSFileManager.defaultManager()
    var imagePickerController:UIImagePickerController?
    
    override func viewDidLoad() {
        MobileBackendApi.sharedInstance.configureS3TransferManager()
        uploadButton.enabled = false
    }
    
    @IBAction func uploadImageButtonPressed(sender: UIButton) {
        let imgDirectoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileName = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(".png")
        let fullyQualifiedPath = "\(imgDirectoryPath)/\(fileName)"
            
        self.saveFileAndUpload(fullyQualifiedPath, imageName: fileName)
    
    }
    
    @IBAction func cameraButtonPressed(sender: UIBarButtonItem) {
        imagePickerController = UIImagePickerController()
        if let imageController = imagePickerController {
            imageController.mediaTypes = [kUTTypeImage as String]
            imageController.allowsEditing = true
            imageController.delegate = self
            
            if isPhotoCameraAvailable() {
                imageController.sourceType = .Camera
            } else {
                imageController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            }
            presentViewController( imageController, animated: true, completion: nil)
        }
    }

    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]){
            
            let mediaType:AnyObject? = info[UIImagePickerControllerMediaType]
            
            if let currentMediaType:AnyObject = mediaType {
                if currentMediaType is String {
                    let imageType = currentMediaType as! String
                    if imageType == kUTTypeImage as NSString {
                        let image = info[ UIImagePickerControllerOriginalImage] as? UIImage
                        if let currentImage = image{
                            //Process Image
                            let size = CGSizeApplyAffineTransform(currentImage.size, CGAffineTransformMakeScale(0.25, 0.25))
                            let hasAlpha = false
                            let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
                            
                            UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
                            currentImage.drawInRect(CGRect(origin: CGPointZero, size: size))
                            
                            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                            
                            //Save Image
                            self.photoImageView.image = scaledImage
                            self.uploadButton.enabled = true

                        }
                    }
                }
            }
            
            picker.dismissViewControllerAnimated( true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        print(" Picker was cancelled")
        picker.dismissViewControllerAnimated( true, completion: nil)
    }
    
    func saveFileAndUpload(imagePath:String, imageName:String) {
        guard let data = UIImageJPEGRepresentation(self.photoImageView.image!, 1.0) else {
            print("Error: Converting Image To Data")
            return
        }
        if fileManager.createFileAtPath(imagePath, contents: data, attributes: nil){
            MobileBackendApi.sharedInstance.uploadImageToS3(imagePath,localFileName: imageName)
        }
    }
    
    private func isPhotoCameraAvailable() -> Bool{
        return UIImagePickerController.isSourceTypeAvailable(.Camera)
    }
}
