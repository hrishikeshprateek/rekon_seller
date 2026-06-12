package com.reckon.reckonorders.NewDesign.NewMenuEnums;

import com.reckon.reckonorders.R;

public enum MenuEnums {
    ORDER_ENTRY(1, "ORDER ENTRY", R.mipmap.order_entry),
    ORDER_HISTORY(2, "ORDER HISTORY", R.mipmap.order_history),
    CART(3, "CART", R.mipmap.cart_icon),
    SCHEME(4, "SCHEME", R.mipmap.scheme),
    OUTSTANDING(5, "OUTSTANDING",R.mipmap.outstanding),
    PAYMENT(6, "PAYMENT", R.mipmap.wallet),
    STATEMENT(7, "STATEMENT", R.mipmap.statement),
    FIND_STOCKIST(8, "FIND STOCKIST", R.mipmap.stockist),
    RECEIPT_BOOK(9, "RECEIPT BOOK", R.mipmap.wallet),
    EXPIRY_ENTRY(19, "EXPIRY ENTRY", R.mipmap.order_entry),
    EXPIRY_CART(20, "EXPIRY CART", R.mipmap.cart_icon),
    EXPIRY_BOOK(21, "EXPIRY BOOK", R.mipmap.order_history);



    private String title;
    private int idIcon;
    private int order;

    MenuEnums(int order, String title, int idIcon) {
        this.title = title;
        this.idIcon = idIcon;
        this.order = order;
    }

    public String getTitle() {
        return title;
    }

    @Override
    public String toString() {
        return this.title;
    }

    public int getIdIcon() {
        return idIcon;
    }

    public int getOrder() {
        return order;
    }
}


