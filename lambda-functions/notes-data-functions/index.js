var doc = require('dynamodb-doc');
var dynamo = new doc.DynamoDB();

exports.handler = function(createPhotoEvent, context ) {

    var photoNote = {};
    photoNote.TableName = "PhotoNotes";
    photoNote.Item = { photoId : createPhotoEvent.id,
                     headline : createPhotoEvent.headline,
                     s3Url: createPhotoEvent.s3Url };

    dynamo.putItem(photoNote, function(err,savedNote){ 
        if(err) {
            context.fail(new Error('Unable to save photo with key: "' + createPhotoEvent.id + '"'));
        } else {
            context.succeed({success: true});
        }
    });
};