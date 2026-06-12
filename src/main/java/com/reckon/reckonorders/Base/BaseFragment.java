package com.reckon.reckonorders.Base;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Utils.LocalStorage.KEY_USER;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.navigation.Navigation;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Activity.AccountActivity;
import com.reckon.reckonorders.Activity.MainActivity;
import com.reckon.reckonorders.Model.ImageModel;
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.Model.StatementsModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.Profile;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.ResponseFromRegistration;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

/*
 * Created by Manvendra Kumar Singh on 15/12/2018.
 */

public abstract class BaseFragment extends Fragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    public int totalCount = 0;
    public LocalStorage localStorage;
    public Gson gson;
//    boolean isKeyboardShowing = false;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        retrofitCallBackListener = this;
        localStorage = new LocalStorage(requireActivity());
        gson = new Gson();
    }

    @Override
    public void onViewCreated(View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        view.setOnTouchListener((v, event) -> {
            hideKeyboard(requireActivity());
            return false;
        });
    }

    public void setupHomeButton(View view) {
        ImageView imgHome = view.findViewById(R.id.actionbar_imgBack);
        imgHome.setOnClickListener(onHomeClick);
    }

    public void setupRefreshButton(View v) {
        View view = v.findViewById(R.id.actionbar_imgRefresh);
        if (view != null) {
            view.setOnClickListener(onRefreshClick);
        }
    }

    View.OnClickListener onHomeClick = view -> {
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).setCurrentTab(0);
    };

    public void setupBackButton(View v) {
        View view = v.findViewById(R.id.actionbar_imgBack);
        if (view != null) {
            view.setOnClickListener(onBackClick);
        }
    }

    /*   public void onKeyboardVisibilityChanged(boolean opened) {
           if (!isSalesMan)
               totalOrderValueCard.setVisibility(opened ? View.GONE : View.VISIBLE);
       }*/
