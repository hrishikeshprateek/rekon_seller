package com.reckon.reckonorders.Activity;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.annotation.SuppressLint;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.provider.Settings;
import android.util.Log;
import android.widget.ImageView;
import android.widget.Toast;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.gson.Gson;
import com.reckon.reckonorders.Base.BaseActivity;
import com.reckon.reckonorders.BuildConfig;
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.Utils.StartActivityUtils;
import com.reckon.reckonorders.databinding.ActivitySplashBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Objects;


/**
 * Created by Manvendra Kumar Singh on 15/12/2018.
 */

public class Splash extends BaseActivity implements RetrofitCallBackListener {
    RetrofitCallBackListener retrofitCallBackListener = this;
    ActivitySplashBinding binding;

    LocalStorage localStorage;
    Gson gson;
    private String androidId;

    @SuppressLint("HardwareIds")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySplashBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        localStorage = new LocalStorage(getApplicationContext());
        retrofitCallBackListener = this;
        binding.splashImg.setImageDrawable(ReckonUtils.getSplashImageDrawable(Splash.this, BuildConfig.APPLICATION_ID));
        binding.splashImg.setScaleType(Objects.equals(getPackageName(), Constant.APP_ID_NEED_INSIGHT_RETAILER) || Objects.equals(getPackageName(), Constant.APP_ID_NEED_INSIGHT_SALESMAN)? ImageView.ScaleType.CENTER_INSIDE: ImageView.ScaleType.CENTER_CROP);
        setPackageManagerInfo();
        SharedPrefUtils.setString(this, Constant.DEVICE_ID, Settings.Secure.getString(this.getContentResolver(), Settings.Secure.ANDROID_ID));
        gson = new Gson();
        ReckonUtils.setBaseUrl(this);
        if (getPackageName().equalsIgnoreCase("com.reckon.unagretailers") || getPackageName().equalsIgnoreCase("com.reckon.unagsalesman")) {
            setHeaderColor("#3D5F7C", "#3D5F7C", false, "#ffffff", "#1E5FA6", "#3D5F7C");
        } else if (getPackageName().equalsIgnoreCase("com.reckon.sarvahithaayurvedalaya")) {
            setHeaderColor("#85a03c", "#85a03c", false, "#ffffff", "#1f6643", "#85a03c");
        } else if (getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
            setHeaderColor("#EA7B7E", "#EA7B7E", false, "#ffffff", "#EA7B7E", "#EA7B7E");
        }else if (getPackageName().equalsIgnoreCase("com.reckon.amareorder") || getPackageName().equalsIgnoreCase("com.reckon.amareretail")) {
            setHeaderColor("#0097b2", "#0097b2", false, "#ffffff", "#1E5FA6", "#0097b2");
        } else {
            setHeaderColor("#13A2DF", "#13A2DF", false, "#ffffff", "#1E5FA6", "#13A2DF");
        }
        try {//SalesMan //Retailer
            String role = BuildConfig.APPLICATION_ID.equalsIgnoreCase("com.reckon.reckonorders") ? Constant.SALESMAN : BuildConfig.APPLICATION_ID.contains(Constant.SALESMAN.toLowerCase()) ? Constant.SALESMAN : Constant.RETAILER;
            SharedPrefUtils.setString(Splash.this, Constant.ROLE, role);
            String _userRole = SharedPrefUtils.getString(Splash.this, Constant.ROLE);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", getApplicationContext().getPackageName());
            jsonObject.put("app_role", _userRole);
            jsonObject.put("device_id", SharedPrefUtils.getString(this, Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(this, Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(this));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(this));
            jsonObject.put("lRole", _userRole);
            new ConnectToRetrofit(retrofitCallBackListener, this, getApiClientByPost().generalSetting(String.valueOf(jsonObject)), Constant.GENERAL_SETTING, false);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void sendFCMToServer(String token) {
        try {
            androidId = Settings.Secure.getString(this.getContentResolver(), Settings.Secure.ANDROID_ID);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", getPackageName());
            jsonObject.put("USERID", SharedPrefUtils.getString(this, Constant.USER_ID));
            jsonObject.put("FCMID", token);
            jsonObject.put("DID", androidId);
            jsonObject.put("device_id", SharedPrefUtils.getString(this, Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(this, Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(this));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(this));
            new ConnectToRetrofit(retrofitCallBackListener, this, getApiClientByPost().sendFCM(String.valueOf(jsonObject)), Constant.PUSH_NOTIFICATION, false);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void fetchFCMToken() {
        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(task -> {
            if (!task.isSuccessful()) {
                Log.w("FCM", "Fetching FCM registration token failed", task.getException());
                return;
            }
            FirebaseMessaging.getInstance().subscribeToTopic("global");
            // Get new FCM registration token
            // Log and toast
            try {
                String token = task.getResult();
                localStorage.setFirebaseToken(token);
                // Log and toast
                Log.d("FCM", token);
                sendFCMToServer(token);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        try {
            if (result != null && action.equalsIgnoreCase(Constant.GENERAL_SETTING)) {
                JSONObject jsonObject = new JSONObject(result);
                SharedPrefUtils.setShowFlexibleUpdate(this, ReckonUtils.getJsonCheckedBoolean(jsonObject, "show_flexible_update", false));
                SharedPrefUtils.setLiveAppVersion(this, Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "live_app_version", "0")));
                SharedPrefUtils.setList(this, Constant.BUSINESS_TYPE_LIST, jsonObject.getJSONArray("Business") != null ? jsonObject.getJSONArray("Business") : new JSONArray());
                SharedPrefUtils.setList(this, Constant.COUNTRY_LIST, jsonObject.getJSONArray("Country") != null ? jsonObject.getJSONArray("Country") : new JSONArray());
                SharedPrefUtils.setList(this, Constant.SearchType, jsonObject.getJSONArray("SearchType") != null ? jsonObject.getJSONArray("SearchType") : new JSONArray());
                SharedPrefUtils.setList(this, Constant.HelpField, jsonObject.getJSONArray("HelpField") != null ? jsonObject.getJSONArray("HelpField") : new JSONArray());
                SharedPrefUtils.setList(this, Constant.ImageList, new JSONArray());
                SharedPrefUtils.setList(this, Constant.ImageList, jsonObject.getJSONArray("ImageList") != null ? jsonObject.getJSONArray("ImageList") : new JSONArray());
                SharedPrefUtils.setList(this, Constant.LoginType, jsonObject.getJSONArray("LoginType") != null ? jsonObject.getJSONArray("LoginType") : new JSONArray());
                SharedPrefUtils.setList(this, Constant.TIME_SLOT, jsonObject.getJSONArray("TimeSlot") != null ? jsonObject.getJSONArray("TimeSlot") : new JSONArray());
                //         Glide.with(this).load(jsonObject.has("Splash")?jsonObject.getString("Splash"):"").apply(RequestOptions.placeholderOf(R.mipmap.splash_bg)).into(binding.splashImg);
                if (jsonObject.has("LicDetail")) {
                    JSONObject object = jsonObject.getJSONObject("LicDetail");
                    LicDetailObjectModel model = new LicDetailObjectModel();
                    model.setBg_color(ReckonUtils.getJsonCheckedString(object, "bg_color", ""));
                    model.setRole(ReckonUtils.getJsonCheckedString(object, "role", "Retailer"));
                    model.setLicno(getLicDetails() != null && getLicDetails().getLicno() != null && !getLicDetails().getLicno().isEmpty() ? getLicDetails().getLicno() : ReckonUtils.getJsonCheckedString(object, "licno", ""));
                    model.setDlcount(ReckonUtils.getJsonCheckedString(object, "dlcount", "1"));
                    model.setDlcount2(ReckonUtils.getJsonCheckedString(object, "dlcount2", "1"));
                    model.setFlcount(ReckonUtils.getJsonCheckedString(object, "flcount", "1"));
                    model.setGstcount(ReckonUtils.getJsonCheckedString(object, "gstcount", "1"));
                    model.setFirmcode(ReckonUtils.getJsonCheckedString(object, "firmcode", ""));
                    String currency = ReckonUtils.getJsonCheckedString(object, "currency", "₹");
                    model.setCurrency(!currency.isEmpty() ? currency : "₹");
                    model.setRegsmscustomer(ReckonUtils.getJsonCheckedString(object, "regsmscustomer", ""));
                    model.setRegsmsfirm(ReckonUtils.getJsonCheckedString(object, "regsmsfirm", ""));
                    model.setRetailerType(ReckonUtils.getJsonCheckedString(object, "retailer_type", ""));
                    model.setHasAddQtyOptions(ReckonUtils.getJsonCheckedBoolean(object, "has_add_qty_options", true));
                    localStorage.setLicDetails(gson.toJson(model));
                }
                if (jsonObject.has("Store") && jsonObject.getJSONObject("Store").length() > 0) {
                    localStorage.setDelStoreInfo(gson.toJson(parseStoreObj(jsonObject.getJSONObject("Store"))));
                }
                gotoNextActivity();
                fetchFCMToken();
            }else if(result != null && action.equalsIgnoreCase(Constant.PUSH_NOTIFICATION)){
            }else{
                Toast.makeText(this, getString(R.string.something_went_wrong), Toast.LENGTH_SHORT).show();
//                gotoNextActivity();
            }
        } catch (Exception e) {
            e.printStackTrace();
//            gotoNextActivity();
            Toast.makeText(this, getString(R.string.something_went_wrong), Toast.LENGTH_SHORT).show();
            fetchFCMToken();
        }
    }
private void gotoNextActivity() {
    new Handler().postDelayed(() -> {
        String activate = SharedPrefUtils.getString(Splash.this, Constant.ACTIVATE);
        if (!activate.isEmpty()) {
            StartActivityUtils.toHome(Splash.this, "");
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
            finish();
        } else {
            StartActivityUtils.toAccount(Splash.this);
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        }
    }, 3000);
}
    private void setPackageManagerInfo() {
        try {
            PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            String versionName = pInfo.versionName;
            int versionCode = pInfo.versionCode;
            SharedPrefUtils.setVersionCode(this, (int) getLongVersionCode(pInfo));
            SharedPrefUtils.setVersionName(this, versionName);
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
    }

    private long getLongVersionCode(PackageInfo pInfo) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return pInfo.getLongVersionCode();
        } else {
            return pInfo.versionCode;
        }
    }
}
