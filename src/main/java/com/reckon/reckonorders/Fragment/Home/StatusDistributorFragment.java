package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.PopupWindow;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Adapter.CommonRowAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Interfaces.ItemListener;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.SelectSinglePopup;
import com.reckon.reckonorders.Others.database.DataHardCode;
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
import butterknife.Unbinder;

public class StatusDistributorFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    @BindView(R.id.rv_distributor_listing)
    RecyclerView rv_distributor_listing;
    @BindView(R.id.noRecordTV)
    LinearLayout noRecordTV;
    @BindView(R.id.search_loc_et)
    EditText search_loc_et;
    @BindView(R.id.fragmentMyVendor_imgSortVendors)
    ImageView imgSortVendors;
    private ArrayList<LoginModel> distributor_list = new ArrayList();
    private ArrayList<LoginModel> new_distributor_list = new ArrayList();
    private SelectSinglePopup popupSortVendors;
    private List<SelectionModel> dataSortDistributors = new ArrayList<>();
    private SelectionModel selectedSortVendors;
    @BindView(R.id.fragmentMyVendor_tvCount)
    TextView tvCount;
    private Unbinder unbinder;

    private int page, maxPage, sortBy = 1;

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_status, container, false);
        unbinder = ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        getBundle();
        setupUI();
        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        try {
            selectedSortVendors = new SelectionModel(1, "All");
            rv_distributor_listing.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
            getDistributorList("", "");

            search_loc_et.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {
                }

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                    if (s.length() == 0) {
                        if (distributor_list.size() == 0)
                            noRecordTV.setVisibility(View.VISIBLE);
                        else noRecordTV.setVisibility(View.GONE);
                        rv_distributor_listing.setAdapter(new CommonRowAdapter(StatusDistributorFragment.this, distributor_list, Constant.DISTRIBUTOR_STATUS));
                    } else {
                        if (new_distributor_list.size() > 0)
                            new_distributor_list.clear();

                        if (distributor_list.size() > 0) {
                            for (int i = 0; i < distributor_list.size(); i++) {
                                if (distributor_list.get(i).getCountry_name().toLowerCase().contains(s.toString().toLowerCase())) {
                                    LoginModel loginModel = new LoginModel();
                                    loginModel.setCountry_name(distributor_list.get(i).getCountry_name());
                                    loginModel.setCountry_id(distributor_list.get(i).getCountry_id());
                                    loginModel.setMobile(distributor_list.get(i).getMobile());
                                    loginModel.setStatus(distributor_list.get(i).getStatus());
                                    loginModel.setEmail(distributor_list.get(i).getEmail());
                                    loginModel.setLicNo(distributor_list.get(i).getLicNo());
                                    loginModel.setAdd1(distributor_list.get(i).getAdd1());
                                    loginModel.setLock(distributor_list.get(i).getLock());
                                    new_distributor_list.add(loginModel);
                                }
                                if (new_distributor_list.size() == 0)
                                    noRecordTV.setVisibility(View.VISIBLE);
                                else noRecordTV.setVisibility(View.GONE);

                                rv_distributor_listing.setAdapter(new CommonRowAdapter(StatusDistributorFragment.this, new_distributor_list, Constant.DISTRIBUTOR_STATUS));
                            }
                        }
                    }
                }

                @Override
                public void afterTextChanged(Editable s) {
                }
            });


        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
        }
    }

    @OnClick({})
    public void onClick(View view) {
        switch (view.getId()) {
        }
    }

    @OnClick(R.id.fragmentMyVendor_frmSortVendor)
    public void onViewClicked(View view) {
        imgSortVendors.setImageResource(R.drawable.ic_select_up);
        createPopupSortVendors();
        popupSortVendors.showAsDropDown(view, 0, 1);
    }

    private void getDistributorList(String isStatusFilter, String isLockFilter) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lCityCode", "");
            jsonObject.put("lMapType", "MAP");
            jsonObject.put("lStatus", isStatusFilter);
            jsonObject.put("lLock", isLockFilter);
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
                loginModel.setStatus(jsonObject.getString("Status") != null ? jsonObject.getString("Status") : "0");
                loginModel.setLock(jsonObject.getString("Lock") != null ? jsonObject.getString("Lock") : "0");
                loginModel.setCity(jsonObject.has("City") ? jsonObject.getString("City") : "");
                distributor_list.add(loginModel);
            }
            if (distributor_list.size() == 0)
                noRecordTV.setVisibility(View.VISIBLE);
            else noRecordTV.setVisibility(View.GONE);
            rv_distributor_listing.setAdapter(new CommonRowAdapter(StatusDistributorFragment.this, distributor_list, Constant.DISTRIBUTOR_STATUS));
            tvCount.setText(selectedSortVendors.getName() + " (" + distributor_list.size() + ")");

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void createPopupSortVendors() {
        if (popupSortVendors == null) {
            dataSortDistributors = DataHardCode.getStatusListSortDistributors();
            popupSortVendors = new SelectSinglePopup(getActivity(), dataSortDistributors, false);
            popupSortVendors.setOnItemListener(new ItemListener() {
                @Override
                public void onItemClicked(int position) {
                    if (position < dataSortDistributors.size()) {
                        selectedSortVendors = dataSortDistributors.get(position);
                        tvCount.setText(position != 0 ? selectedSortVendors.getName() : "All (" + distributor_list.size() + ")");//data.size()
                        sortBy = dataSortDistributors.get(position).getId();
                        switch (sortBy) {
                            case 1:
                                getDistributorList("", "");
                                break;
                            case 2:
                                getDistributorList("1", "0");
                                break;
                            case 3:
                                getDistributorList("0", "0");
                                break;
                            case 4:
                                getDistributorList("", "1");
                                break;
                        }
                    }
                }
            });
            popupSortVendors.setOnDismissListener(new PopupWindow.OnDismissListener() {
                @Override
                public void onDismiss() {
                    imgSortVendors.setImageResource(R.drawable.ic_select_down);
                }
            });
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        search_loc_et.getText().clear();
        JSONObject jsonObject = new JSONObject(result);
        switch (action) {
            case Constant.DISTRIBUTOR:
                try {
                    JSONArray jsonArray2 = jsonObject.getJSONArray("Distributor");
                    setDistributorListingAdapter(jsonArray2);
                } catch (Exception e) {
                    e.printStackTrace();
                    if (distributor_list.size() == 0)
                        noRecordTV.setVisibility(View.VISIBLE);
                    else noRecordTV.setVisibility(View.GONE);
                }

                break;
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        unbinder.unbind();
    }

}
