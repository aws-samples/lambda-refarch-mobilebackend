package com.amazon.apigateway.mobilebackend.demo.models;

import java.util.List;

public class NotesResponse {

	private Boolean success;
	private List<Note> notes;
	
	public NotesResponse(Boolean success, List<Note> notes ) {
		this.success = success;
		this.notes = notes;
	}

	public Boolean getSuccess() {
		return success;
	}

	public void setSuccess(Boolean success) {
		this.success = success;
	}

	public List<Note> getNotes() {
		return notes;
	}

	public void setNotes(List<Note> notes) {
		this.notes = notes;
	}

	@Override
	public String toString() {
		return "NotesResponse [success=" + success + ", notes=" + notes + "]";
	}

}
