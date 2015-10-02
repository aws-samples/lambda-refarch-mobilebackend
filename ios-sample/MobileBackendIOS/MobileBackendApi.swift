//
//  MobileBackendApi.swift
//  MobileBackendIOS
//

import Foundation


class MobileBackendApi  {
    
    static let sharedInstance = MobileBackendApi()
    let awsCognitoCredentialsProvider: AWSCognitoCredentialsProvider
    var cognitoId:String?
    
    init() {
        //Initialize the identity provider
        self.awsCognitoCredentialsProvider = AWSCognitoCredentialsProvider.credentialsWithRegionType(CognitoRegionType, accountId: AWSAccountId, identityPoolId: CognitoIdentityPoolId, unauthRoleArn: CognitoUnauthenticatedRoleArn, authRoleArn: CognitoAuthenticatedRoleArn)
    }
    
    func requestCognitoIdentity() {
        awsCognitoCredentialsProvider.getIdentityId().continueWithBlock() { (task) -> AnyObject! in
            if let error = task.error {
                print("Error Requesting Unauthenticated user identity: \(error.userInfo)")
                self.cognitoId = nil
            } else {
                self.cognitoId = self.awsCognitoCredentialsProvider.identityId
            }
            return nil
        }
    }
    
    func configureS3TransferManager() {
        let configuration = AWSServiceConfiguration(region: DefaultServiceRegionType, credentialsProvider: self.awsCognitoCredentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        AWSS3TransferManager.registerS3TransferManagerWithConfiguration(configuration, forKey: "USEast1AWSTransferManagerClient")
    }
    
    func configureNoteApi() {
        let configuration = AWSServiceConfiguration(region: DefaultServiceRegionType, credentialsProvider: self.awsCognitoCredentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        APINotesApiClient.registerClientWithConfiguration(configuration, forKey: "USEast1NoteAPIManagerClient", withUrl: APIEndpointUrl)
        APINotesApiClient(forKey: "USEast1NoteAPIManagerClient").APIKey = APIGatewayKey
    }
    
    func postNote(headline: String, text: String) {
        let noteRequest = APICreateNoteRequest()
        noteRequest.headline = headline
        noteRequest.text = text
        noteRequest.noteId = NSUUID().UUIDString
        
        let noteApiClient = APINotesApiClient(forKey: "USEast1NoteAPIManagerClient")
        noteApiClient.notesPost(noteRequest).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                print("Failed creating note: [\(error)]")
            }
            if let exception = task.exception {
                print("Failed creating note: [\(exception)]")
            }
            if let noteResponse = task.result as? APICreateNoteResponse {
                if((noteResponse.success) != nil) {
                    print("Saved note successfully")
                }else {
                    print("Unable to save note due to unknown error")
                }
            }
            return task
        }
    }
    
    func uploadImageToS3(localFilePath: String, localFileName: String) {
        let uploadRequest:AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = S3BucketName
        uploadRequest.ACL = AWSS3ObjectCannedACL.PublicRead
        uploadRequest.contentType = "image/png"
        uploadRequest.body = NSURL(fileURLWithPath: localFilePath)
        uploadRequest.key = localFileName
        
        let s3TransferManager = AWSS3TransferManager.S3TransferManagerForKey("USEast1AWSTransferManagerClient")
        
        s3TransferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                if error.domain == AWSS3TransferManagerErrorDomain as String {
                    print("upload() failed: [\(error)]")
                } else {
                    print("upload() failed: [\(error)]")
                }
            }
            
            if let exception = task.exception {
                print("upload() failed: [\(exception)]")
            }
            
            if task.result != nil {
                print("Uploaded local file to S3: [\(localFileName)]")
            }
            return nil
        }
    }
    
}

