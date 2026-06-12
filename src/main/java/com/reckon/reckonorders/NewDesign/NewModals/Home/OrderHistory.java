package com.reckon.reckonorders.NewDesign.NewModals.Home;

public class OrderHistory{
	private String totalOrdersAmount;
	private String bgColor;
	private String totalOrdersCount;
	private String levelColor;
	private boolean visible;
	private String bouncedAmount;
	private String invoicesCount;
	private String title;
	private String invoicesAmount;
	private String bouncedCount;

	public void setTotalOrdersAmount(String totalOrdersAmount){
		this.totalOrdersAmount = totalOrdersAmount;
	}

	public String getTotalOrdersAmount(){
		return totalOrdersAmount;
	}

	public void setBgColor(String bgColor){
		this.bgColor = bgColor;
	}

	public String getBgColor(){
		return bgColor;
	}

	public void setTotalOrdersCount(String totalOrdersCount){
		this.totalOrdersCount = totalOrdersCount;
	}

	public String getTotalOrdersCount(){
		return totalOrdersCount;
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

	public void setBouncedAmount(String bouncedAmount){
		this.bouncedAmount = bouncedAmount;
	}

	public String getBouncedAmount(){
		return bouncedAmount;
	}

	public void setInvoicesCount(String invoicesCount){
		this.invoicesCount = invoicesCount;
	}

	public String getInvoicesCount(){
		return invoicesCount;
	}

	public void setTitle(String title){
		this.title = title;
	}

	public String getTitle(){
		return title;
	}

	public void setInvoicesAmount(String invoicesAmount){
		this.invoicesAmount = invoicesAmount;
	}

	public String getInvoicesAmount(){
		return invoicesAmount;
	}

	public void setBouncedCount(String bouncedCount){
		this.bouncedCount = bouncedCount;
	}

	public String getBouncedCount(){
		return bouncedCount;
	}

	@Override
 	public String toString(){
		return 
			"OrderHistory{" + 
			"total_orders_amount = '" + totalOrdersAmount + '\'' + 
			",bg_color = '" + bgColor + '\'' + 
			",total_orders_count = '" + totalOrdersCount + '\'' + 
			",level_color = '" + levelColor + '\'' + 
			",visible = '" + visible + '\'' + 
			",bounced_amount = '" + bouncedAmount + '\'' + 
			",invoices_count = '" + invoicesCount + '\'' + 
			",title = '" + title + '\'' + 
			",invoices_amount = '" + invoicesAmount + '\'' + 
			",bounced_count = '" + bouncedCount + '\'' + 
			"}";
		}
}
