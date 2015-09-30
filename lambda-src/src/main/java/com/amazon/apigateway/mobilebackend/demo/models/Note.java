package com.amazon.apigateway.mobilebackend.demo.models;

public class Note {
	
    private String id;
    private String headline;
    private String s3Url;
    private String userId;
    
    public Note() { }
    
    public Note(final String userId,final String id, final String headline, final String s3Url) {
    	this.id = id;
    	this.headline = headline;
    	this.s3Url = s3Url;
    	this.userId = userId;
    }
    
    public String getUserId() {return userId;}
    public void setUserId(String userId) {this.userId = userId;}
    
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getHeadline() {return headline;}
    public void setHeadline(String headline) {this.headline = headline;}
    
    public String getS3Url() { return s3Url; }    
    public void setS3Url(String s3Url) { this.s3Url = s3Url; }
    
	@Override
	public String toString() {
		return "NotesData [id=" + id + ", headline=" + headline + ", s3Url=" + s3Url + ", userId=" + userId
				+ "]";
	}
    
}
