package com.amazon.apigateway.mobilebackend.demo.handler;

import java.util.ArrayList;

import com.amazon.apigateway.mobilebackend.demo.models.Note;
import com.amazon.apigateway.mobilebackend.demo.models.NotesRequest;
import com.amazon.apigateway.mobilebackend.demo.models.NotesResponse;
import com.amazon.apigateway.mobilebackend.demo.repositories.NotesRepository;
import com.amazonaws.services.lambda.runtime.Context;

public class NotesApi {
	
	private NotesRepository notesRepository;
	
	public NotesApi(NotesRepository notesRepository ) {
		this.notesRepository = notesRepository;
	}
	
	public NotesApi( ) {
		this.notesRepository = new NotesRepository();
	}
	
    public NotesResponse handleRequest(final NotesRequest notesRequest, final Context context) {
    	final String requestMethod = notesRequest.getRequestMethod();
    	NotesResponse notesResponse;
        switch (requestMethod) {
            case "GET":
            	notesResponse = this.notesRepository.findAll(context.getIdentity());
                break;
            case "POST":
            	notesResponse = this.notesRepository.save(notesRequest, context.getIdentity());
            	break;
            case "DELETE":
            	notesResponse = this.notesRepository.delete(notesRequest, context.getIdentity());
                break;
            default:
            	//If an invalid request is sent, we return an error response
            	notesResponse = new NotesResponse(false, new ArrayList<Note>() );
            	break;
        }
        return notesResponse;
        
    }
    
}