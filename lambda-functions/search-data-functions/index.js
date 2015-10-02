var AWS = require('aws-sdk');
var cloudSearchDomain = new AWS.CloudSearchDomain({endpoint : 'CLOUDSEARCH_SEARCH_ENDPOINT'});

exports.handler = function(event, context) {
    var params = {
      query: event.searchTerm, 
      size: 10,
      start: 0
    };
    
    cloudSearchDomain.search(params, function(err, data) {
      if (err) {
        context.fail(new Error('Error searching for documents with term: "' + event.searchTerm + '"'));// an error occurred
      } else {
        context.succeed(processSearchResults(data));
      }               
    }); 
};

function processSearchResults(data) { 
    //Set base response type
    var response = {};
    response.success = true;
    
    var searchResults = [];
    var hits = data.hits.hit;
    
    for (var i=0; i < hits.length; i++) {
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