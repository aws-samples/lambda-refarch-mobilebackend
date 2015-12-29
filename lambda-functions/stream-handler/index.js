var AWS = require('aws-sdk');
var lambda = new AWS.Lambda();
var cloudSearchDomain;


exports.handler = function(event, context) {
  if (cloudSearchDomain) {
    handleEvent(event, context);
  } else {
    lambda.getFunction({
      "FunctionName": context.functionName,
      "Qualifier": context.functionVersion
    }, function(err, data) {
      if (err) {
        console.log("Error fetching function details: " + err);
        context.fail(err);
      } else {
        var description = data.Configuration.Description;
        if (description) {
          try {
            var config = JSON.parse(description);
            if(config.documentEndpoint) {
              cloudSearchDomain = new AWS.CloudSearchDomain({
                endpoint: config.documentEndpoint
              });
            } else {
              console.log("Error: no documentEndpoint defined in configuration.");
              context.fail("Lambda configuration error");
            }
          } catch (e) {
            console.log("Error deserializing description");
            context.fail(e);
          }
        }
        handleEvent(event, context);
      }
    });
  }
}

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
