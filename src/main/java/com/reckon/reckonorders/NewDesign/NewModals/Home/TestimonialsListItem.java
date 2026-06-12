package com.reckon.reckonorders.NewDesign.NewModals.Home;

public class TestimonialsListItem{
	private String date;
	private String businessName;
	private String name;
	private String rating;
	private String id;
	private String descriptions;
	private String backgroundColor;


	private String fontColor;

	public String getBackgroundColorOfTestimonial() {
		return backgroundColor;
	}

	public void setBackgroundColorOfTestimonial(String backgroundColor) {
		this.backgroundColor = backgroundColor;
	}
	public String getFontColor() {
		return fontColor;
	}

	public void setFontColor(String fontColor) {
		this.fontColor = fontColor;
	}

	public void setDate(String date){
		this.date = date;
	}

	public String getDate(){
		return date;
	}

	public void setBusinessName(String businessName){
		this.businessName = businessName;
	}

	public String getBusinessName(){
		return businessName;
	}

	public void setName(String name){
		this.name = name;
	}

	public String getName(){
		return name;
	}

	public void setRating(String rating){
		this.rating = rating;
	}

	public String getRating(){
		return rating;
	}

	public void setId(String id){
		this.id = id;
	}

	public String getId(){
		return id;
	}

	public void setDescriptions(String descriptions){
		this.descriptions = descriptions;
	}

	public String getDescriptions(){
		return descriptions;
	}

	@Override
 	public String toString(){
		return 
			"TestimonialsListItem{" + 
			"date = '" + date + '\'' + 
			",business_name = '" + businessName + '\'' + 
			",name = '" + name + '\'' + 
			",rating = '" + rating + '\'' + 
			",id = '" + id + '\'' + 
			",descriptions = '" + descriptions + '\'' + 
			"}";
		}
}
