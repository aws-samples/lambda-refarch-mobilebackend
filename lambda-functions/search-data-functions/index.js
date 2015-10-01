var AWS = require('aws-sdk');
var cloudSearchDomain = new AWS.CloudSearchDomain({endpoint : 'CLOUDSEARCH_SEARCH_ENDPOINT'});

exports.handler = function(event, context) {
    var params = {
      query: event.searchTerm, 
      size: 1,
      start: 0
    };
    
    cloudSearchDomain.search(params, function(err, data) {
      if (err) {
        context.fail(new Error('error "' + err + '"'));// an error occurred
      } 
      else {
        context.succeed(processSearchResults(data));
      }               
    });
}

function processSearchResults(data) {
    
    //Set base response type
    var response = {}
    response.success = true;
    
    var searchResults = []
    var hits = data.hits.hit;
    
    for (var i=0; i < hits.length; i++) {
        
        //retrieve the next notes
        var currentMatch = hits[i];
        var note = {};

        //Configure each note and push onto the search results
        note.id = currentMatch.id;
        note.headline = currentMatch.fields.headline[0];
        note.s3Url = currentMatch.fields.s3_url[0];
        note.userId = currentMatch.fields.user_id[0];
        searchResults.push(note);
    }
    
    response.notes = searchResults;
    return response;

}