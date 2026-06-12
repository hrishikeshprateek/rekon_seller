package com.reckon.reckonorders.NewDesign.NewModals.Home;

import java.util.List;

public class Testimonials{
	private String bgColor;
	private String levelColor;
	private boolean visible;
	private List<TestimonialsListItem> testimonialsList;
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

	public void setTestimonialsList(List<TestimonialsListItem> testimonialsList){
		this.testimonialsList = testimonialsList;
	}

	public List<TestimonialsListItem> getTestimonialsList(){
		return testimonialsList;
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
			"Testimonials{" + 
			"bg_color = '" + bgColor + '\'' + 
			",level_color = '" + levelColor + '\'' + 
			",visible = '" + visible + '\'' + 
			",testimonials_list = '" + testimonialsList + '\'' + 
			",title = '" + title + '\'' + 
			"}";
		}
}