package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Adapter.CommonRowAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.LoginModel;
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

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class RequestDistributorFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    @SuppressLint("StaticFieldLeak")
    static EditText search_dis_tv;
    @BindView(R.id.rv_distributor_listing)
    RecyclerView rv_distributor_listing;
    @BindView(R.id.noRecordTV)
    LinearLayout noRecordTV;
    @BindView(R.id.Add_Distributor_submit_fl)
    FrameLayout submitBtn;
    LinearLayout search_distributor_ll;
    String Distributor = "";
    private JSONObject jsonObject = new JSONObject();
    private static String distributor_id, distributor_Lic_No, distributor_Mobile;
    private ArrayList<LoginModel> distributor_list = new ArrayList();
    private ArrayList<LoginModel> comun_list = new ArrayList();
    private ArrayList<LoginModel> mSelectedItemList;


    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_request, container, false);
        ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        search_dis_tv = view.findViewById(R.id.search_dis_tv);
        search_distributor_ll = view.findViewById(R.id.search_distributor_ll);
        rv_distributor_listing.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
        rv_distributor_listing.setVisibility(View.VISIBLE);
        setupUI(view);
        submitBtn.setBackgroundColor(getResources().getColor(R.color.grey));
        submitBtn.setClickable(false);
        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI(View view) {
        try {
            getDistributorList("UNMAP", "", "");
            callingSearchDistributor(view);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void callingSearchDistributor(View view) {
        final ArrayList<LoginModel> new_distributor_list = new ArrayList();
        search_dis_tv.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.length() == 0) {
                    if (distributor_list.size() == 0)
                        noRecordTV.setVisibility(View.VISIBLE);
                    else noRecordTV.setVisibility(View.GONE);
                    rv_distributor_listing.setAdapter(new CommonRowAdapter(RequestDistributorFragment.this, distributor_list, Constant.DISTRIBUTOR, ""));
                } else {
                    if (new_distributor_list.size() > 0)
                        new_distributor_list.clear();

                    if (distributor_list.size() > 0) {
                        if (comun_list.size() > 0)
                            comun_list.clear();
                        comun_list.addAll(distributor_list);
                        for (int i = 0; i < comun_list.size(); i++) {
                            if (comun_list.get(i).getCountry_name().toLowerCase().contains(s.toString().toLowerCase())) {
                                LoginModel loginModel = new LoginModel();
                                loginModel.setCountry_name(comun_list.get(i).getCountry_name());
                                loginModel.setCountry_id(comun_list.get(i).getCountry_id());
                                loginModel.setAdd1(comun_list.get(i).getAdd1());
                                loginModel.setMobile(comun_list.get(i).getMobile());
                                loginModel.setEmail(comun_list.get(i).getEmail());
                                loginModel.setLicNo(comun_list.get(i).getLicNo());
                                loginModel.setCity(comun_list.get(i).getCity());
                                loginModel.setArea(comun_list.get(i).getArea());
                                loginModel.setAcCode(comun_list.get(i).getAcCode());
                                loginModel.setId(comun_list.get(i).getId());
                                loginModel.setPinCode(comun_list.get(i).getPinCode());
                                loginModel.setRCount(comun_list.get(i).getRCount());
                                loginModel.setLock(comun_list.get(i).getLock());
                                loginModel.setStatus(comun_list.get(i).getStatus());
                                new_distributor_list.add(loginModel);
                            }
                            if (new_distributor_list.size() == 0)
                                noRecordTV.setVisibility(View.VISIBLE);
                            else noRecordTV.setVisibility(View.GONE);
                            rv_distributor_listing.setAdapter(new CommonRowAdapter(RequestDistributorFragment.this, new_distributor_list, Constant.DISTRIBUTOR, ""));
                        }
                    }
                }
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
    }

    private void getDistributorList(String MapType, String status, String lock) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lCityCode", "");
            jsonObject.put("lMapType", MapType);
            jsonObject.put("lStatus", status);
            jsonObject.put("lLock", lock);
            jsonObject.put("lBussinessType", "");
            jsonObject.put("cu_id", SharedPrefUtils.getString( getActivity(), Constant.USER_ID_CU));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostDistributorList(String.valueOf(jsonObject)), Constant.DISTRIBUTOR, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @OnClick({R.id.search_distributor_ll, R.id.Add_Distributor_submit_fl})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.search_distributor_ll:
//                GoToCommonListingFragment(view, CODE_REQUEST_DISTRIBUTOR_FILTER, Constant.DISTRIBUTOR);
                break;
            case R.id.Add_Distributor_submit_fl:
                try {
                    String Role = "";
                    JSONArray jsonArray = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.LoginType));
                    for (int i = 0; i < jsonArray.length(); i++) {
                        JSONObject jsonObject1 = jsonArray.getJSONObject(i);
                        if (jsonObject.has("LicUserRole") && jsonObject1.getString("Code").equalsIgnoreCase(jsonObject.getString("LicUserRole"))) {
                            Role = jsonObject1.getString("Code");
                            break;
                        }
                    }
                    if (Role.equalsIgnoreCase("A") && jsonObject.has("LicDLNo") && jsonObject.getString("LicDLNo").equalsIgnoreCase(""))
                        Toast.makeText(getActivity(), "Please first complete your profile before mapping with distributor.", Toast.LENGTH_LONG).show();
                    else
                        submitRequestForDistributor();
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                break;
        }
    }

    private void submitRequestForDistributor() {
        try {
            JSONArray jsonArray = new JSONArray();
            for (LoginModel item : mSelectedItemList) {
                JSONObject mJsonObject = new JSONObject();
                jsonArray.put(mJsonObject.put("id", item.getId()));
            }
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("CUID", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("ids", jsonArray);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(),
                    getApiClientByPost().submitRequestForDistributor(String.valueOf(jsonObject)),
                    Constant.SEND_REQUEST_FOR_DISTRIBUTOR, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    private void GoToCommonListingFragment(View view, int codeRequest, String from) {
    /*    CommonListingFragment fragment = new CommonListingFragment();
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, from);
        fragment.setArguments(bundle);
        addFragment(fragment, true);*/

        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, from);
        Navigation.findNavController(view).navigate(R.id.nav_common_listing, bundle);
    }

    public void getSearchedData(Intent data) {
        Distributor = data.getExtras().containsKey("data") ? data.getStringExtra("data") : "";
        distributor_id = data.getExtras().containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
        distributor_Lic_No = data.getExtras().containsKey("LicNo") ? data.getStringExtra("LicNo") : "";
        distributor_Mobile = !data.getStringExtra("Mobile").equalsIgnoreCase("N/A") ? data.getStringExtra("Mobile") : "";
        search_dis_tv.setText(Distributor);
    }


    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 0) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.SEND_REQUEST_FOR_DISTRIBUTOR:
                    if (jsonObject.getBoolean("status")) {
                        search_dis_tv.setText(Distributor);
                        submitBtn.setBackgroundColor(getResources().getColor(R.color.grey));
                        submitBtn.setClickable(false);
                        distributor_list.removeAll(mSelectedItemList);
                        mSelectedItemList.clear();
                        rv_distributor_listing.setAdapter(new CommonRowAdapter(RequestDistributorFragment.this, distributor_list, Constant.DISTRIBUTOR, ""));
                        Toast.makeText(getActivity(), jsonObject.getString("message"), Toast.LENGTH_SHORT).show();
                    } else
                        Toast.makeText(getActivity(), jsonObject.getString("message"), Toast.LENGTH_SHORT).show();
                    break;
                case Constant.DISTRIBUTOR:
                    try {
                        JSONObject jsonObject2 = new JSONObject(result);
                        if (jsonObject2.has("Distributor")) {
                            setDistributorListingAdapter(jsonObject2.getJSONArray("Distributor"));
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        if (distributor_list.size() == 0)
                            noRecordTV.setVisibility(View.VISIBLE);
                        else noRecordTV.setVisibility(View.GONE);
                    }
                    break;

            }

        }
    }

    private void setDistributorListingAdapter(JSONArray jsonArray) {
        try {
            if (distributor_list != null && distributor_list.size() > 0)
                distributor_list.clear();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                LoginModel loginModel = new LoginModel();
                loginModel.setId(jsonObject.getString("id"));
                loginModel.setCountry_name(jsonObject.getString("Name"));
                loginModel.setCountry_id(jsonObject.getString("Code"));
//                loginModel.setEmail(!jsonObject.getString("Email").equalsIgnoreCase("") ? jsonObject.getString("Email") : "N/A");
                String emailId = ReckonUtils.getJsonCheckedString(jsonObject, "Email", "");
                loginModel.setEmail(ReckonUtils.isValidEmail(emailId)?emailId:"");
                loginModel.setLicNo(jsonObject.getString("LicNo"));
                loginModel.setMobile(!jsonObject.getString("Mobile").equalsIgnoreCase("") ? jsonObject.getString("Mobile") : "");
                loginModel.setAdd1(!jsonObject.getString("Add1").equalsIgnoreCase("") ? jsonObject.getString("Add1") : "N/A");
                loginModel.setShowStock(jsonObject.has("ShowStock") ? jsonObject.getString("ShowStock") : "0");
                loginModel.setRateType(jsonObject.has("RateType") ? jsonObject.getString("RateType") : "");
                loginModel.setCity(jsonObject.has("City") ? jsonObject.getString("City") : "");
                distributor_list.add(loginModel);
            }
            if (distributor_list.size() == 0)
                noRecordTV.setVisibility(View.VISIBLE);
            else noRecordTV.setVisibility(View.GONE);
            rv_distributor_listing.setVisibility(View.VISIBLE);
            rv_distributor_listing.setAdapter(new CommonRowAdapter(RequestDistributorFragment.this, distributor_list, Constant.DISTRIBUTOR, ""));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void getSelectedDistributorItemData(LoginModel loginModel, ArrayList<LoginModel> selectedItemList) {
        mSelectedItemList = selectedItemList;
        if (selectedItemList != null && selectedItemList.size() > 0) {
            submitBtn.setBackgroundColor(getResources().getColor(R.color.btn_color));
            submitBtn.setClickable(true);
        } else {
            submitBtn.setBackgroundColor(getResources().getColor(R.color.grey));
            submitBtn.setClickable(false);
        }

    }
}
