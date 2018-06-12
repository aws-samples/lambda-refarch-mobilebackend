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
        self.awsCognitoCredentialsProvider = AWSCognitoCredentialsProvider.credentials(with: CognitoRegionType, accountId: AWSAccountId, identityPoolId: CognitoIdentityPoolId, unauthRoleArn: CognitoUnauthenticatedRoleArn, authRoleArn: CognitoAuthenticatedRoleArn)
    }
    
    func requestCognitoIdentity() {
        awsCognitoCredentialsProvider.getIdentityId().continue({ (task) -> Any? in
            if let error = task?.error {
                print("Error Requesting Unauthenticated user identity: \(error)")
                self.cognitoId = nil
            } else {
                self.cognitoId = self.awsCognitoCredentialsProvider.identityId
            }
            return nil
        })
    }
    
    func configureS3TransferManager() {
        let configuration = AWSServiceConfiguration(region: DefaultServiceRegionType, credentialsProvider: self.awsCognitoCredentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AWSS3TransferManager.register(with: configuration, forKey: "USEast1AWSTransferManagerClient")
    }
    
    func configureNoteApi() {
        let configuration = AWSServiceConfiguration(region: DefaultServiceRegionType, credentialsProvider: self.awsCognitoCredentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        APINotesApiClient.register(with: configuration, forKey: "USEast1NoteAPIManagerClient", withUrl: APIEndpointUrl)
        APINotesApiClient(forKey: "USEast1NoteAPIManagerClient").apiKey = APIGatewayKey
    }
    
    func postNote(headline: String, text: String) {
        let noteRequest = APICreateNoteRequest()
        noteRequest?.headline = headline
        noteRequest?.text = text
        noteRequest?.noteId = NSUUID().uuidString
        
        let noteApiClient = APINotesApiClient(forKey: "USEast1NoteAPIManagerClient")
        noteApiClient?.notesPost(noteRequest).continue({ (task) -> Any? in
            if let error = task?.error {
                print("Failed creating note: [\(error)]")
            }
            if let exception = task?.exception {
                print("Failed creating note: [\(exception)]")
            }
            if let noteResponse = task?.result as? APICreateNoteResponse {
                if((noteResponse.success) != nil) {
                    print("Saved note successfully")
                }else {
                    print("Unable to save note due to unknown error")
                }
            }
            return task
        })
    }
    
    func uploadImageToS3(localFilePath: String, localFileName: String) {
        let uploadRequest:AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = S3BucketName
        uploadRequest.acl = AWSS3ObjectCannedACL.publicRead
        uploadRequest.contentType = "image/png"
        uploadRequest.body = URL(fileURLWithPath: localFilePath)
        uploadRequest.key = localFileName
        
        let s3TransferManager = AWSS3TransferManager.s3TransferManager(forKey: "USEast1AWSTransferManagerClient")
        
        s3TransferManager?.upload(uploadRequest).continue({ (task) -> Any? in
            if let error = task?.error as NSError? {
                if error.domain == AWSS3TransferManagerErrorDomain as String {
                    print("upload() failed: [\(error)]")
                } else {
                    print("upload() failed: [\(error)]")
                }
            }
            
            if let exception = task?.exception {
                print("upload() failed: [\(exception)]")
            }
            
            if task?.result != nil {
                print("Uploaded local file to S3: [\(localFileName)]")
            }
            return nil
        })
    }
    
}

