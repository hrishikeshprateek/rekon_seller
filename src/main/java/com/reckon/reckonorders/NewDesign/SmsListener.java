package com.reckon.reckonorders.NewDesign;

public interface SmsListener {

    public void onOTPReceived(String otp);

    public void onOTPTimeOut();
}
