package com.reckon.reckonorders.NewDesign.NewModals.Home;

public class BrandListItem{
	private String image;
	private String description;
	private String discount;
	private int id;
	private String title;

	public String getFontColor() {
		return fontColor;
	}

	public void setFontColor(String fontColor) {
		this.fontColor = fontColor;
	}

	private String fontColor;

		public String getBgColor() {
		return bgColor;
	}

	public void setBgColor(String bgColor) {
		this.bgColor = bgColor;
	}

	private String bgColor;

	public void setImage(String image){
		this.image = image;
	}

	public String getImage(){
		return image!=null?image:"";
	}

	public void setDescription(String description){
		this.description = description;
	}

	public String getDescription(){
		return description;
	}

	public void setDiscount(String discount){
		this.discount = discount;
	}

	public String getDiscount(){
		return discount;
	}

	public void setId(int id){
		this.id = id;
	}

	public int getId(){
		return id;
	}

	public void setTitle(String title){
		this.title = title;
	}

	public String getTitle(){
		return title;
	}

	@Override
 	public String toString(){
		return 
			"BrandListItem{" + 
			"image = '" + image + '\'' + 
			",description = '" + description + '\'' + 
			",discount = '" + discount + '\'' + 
			",id = '" + id + '\'' + 
			",title = '" + title + '\'' + 
			"}";
		}
}
