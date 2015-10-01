//
//  AwsMobileService.swift
//  MobileBackendIOS
//

import Foundation

let identityReceivedNotification: String = "identityReceivedNotification"

class AwsMobileService  {
    static let sharedInstance = AwsMobileService()
    
    let awsCognitoCredentialsProvider: AWSCognitoCredentialsProvider
    var cognitoId:String?
    
    init() {
        
        //Initialize the identity provider
        awsCognitoCredentialsProvider = AWSCognitoCredentialsProvider.credentialsWithRegionType(CognitoRegionType, accountId: AWSAccountId, identityPoolId: CognitoIdentityPoolId, unauthRoleArn: CognitoUnauthenticatedRoleArn, authRoleArn: CognitoAuthenticatedRoleArn)
        
        receiveCognitoIdentity()
        
    }
    
    func receiveCognitoIdentity() {
        
        awsCognitoCredentialsProvider.getIdentityId().continueWithBlock() { (task) -> AnyObject! in
            if let error = task.error {
                print("Error Requesting Unauthenticated user: \(error.userInfo)")
                self.cognitoId = nil
            } else {
                
                
                self.cognitoId = self.awsCognitoCredentialsProvider.identityId
                let configuration = AWSServiceConfiguration(region: DefaultServiceRegionType, credentialsProvider: self.awsCognitoCredentialsProvider)
                AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
                
                AWSS3TransferManager.registerS3TransferManagerWithConfiguration(configuration, forKey: "USEast1AWSTransferManagerClient")
                
                //API-GATEWAY CONFIGURATION HERE
                //AWSPhotoNoteMicroserviceClient.registerClientWithConfiguration(configuration, forKey: "USEast1AWSPhotoNoteMicroserviceClient")
            }
            return nil
        }
    }
    
    func uploadImageToS3(localFilePath: String, localFileName: String) {
        let s3TransferManagerUploadRequest:AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        s3TransferManagerUploadRequest.bucket = S3BucketName
        s3TransferManagerUploadRequest.contentType = "image/png"
        
        s3TransferManagerUploadRequest.body = NSURL(fileURLWithPath: localFilePath)
        s3TransferManagerUploadRequest.key = localFileName
        
        // upload(s3TransferManagerUploadRequest)
        
    }
    
    func saveMetadata(fileName:String, headline:String) {
        //INSERT API-GATEAY CLIENT API CALL HERE
    }

    
}

