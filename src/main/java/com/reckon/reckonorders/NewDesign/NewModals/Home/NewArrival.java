package com.reckon.reckonorders.NewDesign.NewModals.Home;

import java.util.List;

public class NewArrival{
	private String bgColor;
	private String levelColor;
	private boolean visible;
	private List<ArrivalListItem> arrivalList;
	private String title;

	public void setBgColor(String bgColor){
		this.bgColor = bgColor;
	}

	public String getBgColor(){
		return bgColor;
	}

	public void setLevelColor(String levelColor){
		this.levelColor = levelColor;
	}

	public String getLevelColor(){
		return levelColor;
	}

	public void setVisible(boolean visible){
		this.visible = visible;
	}

	public boolean isVisible(){
		return visible;
	}

	public void setArrivalList(List<ArrivalListItem> arrivalList){
		this.arrivalList = arrivalList;
	}

	public List<ArrivalListItem> getArrivalList(){
		return arrivalList;
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
			"NewArrival{" + 
			"bg_color = '" + bgColor + '\'' + 
			",level_color = '" + levelColor + '\'' + 
			",visible = '" + visible + '\'' + 
			",arrival_list = '" + arrivalList + '\'' + 
			",title = '" + title + '\'' + 
			"}";
		}
}