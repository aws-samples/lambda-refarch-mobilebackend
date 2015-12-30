var AWS = require('aws-sdk');
var lambda = new AWS.Lambda();

var doc = require('dynamodb-doc');
var dynamo = new doc.DynamoDB();

var tableName;

exports.handler = function(event, context) {
  if (tableName) {
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
            if(config.notesTable) {
              tableName = config.notesTable;
            } else {
              console.log("Error: no notesTable defined in configuration.");
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
};

function handleEvent(createNoteEvent, context) {
    var note = {
        TableName : tableName,
        Item : {
            noteId : createNoteEvent.noteId,
            headline : createNoteEvent.headline,
            text: createNoteEvent.text
        }
    };

    dynamo.putItem(note, function(err,savedNote) {
        if(err) {
            context.fail(new Error('Unable to save note with key: "' + createNoteEvent.noteId + '"'));
        } else {
            context.succeed({success: true});
        }
    });
}
