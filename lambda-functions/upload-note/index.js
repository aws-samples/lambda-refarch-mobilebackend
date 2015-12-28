var doc = require('dynamodb-doc');
var dynamo = new doc.DynamoDB();

exports.handler = function(createNoteEvent, context) {
    var note = {
        TableName : "Notes",
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
};