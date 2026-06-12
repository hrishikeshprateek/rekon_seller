package com.reckon.reckonorders.NewDesign.NewModals.Registration;

public class ResponseFromRegistration {
	private boolean status;
	private String message;
	private String dbName;
	private int id;
	private String baseUrl;
	private Profile profile;

	public void setStatus(boolean status){
		this.status = status;
	}

	public boolean isStatus(){
		return status;
	}

	public void setMessage(String message){
		this.message = message;
	}

	public String getMessage(){
		return message;
	}

	public void setDbName(String dbName){
		this.dbName = dbName;
	}

	public String getDbName(){
		return dbName;
	}

	public void setId(int id){
		this.id = id;
	}

	public int getId(){
		return id;
	}

	public void setBaseUrl(String baseUrl){
		this.baseUrl = baseUrl;
	}

	public String getBaseUrl(){
		return baseUrl;
	}

	public void setProfile(Profile profile){
		this.profile = profile;
	}

	public Profile getProfile(){
		return profile;
	}

	@Override
 	public String toString(){
		return 
			"ResponseFromRegistration{" +
			"status = '" + status + '\'' + 
			",message = '" + message + '\'' + 
			",dbName = '" + dbName + '\'' + 
			",id = '" + id + '\'' + 
			",baseUrl = '" + baseUrl + '\'' + 
			",profile = '" + profile + '\'' + 
			"}";
		}
}
