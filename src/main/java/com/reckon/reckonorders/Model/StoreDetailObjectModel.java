package com.reckon.reckonorders.Model;

import com.google.gson.annotations.SerializedName;

public class StoreDetailObjectModel {

    @SerializedName("Add1")
    private String Add1;
    @SerializedName("Add2")
    private String Add2;
    @SerializedName("Add3")
    private String Add3;
    @SerializedName("Mobile")
    private String Mobile;
    @SerializedName("Name")
    private String Name;
    @SerializedName("PinCode")
    private String PinCode;
    @SerializedName("FirmCode")
    private String FirmCode;

    @SerializedName("id")
    private String id;

    @SerializedName("AcCode")
    private String AcCode;

    @SerializedName("LicNo")
    private String LicNo;

    @SerializedName("Email")
    private String Email;

    @SerializedName("City")
    private String City;

    @SerializedName("Mid")
    private String Mid;

    @SerializedName("field_name")
    private String field_name;
    @SerializedName("field_value")
    private String field_value;

    public boolean isPrimary() {
        return primary;
    }

    public void setPrimary(boolean primary) {
        this.primary = primary;
    }

    @SerializedName("primary")
    private boolean primary;

    public String getField_name() {
        return field_name;
    }

    public void setField_name(String field_name) {
        this.field_name = field_name;
    }

    public String getField_value() {
        return field_value;
    }

    public void setField_value(String field_value) {
        this.field_value = field_value;
    }



    public String getCity() {
        return City;
    }

    public void setCity(String city) {
        City = city;
    }

    public String getMid() {
        return Mid;
    }

    public void setMid(String mid) {
        Mid = mid;
    }

    public String getMkey() {
        return Mkey;
    }

    public void setMkey(String mkey) {
        Mkey = mkey;
    }

    @SerializedName("Mkey")
    private String Mkey;


    public String getEmail() {
        return Email;
    }

    public void setEmail(String email) {
        Email = email;
    }



    public String getLicNo() {
        return LicNo;
    }

    public void setLicNo(String licNo) {
        LicNo = licNo;
    }

    private String firstChar;

    public String getAdd1() {
        return Add1!=null? Add1:"";
    }

    public void setAdd1(String add1) {
        Add1 = add1;
    }

    public String getAdd2() {
        return Add2!=null?Add2:"";
    }

    public void setAdd2(String add2) {
        Add2 = add2;
    }

    public String getAdd3() {
        return Add3!=null?Add3:"";
    }

    public void setAdd3(String add3) {
        Add3 = add3;
    }

    public String getMobile() {
        return Mobile!=null?Mobile:"";
    }

    public void setMobile(String mobile) {
        Mobile = mobile;
    }

    public String getName() {
        return Name!=null?Name:"";
    }

    public void setName(String name) {
        Name = name;
    }

    public String getPinCode() {
        return PinCode!=null?PinCode:"";
    }

    public void setPinCode(String pinCode) {
        PinCode = pinCode;
    }


    public String getFirmCode() {
        return FirmCode;
    }

    public void setFirmCode(String firmCode) {
        FirmCode = firmCode;
    }

    public String getFirstChar() {
        return firstChar;
    }

    public void setFirstChar(String firstChar) {
        this.firstChar = firstChar;
    }
    public String getId() {
        return id!=null?id:"";
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getAcCode() {
        return AcCode!=null?AcCode:"";
    }

    public void setAcCode(String acCode) {
        AcCode = acCode;
    }
}