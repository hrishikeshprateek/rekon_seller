package com.reckon.reckonorders.NewDesign.NewModals.Home;

import java.util.List;

public class Brands{
	private String bgColor;
	private String levelColor;
	private boolean visible;
	private String title;
	private List<BrandListItem> brandList;

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

	public void setTitle(String title){
		this.title = title;
	}

	public String getTitle(){
		return title;
	}

	public void setBrandList(List<BrandListItem> brandList){
		this.brandList = brandList;
	}

	public List<BrandListItem> getBrandList(){
		return brandList;
	}

	@Override
 	public String toString(){
		return 
			"Brands{" + 
			"bg_color = '" + bgColor + '\'' + 
			",level_color = '" + levelColor + '\'' + 
			",visible = '" + visible + '\'' + 
			",title = '" + title + '\'' + 
			",brand_list = '" + brandList + '\'' + 
			"}";
		}
}