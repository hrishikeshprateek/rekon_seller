package com.reckon.reckonorders.NewDesign.NewModals.Home;

import java.util.List;

public class Response{
	private NewArrival newArrival;
	private OrderHistory orderHistory;
	private String bgColor;
	private OrderStatus orderStatus;
	private Testimonials testimonials;
	private Brands brands;
	private List<BannerListItem> bannerList;
	private Menu menu;
	private boolean status;

	public void setNewArrival(NewArrival newArrival){
		this.newArrival = newArrival;
	}

	public NewArrival getNewArrival(){
		return newArrival;
	}

	public void setOrderHistory(OrderHistory orderHistory){
		this.orderHistory = orderHistory;
	}

	public OrderHistory getOrderHistory(){
		return orderHistory;
	}

	public void setBgColor(String bgColor){
		this.bgColor = bgColor;
	}

	public String getBgColor(){
		return bgColor;
	}

	public void setOrderStatus(OrderStatus orderStatus){
		this.orderStatus = orderStatus;
	}

	public OrderStatus getOrderStatus(){
		return orderStatus;
	}

	public void setTestimonials(Testimonials testimonials){
		this.testimonials = testimonials;
	}

	public Testimonials getTestimonials(){
		return testimonials;
	}

	public void setBrands(Brands brands){
		this.brands = brands;
	}

	public Brands getBrands(){
		return brands;
	}

	public void setBannerList(List<BannerListItem> bannerList){
		this.bannerList = bannerList;
	}

	public List<BannerListItem> getBannerList(){
		return bannerList;
	}

	public void setMenu(Menu menu){
		this.menu = menu;
	}

	public Menu getMenu(){
		return menu;
	}

	public void setStatus(boolean status){
		this.status = status;
	}

	public boolean isStatus(){
		return status;
	}

	@Override
 	public String toString(){
		return 
			"Response{" + 
			"new_arrival = '" + newArrival + '\'' + 
			",order_history = '" + orderHistory + '\'' + 
			",bg_color = '" + bgColor + '\'' + 
			",order_status = '" + orderStatus + '\'' + 
			",testimonials = '" + testimonials + '\'' + 
			",brands = '" + brands + '\'' + 
			",banner_list = '" + bannerList + '\'' + 
			",menu = '" + menu + '\'' + 
			",status = '" + status + '\'' + 
			"}";
		}
}