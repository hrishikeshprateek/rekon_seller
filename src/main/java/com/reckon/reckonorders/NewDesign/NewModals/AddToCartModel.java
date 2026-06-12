package com.reckon.reckonorders.NewDesign.NewModals;

import com.reckon.reckonorders.Base.BaseModel;

public class AddToCartModel extends BaseModel {

    String itemCount;
    int id;
    String productName;

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }


    public String getItemCount() {
        return itemCount;
    }

    public void setItemCount(String itemCount) {
        this.itemCount = itemCount;
    }
    
}
