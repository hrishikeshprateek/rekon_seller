package com.reckon.reckonorders.NewDesign.NewModals.Home;

public class ArrivalListItem{
	private String scheme;
	private String productImage;
	private double price;
	private String description;
	private String discount;
	private double mrp;
	private String currency;
	private int id;
	private String productName;

	public void setScheme(String scheme){
		this.scheme = scheme;
	}

	public String getScheme(){
		return scheme;
	}

	public void setProductImage(String productImage){
		this.productImage = productImage;
	}

	public String getProductImage(){
		return productImage;
	}

	public void setPrice(double price){
		this.price = price;
	}

	public double getPrice(){
		return price;
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

	public void setMrp(double mrp){
		this.mrp = mrp;
	}

	public double getMrp(){
		return mrp;
	}

	public void setCurrency(String currency){
		this.currency = currency;
	}

	public String getCurrency(){
		return currency;
	}

	public void setId(int id){
		this.id = id;
	}

	public int getId(){
		return id;
	}

	public void setProductName(String productName){
		this.productName = productName;
	}

	public String getProductName(){
		return productName;
	}

	@Override
 	public String toString(){
		return 
			"ArrivalListItem{" + 
			"scheme = '" + scheme + '\'' + 
			",product_image = '" + productImage + '\'' + 
			",price = '" + price + '\'' + 
			",description = '" + description + '\'' + 
			",discount = '" + discount + '\'' + 
			",mrp = '" + mrp + '\'' + 
			",currency = '" + currency + '\'' + 
			",id = '" + id + '\'' + 
			",product_name = '" + productName + '\'' + 
			"}";
		}
}
