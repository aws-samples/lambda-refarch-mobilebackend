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
            if(config.searchEndpoint) {
              cloudSearchDomain = new AWS.CloudSearchDomain({
                endpoint: config.searchEndpoint
              });
            } else {
              console.log("Error: no searchEndpoint defined in configuration.");
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

function handleEvent(event, context) {
  var params = {
    query: event.searchTerm,
    size: 10,
    start: 0
  };

  cloudSearchDomain.search(params, function(err, data) {
    if (err) {
      context.fail(new Error('Error searching for documents with term: "' + event.searchTerm + '"')); // an error occurred
    } else {
      context.succeed(processSearchResults(data));
    }
  });
}

function processSearchResults(data) {
  //Set base response type
  var response = {
    success: true
  };

  var searchResults = [];
  var hits = data.hits.hit;

  for (var i = 0; i < hits.length; i++) {
    //retrieve the next notes
    var currentMatch = hits[i];
    var searchResult = {};

    //Configure each note and push onto the search results
    searchResult.noteId = currentMatch.id;
    searchResult.headline = currentMatch.fields.headline[0];
    searchResult.text = currentMatch.fields.note_text[0];
    searchResults.push(searchResult);
  }

  response.notes = searchResults;
  return response;
}
