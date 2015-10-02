# AWS Lambda Reference Architecture: Mobile Backend

The [Mobile Backend](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf) reference architecture is a serverless event-driven API architecture that uses AWS Lambda, Amazon API Gateway, and other AWS services. This architecture is ideal for mobile developers who need access to scalable, event-driven infrastructure without having to manage the underlying compute resources. This demo application is based on this architecture and can be created with two AWS CloudFormation templates, an Amazon CloudSearch instance, and a mobile SDK from API Gateway.

[Template One](https://github.com/awslabs/lambda-refarch-mobilebackend/blob/master/cloudformation/mobiledatastore.template)
does the following:

-   Configures the Amazon Simple Storage Service (Amazon S3) bucket to receive user-uploaded photos.

-   Configures the Amazon CloudFront distribution to display static content for uploaded media.

-   Configures the Amazon DynamoDB table for storing mobile data from the iOS application.

[Template Two](https://github.com/awslabs/lambda-refarch-mobilebackend/blob/master/cloudformation/lambdafunctions.template)
does the following:

-   Creates a Lambda function to stream updates from DynamoDB and index in CloudSearch.

-   Creates a Lambda function to store mobile data into DynamoDB.

-   Creates a Lambda function to query CloudSearch and return a matching document.

-   Creates an AWS Identity and Access Management (IAM) role and policy for all three lambda functions to assume when invoked. Permissions allow the
    functions to write output to Amazon CloudWatch Logs, store data in DynamoDB, read from DynamoDB Streams, and store data in CloudSearch.

## Instructions for Creating Mobile Backend

**Important:** CloudSearch, API Gateway, and DynamoDB Streams will be configured through the console. During cleanup, you will need to manually
delete these resources after deleting the AWS CloudFormation stacks.

Step 1 – Create an AWS CloudFormation stack with Template One and copy the Amazon S3 bucket name and CloudFront URL from the AWS CloudFormation output.

Step 2 – Create a CloudSearch domain using the [AWS console](https://console.aws.amazon.com/cloudsearch/home?region=us-east-1). Create a manual index containing attributes for headline and note_text similar to the diagram below:

![Alt text](assets/cloudsearch-attributes.png?raw=true “CloudSearch Attributes”)

Step 3 – Update the following environment variables in each Lambda function based on the output of steps 1 and 2.

	a   CLOUDSEARCH_DOCUMENT_ENDPOINT in streams-data-function/index.js with the Document Endpoint of CloudSearch

	b   CLOUDSEARCH_SEARCH_ENDPOINT in search-data-function/index.js with the Search Endpoint of CloudSearch

Step 4 – Upload a .zip file of each Lambda function to Amazon S3 and create an AWS Cloudformation stack with Template Two.

Step 5 – Add the created DynamoDB Table as an event source for your Lambda streams-data-function in the [AWS Console](https://console.aws.amazon.com/lambda/home?region=us-east-1).

Step 6 - Create a new Amazon Cognito identity pool through the [Amazon Cognito dashboard](https://console.aws.amazon.com/cognito/home) for unauthenticated. Modify the policy document to allow unauthenticated users to "execute-api:*" for API Gateway. Modify the policy document to allow users to upload to the S3 bucket created in Template One. 

## Instructions for Integrating Mobile Application

In order to illustrate the end to end process, you can integrate with the sample mobile application available. The sample mobile application is built for iOS, and requires creating an API Gateway endpoint. The steps for integrating the SDK are described below:

Step 1 - Visit the [API Gateway dashboard](https://console.aws.amazon.com/apigateway/home) in your AWS account and create one new resource endpoint for `/notes`. Assign a POST method for the `/notes` endpoint. Select the `Integration Request` type of “Lambda Function”. Configure the notes endpoint to use the Lambda notes-data-function created from the CloudFormation script.

Under `Models` section, create a CreateNoteRequest model and a CreateNoteResponse model using [these json templates](https://github.com/awslabs/lambda-refarch-mobilebackend/tree/master/apigateway-models).

Under `Method Request` for the method execution, enable API key required and assign the CreateNoteRequest model that was created earlier as the `Request Model`. 

Under `Method Response` for the method execution, select 200 response code and set the Content type to `application/json` and use the CreateNoteResponse model that was created earlier.

Step 2 - In the [API Gateway dashboard] (https://console.aws.amazon.com/apigateway/home) create an API key for API Gateway and then deploy the API.

Step 3 - Install and run [cocoapods](https://guides.cocoapods.org/using/getting-started.html) on the Command Line Interface in the ios-sample directory:

```bash
$ pod install
```

Step 4 - Open the Constants.swift file and add the S3 bucket, Amazon Cognito identity pool, Amazon Cognito identity users, API endpoint, and API key as constants.

Step 5 - Run the mobile application in the simulator. Choose a photo and upload it to S3. Then create a note and post the note to the API. View the mobile backend resources. Documents are added to DynamoDB and then CloudSearch. Media files are available through the CloudFront distribution. And the Lambda Search Api can return relevant searches against the mobile data.
 
## Conclusion

Congratulations! You now should have a working example of a mobile backend reference architecture. You are able to communicate directly to mobile services such as Amazon Cognito for  identities and upload media files directly to Amazon S3. You also configured a serverless API using AWS Lambda and API Gateway.

## Cleanup

To remove all automatically created resources, delete the two AWS CloudFormation stacks. You will manually need to remove the API Gateway endpoint, Amazon Cognito identity pool, and CloudSearch domain.

Note: Deletion of the S3 bucket will fail unless all files in the bucket are removed before the stack is deleted.


## License

This reference architecture sample is licensed under Apache 2.0.
