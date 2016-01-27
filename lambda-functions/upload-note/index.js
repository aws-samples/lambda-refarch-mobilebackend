var AWS = require('aws-sdk');

var DOC = require('dynamodb-doc');

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

function handleEvent(createNoteEvent, context) {
    var note = {
        TableName : config.NotesTable,
        Item : {
            noteId : createNoteEvent.noteId,
            headline : createNoteEvent.headline,
            text: createNoteEvent.text
        }
    };

    doc.put(note, function(err,savedNote) {
        if(err) {
            context.fail(new Error('Unable to save note with key: "' + createNoteEvent.noteId + '"'));
        } else {
            context.succeed({success: true});
        }
    });
}
