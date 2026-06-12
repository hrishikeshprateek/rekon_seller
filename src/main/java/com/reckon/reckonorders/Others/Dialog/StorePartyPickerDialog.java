package com.reckon.reckonorders.Others.Dialog;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.app.Activity;
import android.app.Dialog;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.view.Window;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.reckon.reckonorders.Adapter.PartyPickerAdapter;
import com.reckon.reckonorders.Base.BaseActivity;
import com.reckon.reckonorders.Interfaces.CustomDialogItemListener;
import com.reckon.reckonorders.Interfaces.DialogListener;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class StorePartyPickerDialog extends Dialog implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private ArrayList<StoreDetailObjectModel> partyList = new ArrayList();
    private DialogListener clickListener;
    private CustomDialogItemListener customDialogItemListener;
    @BindView(R.id.dialogConfirm_tvTitle)
    TextView tvTitle;
    @BindView(R.id.imgBack)
    public ImageView imgBack;
    @BindView(R.id.rv_party_listing)
    RecyclerView rv_party_listing;
    @BindView(R.id.noRecordTV)
    LinearLayout noRecordTV;
    private final String title, screen, sourceScreen;
    private final Activity activity;
    public PartyPickerAdapter partyPickerAdapter;
    private LocalStorage localStorage;
    private Gson gson;
    private StoreDetailObjectModel selectedFirmObj;

    public StorePartyPickerDialog(Activity activity, String title, String screen, String sourceScreen) {
        super(activity);
        this.title = title;
        this.activity = activity;
        this.screen = screen;
        this.sourceScreen = sourceScreen;
    }
    public StorePartyPickerDialog(Activity activity, String title, String screen, String sourceScreen, StoreDetailObjectModel storeObjModel) {
        super(activity);
        this.title = title;
        this.activity = activity;
        this.screen = screen;
        this.sourceScreen = sourceScreen;
        this.selectedFirmObj = storeObjModel;
    }

    public void setOnItemClickListener(DialogListener listener) {
        this.clickListener = listener;
    }

    public void setOnItemClickListenerDialog(CustomDialogItemListener listener) {
        this.customDialogItemListener = listener;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setCancelable(screen.equalsIgnoreCase(Constant.MYORDERLIST) || screen.equalsIgnoreCase(Constant.RECEIPT_BOOK));
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.store_party_picker_dialog);
        ButterKnife.bind(this);
        retrofitCallBackListener = this;
        tvTitle.setText(title.toUpperCase());
        localStorage = new LocalStorage(getContext());
        gson = new Gson();
        rv_party_listing.setLayoutManager(new LinearLayoutManager(getContext(), LinearLayoutManager.VERTICAL, false));
        rv_party_listing.setNestedScrollingEnabled(false);
        if (screen.equalsIgnoreCase(Constant.PARTY) || screen.equalsIgnoreCase(Constant.MYORDERLIST) || screen.equalsIgnoreCase(Constant.RECEIPT_BOOK)) {
            getPartyList();
        }else if (screen.equalsIgnoreCase(Constant.DISTRIBUTOR)) {
            getDistributorList("MAP", "1", "0");
        } else if (sourceScreen.equalsIgnoreCase(Constant.CREATE_RECEIPT)) {
            partyPickerAdapter = new PartyPickerAdapter(StorePartyPickerDialog.this, ((BaseActivity) activity).getStoreListData(), selectedFirmObj, screen);
            rv_party_listing.setAdapter(partyPickerAdapter);
        } else {
            ArrayList<StoreDetailObjectModel> storeListData = ((BaseActivity) activity).getStoreListData();
            partyPickerAdapter = new PartyPickerAdapter(StorePartyPickerDialog.this, storeListData, ((BaseActivity) activity).getSelectedStoreDetailsFromPicker(), screen);
            rv_party_listing.setAdapter(partyPickerAdapter);
        }
        if (screen.equalsIgnoreCase(Constant.MYORDERLIST) || screen.equalsIgnoreCase(Constant.RECEIPT_BOOK) ||  sourceScreen.equalsIgnoreCase(Constant.CREATE_RECEIPT)) {
            imgBack.setVisibility(View.VISIBLE);
        }
    }

    public void getSelectedData(StoreDetailObjectModel dataPos) {
        if (customDialogItemListener != null && (screen.equalsIgnoreCase(Constant.PARTY) || screen.equalsIgnoreCase(Constant.DISTRIBUTOR) || screen.equalsIgnoreCase(Constant.MYORDERLIST) || screen.equalsIgnoreCase(Constant.RECEIPT_BOOK))) {
            SharedPrefUtils.setString(activity, Constant.PARTY_CODE, dataPos.getFirmCode());
            customDialogItemListener.onItemClicked(dataPos);
        } else if (customDialogItemListener!=null && sourceScreen.equalsIgnoreCase(Constant.CREATE_RECEIPT)) {
            customDialogItemListener.onItemClicked(dataPos);
        } else {
            localStorage.setSelectedStoreInfo(gson.toJson(dataPos));
            NewMainActivity.binding.appBarNewMain.iconText.setText(((BaseActivity) activity).getSelectedStoreDetailsFromPicker().getFirstChar());
            String arrOfStr[] = ((BaseActivity) activity).getSelectedStoreDetailsFromPicker().getName().split(" ");
            NewMainActivity.binding.appBarNewMain.tvWelcome.setText(arrOfStr.length > 1 ? (arrOfStr[0] + " " + arrOfStr[1]) : arrOfStr[0]);
            if (NewMainActivity.binding.appBarNewMain.tvWelcome.getVisibility() == View.GONE)
                NewMainActivity.binding.appBarNewMain.tvWelcome.setVisibility(View.VISIBLE);
            if (NewMainActivity.binding.appBarNewMain.iconContainer.getVisibility() == View.GONE)
                NewMainActivity.binding.appBarNewMain.iconContainer.setVisibility(View.GONE);
            if (customDialogItemListener != null)
                customDialogItemListener.onItemClicked(dataPos);

        }
        dismiss();
    }

