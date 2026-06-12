package com.reckon.reckonorders.Fragment.Account;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageView;
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
import com.reckon.reckonorders.Others.view.MySpinner;
import com.reckon.reckonorders.Others.view.TextViewLinkHandler;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_CITY_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_COUNTRY_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_STATE_FILTER;

public class RegisterFragment extends BaseFragment implements RetrofitCallBackListener {
    private static final String ID = "id";
    private static final String NAME = "name";
    private RetrofitCallBackListener retrofitCallBackListener;

    @BindView(R.id.fragmentRegister_edtName)
    EditText edtName;
    @BindView(R.id.fragmentRegister_edtEmail)
    EditText edtEmail;
    @BindView(R.id.fragmentRegister_edtPassword)
    EditText edtPassword;
    @BindView(R.id.fragmentRegister_edtConfirmPass)
    EditText edtConfirmPass;
    @BindView(R.id.fragmentRegister_cbTermAndCondition)
    CheckBox cbTermAndCondition;
    @BindView(R.id.fragmentRegister_tvTermAndCondition)
    TextView tvTermAndCondition;
    @BindView(R.id.fragmentRegister_edtMobileNumber)
    TextView Mobile_Number;
    @BindView(R.id.fragmentRegister_edtPinCode)
    EditText _edtPinCode;
    @BindView(R.id.country_code_txt)
    TextView country_code_txt;
    @BindView(R.id.business_type_spinner)
    Spinner business_type_spinner;
    @BindView(R.id.role_type_spinner)
    MySpinner role_type_spinner;
    @BindView(R.id.countryTV)
    TextView countryTV;
    @BindView(R.id.stateTV)
    TextView stateTV;
    @BindView(R.id.cityTV)
    TextView cityTV;
    @BindView(R.id.fragmentLogin_edtLicNo)
    EditText fragmentLogin_edtLicNo;
    @BindView(R.id.select_img)
    ImageView select_img;
    @BindView(R.id.spinner_ll)
    LinearLayout spinner_ll;
    @BindView(R.id.select_tv)
    TextView select_tv;

    private int SelectedPos;
    private String Mobile_number, Country_Code;
    private String business_id, role_id;
    private ArrayList Business_name = new ArrayList(), Business_id = new ArrayList();
    private String Country_id, State_id, City_id;
    private boolean flag, check = false, check1 = false;
    private ArrayList<String> Login_name = new ArrayList(), loginType_id = new ArrayList();

