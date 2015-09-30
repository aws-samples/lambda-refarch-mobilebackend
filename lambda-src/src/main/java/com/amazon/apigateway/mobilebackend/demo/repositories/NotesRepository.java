package com.amazon.apigateway.mobilebackend.demo.repositories;


import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import com.amazon.apigateway.mobilebackend.demo.constants.NotesConstant;
import com.amazon.apigateway.mobilebackend.demo.models.Note;
import com.amazon.apigateway.mobilebackend.demo.models.NotesRequest;
import com.amazon.apigateway.mobilebackend.demo.models.NotesResponse;
import com.amazonaws.auth.EnvironmentVariableCredentialsProvider;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClient;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapper;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapperConfig;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBScanExpression;
import com.amazonaws.services.dynamodbv2.datamodeling.PaginatedScanList;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.Table;
import com.amazonaws.services.dynamodbv2.document.spec.DeleteItemSpec;
import com.amazonaws.services.dynamodbv2.model.AttributeValue;
import com.amazonaws.services.dynamodbv2.model.ComparisonOperator;
import com.amazonaws.services.dynamodbv2.model.Condition;
import com.amazonaws.services.dynamodbv2.model.ReturnValue;
import com.amazonaws.services.lambda.runtime.CognitoIdentity;

public class NotesRepository {
	
	private AmazonDynamoDBClient dynamoDbClient;
    private DynamoDBMapper mapper;
    private DynamoDB dynamoDB;
    private Table table;
    
	public NotesRepository( ) {
	    this.dynamoDbClient = new AmazonDynamoDBClient(new EnvironmentVariableCredentialsProvider());
	    this.mapper = new DynamoDBMapper(this.dynamoDbClient);
		this.dynamoDB = new DynamoDB(new AmazonDynamoDBClient(new EnvironmentVariableCredentialsProvider()));
	    this.table = dynamoDB.getTable(NotesConstant.DYNAMO_TABLE);
	}
	
	/**
	 * Saves a note request under a specific user id
	 * 
	 * @param notesRequest -- contains the attributes for a new note 
	 * @param identity -- contains the mobile user's cognito identity
	 * 
	 * @return a list of notes saved and a success message
	 */
	public NotesResponse save(final NotesRequest notesRequest, final CognitoIdentity identity) {
				
		List<Note> notes = new ArrayList<Note>();
		Boolean isSuccessful = false;
        try {
    	    
            Item item = new Item()
                .withPrimaryKey(NotesConstant.TABLE_USER_ID, identity.getIdentityId(), NotesConstant.TABLE_NOTE_ID, notesRequest.getId())
                .withString(NotesConstant.TABLE_HEADLINE, notesRequest.getHeadline())
                .withString(NotesConstant.TABLE_S3_URL, NotesConstant.CLOUDFRONT_ENDPOINT + notesRequest.getS3Url());
            table.putItem(item);
            
            notes.add(new Note(identity.getIdentityId(),notesRequest.getId(), 
            		notesRequest.getHeadline(), NotesConstant.CLOUDFRONT_ENDPOINT + notesRequest.getS3Url()));
            
            isSuccessful = true;

        } catch (Exception e) {
            System.err.println("Create items failed.");
            System.err.println(e.getMessage());
        }
        
	    return new NotesResponse(isSuccessful, notes);

	}


	/**
	 * Removes a note based on the note's primary key
	 * 
	 * @param notesRequest -- contains the primary key attributes for a note request
	 * @param identity -- contains the mobile user's cognito identity
	 * 
	 * @return a success message that a delete was attempted 
	 */
	public NotesResponse delete(NotesRequest notesRequest, final CognitoIdentity identity) {

	        try {

	            DeleteItemSpec deleteItemSpec = new DeleteItemSpec()
	            .withPrimaryKey(NotesConstant.TABLE_USER_ID, identity.getIdentityId(), NotesConstant.TABLE_NOTE_ID, notesRequest.getId())
	            .withReturnValues(ReturnValue.ALL_OLD);

	            this.table.deleteItem(deleteItemSpec);
	            
	        } catch (Exception e) {
	            System.err.println("Error deleting item in " + this.table);
	            System.err.println(e.getMessage());
	        }
	        
	    //For this demonstration, all delete attempts are marked as successful
	    return new NotesResponse(true, new ArrayList<Note>());
	}
	
	/**
	 * Returns a list of all notes related to a specific cognito user
	 * 
	 * @param identity -- contains the mobile user's cognito identity
	 * 
	 * @return a list of notes associated to a mobile user
	 */
	public NotesResponse findAll(final CognitoIdentity identity) {

		DynamoDBMapperConfig config = new DynamoDBMapperConfig(DynamoDBMapperConfig.ConsistentReads.CONSISTENT);
		
		DynamoDBScanExpression scanExpression = new DynamoDBScanExpression();
		Map<String, Condition> filter = new HashMap<String, Condition>();
		filter.put(NotesConstant.TABLE_USER_ID, new Condition().withComparisonOperator(ComparisonOperator.CONTAINS)
		        .withAttributeValueList(new AttributeValue().withS(identity.getIdentityId())));

		scanExpression.setScanFilter(filter);
		     
		PaginatedScanList<Note> retrievedNotes = this.mapper.scan(Note.class, scanExpression, config);
		
	    
	    List<Note> notes = new ArrayList<Note>();
	    Iterator<Note> notesIterator = retrievedNotes.iterator();
	    while (notesIterator.hasNext()){
	      notes.add(notesIterator.next());
	    }
	    
	 
		return new NotesResponse( true, notes );
	}
	
	

}
