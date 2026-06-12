package com.reckon.reckonorders.Fragment.Home;

/**
 * Created by Manvendra Kumar Singh on 20/02/2019.
 */


import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Adapter.SettingAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class SettingFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    @BindView(R.id.rv_setting_listing)
    RecyclerView rv_setting_listing;
    @BindView(R.id.rv_helpIndex_listing)
    RecyclerView rv_helpIndex_listing;
    @BindView(R.id.search_img)
    ImageView search_img;
    @BindView(R.id.search1_img)
    ImageView search1_img;
    @BindView(R.id.searched_txt)
    TextView searched_txt;
    @BindView(R.id.hint_searched_txt)
    TextView hint_searched_txt;
    @BindView(R.id.check1)
    ImageView check1;
    @BindView(R.id.check2)
    ImageView check2;
    @BindView(R.id.check3)
    ImageView check3;
    @BindView(R.id.check4)
    ImageView check4;
    @BindView(R.id.check5)
    ImageView check5;
    @BindView(R.id.check6)
    ImageView check6;
    @BindView(R.id.check7)
    ImageView check7;
    @BindView(R.id.upload_check_img)
    ImageView upload_check_img;
    @BindView(R.id.actionbar_imgRefresh)
    LinearLayout actionbar_imgRefresh;
    @BindView(R.id.upload_cv)
    CardView upload_cv;
    List<SelectionModel> data1, data;
    boolean IsRef = false, Isbarcode = false, IsBrnd = false, IsPack = false, IsSalt = false, IsCat = false, IsValue = false, isUploadPrescription = false;
    String Mobile_Number, Country_Code, SearchId = "", HintID = "", HintName = "", SearchTypeID = "";
    private String role = "";

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_setting, container, false);
        ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        setupHomeButton(view);
        setupRefreshButton(view);
        getBundle();
        setupUI();
        setTitle(view, getString(R.string.setting).toUpperCase());
        return view;
    }
    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        try {
            setData();
            actionbar_imgRefresh.setVisibility(View.VISIBLE);
            rv_setting_listing.setLayoutManager(new LinearLayoutManager(getActivity()));
            rv_helpIndex_listing.setLayoutManager(new LinearLayoutManager(getActivity()));
            JSONArray jsonArray1 = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.USER_DATA_LIST));
            JSONObject jsonObject = jsonArray1.getJSONObject(0);
            Mobile_Number = jsonObject.has("LicNo") ? jsonObject.getString("LicNo") : "";
            Country_Code = jsonObject.has("CountryCode") ? jsonObject.getString("CountryCode") : "";
            JSONArray jsonArray = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.LoginType));
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject1 = jsonArray.getJSONObject(i);
                if (jsonObject.has("LicUserRole") && jsonObject1.getString("Code").equalsIgnoreCase(jsonObject.getString("LicUserRole"))) {
                    role = jsonObject1.getString("Code");
                    break;
                }
            }
            if (role.equalsIgnoreCase("B"))
                upload_cv.setVisibility(View.GONE);

            setItemSetting();
            setSearchAdapter();
            setHelpAdapter();
            for (int i = 0; i < data.size(); i++) {
                if (SharedPrefUtils.getString(getActivity(), Constant.SearchTypeID).equalsIgnoreCase(data.get(i).getItemId())) {
                    searched_txt.setText(data.get(i).getName());
                    SearchId = data.get(i).getItemId();
                    break;
                }
            }
            for (int j = 0; j < data1.size(); j++) {
                if (SharedPrefUtils.getString(getActivity(), Constant.ItemHelpIndex).equalsIgnoreCase(data1.get(j).getItemId())) {
                    hint_searched_txt.setText(data1.get(j).getName());
                    HintID = data1.get(j).getItemId();
                    HintName = data1.get(j).getName();
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }


    }

    private void setData() {
        Isbarcode = !SharedPrefUtils.getString(getActivity(), Constant.ShowBarcode).equalsIgnoreCase("false");
        IsBrnd = !SharedPrefUtils.getString(getActivity(), Constant.ShowBrand).equalsIgnoreCase("false");
        IsCat = SharedPrefUtils.getBoolean(getActivity(), Constant.ShowIGroup);
        IsPack = !SharedPrefUtils.getString(getActivity(), Constant.ShowPack).equalsIgnoreCase("false");
        IsRef = !SharedPrefUtils.getString(getActivity(), Constant.ShowRefNo).equalsIgnoreCase("false");
        IsSalt = !SharedPrefUtils.getString(getActivity(), Constant.ShowSalt).equalsIgnoreCase("false");
        IsValue = !SharedPrefUtils.getString(getActivity(), Constant.StartWithSearchFieldValue).equalsIgnoreCase("false");
        boolean ItemHelp = !SharedPrefUtils.getString(getActivity(), Constant.ItemHelpIndex).equalsIgnoreCase("false");
        isUploadPrescription =!SharedPrefUtils.getString(getActivity(), Constant.ISUPLOADPRESCRIPTION).equalsIgnoreCase("false");

    }

    private void setItemSetting() {
        check1.setImageResource(IsRef ? R.drawable.my_check_box : R.drawable.uncheck_box);
        check2.setImageResource(IsPack ? R.drawable.my_check_box : R.drawable.uncheck_box);
        check3.setImageResource(IsBrnd ? R.drawable.my_check_box : R.drawable.uncheck_box);
        check4.setImageResource(Isbarcode ? R.drawable.my_check_box : R.drawable.uncheck_box);
        check5.setImageResource(IsSalt ? R.drawable.my_check_box : R.drawable.uncheck_box);
        check6.setImageResource(IsCat ? R.drawable.my_check_box : R.drawable.uncheck_box);
        check7.setImageResource(IsValue ? R.drawable.my_check_box : R.drawable.uncheck_box);
        upload_check_img.setImageResource(isUploadPrescription ? R.drawable.my_check_box : R.drawable.uncheck_box);

    }

    private void setHelpAdapter() {
        data1 = new ArrayList<>();
        try {
            JSONArray jsonArray1 = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.HelpField));
            for (int i = 0; i < jsonArray1.length(); i++) {
                data1.add(new SelectionModel(jsonArray1.getJSONObject(i).getString("Code"), jsonArray1.getJSONObject(i).getString("Code1"), "false"));
            }

            rv_helpIndex_listing.setAdapter(new SettingAdapter(SettingFragment.this, data1, "HINT"));

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setSearchAdapter() {
        data = new ArrayList<>();
        try {
            JSONArray jsonArray = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.SearchType));
            for (int i = 0; i < jsonArray.length(); i++) {
                data.add(new SelectionModel(jsonArray.getJSONObject(i).getString("Code"), jsonArray.getJSONObject(i).getString("Code1"), "false"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }


        rv_setting_listing.setAdapter(new SettingAdapter(SettingFragment.this, data, ""));
    }


    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
        }
    }

    @OnClick({R.id.change_password_ll, R.id.search_type_ll, R.id.help_ll, R.id.selected_ref_ll, R.id.selected_pack_ll, R.id.selected_brand_ll,
            R.id.selected_barcode_ll, R.id.selected_salt_ll, R.id.selected_cat_ll, R.id.selected_value_ll, R.id.fragmentRegister_frmUpdateSetting, R.id.uploadPreSetting_ll})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.change_password_ll:
                addFragment(new ChangePasswordFragment(), true);
                break;
            case R.id.search_type_ll:
                showSearch();
                break;
            case R.id.help_ll:
                showHelp();
                break;
            case R.id.selected_ref_ll:
                IsRef = !IsRef;
                check1.setImageResource(IsRef ? R.drawable.my_check_box : R.drawable.uncheck_box);
                break;
            case R.id.selected_pack_ll:
                IsPack = !IsPack;
                check2.setImageResource(IsPack ? R.drawable.my_check_box : R.drawable.uncheck_box);
                break;
            case R.id.selected_brand_ll:
                IsBrnd = !IsBrnd;

                check3.setImageResource(IsBrnd ? R.drawable.my_check_box : R.drawable.uncheck_box);
                break;
            case R.id.selected_barcode_ll:
                Isbarcode = !Isbarcode;

                check4.setImageResource(Isbarcode ? R.drawable.my_check_box : R.drawable.uncheck_box);
                break;
            case R.id.selected_salt_ll:
                IsSalt = !IsSalt;

                check5.setImageResource(IsSalt ? R.drawable.my_check_box : R.drawable.uncheck_box);
                break;
            case R.id.selected_cat_ll:
                IsCat = !IsCat;

                check6.setImageResource(IsCat ? R.drawable.my_check_box : R.drawable.uncheck_box);
                break;
            case R.id.selected_value_ll:
                IsValue = !IsValue;
                check7.setImageResource(IsValue ? R.drawable.my_check_box : R.drawable.uncheck_box);
                break;
            case R.id.uploadPreSetting_ll:
                isUploadPrescription = !isUploadPrescription;
                upload_check_img.setImageResource(isUploadPrescription ? R.drawable.my_check_box : R.drawable.uncheck_box);
                SharedPrefUtils.setString(getActivity(), Constant.ISUPLOADPRESCRIPTION, isUploadPrescription ?"true":"false" );
                break;
            case R.id.fragmentRegister_frmUpdateSetting:
                postUpdateSetting();
                break;
        }
    }

    private void postUpdateSetting() {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postUpdateSetting(requireActivity().getPackageName(),Mobile_Number,
                    Country_Code, "" + IsRef, "" + IsPack, "" + IsBrnd, "" + Isbarcode,
                    "" + IsSalt, "" + IsCat, SearchId, HintID, "" + IsValue), Constant.UPDATE_PROFILE, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void showSearch() {
        search_img.setImageResource(rv_setting_listing.getVisibility() == View.GONE ? R.drawable.ic_select_up : R.drawable.ic_select_down);
        rv_setting_listing.setVisibility(rv_setting_listing.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
        searched_txt.setVisibility(rv_setting_listing.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
    }

    private void showHelp() {
        search1_img.setImageResource(rv_helpIndex_listing.getVisibility() == View.GONE ? R.drawable.ic_select_up : R.drawable.ic_select_down);
        rv_helpIndex_listing.setVisibility(rv_helpIndex_listing.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
        hint_searched_txt.setVisibility(rv_helpIndex_listing.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
    }

    public void getSelectedData(int Position, String hint) {
        System.out.println("Position===" + Position);
        if (hint.equalsIgnoreCase("HINT")) {
            HintID = data1.get(Position).getItemId();
            HintName = data1.get(Position).getName();
            hint_searched_txt.setText(data1.get(Position).getName());
            SharedPrefUtils.setString(getActivity(), Constant.ItemHelpIndex, HintID);
            showHelp();
        } else {
            SearchId = data.get(Position).getItemId();
            searched_txt.setText(data.get(Position).getName());
            SharedPrefUtils.setString(getActivity(), Constant.SearchTypeID, SearchId);
            showSearch();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        JSONObject jsonObject = new JSONObject(result);
        if (action.equalsIgnoreCase(Constant.GENERAL_SETTING)) {
            SharedPrefUtils.setList(getActivity(), Constant.ImageList,  new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.BUSINESS_TYPE_LIST, jsonObject.getJSONArray("Business") != null ? jsonObject.getJSONArray("Business") : new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.COUNTRY_LIST, jsonObject.getJSONArray("Country") != null ? jsonObject.getJSONArray("Country") : new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.SearchType, jsonObject.getJSONArray("SearchType") != null ? jsonObject.getJSONArray("SearchType") : new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.HelpField, jsonObject.getJSONArray("HelpField") != null ? jsonObject.getJSONArray("HelpField") : new JSONArray());
            SharedPrefUtils.setList(getActivity(), Constant.ImageList, jsonObject.getJSONArray("ImageList") != null ? jsonObject.getJSONArray("ImageList") : new JSONArray());
        } else {
            if (jsonObject.getString("Status").equalsIgnoreCase("true")) {
                Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
                SharedPrefUtils.setString(getActivity(), Constant.ShowBarcode, jsonObject.getString("ShowBarcode"));
                SharedPrefUtils.setString(getActivity(), Constant.ShowBrand, jsonObject.getString("ShowBrand"));
                SharedPrefUtils.setBoolean(getActivity(), Constant.ShowIGroup, jsonObject.getBoolean("ShowIGroup"));
                SharedPrefUtils.setBoolean(getActivity(), Constant.ShowSalt, jsonObject.getBoolean("ShowSalt"));
                SharedPrefUtils.setString(getActivity(), Constant.ShowPack, jsonObject.getString("ShowPack"));
                SharedPrefUtils.setString(getActivity(), Constant.ShowRefNo, jsonObject.getString("ShowRefNo"));
                SharedPrefUtils.setString(getActivity(), Constant.ShowSalt, jsonObject.getString("ShowSalt"));
                SharedPrefUtils.setString(getActivity(), Constant.SearchTypeID, jsonObject.getString("SearchType"));
                SharedPrefUtils.setString(getActivity(), Constant.StartWithSearchFieldValue, jsonObject.getString("StartWithSearchFieldValue"));
                SharedPrefUtils.setString(getActivity(), Constant.ItemHelpIndex, jsonObject.getString("ItemHelpIndex"));
                setData();
                SharedPrefUtils.setString(getActivity(), Constant.SEARCHED_KEY, SearchId);
                SharedPrefUtils.setString(getActivity(), Constant.HELP_KEY, HintID);
                SharedPrefUtils.setString(getActivity(), Constant.HELP_Name, HintName);
                JSONObject obj = new JSONObject();
                try{
                    obj.put("lApkName", requireActivity().getPackageName());
                    obj.put("app_role", SharedPrefUtils.getString(getActivity(), Constant.ROLE));
                    obj.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
                    obj.put("device_name", ReckonUtils.getDeviceName());
                    obj.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
                    obj.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
                    obj.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
                }catch (Exception e){
                    e.printStackTrace();
                }
                new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().generalSetting(String.valueOf(obj)), Constant.GENERAL_SETTING, false);
            } else
                Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();

        }

    }
}
