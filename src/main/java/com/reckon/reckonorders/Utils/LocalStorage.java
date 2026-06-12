package com.reckon.reckonorders.Utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;

import com.reckon.reckonorders.Others.Constant.Constant;

/**
 * Created on 08-May-2020.
 * Created by : Manvendra Kumar Singh
 */
public class LocalStorage {

    private static final String KEY_FIREBASE_TOKEN = "firebaseToken";
    public static final String KEY_USER = "User";
    public static final String KEY_USER_ADDRESS = "user_address";

    private static final String IS_USER_LOGIN = "IsUserLoggedIn";


    private static LocalStorage instance = null;
    SharedPreferences sharedPreferences;
    Editor editor;
    int PRIVATE_MODE = 0;
    Context _context;

    public LocalStorage(Context context) {
        sharedPreferences = context.getSharedPreferences("Preferences", 0);
    }

    public static LocalStorage getInstance(Context context) {
        if (instance == null) {
            synchronized (LocalStorage.class) {
                if (instance == null) {
                    instance = new LocalStorage(context);
                }
            }
        }
        return instance;
    }

    public void createUserLoginSession(String user) {
        editor = sharedPreferences.edit();
        editor.putBoolean(IS_USER_LOGIN, true);
        editor.putString(KEY_USER, user);
        editor.commit();
    }

    public String getUserLogin() {
        return sharedPreferences.getString(KEY_USER, "");
    }


    public void logoutUser() {
        editor = sharedPreferences.edit();
        editor.clear();
        editor.commit();
    }

    public boolean checkLogin() {
        // Check login status
        return !this.isUserLoggedIn();
    }


    public boolean isUserLoggedIn() {
        return sharedPreferences.getBoolean(IS_USER_LOGIN, false);
    }

    public String getUserAddress() {
        if (sharedPreferences.contains(KEY_USER_ADDRESS))
            return sharedPreferences.getString(KEY_USER_ADDRESS, null);
        else return null;
    }


    public void setUserAddress(String user_address) {
        Editor editor = sharedPreferences.edit();
        editor.putString(KEY_USER_ADDRESS, user_address);
        editor.commit();
    }

    public String getCart() {
        if (sharedPreferences.contains("CART"))
            return sharedPreferences.getString("CART", null);
        else return null;
    }


    public void setCart(String cart) {
        Editor editor = sharedPreferences.edit();
        editor.putString("CART", cart);
        editor.commit();
    }

    public void setLicDetails(String lisDetails) {
        Editor editor = sharedPreferences.edit();
        editor.putString("LIC_DETAILS", lisDetails);
        editor.apply();
    }

    public String getLicDetails() {
        if (sharedPreferences.contains("LIC_DETAILS"))
            return sharedPreferences.getString("LIC_DETAILS", null);
        else return null;
    }

    public void setDelStoreInfo(String storeInfo) {
        Editor editor = sharedPreferences.edit();
        editor.putString("STORE", storeInfo);
        editor.apply();
    }

    public String getDelStoreInfo() {
        if (sharedPreferences.contains("STORE"))
            return sharedPreferences.getString("STORE", null);
        else return null;
    }

    public void setStoreList(String storeList) {
        Editor editor = sharedPreferences.edit();
        editor.putString("STORE_LIST", storeList);
        editor.apply();
    }

    public String getStoreList() {
        return sharedPreferences.contains("STORE_LIST") ? sharedPreferences.getString("STORE_LIST", null) : null;
    }

    public void deleteCart() {
        Editor editor = sharedPreferences.edit();
        editor.remove("CART");
        editor.commit();
    }


    public String getOrder() {
        if (sharedPreferences.contains("ORDER"))
            return sharedPreferences.getString("ORDER", null);
        else return null;
    }

    public void setTags(String tags) {
        Editor editor = sharedPreferences.edit();
        editor.putString("TAGS", tags);
        editor.commit();
    }

    public String getTags() {
        if (sharedPreferences.contains("TAGS"))
            return sharedPreferences.getString("TAGS", null);
        else return null;
    }

    public void setOrder(String order) {
        Editor editor = sharedPreferences.edit();
        editor.putString("ORDER", order);
        editor.commit();
    }

    public void deleteOrder() {
        Editor editor = sharedPreferences.edit();
        editor.remove("ORDER");
        editor.commit();
    }
    public void setSelectedStoreInfo(String storeInfo) {
        Editor editor = sharedPreferences.edit();
        editor.putString("STORE_FROM_PICKER", storeInfo);
        editor.apply();
    }

    public String getSelectedStoreInfo() {
        if (sharedPreferences.contains("STORE_FROM_PICKER"))
            return sharedPreferences.getString("STORE_FROM_PICKER", null);
        else return null;
    }

    public String getFirebaseToken() {
        return sharedPreferences.getString(KEY_FIREBASE_TOKEN, null);
    }

    public void setFirebaseToken(String firebaseToken) {
        editor = sharedPreferences.edit();
        editor.putString(KEY_FIREBASE_TOKEN, firebaseToken);
        editor.commit();
    }

    public void setUserRole(String role) {
        Editor editor = sharedPreferences.edit();
        editor.putString("ROLE", role);
        editor.apply();
    }

    public String getUserRole() {
        return sharedPreferences.contains("ROLE") ? sharedPreferences.getString("ROLE", "") : "";
    }

    public void setSelectedAcMobile(String role) {
        Editor editor = sharedPreferences.edit();
        editor.putString(Constant.SELECTED_AC_MOBILE_NUMBER, role);
        editor.apply();
    }
    public String getSelectedAcMobile() {
        return sharedPreferences.contains(Constant.SELECTED_AC_MOBILE_NUMBER) ? sharedPreferences.getString(Constant.SELECTED_AC_MOBILE_NUMBER, "") : "";
    }


}
