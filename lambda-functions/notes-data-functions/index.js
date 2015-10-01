var AWS = require('aws-sdk');
var DOC = require('dynamodb-doc');

var awsClient = new AWS.DynamoDB();
var dynamo = new DOC.DynamoDB(awsClient);

exports.handler = function(createPhotoEvent, context ) {

    var photoNote = {};
    photoNote.TableName = "PhotoNotes";
    photoNote.Item = { userId : context.identity.cognitoIdentityId,
                     photoId : createPhotoEvent.id,
                     headline : createPhotoEvent.headline,
                     s3Url: createPhotoEvent.s3Url };

    dynamo.putItem(photoNote, function(err,savedNote){ 
        if(err) {
            context.fail(new Error('Unable to retrieve user with key: "' + createPhotoEvent.id + '"'));
        } else {
            context.succeed({success: true});
        }
    });
};