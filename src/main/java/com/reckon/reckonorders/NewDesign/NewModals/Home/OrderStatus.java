package com.reckon.reckonorders.NewDesign.NewModals.Home;

public class OrderStatus{
	private String date;
	private String bgColor;
	private String amount;
	private String levelColor;
	private boolean visible;
	private String currency;
	private String id;
	private String title;
	private String status;

	public void setDate(String date){
		this.date = date;
	}

	public String getDate(){
		return date;
	}

	public void setBgColor(String bgColor){
		this.bgColor = bgColor;
	}

	public String getBgColor(){
		return bgColor;
	}

	public void setAmount(String amount){
		this.amount = amount;
	}

	public String getAmount(){
		return amount;
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

	public void setCurrency(String currency){
		this.currency = currency;
	}

	public String getCurrency(){
		return currency;
	}

	public void setId(String id){
		this.id = id;
	}

	public String getId(){
		return id;
	}

	public void setTitle(String title){
		this.title = title;
	}

	public String getTitle(){
		return title;
	}

	public void setStatus(String status){
		this.status = status;
	}

	public String getStatus(){
		return status;
	}

	@Override
 	public String toString(){
		return 
			"OrderStatus{" + 
			"date = '" + date + '\'' + 
			",bg_color = '" + bgColor + '\'' + 
			",amount = '" + amount + '\'' + 
			",level_color = '" + levelColor + '\'' + 
			",visible = '" + visible + '\'' + 
			",currency = '" + currency + '\'' + 
			",id = '" + id + '\'' + 
			",title = '" + title + '\'' + 
			",status = '" + status + '\'' + 
			"}";
		}
}
