package com.reckon.reckonorders.Utils;
/*
 * Created by Manvendra Kumar Singh on 22/12/2018.
 */

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.Others.Constant.Constant;

import org.json.JSONArray;

import java.util.ArrayList;
import java.util.Set;

public class SharedPrefUtils {


    public static String getString(Context context, String key) {
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(context);
        return preferences.getString(key, "");
    }

    public static void setString(Context context, String key, String content) {
        SharedPreferences.Editor edit = PreferenceManager.getDefaultSharedPreferences(context).edit();
        edit.putString(key, content);
        edit.apply();
    }

    public static String getList(Context context, String key) {
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(context);
        return preferences.getString(key, "");
    }

    public static void setList(Context context, String key, JSONArray content) {
        SharedPreferences.Editor edit = PreferenceManager.getDefaultSharedPreferences(context).edit();
        edit.putString(key, content.toString());
        edit.apply();
    }

    public static void setList(Context context, String key, ArrayList content) {
        SharedPreferences.Editor edit = PreferenceManager.getDefaultSharedPreferences(context).edit();
        edit.putString(key, content.toString());
        edit.apply();
    }
    public static void setHash(Context context, String key, Set set){
        SharedPreferences.Editor edit= PreferenceManager.getDefaultSharedPreferences(context).edit();
        edit.putStringSet(key,set);
        edit.apply();
    }
    public static Set getHash(Context context,String key)
    {
        SharedPreferences preferences=PreferenceManager.getDefaultSharedPreferences(context);
        return preferences.getStringSet(key,null);
    }

    public static int getInt(Context context, String key) {
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(context);
        return preferences.getInt(key, 0);
    }

    public static void setInt(Context context, String key, int content) {
        SharedPreferences.Editor edit = PreferenceManager.getDefaultSharedPreferences(context).edit();
        edit.putInt(key, content);
        edit.apply();
    }

    public static boolean getBoolean(Context context, String key) {
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(context);
        return preferences.getBoolean(key, false);
    }

    public static void setBoolean(Context context, String key, Boolean content) {
        SharedPreferences.Editor edit = PreferenceManager.getDefaultSharedPreferences(context).edit();
        edit.putBoolean(key, content);
        edit.apply();
    }


    public static void saveLoginNormal(Context context, String mobile, String password) {
        setString(context, Constant.TYPE_LOGIN, Constant.LOGIN_NORMAL);
        setString(context, Constant.EMAIL, mobile);
        setString(context, Constant.PASSWORD, password);
    }


    public static void removeLogout(Context context) {
        setString(context, Constant.ACTIVATE, "");
        setList(context, Constant.USER_DATA_LIST, new ArrayList<>());
        setString(context, Constant.TYPE_LOGIN, "");
        setString(context, Constant.COUNTRY_CODE, "");
        setString(context, Constant.SEARCHED_KEY, "");
        setString(context, Constant.HELP_KEY, "");
        setString(context, Constant.HELP_Name, "");
        setString(context, Constant.ShowBarcode, "");
        setString(context, Constant.ShowBrand, "");
        setBoolean(context, Constant.ShowIGroup, false);
        setString(context, Constant.ShowPack, "");
        setString(context, Constant.ShowRefNo, "");
        setBoolean(context, Constant.ShowSalt, false);
        setString(context, Constant.SearchTypeID, "");
        setString(context, Constant.StartWithSearchFieldValue, "");
        setString(context, Constant.ItemHelpIndex, "");
    }



