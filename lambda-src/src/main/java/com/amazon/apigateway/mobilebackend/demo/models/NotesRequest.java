package com.amazon.apigateway.mobilebackend.demo.models;

import java.util.UUID;

public class NotesRequest {

	private String id;
	private String headline;
	private String s3Url;
	private String requestMethod;
	
	public NotesRequest(String id, String s3Url, String headline, String requestMethod) {
		this.id = id;
		this.headline = headline;
		this.s3Url = s3Url;
	}
	
	public NotesRequest() {
		this.id = UUID.randomUUID().toString();
	}
	
	public String getId() {
		return id;
	}
	
	public void setId(String id) {
		this.id = id;
	}

	public String getHeadline() {
		return headline;
	}

	public void setHeadline(String headline) {
		this.headline = headline;
	}

	public String getS3Url() {
		return s3Url;
	}

	public void setS3Url(String s3Url) {
		this.s3Url = s3Url;
	}

	public String getRequestMethod() {
		return requestMethod;
	}

	public void setRequestMethod(String requestMethod) {
		this.requestMethod = requestMethod;
	}

	@Override
	public String toString() {
		return "NotesRequest [id=" + id + ", headline=" + headline + ", s3Url=" + s3Url + ", requestMethod="
				+ requestMethod + "]";
	}

}
