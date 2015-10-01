var AWS = require('aws-sdk');
var cloudSearchDomain = new AWS.CloudSearchDomain({endpoint : 'CLOUDSEARCH_DOCUMENT_ENDPOINT'});
var batchDocuments = [];


exports.handler = function(event, context) {
    processSearchRecord(context, 0, event.Records);
}

// Process each DynamoDB record
function processSearchRecord(context, index, records) {

    if (index == records.length) {
        var params = {
            contentType : 'application/json',
            documents : JSON.stringify(batchDocuments)
        };
        cloudSearchDomain.uploadDocuments(params, function(error, result) {
            if(!error) {
                context.succeed("Processed " + records.length + " records.");
                return;
            }
            else {
                context.fail(new Error('error "' + error + '"'));
                return;
            }
        });
    } else {
        record = records[index];
    
        if (record !== undefined && record.eventName === "INSERT") {
            var insertSearchDocument = {
                type : 'add',
                id : record.dynamodb.Keys.photoId.S,
                fields : {
                    user_id : record.dynamodb.Keys.userId.S,
                    headline : record.dynamodb.NewImage.headline.S,
                    s3_url : record.dynamodb.NewImage.s3Url.S
                }
            };
            batchDocuments.push(insertSearchDocument);
            processSearchRecord(context, index+1, records);
        } else {
            processSearchRecord(context, index+1, records);
        }
    }


}