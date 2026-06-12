package com.reckon.reckonorders.Fragment.Account;
/*
 * Created by Manvendra Kumar Singh on 21/12/2018.
 */

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.Utils.StartActivityUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import butterknife.Unbinder;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_CITY_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_COUNTRY_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_STATE_FILTER;

public class ProfileFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;

    @BindView(R.id.business_type_spinner)
    Spinner business_type_spinner;
    @BindView(R.id.countryTV)
    TextView countryTV;
    @BindView(R.id.stateTV)
    TextView stateTV;
    @BindView(R.id.cityTV)
    TextView cityTV;
    @BindView(R.id.fragmentRegister_licNo_txt)
    TextView _licNo_txt;
    @BindView(R.id.fragmentRegister_ed_gstin)
    EditText _ed_gstin;
    @BindView(R.id.fragmentRegister_edtName)
    EditText _edtName;
    @BindView(R.id.fragmentRegister_edtAddress1)
    EditText _edtAddress1;
    @BindView(R.id.fragmentRegister_edtAddress2)
    EditText _edtAddress2;
    @BindView(R.id.fragmentRegister_edtPinCode)
    EditText _edtPinCode;
    @BindView(R.id.fragmentRegister_edtEmail)
    EditText _edtEmail;
    @BindView(R.id.fragmentRegister_edtTelephoneNumber)
    EditText _edtTelephoneNumber;
    @BindView(R.id.fragmentRegister_edtDrugLicense)
    EditText _edtDrugLicense;
    @BindView(R.id.actionbar_imgLogout)
    LinearLayout _imgLogout;
    @BindView(R.id.actionbar_imgRefresh)
    LinearLayout actionbar_imgRefresh;
    @BindView(R.id.fragmentLogin_txtLicNo)
    TextView fragmentLogin_txtLicNo;
    @BindView(R.id.licence_ll)
    LinearLayout licence_ll;
    @BindView(R.id.fragmentProfile_role)
    TextView fragmentProfile_role;

    private String name = "";
    private String business_id;
    private Unbinder unbinder;
    private ArrayList<String> Business_name = new ArrayList(), Business_id = new ArrayList();
    private String Country_id, State_id, City_id;
    private String Country_Code;
    private String role = "";
    private String business_type = "";

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_profile, container, false);
        unbinder = ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        setTitle(view, getString(R.string.my_profile).toUpperCase());
        KeyboardUtils.setupUI(view, getActivity());
        setupHomeButton(view);
        setupRefreshButton(view);
        setupUI();

        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        _imgLogout.setVisibility(View.VISIBLE);
        actionbar_imgRefresh.setVisibility(View.VISIBLE);
        try {
            Business_id.clear();
            Business_name.clear();
            String string = SharedPrefUtils.getList(getActivity(), Constant.BUSINESS_TYPE_LIST);
            JSONArray jsonArray = new JSONArray(string);
            Business_name.add("Select business type");
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                Business_name.add(jsonObject.getString("Code1"));
                Business_id.add(jsonObject.getString("Code"));
            }

            business_type_spinner.setAdapter(new ArrayAdapter<>(requireActivity(), R.layout.spinner_layout, R.id.text1, Business_name));
            business_type_spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    if (position != 0) {
                        business_id = Business_id.get(position - 1);
                    }
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {
                }
            });
            setProfileData();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setProfileData() {
        try {
            JSONArray jsonArray1 = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.USER_DATA_LIST));
            JSONObject jsonObject = jsonArray1.getJSONObject(0);
            _licNo_txt.setText(jsonObject.has("LicNo") ? jsonObject.getString("LicNo") : "");
            _edtEmail.setText(jsonObject.has("LicEmail") ? jsonObject.getString("LicEmail") : "");
            Country_id = jsonObject.has("CountryId") ? jsonObject.getString("CountryId") : "";
            countryTV.setText(jsonObject.has("CountryName") ? jsonObject.getString("CountryName") : "");
            stateTV.setText(jsonObject.has("StateName") ? jsonObject.getString("StateName") : "");
            State_id = jsonObject.has("StateId") ? jsonObject.getString("StateId") : "";
            cityTV.setText(jsonObject.has("CityName") ? jsonObject.getString("CityName") : "");
            City_id = jsonObject.has("CityId") ? jsonObject.getString("CityId") : "";
            business_id = jsonObject.has("BussinessType") ? jsonObject.getString("BussinessType") : "";
            _edtPinCode.setText(jsonObject.has("LicPin") ? jsonObject.getString("LicPin") : "");
            _edtName.setText(jsonObject.has("LicName") ? jsonObject.getString("LicName") : "");
            Country_Code = jsonObject.has("CountryCode") ? jsonObject.getString("CountryCode") : "";
            _ed_gstin.setText(jsonObject.has("LicGstNo") ? jsonObject.getString("LicGstNo") : "");
            _edtDrugLicense.setText(jsonObject.has("LicDLNo") ? jsonObject.getString("LicDLNo") : "");
            _edtAddress1.setText(jsonObject.has("LicAdd1") ? jsonObject.getString("LicAdd1") : "");
            _edtAddress2.setText(jsonObject.has("LicAdd2") ? jsonObject.getString("LicAdd2") : "");
            _edtTelephoneNumber.setText(jsonObject.has("LicMobile") ? jsonObject.getString("LicMobile") : "");

            for (int j = 0; j < Business_id.size(); j++) {
                if (Business_id.get(j).equalsIgnoreCase(jsonObject.has("BussinessType") ? jsonObject.getString("BussinessType") : "")) {
                    business_type_spinner.setSelection(j + 1);
                    business_type = jsonObject.getString("BussinessType");
                    break;
                }
            }
            if (jsonObject.has("LicUserRole") && jsonObject.getString("LicUserRole").equalsIgnoreCase("B")) {
                licence_ll.setVisibility(View.VISIBLE);
                fragmentLogin_txtLicNo.setText(jsonObject.has("LicFirmLicNo") ? jsonObject.getString("LicFirmLicNo") : "");
            }

            String string = SharedPrefUtils.getList(getActivity(), Constant.LoginType);
            JSONArray jsonArray = new JSONArray(string);
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject1 = jsonArray.getJSONObject(i);
                if (jsonObject.has("LicUserRole") && jsonObject1.getString("Code").equalsIgnoreCase(jsonObject.getString("LicUserRole"))) {
                    fragmentProfile_role.setText(jsonObject1.getString("Code1"));
                    role = jsonObject1.getString("Code");
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @OnClick({R.id.select_country_rl, R.id.select_city_rl, R.id.select_state_rl, R.id.fragmentRegister_frmUpdateAccount, R.id.actionbar_imgLogout})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.select_country_rl:
                stateTV.setText("");
                cityTV.setText("");
                GoToCommonListingFragment(CODE_REQUEST_COUNTRY_FILTER, Constant.COUNTRY);
                break;
            case R.id.select_state_rl:
                if (!countryTV.getText().toString().equalsIgnoreCase("")) {
                    cityTV.setText("");
                    GoToCommonListingFragment(CODE_REQUEST_STATE_FILTER, Constant.STATE);
                } else {
                    Toast.makeText(getActivity(), getResources().getString(R.string.please_select_country), Toast.LENGTH_SHORT).show();
                }
                break;
            case R.id.select_city_rl:
                if (countryTV.getText().toString().equalsIgnoreCase("") && stateTV.getText().toString().equalsIgnoreCase("")) {
                    Toast.makeText(getActivity(), getResources().getString(R.string.please_select_country_state), Toast.LENGTH_SHORT).show();
                } else if (stateTV.getText().toString().equalsIgnoreCase("")) {
                    Toast.makeText(getActivity(), getResources().getString(R.string.please_select_state), Toast.LENGTH_SHORT).show();
                } else {
                    GoToCommonListingFragment(CODE_REQUEST_CITY_FILTER, Constant.CITY);
                }
                break;
            case R.id.actionbar_imgLogout:
                logoutPopUp();
                break;
            case R.id.fragmentRegister_frmUpdateAccount:
                if (role.equalsIgnoreCase("A")) {
                    if (checkValidInput())
                        postUpdateProfile();
                } else postUpdateProfile();

                break;

        }


    }

    private boolean checkValidInput() {
        String strError = "";
        if (TextUtils.isEmpty(_ed_gstin.getText()))
            strError = getString(R.string.error_input_gstin);
        else if (TextUtils.isEmpty(_edtName.getText()))
            strError = getString(R.string.plz_enter_firm_name);
        else if (TextUtils.isEmpty(_edtAddress1.getText()))
            strError = getString(R.string.plz_enter_add);
        else if (TextUtils.isEmpty(stateTV.getText()))
            strError = getString(R.string.please_select_state);
        else if (TextUtils.isEmpty(cityTV.getText()))
            strError = getString(R.string.please_select_city);
        else if (business_type.equalsIgnoreCase("A") && TextUtils.isEmpty(_edtDrugLicense.getText()))
            strError = getString(R.string.plz_enter_drug);
        if (TextUtils.isEmpty(strError))
            return true;
        else {
            ReckonUtils.showAlert(getActivity(), getString(R.string.error), strError, null);
            return false;
        }
    }

    private void postUpdateProfile() {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postUpdateProfile(requireActivity().getPackageName(),business_id, _licNo_txt.getText().toString(),
                    Country_Code, _edtName.getText().toString(), _edtAddress1.getText().toString(), _edtAddress2.getText().toString(), "", _edtEmail.getText().toString(),
                    _edtDrugLicense.getText().toString(), _ed_gstin.getText().toString(), _edtPinCode.getText().toString(), City_id, "", _edtTelephoneNumber.getText().toString(), role, fragmentLogin_txtLicNo.getText().toString()), Constant.UPDATE_PROFILE, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void logoutPopUp() {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(getActivity());
        alertDialogBuilder.setMessage("Do you want to Logout?");
        alertDialogBuilder.setPositiveButton("OK",
                new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface arg0, int arg1) {
                        resetFieldAfterLogout();
                    }
                });

        alertDialogBuilder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {

            }
        });

        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(getResources().getColor(R.color.black));
        alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(getResources().getColor(R.color.black));
    }

    private void resetFieldAfterLogout() {
        SharedPrefUtils.removeLogout(getActivity());
        StartActivityUtils.toAccount(getActivity());
        getActivity().overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        getActivity().finish();
    }

    private void GoToCommonListingFragment(int codeRequest, String from) {
        CommonListingFragment fragment = new CommonListingFragment();
        fragment.setTargetFragment(this, codeRequest);
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, from);
        fragment.setArguments(bundle);
        addFragment(fragment, true);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        switch (requestCode) {
            case CODE_REQUEST_COUNTRY_FILTER:
                String Country = Objects.requireNonNull(data.getExtras()).containsKey("data") ? data.getStringExtra("data") : "";
                Country_id = data.getExtras().containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
                countryTV.setText(Country);
                break;
            case CODE_REQUEST_STATE_FILTER:
                String State = Objects.requireNonNull(data.getExtras()).containsKey("data") ? data.getStringExtra("data") : "";
                State_id = data.getExtras().containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
                stateTV.setText(State);
                break;
            case CODE_REQUEST_CITY_FILTER:
                String city = Objects.requireNonNull(data.getExtras()).containsKey("data") ? data.getStringExtra("data") : "";
                City_id = data.getExtras().containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
                cityTV.setText(city);
                break;
        }
    }


    @Override
    public void onDestroyView() {
        super.onDestroyView();
        unbinder.unbind();
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        JSONObject jsonObject = new JSONObject(result);
        if (action.equalsIgnoreCase(Constant.UPDATE_PROFILE)) {
            if (jsonObject.has("Status") && jsonObject.getString("Status").equalsIgnoreCase("false"))
                Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
            else {
                ArrayList<JSONObject> userDataList = new ArrayList<>();
                userDataList.add(jsonObject);
                SharedPrefUtils.setString(getActivity(), Constant.COUNTRY_CODE, jsonObject.has("CountryCode") ? jsonObject.getString("CountryCode") : "");
                SharedPrefUtils.setList(getActivity(), Constant.USER_DATA_LIST, userDataList);//TODO: User Data will be same as login response data
                setProfileData();
                Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
            }
        }
    }
}
