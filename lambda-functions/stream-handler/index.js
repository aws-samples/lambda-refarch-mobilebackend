var AWS = require('aws-sdk');
var doc = new AWS.DynamoDB.DocumentClient();

var config;

exports.handler = function(event, context) {
  if (config) {
    handleEvent(event, context);
  } else {
    var params = {
      TableName: 'MobileRefArchConfig',
      Key: { Environment: 'demo' }
    };
    doc.get(params, function(err, data) {
      if (err) {
        console.log(err, err.stack);
        context.fail(err);
      } else {
        config = data.Item;
        handleEvent(event, context);
      }
    });
  }
};

function handleEvent(event, context) {
    var records = event.Records;
    var searchDocuments = createSearchDocuments(records);

    uploadSearchDocuments(context, searchDocuments);
}

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
        var cloudSearchDomain = new AWS.CloudSearchDomain({
          endpoint: config.DocumentEndpoint
        });

        var params = {
            contentType : 'application/json',
            documents : JSON.stringify(searchDocuments)
        };

        cloudSearchDomain.uploadDocuments(params, function(error, result) {
            if(!error) {
                context.succeed("Processed " + searchDocuments.length + " search records.");
            } else {
                context.fail(new Error('Unable to upload search documents: ' + error));
            }
        });
    } else {
        context.succeed("No new documents were added to the DynamoDB Table.");
    }
}