    public static RegisterFragment newInstance(String id, String name) {
        Bundle args = new Bundle();
        args.putString(ID, id);
        args.putString(NAME, name);
        RegisterFragment fragment = new RegisterFragment();
        fragment.setArguments(args);
        return fragment;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_register, container, false);
        ButterKnife.bind(this, view);
        setTitle(view, getString(R.string.create_your_account).toUpperCase());
        retrofitCallBackListener = this;
        KeyboardUtils.setupUI(view, getActivity());
        setupBackButton(view);
        getBundle();
        setupUI();
        setUPInitialData();
        return view;
    }

    private void setUPInitialData() {
        try {
            loginType_id.clear();
            Login_name.clear();
            String string = SharedPrefUtils.getList(getActivity(), Constant.LoginType);
            JSONArray jsonArray = new JSONArray(string);
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                Login_name.add(jsonObject.getString("Code1"));
                loginType_id.add(jsonObject.getString("Code"));
            }
            role_type_spinner.setAdapter(new ArrayAdapter<>(requireActivity(), R.layout.spinner_layout, R.id.text1, Login_name));
            role_type_spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    role_id = loginType_id.get(position);
                    SelectedPos = position;
                    loginType_id.size();
                    if (role_id.equalsIgnoreCase(loginType_id.get(1)))
                        fragmentLogin_edtLicNo.setVisibility(View.VISIBLE);
                    else fragmentLogin_edtLicNo.setVisibility(View.GONE);
                    if (check) {
                        check = false;
                        spinner_ll.setVisibility(spinner_ll.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
                        select_img.setImageResource(spinner_ll.getVisibility() == View.GONE ? R.drawable.ic_select_down : R.drawable.ic_select_up);
                        select_tv.setText(Login_name.get(position));
                    }
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {
                    System.out.println(parent);
                }
            });
            role_type_spinner.setSelection(SelectedPos);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @OnClick({R.id.fragmentRegister_frmCreateAccount, R.id.select_type_ll, R.id.fragmentRegister_tvLogin, R.id.fragmentRegister_edtCategory, R.id.select_country_rl, R.id.select_city_rl, R.id.select_state_rl})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.fragmentRegister_frmCreateAccount:
                if (checkValidInput())
                    postRegistered(business_id, Mobile_Number.getText().toString(), edtName.getText().toString(), edtEmail.getText().toString(), edtPassword.getText().toString(), City_id, _edtPinCode.getText().toString());
                break;
            case R.id.fragmentRegister_tvLogin:
                getActivity().onBackPressed();
                break;
            case R.id.fragmentRegister_edtCategory:
                break;
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
            case R.id.select_type_ll:
                showSSelection();
                break;
        }
    }

    private void showSSelection() {
        if (spinner_ll.getVisibility() == View.GONE) {
            role_type_spinner.performClick();
        }
        spinner_ll.setVisibility(spinner_ll.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
        select_img.setImageResource(spinner_ll.getVisibility() == View.GONE ? R.drawable.ic_select_down : R.drawable.ic_select_up);
        check = spinner_ll.getVisibility() == View.VISIBLE;
    }

    private void postRegistered(String bussiness_type_id, String LicNo, String LicName, String LicEmail, String LicPassword, String LicCity, String LicPinCode) {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postRegistered(requireActivity().getPackageName(),bussiness_type_id, LicNo, LicName, LicEmail, LicPassword, LicCity, LicPinCode, Country_Code, role_id, fragmentLogin_edtLicNo.getText().toString()), Constant.SIGNUP, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
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
    private void setupUI() {
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
        } catch (Exception e) {
            e.printStackTrace();
        }
        country_code_txt.setText("+" + Country_Code);
        Mobile_Number.setText(Mobile_number);
        tvTermAndCondition.setMovementMethod(new TextViewLinkHandler() {
            @Override
            public void onLinkClick(String url) {
                Toast.makeText(getActivity(), "Terms & Condition functionality is under development", Toast.LENGTH_SHORT).show();
            }
        });
        business_type_spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                if (position != 0) {
                    business_id = Business_id.get(position - 1).toString();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });
    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            Mobile_number = bundle.containsKey(ID) ? bundle.getString(ID) : "";
            Country_Code = bundle.containsKey(NAME) ? bundle.getString(NAME) : "";
        }
    }


    public boolean checkValidInput() {
        String strError = "";
        if (business_id == null || business_id.equalsIgnoreCase(""))
            strError = getString(R.string.error_business_type);
        else if (TextUtils.isEmpty(edtName.getText()))
            strError = getString(R.string.error_input_name);
        else if (!TextUtils.isEmpty(edtEmail.getText()) && !ReckonUtils.isValidEmail(edtEmail.getText().toString()))
            strError = getString(R.string.error_format_email);
        else if (edtPassword.getText().length() < 6 || TextUtils.isEmpty(edtPassword.getText()))
            strError = getString(R.string.error_length_password);
        else if (TextUtils.isEmpty(edtConfirmPass.getText()))
            strError = getString(R.string.error_empty_confirm_pass);
        else if (!edtPassword.getText().toString().equals(edtConfirmPass.getText().toString()))
            strError = getString(R.string.error_confirm_password);
        else if (TextUtils.isEmpty(countryTV.getText()))
            strError = getString(R.string.please_select_country);
        else if (TextUtils.isEmpty(stateTV.getText()))
            strError = getString(R.string.please_select_state);
        else if (TextUtils.isEmpty(cityTV.getText()))
            strError = getString(R.string.please_select_city);
        else if (!cbTermAndCondition.isChecked())
            strError = getString(R.string.error_not_agree_terms);
        if (TextUtils.isEmpty(strError))
            return true;
        else {
            ReckonUtils.showAlert(getActivity(), getString(R.string.error), strError, null);
            return false;
        }
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
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        JSONObject jsonObject = new JSONObject(result);
        if (jsonObject.getString("Status").equalsIgnoreCase("true")) {
            Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
            addFragment(new LoginFragment(), false);
        }
    }
}