/*    public void setUpKeyBoardListener(View v) {
        // ContentView is the root view of the layout of this activity/fragment
        if(v!=null)
            v.getViewTreeObserver().addOnGlobalLayoutListener(
                    () -> {
                        Rect r = new Rect();
                        v.getWindowVisibleDisplayFrame(r);
                        int screenHeight = v.getRootView().getHeight();
                        // r.bottom is the position above soft keypad or device button.
                        // if keypad is shown, the r.bottom is smaller than that before.
                        int keypadHeight = screenHeight - r.bottom;
                        if (keypadHeight > screenHeight * 0.15) { // 0.15 ratio is perhaps enough to determine keypad height.
                            // keyboard is opened
                            if (!isKeyboardShowing) {
                                isKeyboardShowing = true;
//                                onKeyboardVisibilityChanged(true);
                            }
                        }
                        else {
                            // keyboard is closed
                            if (isKeyboardShowing) {
                                isKeyboardShowing = false;
//                                onKeyboardVisibilityChanged(false);
                            }
                        }
                    });
    }*/
    public void setTitle(View v, String title) {
        TextView view = v.findViewById(R.id.actionbar_tvTitle);
        if (view != null) {
            view.setText(title);
        }
    }

    View.OnClickListener onBackClick = view -> {
        FragmentManager fm = getFragmentManager();
        if (getActivity() instanceof AccountActivity && fm.getBackStackEntryCount() > 0) {
            fm.popBackStack();
        } else {
            getActivity().onBackPressed();
        }
    };
    View.OnClickListener onRefreshClick = new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            try{
                JSONObject jsonObject = new JSONObject();
                jsonObject.put("lApkName", requireActivity().getPackageName());
                jsonObject.put("app_role", SharedPrefUtils.getString(getActivity(), Constant.ROLE));
                jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
                jsonObject.put("device_name", ReckonUtils.getDeviceName());
                jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
                jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
                jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
                new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().generalSetting(String.valueOf(jsonObject)), Constant.GENERAL_SETTING, true);
            }catch (Exception e){
                e.printStackTrace();
            }
        }
    };

    public void clearAllBackStack() {
        if (getActivity() instanceof BaseActivity) {
            ((BaseActivity) getActivity()).clearAllBackStack();
        }
    }

    public void replaceFragment(BaseFragment fragment, int containerViewId, boolean isAddToBackStack) {

        if (getActivity() instanceof BaseActivity) {
            ((BaseActivity) getActivity()).replaceFragment(fragment, containerViewId, isAddToBackStack);
        }
    }

    public void replaceFragment(BaseFragment fragment, boolean isAddToBackStack) {
        if (getActivity() instanceof BaseActivity) {
            if (getActivity() instanceof AccountActivity)
                ((BaseActivity) getActivity()).replaceFragment(fragment, R.id.activityAccount_fmContainer, isAddToBackStack);
            else if (getActivity() instanceof MainActivity)
                ((BaseActivity) getActivity()).addFragment(fragment, android.R.id.tabcontent, isAddToBackStack);
        }
    }

    public void addFragment(BaseFragment fragment, boolean isAddToBackStack) {
        if (getActivity() instanceof BaseActivity) {
            if (getActivity() instanceof AccountActivity)
                ((BaseActivity) getActivity()).addFragment(fragment, R.id.activityAccount_fmContainer, isAddToBackStack);
            else if (getActivity() instanceof MainActivity)
                ((BaseActivity) getActivity()).addFragment(fragment, android.R.id.tabcontent, isAddToBackStack);
            else if (getActivity() instanceof NewMainActivity)
                ((BaseActivity) getActivity()).addFragment(fragment, R.id.nav_host_fragment_content_new_main, isAddToBackStack);
        }
    }


    public void showLoading() {
        if (getActivity() instanceof BaseActivity) {
            ((BaseActivity) getActivity()).showLoading();
        }
    }

    public void dismissLoading() {
        if (getActivity() instanceof BaseActivity) {
            ((BaseActivity) getActivity()).dismissLoading();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        JSONObject jsonObject = new JSONObject(result);
        if (action.equalsIgnoreCase(Constant.GENERAL_SETTING)) {
            SharedPrefUtils.setList(getActivity(), Constant.BUSINESS_TYPE_LIST, jsonObject.getJSONArray("Business") != null ? jsonObject.getJSONArray("Business") : new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.COUNTRY_LIST, jsonObject.getJSONArray("Country") != null ? jsonObject.getJSONArray("Country") : new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.SearchType, jsonObject.getJSONArray("SearchType") != null ? jsonObject.getJSONArray("SearchType") : new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.HelpField, jsonObject.getJSONArray("HelpField") != null ? jsonObject.getJSONArray("HelpField") : new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.ImageList, jsonObject.getJSONArray("ImageList") != null ? jsonObject.getJSONArray("ImageList") : new JSONArray());

        }

    }

    public ArrayList<ProductModel> getParsedProductList(JSONArray jsonArray, String action) {
        ArrayList<ProductModel> product_list = new ArrayList();
        try {
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                product_list.add(parseProductJson(jsonObject, action));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return product_list;

    }

    public ProductModel parseProductJson(JSONObject jsonObject, String action) {
        ProductModel productModel = new ProductModel();
        try {
            productModel.setProductName(ReckonUtils.getJsonCheckedString(jsonObject, "Name", "").trim());
            productModel.setDescription(ReckonUtils.getJsonCheckedString(jsonObject, "Description", ""));

            productModel.setProductMfgComp(ReckonUtils.getJsonCheckedString(jsonObject, "MfgComp", ""));
            productModel.setProductRefNumber(ReckonUtils.getJsonCheckedString(jsonObject, "RefNumber", "N/A"));
            productModel.setProductStockType(ReckonUtils.getJsonCheckedString(jsonObject, "StockType", ""));
            productModel.setProductMrp(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(jsonObject, "Mrp", "0.0"))));
            productModel.setProductRate(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(jsonObject, "Rate", "0.0"))));
            productModel.setProductpacking(ReckonUtils.getJsonCheckedString(jsonObject, "packing", ""));
            productModel.setProductCode(ReckonUtils.getJsonCheckedString(jsonObject, "Code", ""));
            productModel.setProductbarcode(ReckonUtils.getJsonCheckedString(jsonObject, "barcode", ""));
            productModel.setProductPRate(ReckonUtils.getJsonCheckedString(jsonObject, "PRate", ""));
            productModel.setProductStock(ReckonUtils.getJsonCheckedString(jsonObject, "Stock", ""));
            productModel.setProductIGroup(ReckonUtils.getJsonCheckedString(jsonObject, "IGroup", ""));
            productModel.setImageUrl(getUserImageBaseUrl() + ReckonUtils.getJsonCheckedString(jsonObject, "ImageUrl", ""));
            productModel.setSCName(ReckonUtils.getJsonCheckedString(jsonObject, "SCName", ""));
            productModel.setRemark(ReckonUtils.getJsonCheckedString(jsonObject, "Remark", ""));
            productModel.setTax(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(jsonObject, "Tax", "0"))));
            productModel.setProductRateA(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(jsonObject, "RateA", "0.0"))));
            productModel.setSchemeAmt(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(jsonObject, "ItemSchAmt", "0.0"))));
            String salt = ReckonUtils.getJsonCheckedString(jsonObject, "Salt", "");
            productModel.setProductSalt(salt.replace(".", ""));
            String SchQty = ReckonUtils.getJsonCheckedString(jsonObject, "SchQty", "");
            String DSchQty = ReckonUtils.getJsonCheckedString(jsonObject, "DSchQty", "");
            productModel.setSchQty(SchQty);
            productModel.setDSchQty(DSchQty);

            productModel.setScheme(ReckonUtils.getJsonCheckedString(jsonObject, "SchNarr", ""));
            productModel.setIsSchemeSelected("N");
            productModel.setProductIdCol(Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "IDCOL", "0")));
            if (action.equalsIgnoreCase(Constant.PRODUCT))
                totalCount = Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "RCount", "0"));
            productModel.setShowBarcode(SharedPrefUtils.getString(getActivity(), Constant.ShowBarcode));
            productModel.setShowBrand(SharedPrefUtils.getString(getActivity(), Constant.ShowBrand));
            productModel.setShowIGroup(SharedPrefUtils.getBoolean(getActivity(), Constant.ShowIGroup));
            productModel.setShowPack(SharedPrefUtils.getString(getActivity(), Constant.ShowPack));
            productModel.setShowRefNo(SharedPrefUtils.getString(getActivity(), Constant.ShowRefNo));
            productModel.setShowSalt(SharedPrefUtils.getBoolean(getActivity(), Constant.ShowSalt));
            productModel.setQuantityList(jsonObject.has("QtyList") ? jsonObject.getJSONArray("QtyList") : new JSONArray());
            productModel.setStockExist(ReckonUtils.getJsonCheckedBoolean(jsonObject, "IsStockExist", false));
            productModel.setInvoiceQty(ReckonUtils.getJsonCheckedString(jsonObject, "InvQty", "0"));
            productModel.setBalanceQty(ReckonUtils.getJsonCheckedString(jsonObject, "BalQty", "0"));
            if (jsonObject.has("FirmDetail")) {
                JSONObject objFirm = jsonObject.getJSONObject("FirmDetail");
                productModel.setDistributor(ReckonUtils.getJsonCheckedString(objFirm, "Distributor", ""));
                productModel.setRating(Double.parseDouble(ReckonUtils.getJsonCheckedString(objFirm, "Rating", "0")));
                productModel.setFCode(ReckonUtils.getJsonCheckedString(objFirm, "FCode", ""));
                productModel.setFLicNo(ReckonUtils.getJsonCheckedString(objFirm, "FLicNo", ""));
                productModel.setIsStockistActive(Integer.parseInt(ReckonUtils.getJsonCheckedString(objFirm, "Active", "0")));
                productModel.setActiveText(ReckonUtils.getJsonCheckedString(objFirm, "ActiveText", "0"));
                productModel.setAcCode(ReckonUtils.getJsonCheckedString(objFirm, "AcCode", ""));
            }
            productModel.setNumberOfOrder(ReckonUtils.getJsonCheckedString(jsonObject, "No", ""));
            productModel.setQtyOrdered(ReckonUtils.getJsonCheckedString(jsonObject, "Qty", "0"));
            productModel.setDaysAgoOrder(ReckonUtils.getJsonCheckedString(jsonObject, "Days", ""));

            productModel.setShowMrp(ReckonUtils.getJsonCheckedBoolean(jsonObject, "ShowMrp", false));
            productModel.setShowRate(ReckonUtils.getJsonCheckedBoolean(jsonObject, "ShowRate", false));
            productModel.setShowScheme(ReckonUtils.getJsonCheckedBoolean(jsonObject, "ShowScheme", false));
            productModel.setShowStock(ReckonUtils.getJsonCheckedBoolean(jsonObject, "ShowStock", false));
            productModel.setRefNumber(ReckonUtils.getJsonCheckedString(jsonObject, "RefNumber", ""));
            if (jsonObject.has("Cart")) {
                JSONObject addedCartInfoObj = jsonObject.getJSONObject("Cart");
                productModel.setProductDQty(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "DQty", "0"));
                productModel.setProductCount(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "DQty", "0"));
                productModel.setFQty(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "FQty", "0"));
                productModel.setDFQTYCart(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "DFQTY", "0"));
                productModel.setAmt(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "Amt", "0"))));
                productModel.setDiscAmtCart(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "DiscAmt", "0"))));
                productModel.setDisc1AmtCart(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "Disc1Amt", "0"))));
                productModel.setDisc2AmtCart(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "Disc2Amt", "0"))));
                productModel.setTotalDiscCart(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "totalDisc", "0"))));
                productModel.setDisc1PerCart(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "Disc1Per", ""));
                productModel.setDisc2PerCart(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "Disc2Per", ""));
                productModel.setNetAmtCart(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "NetAmt", ""));
                productModel.setTaxAmtCart(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "TaxAmt", ""));
                productModel.setItemSchAmtCart(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "ItemSchAmt", ""));
                productModel.setDiscPerCart(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "DiscPer", ""));
                productModel.setDoRemarkCart(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "DoRemark", ""));

                productModel.setSchQty(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "SchQty", ""));
                productModel.setDSchQty(ReckonUtils.getJsonCheckedString(addedCartInfoObj, "DSchQty", ""));
            } else {
                productModel.setProductCount(ReckonUtils.getJsonCheckedString(jsonObject, "DQty", "0"));
                productModel.setProductDQty(ReckonUtils.getJsonCheckedString(jsonObject, "DQty", "0"));
                productModel.setAmt(String.valueOf(Float.parseFloat(ReckonUtils.getJsonCheckedString(jsonObject, "Amt", "0"))));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return productModel;
    }

    public ArrayList<StatementsModel> parseStatementItemsJson(JSONObject object, String action) {
        ArrayList<StatementsModel> arrayList = new ArrayList<>();
        try {
            JSONArray jsonArray = object.getJSONArray("items");
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject object1 = jsonArray.getJSONObject(i);
                StatementsModel model = new StatementsModel();
                model.setTitle(ReckonUtils.getJsonCheckedString(object1, "title", ""));
                model.setValue(ReckonUtils.getJsonCheckedString(object1, "value", ""));
                model.setValueTextSize(ReckonUtils.getJsonCheckedString(object1, "value_text_size", ""));
                model.setTitleColor(ReckonUtils.getJsonCheckedString(object1, "title_color", ""));
                model.setValueColor(ReckonUtils.getJsonCheckedString(object1, "value_color", ""));
                model.setTitleTextSize(ReckonUtils.getJsonCheckedString(object1, "title_text_size", ""));
                arrayList.add(model);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return arrayList;
    }

    public StoreDetailObjectModel getStoreDetails() {
        StoreDetailObjectModel model = null;
        if (localStorage.getDelStoreInfo() != null) {
            model = gson.fromJson(localStorage.getDelStoreInfo(), new TypeToken<StoreDetailObjectModel>() {
            }.getType());
            return model;
        }
        return null;
    }

    public Profile getUserProfile() {
        Profile savedProfile = null;
        ResponseFromRegistration response = gson.fromJson(SharedPrefUtils.getString(getActivity(), KEY_USER), ResponseFromRegistration.class);
        if (response != null)
            savedProfile = response.getProfile();
        return savedProfile;
    }

    public String getUserImageBaseUrl() {
        String url = "";
        ResponseFromRegistration response = gson.fromJson(SharedPrefUtils.getString(getActivity(), KEY_USER), ResponseFromRegistration.class);
        if (response != null)
            url = response.getBaseUrl();
        return url;
    }

    public LicDetailObjectModel getLicDetails() {
        TypeToken<LicDetailObjectModel> _type = new TypeToken<LicDetailObjectModel>() {};
        return localStorage.getLicDetails() != null ? gson.fromJson(localStorage.getLicDetails(), _type.getType()) : null;
    }

    public String calculatePrice(ArrayList<Float> priceList) {
        double totalPrice = 0.0;
        for (int i = 0; i < priceList.size(); i++) {
            totalPrice = totalPrice + priceList.get(i);
        }
        return Math.round(totalPrice * 100.0) / 100.0 + "";
    }

    public void parseStoreData(JSONArray storeArray) {
        try {
            ArrayList<StoreDetailObjectModel> modelArrayList = new ArrayList<>();
            for (int i = 0; i < storeArray.length(); i++) {
                if (!ReckonUtils.getJsonCheckedString(storeArray.getJSONObject(i), "Name", "").trim().isEmpty())
                    modelArrayList.add(parseStoreObj(storeArray.getJSONObject(i)));
            }
            localStorage.setStoreList(gson.toJson(modelArrayList));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    public ArrayList<LoginModel> getCountryListData(){
        ArrayList<LoginModel> list = new ArrayList<>();
        String string = SharedPrefUtils.getList(getActivity(), Constant.COUNTRY_LIST);
        try {
            JSONArray jsonArray = new JSONArray(string);
            for(int i=0; i<jsonArray.length(); i++){
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                LoginModel loginModel = new LoginModel();
                loginModel.setTitle(ReckonUtils.getJsonCheckedString(jsonObject, "Name", ""));
                loginModel.setId(ReckonUtils.getJsonCheckedString(jsonObject, "id", ""));
                loginModel.setMobileLength(Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "mlen", "0")));
                loginModel.setMobilePrefix(ReckonUtils.getJsonCheckedString(jsonObject, "mprefix", "0"));
                list.add(loginModel);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
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
            model.setPrimary(ReckonUtils.getJsonCheckedBoolean(object, "primary", false));
            model.setFirstChar(ReckonUtils.getFirstCharFromString(model.getName()));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return model;
    }

    public StoreDetailObjectModel parseStoreObjFromDistributorList(LoginModel loginModel) {
        StoreDetailObjectModel model = new StoreDetailObjectModel();
        try {
            model.setName(loginModel.getCountry_name());
            model.setAdd1(loginModel.getAdd1());
            model.setAdd2(loginModel.getAdd2());
            model.setAdd3(loginModel.getAdd3());
            model.setName(loginModel.getCountry_name());
            model.setMobile(loginModel.getMobile());
            model.setPinCode(loginModel.getPinCode());
            model.setFirmCode(loginModel.getCountry_id());
            model.setFirstChar(ReckonUtils.getFirstCharFromString(model.getName()));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return model;
    }

    public ArrayList<StoreDetailObjectModel> getStoreListData() {
        return localStorage.getStoreList() != null ? gson.fromJson(localStorage.getStoreList(), new TypeToken<ArrayList<StoreDetailObjectModel>>() {
        }.getType()) : new ArrayList<>();
    }

    public ArrayList<ImageModel> getImageDataModelList(JSONArray gstImgList, String baseUrl) {
        ArrayList<ImageModel> arrayList = new ArrayList<>();
        try {
            for (int i = 0; i < gstImgList.length(); i++) {
                JSONObject img = gstImgList.getJSONObject(i);
                ImageModel imageModel = new ImageModel();
                imageModel.setId(ReckonUtils.getJsonCheckedString(img, "ID", "0"));
                String imageUrl = ReckonUtils.getJsonCheckedString(img, "IMAGEURL", "");
                imageModel.setImageUrl(imageUrl.contains("http") ? imageUrl : baseUrl + imageUrl);
                arrayList.add(imageModel);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return arrayList;

    }

    public StoreDetailObjectModel getSelectedStoreDetailsFromPicker() {
        StoreDetailObjectModel model = null;
        if (localStorage.getSelectedStoreInfo() != null) {
            model = gson.fromJson(localStorage.getSelectedStoreInfo(), new TypeToken<StoreDetailObjectModel>() {
            }.getType());
            return model;
        }
        return null;
    }
    public LoginModel parsePartyJsonData(JSONObject jsonObject) {
        LoginModel loginModel = new LoginModel();
        try {
            loginModel.setCountry_name(jsonObject.getString("Name"));
            loginModel.setCountry_id(jsonObject.getString("Code"));
            String emailId = ReckonUtils.getJsonCheckedString(jsonObject, "Email", "");
            loginModel.setEmail(ReckonUtils.isValidEmail(emailId)?emailId:"");
            loginModel.setGstNumber(jsonObject.has("GstNumber") ? jsonObject.getString("GstNumber") : "");
            loginModel.setMobile(!jsonObject.getString("Mobile").equalsIgnoreCase("") ? jsonObject.getString("Mobile") : "");
            loginModel.setAdd1(!jsonObject.getString("Address1").equalsIgnoreCase("") ? jsonObject.getString("Address1") : "");
            loginModel.setAdd2(!jsonObject.getString("Address2").equalsIgnoreCase("") ? jsonObject.getString("Address2") : "");
            loginModel.setAdd3(!jsonObject.getString("Address3").equalsIgnoreCase("") ? jsonObject.getString("Address3") : "");
            loginModel.setPinCode(jsonObject.has("PinCode") ? jsonObject.getString("PinCode") : "");
            loginModel.setRCount(jsonObject.has("RCount") ? jsonObject.getString("RCount") : "");
            loginModel.setShowStock(jsonObject.has("ShowStock") ? jsonObject.getString("ShowStock") : "");
            loginModel.setShowUpdateLocation(jsonObject.has("show_update_location") ? jsonObject.getBoolean("show_update_location") : true);
            loginModel.setOpeningBalance(jsonObject.has("OpBal") ? jsonObject.getString("OpBal") : "");
            loginModel.setClosingBalance(jsonObject.has("ClosBal") ? jsonObject.getString("ClosBal") : "");
            loginModel.setAcIdCol(jsonObject.has("ac_id_col") ? jsonObject.getString("ac_id_col") : "");
            loginModel.setLatitude(jsonObject.has("latitude") ? jsonObject.getString("latitude") : "");
            loginModel.setLongitude(jsonObject.has("longitude") ? jsonObject.getString("longitude") : "");
            loginModel.setGoogleAddress(jsonObject.has("google_address") ? jsonObject.getString("google_address") : "");
            loginModel.setDistance(jsonObject.has("distance") ? jsonObject.getString("distance") : "");
            loginModel.setAccountStatus(ReckonUtils.getJsonCheckedString(jsonObject, "account_status", ""));
            loginModel.setAccountCreditLimit(ReckonUtils.getJsonCheckedString(jsonObject, "account_creditlimit", ""));
            loginModel.setAccountCreditDays(ReckonUtils.getJsonCheckedString(jsonObject, "account_creditdays", ""));
            loginModel.setAccountCreditBills(ReckonUtils.getJsonCheckedString(jsonObject, "account_creditbills", ""));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return loginModel;
    }
    public void parseUserDetails(Profile profile, JSONObject profileObject, String baseUrl) {
        try {
            profile.setNAME(ReckonUtils.getJsonCheckedString(profileObject, "NAME", ""));
            profile.setADDRESS1(ReckonUtils.getJsonCheckedString(profileObject, "ADDRESS1", ""));
            profile.setADDRESS2(ReckonUtils.getJsonCheckedString(profileObject, "ADDRESS2", ""));
            profile.setGSTNUMBER(ReckonUtils.getJsonCheckedString(profileObject, "GSTNUMBER", ""));
            profile.setAREA(ReckonUtils.getJsonCheckedString(profileObject, "AREA", ""));
            profile.setCUID(Integer.parseInt(ReckonUtils.getJsonCheckedString(profileObject, "CUID", "0")));
            profile.setCITY(ReckonUtils.getJsonCheckedString(profileObject, "CITY", ""));
            profile.setSTATE(ReckonUtils.getJsonCheckedString(profileObject, "STATE", ""));
            profile.setDLNO1(ReckonUtils.getJsonCheckedString(profileObject, "DLNO1", ""));
            profile.setDLNO2(ReckonUtils.getJsonCheckedString(profileObject, "DLNO2", ""));
            profile.setPINCODE(ReckonUtils.getJsonCheckedString(profileObject, "PINCODE", ""));
            profile.setMOBILENO(ReckonUtils.getJsonCheckedString(profileObject, "MOBILENO", ""));
            profile.setFOODLICNO(ReckonUtils.getJsonCheckedString(profileObject, "FOODLICNO", ""));

            JSONArray gstImgList = profileObject.has("GST1IMAGEPATH") ? profileObject.getJSONArray("GST1IMAGEPATH") : new JSONArray();
            JSONArray dlImgList = profileObject.has("DLIMAGEPATH") ? profileObject.getJSONArray("DLIMAGEPATH") : new JSONArray();
            JSONArray dl2ImgList = profileObject.has("DL2MAGEPATH") ? profileObject.getJSONArray("DL2MAGEPATH") : new JSONArray();
            JSONArray flImgList = profileObject.has("FL1IMAGEPATH") ? profileObject.getJSONArray("FL1IMAGEPATH") : new JSONArray();

            profile.setGSTIMAGEPATH(new ArrayList<>(getImageDataModelList(gstImgList, baseUrl)));
            profile.setFLIMAGEPATH(new ArrayList<>(getImageDataModelList(flImgList, baseUrl)));
            profile.setDLIMAGEPATH(new ArrayList<>(getImageDataModelList(dlImgList, baseUrl)));
            profile.setDL2IMAGEPATH(new ArrayList<>(getImageDataModelList(dl2ImgList, baseUrl)));

            String dl1ImageUrl = profileObject.has("DL1IMAGEURL") ? profileObject.getString("DL1IMAGEURL") : "";
            String dl2ImageUrl = profileObject.has("DL2IMAGEURL") ? profileObject.getString("DL2IMAGEURL") : "";
            String gst1ImageUrl = profileObject.has("GST1IMAGEURL") ? profileObject.getString("GST1IMAGEURL") : "";
            String fl1ImageUrl = profileObject.has("FL1IMAGEURL") ? profileObject.getString("FL1IMAGEURL") : "";

            profile.setDL1IMAGEURL(dl1ImageUrl.contains("http") ? dl1ImageUrl : baseUrl + dl1ImageUrl);
            profile.setDL2IMAGEURL(dl2ImageUrl.contains("http") ? dl2ImageUrl : baseUrl + dl2ImageUrl);
            profile.setGST1IMAGEURL(gst1ImageUrl.contains("http") ? gst1ImageUrl : baseUrl + gst1ImageUrl);
            profile.setFL1IMAGEURL(fl1ImageUrl.contains("http") ? fl1ImageUrl : baseUrl + fl1ImageUrl);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void navigateToPartyFragmentListing(View v, String page, Bundle mBundle) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, page);
        bundle.putString("BrandItemId", mBundle.containsKey("BrandItemId") ? mBundle.getString("BrandItemId") : "");
        bundle.putString("isNewArrival", mBundle.containsKey("isNewArrival") ? mBundle.getString("isNewArrival") : "");
        bundle.putString("withScheme", mBundle.containsKey("withScheme") ? mBundle.getString("withScheme") : "");
        Navigation.findNavController(v).navigate(R.id.navPartyLisingFragment, bundle);
    }

    public void orderEntryClickHandling(View v, String constant, Bundle bundle) {
        if (getLicDetails().getRole().equalsIgnoreCase("SalesMan")) {
            if (constant.equalsIgnoreCase(Constant.NEW_ORDER)) {
                ArrayList<StoreDetailObjectModel> storeListData = getStoreListData();
                navigateToPartyFragmentListing(v, constant, bundle);
            } else if (constant.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || constant.equalsIgnoreCase(Constant.OUTSTANDING) ||
                    constant.equalsIgnoreCase(Constant.BRAND_LIST) || constant.equalsIgnoreCase(Constant.BRAND) || constant.equalsIgnoreCase(Constant.NEW_ARRIVAL)) {
                navigateToPartyFragmentListing(v, constant, bundle);
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
                if (constant.equalsIgnoreCase(Constant.NEW_ORDER)) {
                    clearData();
                    bundle.putString(Constant.OPEN_PRODUCT_LIST_DIRECT, Constant.YES);
                    Navigation.findNavController(v).navigate(R.id.action_nav_home_to_menu_newOrder2, bundle);
                } else {
                    Navigation.findNavController(v).navigate(R.id.nav_common_listing, bundle);
                }
            } else if (constant.equalsIgnoreCase(Constant.BRAND_LIST)) {
                Navigation.findNavController(v).navigate(R.id.action_brand_item_to_new_order_list, bundle);
            } else if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE)) {
                StoreDetailObjectModel store = getStoreDetails();
                Bundle newBundle = new Bundle();
                newBundle.putString("name", store.getName());
                newBundle.putString(Constant.SELECTED_ID, store.getFirmCode());
                newBundle.putString(Constant.ID, store.getFirmCode());
                newBundle.putString("LicNo", store.getLicNo());
                newBundle.putString("address", store.getAdd1());
                if (constant.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT)) {
                    LoginModel loginModel = new LoginModel();
                    loginModel.setAcCode(store.getAcCode());
                    loginModel.setAdd1(store.getAdd1());
                    loginModel.setAdd2(store.getAdd2());
                    loginModel.setAdd3(store.getAdd3());
                    loginModel.setCountry_id(store.getId());
                    loginModel.setCountry_name(store.getName());
                    loginModel.setMobile(store.getMobile());
                    loginModel.setLicNo(store.getLicNo());
                    loginModel.setEmail(store.getEmail());
                    loginModel.setCity(store.getCity());
                    newBundle.putString(Constant.PARTY_LIST, new Gson().toJson(loginModel));
                    Navigation.findNavController(v).navigate(R.id.nav_account_statement, newBundle);
                } else if (constant.equalsIgnoreCase(Constant.OUTSTANDING)) {
                    Navigation.findNavController(v).navigate(R.id.nav_outlet_details, newBundle);
                } else if (constant.equalsIgnoreCase(Constant.NEW_ORDER)) {
                    Navigation.findNavController(v).navigate(R.id.action_nav_home_to_menu_newOrder2, bundle);
                } else if (constant.equalsIgnoreCase(Constant.BRAND)) {
                    Navigation.findNavController(v).navigate(R.id.action_nav_home_to_menu_newOrder2, bundle);
                }
            } else {
                Navigation.findNavController(v).navigate(R.id.action_nav_home_to_menu_newOrder2, bundle);
            }
        }
    }

    private void clearData() {
        if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
            LicDetailObjectModel model = getLicDetails();
            model.setFirmcode("");
            model.setFirmName("");
            model.setFirmAdd("");
            localStorage.setLicDetails(gson.toJson(model));
            SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, "");
        }
    }

    public static void hideKeyboard(Activity activity) {
        InputMethodManager imm = (InputMethodManager) activity.getSystemService(Activity.INPUT_METHOD_SERVICE);
        //Find the currently focused view, so we can grab the correct window token from it.
        View view = activity.getCurrentFocus();
        //If no view currently has focus, create a new one, just so we can grab a window token from it
        if (view == null) {
            view = new View(activity);
        }
        imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
    }


    public int getStatusBarColorOfApp() {
        return ((BaseActivity) getActivity()).getStatusBarColorOfApp();
    }

    public int getButtonColor() {

        return ((BaseActivity) getActivity()).getButtonColor();
    }

    public int getHeaderTextColor() {

        return ((BaseActivity) getActivity()).getHeaderTextColor();
    }

    public int getSecondHeaderTextColor() {

        return ((BaseActivity) getActivity()).getSecondHeaderTextColor();
    }

    public int getThirdHeaderColor() {

        return ((BaseActivity) getActivity()).getThirdHeaderColor();
    }

    public boolean isLightIcon() {
        return ((BaseActivity) getActivity()).isLightIcon();
    }

}