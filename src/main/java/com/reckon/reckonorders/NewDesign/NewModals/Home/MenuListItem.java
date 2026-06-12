package com.reckon.reckonorders.NewDesign.NewModals.Home;

public class MenuListItem {
	private String image;
	private boolean visible;
	private String screenName;
	private String bgCard;
	private String link;
	private int id;
	private String title;
	private int type;
	private String colorTitle;


	private boolean isActive;




	public void setImage(String image){
		this.image = image;
	}

	public String getImage(){
		return image;
	}

	public void setVisible(boolean visible){
		this.visible = visible;
	}

	public boolean isVisible(){
		return visible;
	}

	public void setScreenName(String screenName){
		this.screenName = screenName;
	}

	public String getScreenName(){
		return screenName;
	}

	public void setBgCard(String bgCard){
		this.bgCard = bgCard;
	}

	public String getBgCard(){
		return bgCard;
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

	public void setTitle(String title){
		this.title = title;
	}

	public String getTitle(){
		return title;
	}

	public void setType(int type){
		this.type = type;
	}

	public int getType(){
		return type;
	}

	public void setColorTitle(String colorTitle){
		this.colorTitle = colorTitle;
	}

	public String getColorTitle(){
		return colorTitle;
	}

	@Override
 	public String toString(){
		return 
			"MenuListItem{" +
			"image = '" + image + '\'' + 
			",visible = '" + visible + '\'' + 
			",screen_name = '" + screenName + '\'' + 
			",bg_card = '" + bgCard + '\'' + 
			",link = '" + link + '\'' + 
			",id = '" + id + '\'' + 
			",title = '" + title + '\'' + 
			",type = '" + type + '\'' + 
			",color_title = '" + colorTitle + '\'' + 
			"}";
		}

	public boolean isActive() {
		return isActive;
	}

	public void setActive(boolean active) {
		isActive = active;
	}
}