/*    public Dialog onClick(CharSequence text, final OnClickListener listener) {
//        P.mPositiveButtonText = text;
//        P.mPositiveButtonListener = listener;
        return this;
    }*/

    @OnClick({R.id.imgBack})
    void onViewClicked(View view) {
        switch (view.getId()) {
            case R.id.imgBack:
                dismiss();
                if (customDialogItemListener != null)
                    customDialogItemListener.onItemClicked(null);
                break;
        }
    }

    private void getPartyList() {
        try {
            String firmCode = ((BaseActivity) activity).getSelectedStoreDetailsFromPicker().getFirmCode();
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", ((BaseActivity) activity).getPackageName());
            jsonObject.put("lLicNo", ((BaseActivity) activity).getLicDetails().getLicno());
            jsonObject.put("lPageNo", String.valueOf(1));
            jsonObject.put("lSize", String.valueOf(1000));
            jsonObject.put("lSearchFieldValue", "");
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("FirmCode", firmCode);
            jsonObject.put("FromDo", screen.equalsIgnoreCase(Constant.PARTY) ? "1" : "0");
            jsonObject.put("lUserId", SharedPrefUtils.getString(activity, Constant.USER_ID));
            jsonObject.put("device_id", SharedPrefUtils.getString(activity, Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(activity, Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(activity));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(activity));
            jsonObject.put("app_role", SharedPrefUtils.getString(activity, Constant.ROLE));
            if(screen.equalsIgnoreCase(Constant.RECEIPT_BOOK)){
                jsonObject.put("ltype", "1");
                new ConnectToRetrofit(retrofitCallBackListener, activity, getApiClientByPost().getPartyList(String.valueOf(jsonObject)), Constant.PARTY, true);
            }else{
                new ConnectToRetrofit(retrofitCallBackListener, activity, getApiClientByPost().getDraftPartyList(String.valueOf(jsonObject)), Constant.PARTY, true);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void getDistributorList(String MapType, String status, String lock) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", activity.getPackageName());
            jsonObject.put("lLicNo", SharedPrefUtils.getString(activity, Constant.USER_ID));
            jsonObject.put("lCityCode", "");
            jsonObject.put("lMapType", MapType);
            jsonObject.put("lStatus", status);
            jsonObject.put("lLock", lock);
            jsonObject.put("lBussinessType", "");
            jsonObject.put("cu_id", SharedPrefUtils.getString(activity, Constant.USER_ID_CU));
            jsonObject.put("from_do", (sourceScreen!=null&&sourceScreen.equalsIgnoreCase(Constant.CART_SCREEN))?"1":"0");
            jsonObject.put("device_id", SharedPrefUtils.getString(activity, Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(activity));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(activity));
            jsonObject.put("app_role", SharedPrefUtils.getString(activity, Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, activity, getApiClientByPost().PostDistributorList(String.valueOf(jsonObject)), Constant.DISTRIBUTOR, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 1) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.PARTY:
                    try {
                        JSONArray jsonArray2 = jsonObject.getJSONArray("Account");
                        setPartyListingAdapter(jsonArray2, Constant.PARTY);
                    } catch (Exception e) {
                        e.printStackTrace();
                        dismiss();
                        if (partyList.size() == 0)
                            noRecordTV.setVisibility(View.VISIBLE);
                        else noRecordTV.setVisibility(View.GONE);
                    }
                    break;
                case Constant.DISTRIBUTOR:
                    try {
                        if (jsonObject.has("Distributor")) {
                            JSONArray jsonArray2 = jsonObject.getJSONArray("Distributor");
                            setDistributorListingAdapter(jsonArray2);
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        if (partyList.size() == 0)
                            noRecordTV.setVisibility(View.VISIBLE);
                        else noRecordTV.setVisibility(View.GONE);
                    }
                    break;
            }

        }

    }

    private void setPartyListingAdapter(JSONArray jsonArray, String type) {
        try {
            if (partyList != null && partyList.size() > 0) {
                partyList.clear();
            }
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                StoreDetailObjectModel model = new StoreDetailObjectModel();
                try {
                    model.setAdd1(ReckonUtils.getJsonCheckedString(jsonObject, "Address1", ""));
                    model.setAdd2(ReckonUtils.getJsonCheckedString(jsonObject, "Address2", ""));
                    model.setAdd3(ReckonUtils.getJsonCheckedString(jsonObject, "Address3", ""));
                    model.setName(ReckonUtils.getJsonCheckedString(jsonObject, "Name", ""));
                    model.setMobile(ReckonUtils.getJsonCheckedString(jsonObject, "Mobile", ""));
                    model.setPinCode(ReckonUtils.getJsonCheckedString(jsonObject, "PinCode", ""));
                    model.setFirmCode(ReckonUtils.getJsonCheckedString(jsonObject, "Code", ""));
                    model.setFirstChar(ReckonUtils.getFirstCharFromString(model.getName()));
                    if (screen.equalsIgnoreCase(Constant.PARTY) || screen.equalsIgnoreCase(Constant.MYORDERLIST) || screen.equalsIgnoreCase(Constant.RECEIPT_BOOK))
                        partyList.add(model);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            if (partyList.size() == 0) {
                noRecordTV.setVisibility(View.VISIBLE);
                imgBack.setVisibility(View.VISIBLE);
                new Handler().postDelayed(() -> {
//                    customDialogItemListener.onItemClicked(null);
                    dismiss();
                }, 2500);
            } else {
                if (!screen.equalsIgnoreCase(Constant.MYORDERLIST) && !screen.equalsIgnoreCase(Constant.RECEIPT_BOOK)) {
                    imgBack.setVisibility(View.GONE);
                }
                noRecordTV.setVisibility(View.GONE);
            }

            partyPickerAdapter = new PartyPickerAdapter(StorePartyPickerDialog.this, partyList, ((BaseActivity) activity).getSelectedStoreDetailsFromPicker(), screen);
            rv_party_listing.setAdapter(partyPickerAdapter);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setDistributorListingAdapter(JSONArray jsonArray) {
        try {
            if (partyList != null && partyList.size() > 0)
                partyList.clear();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                StoreDetailObjectModel model = new StoreDetailObjectModel();
                try {
                    model.setAdd1(ReckonUtils.getJsonCheckedString(jsonObject, "Add1", ""));
                    model.setAdd2(ReckonUtils.getJsonCheckedString(jsonObject, "Add2", ""));
                    model.setAdd3(ReckonUtils.getJsonCheckedString(jsonObject, "Add3", ""));
                    model.setCity(ReckonUtils.getJsonCheckedString(jsonObject, "City", ""));
                    model.setName(ReckonUtils.getJsonCheckedString(jsonObject, "Name", ""));
                    model.setEmail(ReckonUtils.getJsonCheckedString(jsonObject, "Email", ""));
                    model.setMobile(ReckonUtils.getJsonCheckedString(jsonObject, "Mobile", ""));
                    model.setPinCode(ReckonUtils.getJsonCheckedString(jsonObject, "PinCode", ""));
                    model.setFirmCode(ReckonUtils.getJsonCheckedString(jsonObject, "Code", ""));
                    model.setId(ReckonUtils.getJsonCheckedString(jsonObject, "id", ""));
                    model.setAcCode(ReckonUtils.getJsonCheckedString(jsonObject, "AcCode", ""));
                    model.setAcCode(ReckonUtils.getJsonCheckedString(jsonObject, "AcCode", ""));
                    model.setLicNo(ReckonUtils.getJsonCheckedString(jsonObject, "LicNo", ""));
                    model.setFirstChar(ReckonUtils.getFirstCharFromString(model.getName()));
                    partyList.add(model);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            if (partyList.size() == 0) {
                noRecordTV.setVisibility(View.VISIBLE);
                imgBack.setVisibility(View.VISIBLE);
                new Handler().postDelayed(() -> {
                    dismiss();
                }, 2500);
            } else {
                if (!screen.equalsIgnoreCase(Constant.MYORDERLIST) && !screen.equalsIgnoreCase(Constant.RECEIPT_BOOK)) {
                    imgBack.setVisibility(View.GONE);
                }
                noRecordTV.setVisibility(View.GONE);
            }

            partyPickerAdapter = new PartyPickerAdapter(StorePartyPickerDialog.this, partyList, ((BaseActivity) activity).getSelectedStoreDetailsFromPicker(), screen);
            rv_party_listing.setAdapter(partyPickerAdapter);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