    public static void setShowIncreaseDecreaseBtn(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_INCREASE_DECREASE_BUTTON, value);
        editor.apply();
    }
    public static boolean getShowIncreaseDecreaseBtn(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_INCREASE_DECREASE_BUTTON, true);
    }

    public static void setShowDiscountPcs(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_DISCOUNT_PCS, value);
        editor.apply();
    }
    public static boolean getShowDiscountPcs(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_DISCOUNT_PCS, true);
    }

    public static void setShowFreeQty(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_FREE_QTY, value);
        editor.apply();
    }
    public static boolean getShowFreeQty(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_FREE_QTY, true);
    }

    public static void setShowStock(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_STOCK, value);
        editor.apply();
    }
    public static boolean getShowStock(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_STOCK, true);
    }

    public static void setShowRate(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_RATE, value);
        editor.apply();
    }
    public static boolean getShowRate(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_RATE, true);
    }

    public static void setShowDiscountPer(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_DISCOUNT_PER, value);
        editor.apply();
    }
    public static boolean getShowDiscountPer(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_DISCOUNT_PER, true);
    }

    public static void setShowMRP(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_MRP, value);
        editor.apply();
    }
    public static boolean getShowMRP(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_MRP, true);
    }

    public static void setShowScheme(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_SCHEME, value);
        editor.apply();
    }
    public static boolean getShowScheme(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_SCHEME, true);
    }

    public static void setShowEnablePriceEdt(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.ENABLE_PRICE_EDT, value);
        editor.apply();
    }
    public static boolean getShowEnablePriceEdt(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.ENABLE_PRICE_EDT, true);
    }

    public static void setShowItemRemark(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_ITEM_REMARK, value);
        editor.apply();
    }
    public static boolean getShowItemRemark(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_ITEM_REMARK, true);
    }
    public static void setShowProductDiscount(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_PRODUCT_DISCOUNT, value);
        editor.apply();
    }
    public static boolean getShowProductDiscount(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_PRODUCT_DISCOUNT, true);
    }

    public static void setShowManualScheme(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_MANUAL_SCHEME, value);
        editor.apply();
    }
    public static boolean getShowManualScheme(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_MANUAL_SCHEME, true);
    }

    public static void setShowAddDetailsBottomSheet(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_ADD_DETAILS_BOTTOM_SHEET, value);
        editor.apply();
    }
    public static boolean getShowAddDetailsBottomSheet(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_ADD_DETAILS_BOTTOM_SHEET, true);
    }

    public static void setShowAddDiscountPer(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_ADD_DISCOUNT_PER, value);
        editor.apply();
    }
    public static boolean getShowAddDiscountPer(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_ADD_DISCOUNT_PER, true);
    }

    public static void setShowItemRefNo(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_ITEM_REF_NO, value);
        editor.apply();
    }
    public static boolean getShowItemRefNo(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_ITEM_REF_NO, true);
    }

    public static void setSearchFilterList(Activity activity, String value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putString(Constant.SEARCH_FILTER_LIST, value);
        editor.apply();
    }
    public static ArrayList<StoreDetailObjectModel> getSearchFilterList(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getString(Constant.SEARCH_FILTER_LIST, null) != null ? new Gson().fromJson(sharedPref.getString(Constant.SEARCH_FILTER_LIST, null), new TypeToken<ArrayList<StoreDetailObjectModel>>() {
        }.getType()) : null;
    }

    public static void setVersionCode(Activity activity, int value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putInt(Constant.V_CODE, value);
        editor.apply();
    }
    public static int getVersionCode(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getInt(Constant.V_CODE, 0);
    }
    public static void setVersionName(Activity activity, String value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putString(Constant.V_NAME, value);
        editor.apply();
    }
    public static String getVersionName(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getString(Constant.V_NAME, "");
    }

    public static void setShowSaltComp(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_SALT_COMP, value);
        editor.apply();
    }
    public static boolean getShowSaltComp(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_SALT_COMP, false);
    }


    public static void setShowICompany(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_COMPANY, value);
        editor.apply();
    }
    public static boolean getShowICompany(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_COMPANY, false);
    }

    public static void setShowLocation(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_LOCATION, value);
        editor.apply();
    }
    public static boolean getShowLocation(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_LOCATION, false);
    }

    public static void setShowItemCategory(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_ITEM_CATEGORY, value);
        editor.apply();
    }
    public static boolean getShowItemCategory(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_ITEM_CATEGORY, false);
    }

    public static void setShowFlexibleUpdate(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.SHOW_FLEXIBLE_UPDATE, value);
        editor.apply();
    }
    public static boolean getShowFlexibleUpdate(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.SHOW_FLEXIBLE_UPDATE, false);
    }

    public static void setLiveAppVersion(Activity activity, int value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putInt(Constant.LIVE_APP_VERSION, value);
        editor.apply();
    }
    public static int getLiveAppVersion(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getInt(Constant.LIVE_APP_VERSION, 0);
    }

    public static void setEnableScreenshot(Activity activity, boolean value) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putBoolean(Constant.ENABLE_SCREENSHOT, value);
        editor.apply();
    }
    public static boolean getEnableScreenshot(Activity activity) {
        SharedPreferences sharedPref = activity.getPreferences(Context.MODE_PRIVATE);
        return sharedPref.getBoolean(Constant.ENABLE_SCREENSHOT, false);
    }
}
