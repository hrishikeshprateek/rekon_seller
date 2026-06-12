package com.reckon.reckonorders.NewDesign.NewModals.Home;

import java.util.List;

public class Menu{
	private String bgColor;
	private String levelColor;
	private boolean visible;
	private List<MenuListItem> manuList;
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

	public void setManuList(List<MenuListItem> manuList){
		this.manuList = manuList;
	}

	public List<MenuListItem> getManuList(){
		return manuList;
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
			"Menu{" + 
			"bg_color = '" + bgColor + '\'' + 
			",level_color = '" + levelColor + '\'' + 
			",visible = '" + visible + '\'' + 
			",manu_list = '" + manuList + '\'' + 
			",title = '" + title + '\'' + 
			"}";
		}
}