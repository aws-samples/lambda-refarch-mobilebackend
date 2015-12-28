# AWS Lambda Reference Architecture: Mobile Backend

## Introduction

The Mobile Backend reference architecture ([diagram](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) demonstrates how to use AWS Lambda along with other services to build a serverless backend for a mobile application. The specific example application provided enables users to upload photos and notes via S3 and API Gateway respectively. The notes are stored in Amazon DynamoDB and are processed asynchronously using DynamoDB streams and a Lambda function in order to add them to an Amazon CloudSearch domain. In addition to the source code for the Lambda functions, this repository also contains a prototype iOS application that provides examples for how to use the AWS mobile SDKs to interface with the backend resources defined in the architecture.

## Running the example

To run the full example application you must first deploy the backend resources and then compile and run the example iOS application.

### Deploying the Backend

The provided AWS CloudFormation template will create most of the backend resources necessary for this example, but you will need to create the Amazon CloudSearch domain, API Gateway REST API, and Cognito identity pool outside of AWS CloudFormation.

#### Step 1. Create Amazon CloudSearch Domain

1. Create a new Amazon CloudSearch domain using the [AWS CLI](https://aws.amazon.com/cli/) providing a domain name of your choice.
```
aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
```

1. Note the ARN of the new domain in the output document. You will use this as an input when launching the CloudFormation stack.

1. Define indexes for the `headline` and `text` fields.
```
aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
aws cloudsearch define-index-field --name text --type text --domain-name [YOUR_DOMAIN_NAME]
```

#### Step 2. Create an API Gateway REST API

1. Using the [AWS CLI](https://aws.amazon.com/cli/), create a new API providing a name of your choice.
```
aws apigateway create-rest-api --name [YOUR_API_NAME]
```

1. Note the API ID provided in the output document. You will use this as an input when launching the CloudFormation stack.

#### Step 3. Create a Cognito Identity Pool

1. Create a new identity pool using the [AWS CLI](https://aws.amazon.com/cli/) providing a name of your choice.

```
aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
```

2. Note the IdentityPoolId from the output document. You will use this as a parameter when launching the CloudFormation stack.

#### Step 4. Launch the AWS CloudFormation template

Use the following link to launch the provided AWS CloudFormation template in your account.

[![Launch Lambda Mobile Backend into North Virginia with CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

*Note:* The provided template can be launched in the us-east-1 region using the provided bucket. If you would like to launch this stack in a different region you must create an Amazon S3 bucket in that region and copy the template and Lambda function definitions into it.

When prompted enter the parameter values for the CloudSearch domain, API Gateway REST API, and Cognito identity pool resources you created in the previous steps.

#### Step 5. Update your API Gateway REST API

Once the CloudFormation stack has been created, you need to update the API you created previously to use the newly created `NotesApiFunction`.

1. Select your API in the [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis).
1. Click *Create Resource* to create a new child resource under /.
1. Enter `notes` as the resource name and `/notes` as the resource path.
1. Click *Create Resource*.
1. With the new `/notes` resource selected, click *Create Method*.
1. Select `POST` and click the checkbox.
1. Select *Lambda Function* as the integration type and the region where you launched the CloudFormation stack as the Lambda region.
1. Type 'NotesApiFunction' in the *Lambda Function* input box and select the function crated by the CloudFormation Stack.
1. Click *Save* and grant API Gateway permission to execute the Lambda function.
1. Click Method Request to edit the request configuration.
1. Set the *Authorization type* to `AWS_IAM` and set *API Key Required* to `true`. Click the check mark next to each field.
1. Click *Deploy API*.
1. Select `New Stage` for *Deployment stage* and provide a name in the *Stage name* field.
1. Note the *Invoke URL* for the new stage. You will use this value when running the sample iOS app.

#### Step 6. Update your Cognito Identity Pool

1. Select your identity pool in the [Amazon Cognito Console](https://console.aws.amazon.com/cognito/home?region=us-east-1).
1. Click *Edit Identity Pool*
1. For both the *Unauthenticated role* and the *Authenticated role* select the MobileClientRole created by the CloudFormation stack. The full ARN for the role is provided in the outputs of the stack.
1. Click *Save Changes*


### Running the sample iOS application

#### Prerequisites

To run the provided iOS sample application you must be running *Mac OS X 10.10 (Yosemite)* or higher. You must also have the latest version of *[Xcode](https://itunes.apple.com/us/app/xcode/id497799835)* and *[Cocoa Pods](https://cocoapods.org/)* installed. 


[Template One](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobiledatastore.template)
does the following:

-   Configures the Amazon Simple Storage Service (Amazon S3) bucket to receive user uploaded photos.

-   Configures the Amazon CloudFront distribution to display static content for uploaded media.

-   Configures the Amazon DynamoDB Table for storing mobile data from the iOS application.

[Template Two](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambdafunctions.template)
does the following:

-   Creates a Lambda function to stream updates from DynamoDB and index in CloudSearch.

-   Creates a Lambda function to store mobile data into DynamoDB.

-   Creates a Lambda function to query CloudSearch and return a matching document.

-   Creates an AWS Identity and Access Management (IAM) role and policy for all three lambda functions to assume when invoked. Permissions allow the
functions to write output to Amazon CloudWatch Logs, store data in DynamoDB, read from DynamoDB Streams, and store data in CloudSearch.

## Instructions for Creating Mobile Backend

**Important:** CloudSearch, API Gateway, and DynamoDB Streams will be configured through the console. During cleanup, you will need to manually delete these resources after deleting the AWS CloudFormation Stacks. The provided CloudFormation template retreives its Lambda code from a bucket in the us-east-1 region. To launch this sample in another region, please modify the template and upload the Lambda code to a bucket in that region.


Step 1 – Create an AWS CloudFormation Stack with Template One and copy the S3 bucket name from the AWS CloudFormation output.

Step 2 – Create a CloudSearch domain using the [AWS console](https://console.aws.amazon.com/cloudsearch/home?region=us-east-1). Create a manual index containing attributes for headline, s3_url, user_id similar to the diagram below:

![Alt text](assets/cloudsearch-attributes.png?raw=true “CloudSearch Attributes”)

Step 3 – Update the following environment variables in each Lambda function based on the output of Steps 1 and 2.

a   CLOUDSEARCH_DOCUMENT_ENDPOINT in streams-data-function/index.js with the Document Endpoint of CloudSearch

b   CLOUDSEARCH_SEARCH_ENDPOINT in search-data-function/index.js with the Search Endpoint of CloudSearch

Step 4 – Upload a .zip file of each lambda function to Amazon S3 and create an AWS Cloudformation Stack with Template Two.

Step 5 – Add the created DynamoDB table as an event source for your streams-data-function in the [AWS console](https://console.aws.amazon.com/lambda/home?region=us-east-1).


## Instructions for Integrating Mobile Application

In order to illustrate the end-to-end process, you can integrate with the sample mobile application available. The sample mobile application is built for iOS and requires creating a mobile SDK. The steps for integrating the SDK are described below:

Step 1 - Create a new Amazon Cognito identity pool through the [Amazon Cognito dashboard](https://console.aws.amazon.com/cognito/home) for unauthenticated users. Modify the policy document to allow unauthenticated users to "execute-api:*" for API Gateway. Modify the policy document to allow users to upload to the S3 bucket created in Template One.

Step 2 - Visit the [API Gateway dashboard](https://console.aws.amazon.com/apigateway/home) in your AWS account and create a new resource endpoints for `/notes`. Assign a POST method for the `/notes` endpoint. For the method, select the `Integration Request` type of “Lambda Function.” Configure the notes endpoint to use the notes-data-function.

Under `Models` section, create a CreateNoteRequest and a CreateNoteResponse model using [these JSON templates ](https://github.com/awslabs/lambda-refarch-mobilebackend/tree/master/apigateway-models).

Under `Method Request` for the method execution, enable API key required and assign the CreateNoteRequest model that was created earlier as the `Request Model`.

Under `Method Response` for the method exectuion, for a 200 response code select a content type of `application/json` and use the CreateNoteResponse model that was created earlier.

Step 3 - In the [API Gateway dashboard](https://console.aws.amazon.com/apigateway/home) create an API key for API Gateway and then deploy the API Gateway in order to copy the deployment endpoint url.

Step 4 - Install and run [cocoapods](https://guides.cocoapods.org/using/getting-started.html) on the Command Line Interface:

```bash
$ pod install
```

Step 5 - Open the Constants.swift file and add the Account Id, S3 bucket, Amazon Cognito identity pool, Amazon Cognito identity users, API key, and API Gateway endpoint as constants.

Step 6 - Run the mobile application in the simulator. Choose a photo and upload it to S3. Then view the iamge is uploaded in Amazon S3, and then use the Amazon CloudFront Distribution url to view the image through the CDN. Then select the button to add a note in the iOS application. Add a note in the mobile application and save. Then view DynamoDB to see the note added to the Notes Table. View the CloudSearch domain to see a document added to your search index. Review the Amazon CloudWatch Log events from the streams Lambda function for evidence that the functions are pulling data as mobile users are publishing.

## Conclusion

Congratulations! You now should have a working example of a mobile backend reference architecture. You are able to communicate directly to mobile services such as Amazon Cognito for  identities and upload media files directly to Amazon S3. You also configured a serverless API using AWS Lambda and Amazon API Gateway.

## Cleanup

To remove all automatically created resources, delete the two AWS CloudFormation stacks. You will need to manually remove the API Gateway endpoint, Amazon Cognito identity pool, and CloudSearch domain.

Note: Deletion of the S3 bucket will fail unless all files in the bucket are removed before the stack is deleted.


## License

This reference architecture sample is licensed under Apache 2.0.
