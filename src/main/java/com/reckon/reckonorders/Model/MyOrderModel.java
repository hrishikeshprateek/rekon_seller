package com.reckon.reckonorders.Model;

import org.json.JSONArray;

public class MyOrderModel {
    public String getFIRM_NAME() {
        return FIRM_NAME;
    }

    public void setFIRM_NAME(String FIRM_NAME) {
        this.FIRM_NAME = FIRM_NAME;
    }

    public String getFIRM_LICNO() {
        return FIRM_LICNO;
    }

    public void setFIRM_LICNO(String FIRM_LICNO) {
        this.FIRM_LICNO = FIRM_LICNO;
    }

    public String getFIRM_CODE() {
        return FIRM_CODE;
    }

    public void setFIRM_CODE(String FIRM_CODE) {
        this.FIRM_CODE = FIRM_CODE;
    }

    private String FIRM_NAME;
    private String FIRM_LICNO;
    private String FIRM_CODE;

    public String getOrderIName() {
        return OrderIName;
    }

    public void setOrderIName(String orderIName) {
        OrderIName = orderIName;
    }

    public String getOrderPack() {
        return OrderPack;
    }

    public void setOrderPack(String orderPack) {
        OrderPack = orderPack;
    }

    public String getOrderBalQty() {
        return OrderBalQty;
    }

    public void setOrderBalQty(String orderBalQty) {
        OrderBalQty = orderBalQty;
    }

    public String getOrderOQty() {
        return OrderOQty;
    }

    public void setOrderOQty(String orderOQty) {
        OrderOQty = orderOQty;
    }

    private String OrderIName;
    private String OrderPack;
    private String OrderBalQty;
    private String OrderOQty;


    public String getORDERDATE() {
        return ORDERDATE;
    }

    public void setORDERDATE(String ORDERDATE) {
        this.ORDERDATE = ORDERDATE;
    }

    public String getORDERNUMBER() {
        return ORDERNUMBER;
    }

    public void setORDERNUMBER(String ORDERNUMBER) {
        this.ORDERNUMBER = ORDERNUMBER;
    }

    public String getORDERSTATUS() {
        return ORDERSTATUS;
    }

    public void setORDERSTATUS(String ORDERSTATUS) {
        this.ORDERSTATUS = ORDERSTATUS;
    }

    private String ORDERDATE;
    private String ORDERNUMBER;
    private String ORDERSTATUS;


    public JSONArray getOrderList() {
        return OrderList;
    }

    public void setOrderList(JSONArray orderList) {
        OrderList = orderList;
    }

    private JSONArray OrderList;

}
