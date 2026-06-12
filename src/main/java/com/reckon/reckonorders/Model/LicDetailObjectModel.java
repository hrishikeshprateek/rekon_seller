package com.reckon.reckonorders.Model;

import com.google.gson.annotations.SerializedName;

public class LicDetailObjectModel {

    private String bg_color;
    private String role;
    private String licno;
    private String dlcount;
    private String firmcode;
    private String flcount;
    private String gstcount;
    private String currency;
    private String regsmscustomer;
    private String retailerType;
    private String firmName;
    private String firmAdd;
    private boolean hasAddQtyOptions;

    public boolean isHasAddQtyOptions() {
        return hasAddQtyOptions;
    }

    public void setHasAddQtyOptions(boolean hasAddQtyOptions) {
        this.hasAddQtyOptions = hasAddQtyOptions;
    }


    public String getDlcount2() {
        return dlcount2;
    }

    public void setDlcount2(String dlcount2) {
        this.dlcount2 = dlcount2;
    }

    private String dlcount2;


    public String getBg_color() {
        return bg_color;
    }

    public void setBg_color(String bg_color) {
        this.bg_color = bg_color;
    }

    public String getRole() {
        return role!=null && !role.isEmpty()?role:"Retailer";
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getLicno() {
        return licno;
    }

    public void setLicno(String licno) {
        this.licno = licno;
    }

    public String getDlcount() {
        return dlcount;
    }

    public void setDlcount(String dlcount) {
        this.dlcount = dlcount;
    }

    public String getFirmcode() {
        return firmcode;
    }

    public void setFirmcode(String firmcode) {
        this.firmcode = firmcode;
    }

    public String getFlcount() {
        return flcount;
    }

    public void setFlcount(String flcount) {
        this.flcount = flcount;
    }

    public String getGstcount() {
        return gstcount;
    }

    public void setGstcount(String gstcount) {
        this.gstcount = gstcount;
    }

    public String getCurrency() {
        return currency!=null? currency:"₹";
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getRegsmscustomer() {
        return regsmscustomer;
    }

    public void setRegsmscustomer(String regsmscustomer) {
        this.regsmscustomer = regsmscustomer;
    }

    public String getRegsmsfirm() {
        return regsmsfirm;
    }

    public void setRegsmsfirm(String regsmsfirm) {
        this.regsmsfirm = regsmsfirm;
    }

    public void setRateFactor(String rateFactor) {
        RateFactor = rateFactor;
    }

    private String regsmsfirm;


    @SerializedName("PARAMNAME")
    private String PARAMNAME;

    @SerializedName("PARAMVALUE")
    private String PARAMVALUE;

    @SerializedName("RateFactor")
    private String RateFactor;


    public String getPARAMNAME() {
        return PARAMNAME != null ? PARAMNAME : "";
    }

    public void setPARAMNAME(String PARAMNAME) {
        this.PARAMNAME = PARAMNAME;
    }

    public String getPARAMVALUE() {
        return PARAMVALUE != null ? PARAMVALUE : "";
    }

    public void setPARAMVALUE(String PARAMVALUE) {
        this.PARAMVALUE = PARAMVALUE;
    }

    public String getRateFactor() {
        return RateFactor;
    }
    public String getRetailerType() {
        return retailerType;
    }

    public void setRetailerType(String retailerType) {
        this.retailerType = retailerType;
    }

    public String getFirmName() {
        return firmName;
    }

    public void setFirmName(String firmName) {
        this.firmName = firmName;
    }

    public String getFirmAdd() {
        return firmAdd;
    }

    public void setFirmAdd(String firmAdd) {
        this.firmAdd = firmAdd;
    }
}