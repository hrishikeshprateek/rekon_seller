package com.reckon.reckonorders.Base;
/*
 * Created by Manvendra Kumar Singh on 15/12/2018.
 */

import static com.reckon.reckonorders.Utils.LocalStorage.KEY_USER;

import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.navigation.NavController;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.Profile;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.ResponseFromRegistration;
import com.reckon.reckonorders.NewDesign.NewModals.ThemeColorModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.LoadingDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONObject;

import java.util.ArrayList;

public class BaseActivity extends AppCompatActivity {
    private LoadingDialog mDialogView;
    Gson gson;
    LocalStorage localStorage;
    private ThemeColorModel colorModel;


    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        localStorage = new LocalStorage(getApplicationContext());
        gson = new Gson();
        // getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
    }

    public void clearLocalStorage() {
        localStorage.logoutUser();
    }

    private void addReplaceFragment(BaseFragment fragment, int containerViewId, boolean isReplace, boolean isAddToBackStack) {
        FragmentManager fragmentManager = getSupportFragmentManager();
        if (fragmentManager != null && fragment != null) {
            FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
            fragmentTransaction.setCustomAnimations(R.anim.enter_from_right, R.anim.exit_to_left, R.anim.enter_from_left, R.anim.exit_to_right);
            if (isReplace)
                fragmentTransaction.replace(containerViewId, fragment);
            else {
                Fragment currentFragment = getSupportFragmentManager().findFragmentById(containerViewId);
                if (currentFragment != null) {
                    fragmentTransaction.hide(currentFragment);
                }
                fragmentTransaction.add(containerViewId, fragment, fragment.getClass().getSimpleName());
            }
            if (isAddToBackStack) {
                fragmentTransaction.addToBackStack(fragment.getClass().getSimpleName());
            }
            fragmentTransaction.commit();
        }
    }


    public ArrayList<StoreDetailObjectModel> getStoreListData() {
        return localStorage.getStoreList() != null ? gson.fromJson(localStorage.getStoreList(), new TypeToken<ArrayList<StoreDetailObjectModel>>() {
        }.getType()) : null;
    }

    public Profile getUserProfile(Context context) {
        Profile savedProfile = null;
        ResponseFromRegistration response = gson.fromJson(SharedPrefUtils.getString(context, KEY_USER), ResponseFromRegistration.class);
        if (response != null)
            savedProfile = response.getProfile();
        return savedProfile;
    }
    public String getUserImageBaseUrl(Context context) {
        String url = "";
        ResponseFromRegistration response = gson.fromJson(SharedPrefUtils.getString(context, KEY_USER), ResponseFromRegistration.class);
        if (response != null)
            url = response.getBaseUrl();
        return url;
    }
    /**
     * find root parent of fragment
     */
    public static Fragment getRootParentFragment(Fragment fragment) {
        Fragment parent = fragment.getParentFragment();
        if (parent == null)
            return fragment;
        else
            return getRootParentFragment(parent);
    }

    public void replaceFragment(BaseFragment fragment, int containerViewId, boolean isAddToBackStack) {
        addReplaceFragment(fragment, containerViewId, true, isAddToBackStack);
    }

    public void addFragment(BaseFragment fragment, int containerViewId, boolean isAddToBackStack) {
        addReplaceFragment(fragment, containerViewId, false, isAddToBackStack);
    }

    public void showLoading() {
        if (ReckonUtils.isNetworkAvailable(this))
            if (mDialogView != null) {
                mDialogView.show();
            } else {
                mDialogView = new LoadingDialog(this);
                mDialogView.setCanceledOnTouchOutside(false);
                mDialogView.show();
            }
    }

    public void dismissLoading() {
        if (mDialogView != null) {
            mDialogView.dismiss();
        }
    }

    public void clearAllBackStack() {
        FragmentManager fm = getSupportFragmentManager();
        int count = fm.getBackStackEntryCount();
        for (int i = 0; i < count; ++i) {
            fm.popBackStack();
        }
    }

    public LicDetailObjectModel getLicDetails() {
        TypeToken<LicDetailObjectModel> _type = new TypeToken<LicDetailObjectModel>() {};
        return localStorage.getLicDetails() != null ? gson.fromJson(localStorage.getLicDetails(), _type.getType()) : null;
    }

    public StoreDetailObjectModel parseStoreObj(JSONObject object) {
        StoreDetailObjectModel model = new StoreDetailObjectModel();
        try {
            model.setAdd1(ReckonUtils.getJsonCheckedString(object, "Add1", ""));
            model.setAdd2(ReckonUtils.getJsonCheckedString(object, "Add2", ""));
            model.setAdd3(ReckonUtils.getJsonCheckedString(object, "Add3", ""));
            model.setName(ReckonUtils.getJsonCheckedString(object, "Name", ""));
            model.setMobile(ReckonUtils.getJsonCheckedString(object, "Mobile", ""));
            model.setPinCode(ReckonUtils.getJsonCheckedString(object, "PinCode", ""));
            model.setFirmCode(ReckonUtils.getJsonCheckedString(object, "FirmCode", ""));
            model.setFirstChar(ReckonUtils.getFirstCharFromString(model.getName()));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return model;
    }

    public StoreDetailObjectModel getSelectedStoreDetailsFromPicker() {
        StoreDetailObjectModel model = null;
        if (localStorage.getSelectedStoreInfo() != null) {
            model = gson.fromJson(localStorage.getSelectedStoreInfo(), new TypeToken<StoreDetailObjectModel>() {
            }.getType());
            return model;
        }
        return model;
    }

    public void setHeaderColor(String headerColor, String buttonColor, Boolean lightIcon, String textColor, String secondHeaderColor, String thirdHeaderColor) {
        colorModel = new ThemeColorModel();
        colorModel.setHeaderTextColor(textColor);
        colorModel.setButtonColor(buttonColor);
        colorModel.setLightIcon(lightIcon);
        colorModel.setStatusBarColor(headerColor);///TODO: Add for navigationBarItem Color
        colorModel.setSecondHeaderTextColor(secondHeaderColor);
        colorModel.setThirdHeaderTextColor(thirdHeaderColor);
    }

    public int getStatusBarColorOfApp() {
        return Color.parseColor(colorModel.getStatusBarColor());
    }

    public int getButtonColor() {
        return Color.parseColor(colorModel.getButtonColor());
    }

    public int getHeaderTextColor() {
        return Color.parseColor(colorModel.getHeaderTextColor());
    }

    public int getSecondHeaderTextColor() {
        return Color.parseColor(colorModel.getSecondHeaderTextColor());
    }

    public int getThirdHeaderColor() {
        return Color.parseColor(colorModel.getThirdHeaderTextColor());
    }

    public boolean isLightIcon() {
        return colorModel.isLightIcon();
    }

    public void orderEntryClickHandling(View v, String constant, Bundle bundle, NavController navController) {
        if (getLicDetails().getRole().equalsIgnoreCase("SalesMan")) {
            if (constant.equalsIgnoreCase(Constant.NEW_ORDER)) {
//                ArrayList<StoreDetailObjectModel> storeListData = getStoreListData();
                navigateToPartyFragmentListing(navController, constant, bundle);
            } else if (constant.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || constant.equalsIgnoreCase(Constant.OUTSTANDING) || constant.equalsIgnoreCase(Constant.BRAND_LIST)) {
                navigateToPartyFragmentListing(navController, constant, bundle);
            }

      /*      if (storeListData.size() == 1) {
                ///TODO: Send for selecting party/account/customer from the party list
                navigateToPartyFragmentListing(v, Constant.NEW_ORDER);
            } else if (storeListData.size() > 1) {
                ///TODO: Send for selecting Store/Firm
                navigateToPartyFragmentListing(v, Constant.FIRM);
            }*/
        } else {
            if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
                bundle.putString(Constant.FROM, constant);
                navController.navigate(R.id.nav_common_listing, bundle);
            } else if (constant.equalsIgnoreCase(Constant.BRAND_LIST)) {
                navController.navigate(R.id.action_brand_item_to_new_order_list, bundle);
            } else {
                navController.navigate(R.id.action_nav_home_to_menu_newOrder2, bundle);
            }
        }
    }


    private void navigateToPartyFragmentListing(NavController v, String page, Bundle mBundle) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, page);
        bundle.putString("BrandItemId", mBundle.containsKey("BrandItemId") ? mBundle.getString("BrandItemId") : "");
        bundle.putString("isNewArrival", mBundle.containsKey("isNewArrival") ? mBundle.getString("isNewArrival") : "");
        bundle.putString("withScheme", mBundle.containsKey("withScheme") ? mBundle.getString("withScheme") : "");
        v.navigate(R.id.navPartyLisingFragment, bundle);
    }

    public boolean isGooglePlayServicesAvailable(Activity activity) {
        GoogleApiAvailability googleApiAvailability = GoogleApiAvailability.getInstance();
        int status = googleApiAvailability.isGooglePlayServicesAvailable(activity);
        if(status != ConnectionResult.SUCCESS) {
            if(googleApiAvailability.isUserResolvableError(status)) {
                googleApiAvailability.getErrorDialog(activity, status, 2404).show();
            }
            return false;
        }
        return true;
    }
}
