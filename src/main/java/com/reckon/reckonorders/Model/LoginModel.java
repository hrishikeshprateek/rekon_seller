package com.reckon.reckonorders.Model;
/*
 * Created by Manvendra Kumar Singh on 29/12/2018.
 */

import com.reckon.reckonorders.Base.BaseModel;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BannerListItem;

import java.util.ArrayList;

public class LoginModel extends BaseModel {
    private String country_name;
    private String country_id;
    private String id;
    private String Email;
    private String RateType;
    private String City;
    private String State;
    private String Area;
    private String GstNumber;
    private String PinCode;
    private String RCount;
    private String Add2;
    private String Add3;
    private String paymentDate;
    private String customerType;
    private String closingBalance;
    private String openingBalance;
    private String AcCode;
    private String rating = "";
    private String business;
    private boolean showUpdateLocation;
    private String acIdCol;
    private String latitude;
    private String longitude;
    private String googleAddress;
    private String title;

    public String getAccountCreditLimit() {
        return accountCreditLimit;
    }

    public void setAccountCreditLimit(String accountCreditLimit) {
        this.accountCreditLimit = accountCreditLimit;
    }

    public String getAccountCreditDays() {
        return accountCreditDays;
    }

    public void setAccountCreditDays(String accountCreditDays) {
        this.accountCreditDays = accountCreditDays;
    }

    public String getAccountCreditBills() {
        return accountCreditBills;
    }

    public void setAccountCreditBills(String accountCreditBills) {
        this.accountCreditBills = accountCreditBills;
    }

    private String accountCreditLimit;
    private String accountCreditDays;
    private String accountCreditBills;



    public String getAccountStatus() {
        return accountStatus;
    }

    public void setAccountStatus(String accountStatus) {
        this.accountStatus = accountStatus;
    }

    private String accountStatus;


    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMobilePrefix() {
        return mobilePrefix;
    }

    public void setMobilePrefix(String mobilePrefix) {
        this.mobilePrefix = mobilePrefix;
    }

    public int getMobileLength() {
        return mobileLength;
    }

    public void setMobileLength(int mobileLength) {
        this.mobileLength = mobileLength;
    }

    private String mobilePrefix;
    private int mobileLength;






    public String getDistance() {
        return distance;
    }

    public void setDistance(String distance) {
        this.distance = distance;
    }

    private String distance;

    public String getLatitude() {
        return latitude;
    }

    public void setLatitude(String latitude) {
        this.latitude = latitude;
    }

    public String getLongitude() {
        return longitude;
    }

    public void setLongitude(String longitude) {
        this.longitude = longitude;
    }

    public String getGoogleAddress() {
        return googleAddress;
    }

    public void setGoogleAddress(String googleAddress) {
        this.googleAddress = googleAddress;
    }



    public String getAcIdCol() {
        return acIdCol;
    }

    public void setAcIdCol(String acIdCol) {
        this.acIdCol = acIdCol;
    }

    private ArrayList<BannerListItem> bannerList;
    public boolean isShowUpdateLocation() {
        return showUpdateLocation;
    }

    public void setShowUpdateLocation(boolean showUpdateLocation) {
        this.showUpdateLocation = showUpdateLocation;
    }



    public String getAcCode() {
        return AcCode;
    }

    public void setAcCode(String acCode) {
        AcCode = acCode;
    }



    public String getClosingBalance() {
        return closingBalance;
    }

    public void setClosingBalance(String closingBalance) {
        this.closingBalance = closingBalance;
    }

    public String getOpeningBalance() {
        return openingBalance;
    }

    public void setOpeningBalance(String openingBalance) {
        this.openingBalance = openingBalance;
    }



    public String getCustomerType() {
        return customerType;
    }

    public void setCustomerType(String customerType) {
        this.customerType = customerType;
    }
    public String getPaymentDate() {
        return paymentDate;
    }

    public void setPaymentDate(String paymentDate) {
        this.paymentDate = paymentDate;
    }
    public String getState() {
        return State;
    }

    public void setState(String state) {
        State = state;
    }

    public String getArea() {
        return Area;
    }

    public void setArea(String area) {
        Area = area;
    }

    public String getStatus() {
        return Status;
    }

    public void setStatus(String status) {
        Status = status;
    }

    public String getLock() {
        return Lock;
    }

    public void setLock(String lock) {
        Lock = lock;
    }

    private String Status;
    private String Lock;

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

    public String getAdd1() {
        return Add1;
    }

    public void setAdd1(String add1) {
        Add1 = add1;
    }

    private String LicNo;
    private String Mobile;
    private String Add1;
    private String ShowStock;


    public String getCountry_name() {
        return country_name;
    }

    public void setCountry_name(String country_name) {
        this.country_name = country_name;
    }

    public String getCountry_id() {
        return country_id;
    }

    public void setCountry_id(String country_id) {
        this.country_id = country_id;
    }


    public String getMobile() {
        return Mobile!=null?Mobile:"";
    }

    public void setMobile(String mobile) {
        Mobile = mobile;
    }

    public String getShowStock() {
        return ShowStock;
    }

    public void setShowStock(String showStock) {
        ShowStock = showStock;
    }

    public String getRateType() {
        return RateType;
    }

    public void setRateType(String rateType) {
        RateType = rateType;
    }

    public String getCity() {
        return City;
    }

    public void setCity(String city) {
        City = city;
    }

    public String getGstNumber() {
        return GstNumber;
    }

    public void setGstNumber(String gstNumber) {
        GstNumber = gstNumber;
    }

    public String getPinCode() {
        return PinCode;
    }

    public void setPinCode(String pinCode) {
        PinCode = pinCode;
    }

    public String getRCount() {
        return RCount;
    }

    public void setRCount(String RCount) {
        this.RCount = RCount;
    }

    public String getAdd2() {
        return Add2;
    }

    public void setAdd2(String add2) {
        Add2 = add2;
    }

    public String getAdd3() {
        return Add3;
    }

    public void setAdd3(String add3) {
        Add3 = add3;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public ArrayList<BannerListItem> getBannerList() {
        return bannerList;
    }

    public void setBannerList(ArrayList<BannerListItem> bannerList) {
        this.bannerList = bannerList;
    }

    public String getRating() {
        return rating;
    }

    public void setRating(String rating) {
        this.rating = rating;
    }

    public String getBusiness() {
        return business!=null?business:"";
    }

    public void setBusiness(String business) {
        this.business = business;
    }
}
