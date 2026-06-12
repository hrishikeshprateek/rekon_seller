package com.reckon.reckonorders.NewDesign.NewModals;

import android.graphics.drawable.Drawable;

import com.reckon.reckonorders.Base.BaseModel;

import java.util.ArrayList;

public class TestDataForItemShow extends BaseModel {

    String product_name;

    public TestDataForItemShow(String product_name, String product_description, String product_price, String product_discount, String product_price_after_discount, int product_image) {
        this.product_name = product_name;
        this.product_description = product_description;
        this.product_price = product_price;
        this.product_discount = product_discount;
        this.product_price_after_discount = product_price_after_discount;
        this.product_image = product_image;
    }

    String product_description;
    String product_price;
    String product_discount;
    String product_price_after_discount;

    int product_image;

    public String getProduct_name() {
        return product_name;
    }

    public void setProduct_name(String product_name) {
        this.product_name = product_name;
    }

    public String getProduct_description() {
        return product_description;
    }

    public void setProduct_description(String product_description) {
        this.product_description = product_description;
    }

    public String getProduct_price() {
        return product_price;
    }

    public void setProduct_price(String product_price) {
        this.product_price = product_price;
    }

    public String getProduct_discount() {
        return product_discount;
    }

    public void setProduct_discount(String product_discount) {
        this.product_discount = product_discount;
    }

    public String getProduct_price_after_discount() {
        return product_price_after_discount;
    }

    public void setProduct_price_after_discount(String product_price_after_discount) {
        this.product_price_after_discount = product_price_after_discount;
    }

    public int getProduct_image() {
        return product_image;
    }

    public void setProduct_image(int product_image) {
        this.product_image = product_image;
    }



}
