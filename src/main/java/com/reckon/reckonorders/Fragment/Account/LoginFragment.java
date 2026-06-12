package com.reckon.reckonorders.Fragment.Account;

import static android.app.Activity.RESULT_OK;
import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Utils.LocalStorage.KEY_USER;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.InputFilter;
import android.text.InputType;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.content.res.ResourcesCompat;

import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.auth.api.phone.SmsRetrieverClient;
import com.google.android.gms.tasks.Task;
import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;
import com.reckon.reckonorders.Adapter.CountryPickerAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.ImageModel;
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.IncomingSms;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.Profile;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.ResponseFromRegistration;
import com.reckon.reckonorders.NewDesign.RegisterFragmentWithStep;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.ConfirmDialog;
import com.reckon.reckonorders.Others.Dialog.CountryPickerDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.Utils.StartActivityUtils;
import com.reckon.reckonorders.databinding.ActivityLoginBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class LoginFragment extends BaseFragment implements RetrofitCallBackListener, CountryPickerAdapter.RecyclerViewItemClickListener {
    private static final int CONSENT_CODE = 666;
    private RetrofitCallBackListener retrofitCallBackListener;
    ActivityLoginBinding loginBinding;
    ArrayList<ImageModel> encodedImageGSTN = new ArrayList<>();
    ArrayList<ImageModel> encodedImageFL = new ArrayList<>();
    ArrayList<ImageModel> encodedImageDL = new ArrayList<>();
    private ConfirmDialog confirmDialog;
    private String Mobile_Number = "", Country_Code = "91";
    private boolean flag, createPassword = true;
    private IncomingSms mySMSBroadcastReceiver;
    private String otpType;
    SmsRetrieverClient client;
    boolean passwordShow = false;
    LocalStorage localStorage;
    private boolean isSalesMan;
    private AlertDialog alertDialog = null;
    private boolean gotoDashboard = false;
    private CountryPickerDialog countryPickerDialog;

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        loginBinding = ActivityLoginBinding.inflate(inflater, container, false);
        localStorage = new LocalStorage(requireActivity());
        loginBinding.AppLogo.setImageResource(ReckonUtils.getAppIcon(requireActivity()));
        loginBinding.eyeImage.setOnClickListener(v -> {
            if (passwordShow) {
                passwordShow = false;
                loginBinding.edtPassword.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
                loginBinding.eyeImage.setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.eye, null));
            } else {
                passwordShow = true;
                loginBinding.edtPassword.setInputType(InputType.TYPE_CLASS_TEXT);
                loginBinding.eyeImage.setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.hidden, null));
            }
            loginBinding.edtPassword.setSelection(loginBinding.edtPassword.getText().length());
        });
        setTitle(loginBinding.getRoot(), getString(R.string.login).toUpperCase());
        String versionName = getString(R.string.version) + " - " + SharedPrefUtils.getVersionName(requireActivity()) + "(" + SharedPrefUtils.getVersionCode(requireActivity()) + ")";
        loginBinding.versionNameTv.setText(versionName);
        retrofitCallBackListener = this;
        loginBinding.ccp.setOnCountryChangeListener(() -> {
            Country_Code = loginBinding.ccp.getSelectedCountryCode();
            loginBinding.countryCodeText.setText("+" + Country_Code);
        });
        checkPermissionAndRequest();
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        loginBinding.rlSignUpView.setVisibility(isSalesMan ? View.GONE : View.VISIBLE);
        loginBinding.etLicNo.setFilters(new InputFilter[]{new InputFilter.AllCaps()});
        loginBinding.etLicNo.setVisibility(isSalesMan ? View.VISIBLE : View.GONE);
        createPassword = !isSalesMan;
        if (!getCountryListData().isEmpty()) {
            loginBinding.edtMobile.setFilters(new InputFilter[]{new InputFilter.LengthFilter(getCountryListData().get(0).getMobileLength())});
            Country_Code = getCountryListData().get(0).getMobilePrefix();
            loginBinding.countryCodeText.setText("+" + getCountryListData().get(0).getMobilePrefix());
        }
        loginBinding.selectCountryLl.setOnClickListener(view -> {

            countryPickerDialog = new CountryPickerDialog(requireActivity(), new CountryPickerAdapter(getCountryListData(), this));
            countryPickerDialog.show();
            countryPickerDialog.setCanceledOnTouchOutside(false);
        });

        return loginBinding.getRoot();
    }


    @Override
    public void onViewCreated(View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        loginBinding.loginButton.setOnClickListener(v -> {
            if (checkValidInput())
                postLogin(loginBinding.edtMobile.getText().toString(), loginBinding.edtPassword.getText().toString());
        });
        loginBinding.tvSignUp.setOnClickListener(v -> {
            flag = false;
            SendOTPDialog(getActivity(), getString(R.string.create_new_account), getString(R.string.enter_your_mobile_number_to_create), "0");
        });
        loginBinding.tvForgotPassword.setOnClickListener(v -> {
            flag = true;
            if (isSalesMan)
                SendOTPDialog(getActivity(), getString(R.string.create_password), "", "1");
            else
                SendOTPDialog(getActivity(), getString(R.string.forgot_your_password), getString(R.string.enter_your_mobile_number_to_forgot), "1");
        });
    }

    private void checkPermissionAndRequest() {
        Dexter.withContext(getActivity())
                .withPermissions(
                        Manifest.permission.READ_SMS,
                        Manifest.permission.RECEIVE_SMS
                ).withListener(new MultiplePermissionsListener() {
                    @Override
                    public void onPermissionsChecked(MultiplePermissionsReport report) {/* ... */}

                    @Override
                    public void onPermissionRationaleShouldBeShown(List<PermissionRequest> permissions, PermissionToken token) {/* ... */}
                }).check();
    }

    private void postLogin(String email, String password) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("LicNo", loginBinding.etLicNo.getText().toString());
            jsonObject.put("MobileNo", email);
            jsonObject.put("Password", password);
            jsonObject.put("CountryCode", Country_Code);
            jsonObject.put("app_role", getLicDetails() != null ? getLicDetails().getRole() : Constant.RETAILER);
            jsonObject.put("LoginDeviceId", SharedPrefUtils.getString(getActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("lRole", getLicDetails() != null ? getLicDetails().getRole() : Constant.RETAILER);
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postLogin(String.valueOf(jsonObject)), Constant.LOGIN, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public boolean checkValidInput() {
        String strError = "";
        if (isSalesMan && loginBinding.etLicNo.getText().toString().isEmpty())
            strError = getString(R.string.empty_lic_no);
        else if (isSalesMan && (loginBinding.etLicNo.getText().length() < 4 || loginBinding.etLicNo.getText().length() > 20))
            strError = getString(R.string.lic_no_length_error);
        else if (loginBinding.edtMobile.getText().toString().isEmpty())
            strError = getString(R.string.empty_mobile);
        else if (loginBinding.edtMobile.getText().length() < 8 || loginBinding.edtMobile.getText().length() > 12)
            strError = getString(R.string.mobile_length_error);
        else if (createPassword && TextUtils.isEmpty(loginBinding.edtPassword.getText()))
            strError = getString(R.string.error_empty_pass);
        else if (createPassword && loginBinding.edtPassword.getText().length() < 6)
            strError = getString(R.string.error_length_password);
        if (TextUtils.isEmpty(strError))//ONS92894
            return true;
        else {
            ReckonUtils.showAlert(getActivity(), getString(R.string.error), strError, null);
            return false;
        }
    }

    private void SendOTPDialog(final Context context, final String title, String content, final String OTPType) {
        otpType = OTPType;
        confirmDialog = new ConfirmDialog(context, title, content);

        if (title.equalsIgnoreCase(getResources().getString(R.string.forgot_your_password)))
            confirmDialog.setTextConfirm("Send Request");
        else if (title.equalsIgnoreCase(getResources().getString(R.string.create_password))) {
            confirmDialog.setTextConfirm("Submit");
        } else {
            confirmDialog.setTextConfirm("Create");
        }
        confirmDialog.setOnItemClickListener(() -> {
            startSMSRetrieverClient();
            try {
                if (title.equalsIgnoreCase(getResources().getString(R.string.create_password))) {
                    String _edtPassword = confirmDialog._edtPassword.getText().toString();
                    String _edtConfirmPass = confirmDialog._edtConfirmPass.getText().toString();
                    if (_edtPassword.equalsIgnoreCase(""))
                        Toast.makeText(getActivity(), getString(R.string.error_new_password_empty), Toast.LENGTH_LONG).show();
                    else if (_edtPassword.length() < 6)
                        Toast.makeText(getActivity(), getString(R.string.error_length_password), Toast.LENGTH_LONG).show();
                    else if (_edtConfirmPass.equalsIgnoreCase(""))
                        Toast.makeText(getActivity(), getString(R.string.error_confirm_password_empty), Toast.LENGTH_LONG).show();
                    else if (!_edtPassword.equalsIgnoreCase(_edtConfirmPass))
                        Toast.makeText(getActivity(), getString(R.string.error_confirm_password), Toast.LENGTH_LONG).show();
                    else
                        new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postCreatePassword(requireActivity().getPackageName(), Mobile_Number, Country_Code, _edtPassword, "", "1"), Constant.CREATE_PASSWORD, true);
                } else {
                    gotoDashboard = false;
                    Mobile_Number = confirmDialog.tvmobileNumber.getText().toString();
                    Country_Code = confirmDialog.countryCodeAndroid;
                    if (!Mobile_Number.equalsIgnoreCase("") && !(Mobile_Number.length() < 10)) {
                        new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().sendOtp(requireActivity().getPackageName(), Mobile_Number, Country_Code, OTPType), Constant.SEND_OTP, true);
                    } else
                        Toast.makeText(getActivity(), "Please enter your mobile number", Toast.LENGTH_LONG).show();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
        confirmDialog.show();
    }

    private void VerifyOTPDialog(final Context context, String title, String content) {
        confirmDialog = new ConfirmDialog(context, title, content);
        confirmDialog.setTextConfirm("Verify");
        try {
            if (confirmDialog != null && !confirmDialog.ed_OTP.getText().toString().isEmpty()) {
                new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().verifyOtp(String.valueOf(getVerifyOtpObj())), Constant.VERIFY_OTP, true);
            } else
                Toast.makeText(getActivity(), "Please enter OTP.", Toast.LENGTH_LONG).show();
        } catch (Exception e) {
            e.printStackTrace();
        }

        confirmDialog.setOnItemClickListener(() -> {
            confirmDialog.tvConfirm.setOnClickListener(v -> {
                try {
                    if (!confirmDialog.ed_OTP.getText().toString().equalsIgnoreCase("")) {
                        new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().verifyOtp(String.valueOf(getVerifyOtpObj())), Constant.VERIFY_OTP, true);
                    } else
                        Toast.makeText(getActivity(), "Please enter OTP.", Toast.LENGTH_LONG).show();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            });
            confirmDialog.resendbtn.setOnClickListener(v -> {
                try {
                    confirmDialog.resendbtn.setEnabled(false);
                    confirmDialog.resendbtn.setTextColor(getResources().getColor(R.color.red_wine, null));
                    if (!Mobile_Number.equalsIgnoreCase(""))
                        new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().sendOtp(requireActivity().getPackageName(), Mobile_Number, Country_Code, otpType), Constant.SEND_OTP, true);
                    else
                        Toast.makeText(getActivity(), "Please enter your mobile number", Toast.LENGTH_LONG).show();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            });
        });

        confirmDialog.show();

        if (confirmDialog.ed_OTP != null)
            confirmDialog.ed_OTP.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {

                }

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                    if (confirmDialog.ed_OTP.length() == 6) {
                        new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().verifyOtp(String.valueOf(getVerifyOtpObj())), Constant.VERIFY_OTP, true);
                    }
                }

                @Override
                public void afterTextChanged(Editable s) {

                }
            });
        confirmDialog.StartTimer();
    }

    JSONObject getVerifyOtpObj() {
        JSONObject object = new JSONObject();
        try {
            object.put("lApkName", requireActivity().getPackageName());
            object.put("MobileNo", Mobile_Number);
            object.put("OTP", confirmDialog.ed_OTP.getText().toString());
            object.put("CountryCode", Country_Code);
            object.put("device_id", SharedPrefUtils.getString(getActivity(), Constant.DEVICE_ID));
            object.put("device_name", ReckonUtils.getDeviceName());
            object.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            object.put("updatedevice_id", gotoDashboard);
            object.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            object.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            object.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            object.put("LicNo", loginBinding.etLicNo.getText().toString());
        } catch (Exception e) {
            e.printStackTrace();
        }
        return object;
    }


    private void startSMSRetrieverClient() {
        client = SmsRetriever.getClient(requireActivity());
        client.startSmsUserConsent(null);
        Task<Void> task = client.startSmsRetriever();
        task.addOnSuccessListener(aVoid -> {

        });
        task.addOnFailureListener(e -> {
            // Failed to start retriever, inspect Exception for more details
            // ...

            Toast.makeText(getActivity(), "sms retriever failed", Toast.LENGTH_LONG).show();
        });
    }

    private void registerBroadcastReceiver() {
        mySMSBroadcastReceiver = new IncomingSms();
        mySMSBroadcastReceiver.init(new IncomingSms.OTPReceiveListener() {
            @Override
            public void onOTPReceived(Intent intent) {
                startActivityForResult(intent, CONSENT_CODE);
            }

            @Override
            public void onOTPTimeOut() {

            }
        });
         /*  IntentFilter intentFilter = new IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION);
        requireActivity().registerReceiver(mySMSBroadcastReceiver, intentFilter, RECEIVER_EXPORTED, null);*/
    }

    private ResponseFromRegistration saveUserData(JSONObject jsonObject) {
        try {
            ResponseFromRegistration response = new ResponseFromRegistration();
            Profile profile = new Profile();
            String baseUrl = jsonObject.has("BaseUrl") ? jsonObject.getString("BaseUrl") : "";
            if (TextUtils.isEmpty(baseUrl))
                baseUrl = Constant.IMAGE_UPLOAD_URL;
            baseUrl = baseUrl + "/";
            JSONObject profileObject = jsonObject.has("Profile") ? jsonObject.getJSONObject("Profile") : new JSONObject();
            SharedPrefUtils.setString(getActivity(), Constant.USER_ID, ReckonUtils.getJsonCheckedString(profileObject, "MOBILENO", ""));
            SharedPrefUtils.setString(getActivity(), Constant.USER_ID_CU, ReckonUtils.getJsonCheckedString(profileObject, "CUID", ""));
            SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, ReckonUtils.getJsonCheckedString(jsonObject, "AcCode", ""));
            parseUserDetails(profile, profileObject, baseUrl);
            JSONArray storeArray = jsonObject.has("Store") && jsonObject.getJSONArray("Store").length() > 0 ? jsonObject.getJSONArray("Store") : new JSONArray();
            parseStoreData(storeArray);
            response.setBaseUrl(baseUrl);
            response.setId(Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "Id", "0")));
            response.setProfile(profile);
            return response;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }


    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && !result.isEmpty()) {
            JSONObject jsonObject = new JSONObject(result);
            if (action.equalsIgnoreCase(Constant.LOGIN)) {
                if (jsonObject.getString(Constant.STATUS).equalsIgnoreCase("false")) {
                    boolean alreadyLoggedIn = ReckonUtils.getJsonCheckedBoolean(jsonObject, "AllReadyLogin", false);
                    createPassword = jsonObject.optBoolean("CreatePasswd") && jsonObject.getBoolean("CreatePasswd");
                    if (alreadyLoggedIn) {
                        String uiMsg = ReckonUtils.getJsonCheckedString(jsonObject, "Message", "");
                        JSONObject profileObject = jsonObject.has("Profile") ? jsonObject.getJSONObject("Profile") : new JSONObject();
                        SharedPrefUtils.setString(getActivity(), Constant.USER_ID_CU, ReckonUtils.getJsonCheckedString(profileObject, "CUID", ""));
                        Mobile_Number = loginBinding.edtMobile.getText().toString();
                        gotoDashboard = true;
//                        goToDashboardPage(jsonObject, false);
                        showAlreadyLoggedInDialog(uiMsg);
                    } else if (createPassword) {
                        gotoDashboard = false;
                        Toast.makeText(getActivity(), jsonObject.getString(Constant.MESSAGE), Toast.LENGTH_LONG).show();
                        Mobile_Number = loginBinding.edtMobile.getText().toString();
//                        loginBinding.tvForgotPassword.setText(isSalesMan ? createPassword ? getResources().getString(R.string.create_password) : getResources().getString(R.string.forgot_password) : getResources().getString(R.string.forgot_password));
                        flag = true;
                        if (isSalesMan)
                            SendOTPDialog(getActivity(), getString(R.string.create_password), "", "1");
                    } else {
                        Toast.makeText(getActivity(), jsonObject.getString(Constant.MESSAGE), Toast.LENGTH_LONG).show();
                    }
                } else {
                    goToDashboardPage(jsonObject, true);
                }
            } else if (action.equalsIgnoreCase(Constant.SEND_OTP)) {
                if (jsonObject.getString(Constant.STATUS).equalsIgnoreCase("false")) {
                    Toast.makeText(getActivity(), jsonObject.getString(Constant.MESSAGE), Toast.LENGTH_LONG).show();
                } else {
                    Toast.makeText(getActivity(), jsonObject.getString(Constant.MESSAGE), Toast.LENGTH_LONG).show();
                    if (confirmDialog != null && confirmDialog.isShowing())
                        confirmDialog.dismiss();
                    VerifyOTPDialog(getActivity(), getString(R.string.mobile_verification), getString(R.string.enter_otp));
                }
            } else if (action.equalsIgnoreCase(Constant.VERIFY_OTP)) {
                if (jsonObject.getString(Constant.STATUS).equalsIgnoreCase("false"))
                    Toast.makeText(getActivity(), jsonObject.getString(Constant.MESSAGE), Toast.LENGTH_LONG).show();
                else {
                    if (jsonObject.getString(Constant.MESSAGE).equalsIgnoreCase(""))
                        Toast.makeText(getActivity(), getString(R.string.successfully_verified), Toast.LENGTH_LONG).show();
                    else
                        Toast.makeText(getActivity(), jsonObject.getString(Constant.MESSAGE), Toast.LENGTH_LONG).show();
                    if (confirmDialog != null && confirmDialog.isShowing())
                        confirmDialog.dismiss();
                    if (flag) {
                        SendOTPDialog(getActivity(), requireActivity().getResources().getString(R.string.create_password), "", "1");
                    } else if (gotoDashboard) {
                        goToDashboardPage(jsonObject, true);
                    } else {
                        addFragment(RegisterFragmentWithStep.newInstance(Mobile_Number, Country_Code), true);
                    }
                }
            } else if (action.equalsIgnoreCase(Constant.CREATE_PASSWORD)) {
                Toast.makeText(getActivity(), jsonObject.getString(Constant.MESSAGE), Toast.LENGTH_LONG).show();
                if (confirmDialog != null && confirmDialog.isShowing())
                    confirmDialog.dismiss();
            }
        }
    }

    private void goToDashboardPage(JSONObject jsonObject, boolean navigatePage) throws JSONException {
        if (jsonObject.has("LicNo")) {
            LicDetailObjectModel model = getLicDetails();
            if (model != null) {
                model.setLicno(ReckonUtils.getJsonCheckedString(jsonObject, "LicNo", ""));
                localStorage.setLicDetails(gson.toJson(model));
            }
        }
        createPassword = ReckonUtils.getJsonCheckedBoolean(jsonObject, "CreatePasswd", false);
        loginBinding.tvForgotPassword.setText(getResources().getString(R.string.forgot_password));
        SharedPrefUtils.setString(getActivity(), KEY_USER, gson.toJson(saveUserData(jsonObject)));
        SharedPrefUtils.setString(getActivity(), Constant.ACTIVATE, "1");
        if (navigatePage) {
            addFragment(new LoginFragment(), false);
            StartActivityUtils.toHome(getActivity(), "");
            requireActivity().overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        }

    }

    private void showAlreadyLoggedInDialog(String uiMsg) {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(requireActivity());
        alertDialogBuilder.setMessage(uiMsg);
        alertDialogBuilder.setPositiveButton("YES",
                (arg0, arg1) -> {
                    alertDialog.cancel();
//                    Toast.makeText(getActivity(), uiMsg, Toast.LENGTH_SHORT).show();
                    sendOTPForLoginInAnotherDevice();
                });
        alertDialogBuilder.setNegativeButton("NO", (dialog, which) -> {
            alertDialog.cancel();
        });
        alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(getResources().getColor(R.color.black));
        alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(getResources().getColor(R.color.black));
    }

    private void sendOTPForLoginInAnotherDevice() {
        gotoDashboard = true;
        new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().sendOtp(requireActivity().getPackageName(), loginBinding.edtMobile.getText().toString(), Country_Code, "1"), Constant.SEND_OTP, true);
    }

    @Override
    public void onStart() {
        super.onStart();
//        registerBroadcastReceiver();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
//        if (mySMSBroadcastReceiver != null)
//            requireActivity().unregisterReceiver(mySMSBroadcastReceiver);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == CONSENT_CODE) {
            if ((resultCode == RESULT_OK) && data != null) {
                String message = data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE);
                getOtpForMessage(message);
            }
        }
    }

    private void getOtpForMessage(String message) {
        Pattern pattern = Pattern.compile("(|^)\\d{6}");
        Matcher matcher = pattern.matcher(message);
        if (matcher.find()) {
            String val = matcher.group(0);
            confirmDialog.ed_OTP.setText(val);
        }
    }

    @Override
    public void clickOnItem(LoginModel data) {
        Country_Code = data.getMobilePrefix();
        loginBinding.countryCodeText.setText("+" + data.getMobilePrefix());
        loginBinding.edtMobile.setFilters(new InputFilter[]{new InputFilter.LengthFilter(data.getMobileLength())});
        if (countryPickerDialog != null) {
            countryPickerDialog.dismiss();
        }
    }
}
