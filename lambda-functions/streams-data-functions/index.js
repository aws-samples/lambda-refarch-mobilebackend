var AWS = require('aws-sdk');
var cloudSearchDomain = new AWS.CloudSearchDomain({endpoint : 'CLOUDSEARCH_DOCUMENT_ENDPOINT'});

exports.handler = function(event, context) {
    var records = event.Records;
    var searchDocuments = createSearchDocuments(records);
	
    uploadSearchDocuments(context, searchDocuments);
};

function createSearchDocuments(records) {
    var searchDocuments = [];
	
    for(var i = 0; i<records.length; i++) {
        var record = records[i];
		
        if (record.eventName === "INSERT") {
            var searchDocument = {
                type : 'add',
                id : record.dynamodb.Keys.noteId.S,
                fields : {
                    headline : record.dynamodb.NewImage.headline.S,
                    note_text : record.dynamodb.NewImage.text.S
                }
            };
            searchDocuments.push(searchDocument);
        }
    }
    return searchDocuments;
}

function uploadSearchDocuments(context, searchDocuments) {
    if(searchDocuments.length > 0) {
        var params = {
            contentType : 'application/json',
            documents : JSON.stringify(searchDocuments)
        };
		
        cloudSearchDomain.uploadDocuments(params, function(error, result) {
            if(!error) {
                context.succeed("Processed " + searchDocuments.length + " search records.");
            } else {
                context.fail(new Error('Unable to upload search documents: "' + searchDocuments + '"'));
            }
        });
    } else {
        context.succeed("No new documents were added to the DynamoDB Table.");
    }   
}