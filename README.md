# AWS Lambda Reference Architecture: Mobile Backends


[Template One](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backends/lambda_data_stores.template)
does the following:

-   Configures the Amazon Simple Storage Service (Amazon S3) bucket to receive user uploaded photos.

-   Configures the Amazon CloudFront distribution to display static content for uploaded media.

-   Configures the Amazon DynamoDB Table for storing mobile data from the iOS application.

[Template Two](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backends/lambda_api_functions.template)
does the following:

-   Creates a Lambda function to stream updates from DynamoDB and index in CloudSearch.

-   Creates a Lambda function to store mobile data into DynamoDB.

-   Creates a Lambda function to query CloudSearch and return a matching document.

-   Creates an AWS Identity and Access Management (IAM) role and policy for all three lambda functions to assume when invoked. Permissions allow the
functions to write output to Amazon CloudWatch Logs, store data in DynamoDB, read from DynamoDB Streams, and store data in CloudSearch.

## Instructions for Creating Mobile Backend

**Important:** CloudSearch, API Gateway, and DynamoDB Streams will be configured through the console. During cleanup, you will need to manually
delete these resources after deleting the AWS CloudFormation Stacks.


Step 1 – Create an AWS CloudFormation Stack with Template One and copy the S3 bucket name and CloudFront URL from the AWS CloudFormation output.

Step 2 – Create a CloudSearch domain using the [AWS console](https://console.aws.amazon.com/cloudsearch/home?region=us-east-1). Create a manual index containing attributes for headline, s3_url, user_id similar to the diagram below:

![Alt text](assets/cloudsearch-attributes.png?raw=true “CloudSearch Attributes”)

Step 3 – Update the following environment variables in each Lambda function based on the output of Steps 1 and 2.

a   CLOUDSEARCH_DOCUMENT_ENDPOINT in streams-data-function/index.js with the Document Endpoint of CloudSearch

b   CLOUDSEARCH_SEARCH_ENDPOINT in search-data-function/index.js with the Search Endpoint of CloudSearch

c   CLOUDFRONT_URL in notes-data-function/index.js with the CloudFront output from AWS CloudFormation Template One

Step 4 – Upload a .zip file of each lambda function to Amazon S3 and create an AWS Cloudformation Stack with Template Two.

Step 5 – Add the created DynamoDB table as an event source for your streams-data-function in the [AWS console](https://console.aws.amazon.com/lambda/home?region=us-east-1).

Step 6 - Create a new Amazon Cognito identity pool through the [Amazon Cognito dashboard](https://console.aws.amazon.com/cognito/home) for unauthenticated users. Modify the policy document to allow unauthenticated users to "execute-api:*" for API Gateway. Modify the policy document to allow users to upload to the S3 bucket created in Template One. 

## Instructions for Integrating Mobile Application

In order to illustrate the end-to-end process, you can integrate with the sample mobile application available. The sample mobile application is built for iOS and requires creating a mobile SDK. The steps for integrating the SDK are described below:

Step 1 - Visit the [API Gateway dashboard](https://console.aws.amazon.com/apigateway/home) in your AWS account and create two new resource endpoints for `/photos` and `search`. Assign a POST method for the `/photos` endpoint and a GET method for the `search` endpoint. For each method, select the `Integration Request` type of “Lambda Function.” Configure the photos endpoint to use the notes-data-function, and configure the search endpoint to use the search-data-function both created from the AWS CloudFormation script.

Under `Models` section, create a PhotoNoteRequest and a PhotoNotesResponse model using [these JSON templates ](https://github.com/awslabs/lambda-refarch-mobilebackend/blob/master/apigateway-templates/).

Under `Method Request` for each method execution, enable AWS_IAM authorization, API key required, and assign the PhotoNotesResponse model that was created earlier as the `Request Model`. 

Under `Integration Request` for both method execution, enable `Invoke with caller credentials` in order to pass Amazon Cognito IAM identities through API Gateway.

Under `Method Response` for both method executions, for a 200 response code select a content type of `application/json` and use the PhotoNotesResponse model that was created earlier.

Step 2 - In the [API Gateway dashboard](https://console.aws.amazon.com/apigateway/home) create an API key for API Gateway and then download an iOS SDK and copy the SDK files into the ‘APIGateway’ folder of the iOS application.

Step 3 - Install and run [cocoapods](https://guides.cocoapods.org/using/getting-started.html) on the Command Line Interface:

```bash
$ pod install
```

Step 4 - Open the Constants.swift file and add the S3 bucket, Amazon Cognito identity pool, Amazon Cognito identity users, and API key as constants.

Step 5 - Run the mobile application in the simulator. Choose a photo and add a headline to  the note. Then view DynamoDB to see the photo note added to the mobile storage. View the CloudSearch domain to see a document added to your search index. Review the Amazon CloudWatch Log events from the streams Lambda function for evidence that the functions are pulling data as mobile users are publishing.

## Conclusion

Congratulations! You now should have a working example of a mobile backend reference architecture. You are able to communicate directly to mobile services such as Amazon Cognito for  identities and upload media files directly to Amazon S3. You also configured a serverless API using AWS Lambda and Amazon API Gateway.

## Cleanup

To remove all automatically created resources, delete the two AWS CloudFormation stacks. You will need to manually remove the API Gateway endpoint, Amazon Cognito identity pool, and CloudSearch domain.

Note: Deletion of the S3 bucket will fail unless all files in the bucket are removed before the stack is deleted.


## License

This reference architecture sample is licensed under Apache 2.0.
