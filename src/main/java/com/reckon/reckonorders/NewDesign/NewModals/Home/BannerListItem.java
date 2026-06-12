package com.reckon.reckonorders.NewDesign.NewModals.Home;

public class BannerListItem{
	private String imageUrl;
	private String link;

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	private String title;
	private int id;
	private String type;

	public String getDealsInId() {
		return dealsInId;
	}

	public void setDealsInId(String dealsInId) {
		this.dealsInId = dealsInId;
	}

	private String dealsInId;

	public void setImageUrl(String imageUrl){
		this.imageUrl = imageUrl;
	}

	public String getImageUrl(){
		return imageUrl;
	}

	public void setLink(String link){
		this.link = link;
	}

	public String getLink(){
		return link;
	}

	public void setId(int id){
		this.id = id;
	}

	public int getId(){
		return id;
	}

	@Override
 	public String toString(){
		return 
			"BannerListItem{" + 
			"image_url = '" + imageUrl + '\'' + 
			",link = '" + link + '\'' + 
			",id = '" + id + '\'' + 
			"}";
		}
}
