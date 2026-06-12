package com.reckon.reckonorders.NewDesign;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_AREA_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_CITY_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_COUNTRY_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_STATE_FILTER;
import static com.reckon.reckonorders.Utils.LocalStorage.KEY_USER;
import static com.reckon.reckonorders.Utils.ReckonUtils.hasPermissions;
import static com.reckon.reckonorders.Utils.ReckonUtils.hasRationalPermissions;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;
import android.provider.Settings;
import android.text.Editable;
import android.text.InputFilter;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;
import com.reckon.reckonorders.Adapter.PhotosAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Fragment.Account.CommonListingFragment;
import com.reckon.reckonorders.Fragment.Account.LoginFragment;
import com.reckon.reckonorders.Model.ImageModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.Profile;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.ResponseFromRegistration;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.view.MySpinner;
import com.reckon.reckonorders.Others.view.TextViewLinkHandler;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import gun0912.tedimagepicker.builder.TedImagePicker;

@SuppressLint("NonConstantResourceId")
public class RegisterFragmentWithStep extends BaseFragment implements RetrofitCallBackListener {
    private static final String ID = "id";
    private static final String NAME = "name";
    ImageModel model;
    private RetrofitCallBackListener retrofitCallBackListener;
    @BindView(R.id.submit_button_tv)
    TextView submit_button_tv;
    @BindView(R.id.fragmentRegister_edtName)
    EditText edtName;
    @BindView(R.id.address1_et)
    EditText address1_et;
    @BindView(R.id.address2_et)
    EditText address2_et;
    @BindView(R.id._rvPhoto_FL)
    public RecyclerView _rvPhoto_FL;
    @BindView(R.id._rvPhoto_GSTN)
    public RecyclerView _rvPhoto_GSTN;
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
    @BindView(R.id.drugLicenseImageLayout)
    LinearLayout drugLicenseImageLayout;
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
    @BindView(R.id.areaTv)
    TextView areaTv;
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
    @BindView(R.id.imageSelectionFoodLl)
    LinearLayout imageSelectionFoodLl;
    @BindView(R.id.imageSelectionGSTNll)
    LinearLayout imageSelectionGSTNll;
    @BindView(R.id.tv_selectImageFL)
    TextView tv_selectImageFL;
    @BindView(R.id.tv_selectImageGSTN)
    TextView tv_selectImageGSTN;
    @BindView(R.id.edtDrugLicense)
    EditText edtDrugLicense;
    @BindView(R.id.edtDrugLicense2)
    EditText edtDrugLicense2;
    @BindView(R.id.edtFood)
    EditText edtFood;
    @BindView(R.id.edtGSTN)
    EditText edtGSTN;
    @BindView(R.id.register_step_1_rl)
    RelativeLayout register_step_1_rl;
    @BindView(R.id.register_step_2_rl)
    RelativeLayout register_step_2_rl;
    @BindView(R.id.step_1_bottom_view)
    View step_1_bottom_view;
    @BindView(R.id.step_2_bottom_view)
    View step_2_bottom_view;
    @BindView(R.id.save_next_fl)
    FrameLayout save_next_fl;
    ArrayList<ImageModel> encodedImageGSTN = new ArrayList<>();
    ArrayList<ImageModel> encodedImageFL = new ArrayList<>();
    ArrayList<ImageModel> encodedImageDL = new ArrayList<>();
    ArrayList<ImageModel> encodedImageDL2 = new ArrayList<>();
    @BindView(R.id.back_submit_buttons_ll)
    LinearLayout back_submit_buttons_ll;
    @BindView(R.id.terms_rl)
    RelativeLayout terms_rl;
    @BindView(R.id.step1_screen_ll)
    LinearLayout step1_screen_ll;
    @BindView(R.id.step2_screen_ll)
    LinearLayout step2_screen_ll;
    @BindView(R.id.store_details_des_tv)
    TextView store_details_des_tv;
    @BindView(R.id.drugLicenseImagePickerText)
    TextView drugLicenseImagePickerText;
    @BindView(R.id.drugLicense2ImagePickerText)
    TextView drugLicense2ImagePickerText;
    @BindView(R.id.GSTNImagePickerText)
    TextView GSTNImagePickerText;
    @BindView(R.id.foodLicensePickerText)
    TextView foodLicensePickerText;
    @BindView(R.id._rvPhoto)
    public RecyclerView _rvPhoto;
    @BindView(R.id._rvPhotoDL2)
    public RecyclerView _rvPhotoDL2;

    @BindView(R.id.image_bg_GSTN)
    public LinearLayout image_bg_GSTN;
    @BindView(R.id.image_bg)
    public LinearLayout image_bg;
    @BindView(R.id.imageBG2)
    public LinearLayout imageBG2;
    @BindView(R.id.image_bg_FL)
    public LinearLayout image_bg_FL;
    private int SelectedPos;
    private String Mobile_number, Country_Code;
    private String business_id, role_id;
    private ArrayList Business_name = new ArrayList(), Business_id = new ArrayList();
    private String Country_id, State_id, City_id, areaId;
    private boolean flag, check = false, check1 = false;
    private ArrayList<String> Login_name = new ArrayList(), loginType_id = new ArrayList();
    boolean isFirstTabSelected = true;
    final int REQUEST_PERMISSIONS = 103;
    private PhotosAdapter photoAdapter;
    private Bitmap bitmap;
    private String docTypeEnum, dlUploadedImageName="",dl2UploadedImageName = "", gstUploadedImageName="", flUploadedImageName="";

    public static RegisterFragmentWithStep newInstance(String id, String name) {
        Bundle args = new Bundle();
        args.putString(ID, id);
        args.putString(NAME, name);
        RegisterFragmentWithStep fragment = new RegisterFragmentWithStep();
        fragment.setArguments(args);
        return fragment;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_register_with_step, container, false);
        ButterKnife.bind(this, view);
        setTitle(view, getString(R.string.create_your_account).toUpperCase());
        retrofitCallBackListener = this;
        KeyboardUtils.setupUI(view, getActivity());
        setupBackButton(view);
        getBundle();
        setupUI();
        setUPInitialData();
        setUpTabsColor();
        return view;
    }

    private void setUpTabsColor() {
        if (isFirstTabSelected) {
            step_1_bottom_view.setBackgroundResource(R.color.new_blue);
            step_2_bottom_view.setBackgroundResource(R.color.colorGrayLight);
            step1_screen_ll.setVisibility(View.VISIBLE);
            step2_screen_ll.setVisibility(View.GONE);
            store_details_des_tv.setVisibility(View.GONE);
            save_next_fl.setVisibility(View.VISIBLE);
            back_submit_buttons_ll.setVisibility(View.GONE);
            terms_rl.setVisibility(View.GONE);
        } else {
            step_1_bottom_view.setBackgroundResource(R.color.new_blue);
            step_2_bottom_view.setBackgroundResource(R.color.new_blue);
            step1_screen_ll.setVisibility(View.GONE);
            store_details_des_tv.setVisibility(View.VISIBLE);
            step2_screen_ll.setVisibility(View.VISIBLE);
            save_next_fl.setVisibility(View.GONE);
            back_submit_buttons_ll.setVisibility(View.VISIBLE);
            terms_rl.setVisibility(View.VISIBLE);
        }
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

    @OnClick({R.id.image_bg, R.id.imageBG2, R.id.image_bg_GSTN, R.id.submit_button_tv, R.id.image_bg_FL, R.id.select_area_rl, R.id.back_button_fl, R.id.submit_button_fl, R.id.save_next_fl, R.id.fragmentRegister_frmCreateAccount, R.id.select_type_ll, R.id.fragmentRegister_tvLogin, R.id.fragmentRegister_edtCategory, R.id.select_country_rl, R.id.select_city_rl, R.id.select_state_rl})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.back_button_fl:
                isFirstTabSelected = true;
                setUpTabsColor();
                break;
            case R.id.fragmentRegister_frmCreateAccount:
                if (checkValidInput())
                    //   postRegistered(business_id, Mobile_Number.getText().toString(), edtName.getText().toString(), edtEmail.getText().toString(), edtPassword.getText().toString(), City_id, _edtPinCode.getText().toString());
                    break;
            case R.id.fragmentRegister_tvLogin:
                getActivity().onBackPressed();
                break;
            case R.id.fragmentRegister_edtCategory:
                break;
            case R.id.select_area_rl:
                if (_edtPinCode.getText().length() < 6) {
                    Toast.makeText(getActivity(), getString(R.string.error_pincode_length), Toast.LENGTH_SHORT).show();
                } else {
                    stateTV.clearComposingText();
                    cityTV.clearComposingText();
                    GoToCommonListingFragment(CODE_REQUEST_AREA_FILTER, Constant.AREA);
                }
                break;
            case R.id.select_type_ll:
                showSSelection();
                break;
            case R.id.submit_button_tv:
                if (checkStep1InputValidation()) {
                    if (checkStep2Validation()) {
                        JSONObject userInfo = new JSONObject();
                        try {
                            userInfo.put("MOBILENO", Country_Code + Mobile_Number.getText().toString());
                            userInfo.put("NAME", edtName.getText().toString());
                            userInfo.put("ADDRESS1", address1_et.getText().toString());
                            userInfo.put("PASSWORD", edtPassword.getText().toString());
                            userInfo.put("ADDRESS2", address2_et.getText().toString());
                            userInfo.put("GSTNUMBER", edtGSTN.getText().toString());
                            userInfo.put("DLNO1", edtDrugLicense.getText().toString());
                            userInfo.put("DLNO2", edtDrugLicense2.getText().toString());
                            userInfo.put("FOODLICNO", edtFood.getText().toString());
                            userInfo.put("PINCODE", _edtPinCode.getText().toString());
                            userInfo.put("AREA", areaTv.getText().toString());
                            userInfo.put("CITY", cityTV.getText().toString());
                            userInfo.put("STATE", stateTV.getText().toString());
                            userInfo.put("PASSWORD", edtConfirmPass.getText().toString());
                            JSONArray dlImageList = new JSONArray();
                            for (ImageModel imageModel : encodedImageDL) {
                                JSONObject imagesObj = new JSONObject();
                                imagesObj.put("ID", imageModel.getId());
                                imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                                dlImageList.put(imagesObj);
                            }
                            userInfo.put("DLIMAGEPATH", dlImageList);

                            JSONArray dl2ImageList = new JSONArray();
                            for (ImageModel imageModel : encodedImageDL2) {
                                JSONObject imagesObj = new JSONObject();
                                imagesObj.put("ID", imageModel.getId());
                                imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                                dl2ImageList.put(imagesObj);
                            }
                            userInfo.put("DL2IMAGEPATH", dl2ImageList);

                            JSONArray gstImageList = new JSONArray();

                            for (ImageModel imageModel : encodedImageGSTN) {
                                JSONObject gstImagesObj = new JSONObject();
                                gstImagesObj.put("ID", imageModel.getId());
                                gstImagesObj.put("IMAGEURL", imageModel.getImageUrl());
                                gstImageList.put(gstImagesObj);
                            }
                            userInfo.put("GSTIMAGEPATH", gstImageList);
                            JSONArray flImageList = new JSONArray();
                            for (ImageModel imageModel : encodedImageFL) {
                                JSONObject imagesObj = new JSONObject();
                                imagesObj.put("ID", imageModel.getId());
                                imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                                flImageList.put(imagesObj);
                            }
                            userInfo.put("FLIMAGEPATH", flImageList);

                            userInfo.put("DL1IMAGEURL", dlUploadedImageName);
                            userInfo.put("DL2IMAGEURL", dl2UploadedImageName);
                            userInfo.put("GST1IMAGEURL", gstUploadedImageName);
                            userInfo.put("FL1IMAGEURL", flUploadedImageName);
                            userInfo.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
                            userInfo.put("device_name", ReckonUtils.getDeviceName());
                            userInfo.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
                            userInfo.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
                            userInfo.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
                            userInfo.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                        registerUserOnServer(userInfo);
                    }
                }
                break;
            case R.id.save_next_fl:
                if (checkStep1InputValidation()) {
                    isFirstTabSelected = false;
                    setUpTabsColor();
                }
                break;
            case R.id.image_bg:
                docTypeEnum = Constant.DL;
                showImagePicker(Constant.DL);
                break;
            case R.id.imageBG2:
                docTypeEnum = Constant.DL2;
                showImagePicker(Constant.DL2);
                break;
            case R.id.image_bg_GSTN:
                docTypeEnum = Constant.GST;
                showImagePicker(Constant.GST);
                break;
            case R.id.image_bg_FL:
                docTypeEnum = Constant.FL;
                showImagePicker(Constant.FL);
                break;
        }
    }

    private void registerUserOnServer(JSONObject userInfo) {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postUserRegister(requireActivity().getPackageName(), String.valueOf(userInfo)), Constant.SIGNUP, true);
        } catch (Exception e) {
            e.printStackTrace();
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

    private void GoToCommonListingFragment(int codeRequest, String from) {
        CommonListingFragment fragment = new CommonListingFragment();
        fragment.setTargetFragment(this, codeRequest);
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, from);
        bundle.putString(Constant.PIN_CODE, _edtPinCode.getText().toString());
        fragment.setArguments(bundle);
        addFragment(fragment, true);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        try {
            LocalStorage localStorage = new LocalStorage(getActivity().getApplicationContext());
            GSTNImagePickerText.setText(getResources().getString(R.string.you_can_select_upto) + " " + getLicDetails().getGstcount() + " " + getResources().getString(R.string.documents));
            drugLicenseImagePickerText.setText(getResources().getString(R.string.you_can_select_upto) + " " + getLicDetails().getDlcount() + " " + getResources().getString(R.string.documents));
            drugLicense2ImagePickerText.setText(getResources().getString(R.string.you_can_select_upto) + " " + getLicDetails().getDlcount2() + " " + getResources().getString(R.string.documents));
            foodLicensePickerText.setText(getResources().getString(R.string.you_can_select_upto) + " " + getLicDetails().getFlcount() + " " + getResources().getString(R.string.documents));
            try{
                drugLicenseImagePickerText.setVisibility(Integer.parseInt(getLicDetails().getDlcount())>1?View.VISIBLE:View.GONE);
                drugLicense2ImagePickerText.setVisibility(Integer.parseInt(getLicDetails().getDlcount())>1?View.VISIBLE:View.GONE);
                GSTNImagePickerText.setVisibility(Integer.parseInt(getLicDetails().getGstcount())>1?View.VISIBLE:View.GONE);
                foodLicensePickerText.setVisibility(Integer.parseInt(getLicDetails().getFlcount())>1?View.VISIBLE:View.GONE);
            }catch (Exception e){
                e.printStackTrace();
            }
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
        _edtPinCode.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                areaTv.setText("");
                cityTV.setText("");
                stateTV.setText("");
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
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
        edtGSTN.setFilters(new InputFilter[]{new InputFilter.AllCaps(),new InputFilter.LengthFilter(15)});
        edtFood.setFilters(new InputFilter[]{new InputFilter.AllCaps()});
        edtDrugLicense.setFilters(new InputFilter[]{new InputFilter.AllCaps()});
        edtDrugLicense2.setFilters(new InputFilter[]{new InputFilter.AllCaps()});
        edtGSTN.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
//                if (s.length() == 6)
//                    imageSelectionGSTNll.setVisibility(View.VISIBLE);
//                else if (s.length() == 0)
//                    imageSelectionGSTNll.setVisibility(View.GONE);
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
        edtFood.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
//                if (s.length() == 4)
//                    imageSelectionFoodLl.setVisibility(View.VISIBLE);
//                else if (s.length() == 0)
//                    imageSelectionFoodLl.setVisibility(View.GONE);
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
        edtDrugLicense.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
//                if (s.length() == 6)
//                    drugLicenseImageLayout.setVisibility(View.VISIBLE);
//                else if (s.length() == 0)
//                    drugLicenseImageLayout.setVisibility(View.GONE);
            }

            @Override
            public void afterTextChanged(Editable s) {

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

    private void setContactImageAdapter(RecyclerView rvPhoto, ArrayList<ImageModel> arrayList, String _docType, int maxImage, int uriType) {
        rvPhoto.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.HORIZONTAL, false));
        photoAdapter = new PhotosAdapter(arrayList, this, _docType, maxImage, uriType);
        rvPhoto.setNestedScrollingEnabled(false);
        rvPhoto.setAdapter(photoAdapter);
        rvPhoto.hasFixedSize();
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

    public boolean checkStep1InputValidation() {
        String strError = "";
        if (TextUtils.isEmpty(edtName.getText()))
            strError = getString(R.string.error_input_name);
        else if (TextUtils.isEmpty(address1_et.getText()))
            strError = getString(R.string.error_address1);
        else if (TextUtils.isEmpty(_edtPinCode.getText()))
            strError = getString(R.string.error_pincode);
        else if (_edtPinCode.getText().length() < 6)
            strError = getString(R.string.error_pincode_length);
        else if (TextUtils.isEmpty(areaTv.getText()))
            strError = getString(R.string.please_select_area);
        else if (edtPassword.getText().length() < 6 || TextUtils.isEmpty(edtPassword.getText()))
            strError = getString(R.string.error_length_password);
        else if (TextUtils.isEmpty(edtConfirmPass.getText()))
            strError = getString(R.string.error_empty_confirm_pass);
        else if (!edtPassword.getText().toString().equals(edtConfirmPass.getText().toString()))
            strError = getString(R.string.error_confirm_password);
        if (TextUtils.isEmpty(strError))
            return true;
        else {
            Toast.makeText(getActivity(), strError, Toast.LENGTH_SHORT).show();
//            ReckonUtils.showAlert(getActivity(), getString(R.string.error), strError, null);
            return false;
        }
    }

    public boolean checkStep2Validation() {
        String strError = "";
        /*if (TextUtils.isEmpty(edtDrugLicense.getText()))
            strError = getString(R.string.error_drug_license);
        else*/ if (!TextUtils.isEmpty(edtDrugLicense.getText())&& encodedImageDL.size() == 0)
            strError = getString(R.string.error_drug_image);
        else if (!TextUtils.isEmpty(edtDrugLicense2.getText())&& encodedImageDL2.size() == 0)
            strError = getString(R.string.error_drug_image2);
        else if (!TextUtils.isEmpty(edtGSTN.getText())&& encodedImageGSTN.size() == 0)
            strError = getString(R.string.error_GSTN_image);
        else if (!TextUtils.isEmpty(edtGSTN.getText())&&edtGSTN.getText().length() < 15)
            strError = getString(R.string.invalid_gstn);
        else if (!TextUtils.isEmpty(edtFood.getText()) && encodedImageFL.size() == 0) {
            strError = getString(R.string.error_Food_image);
        } else if (!cbTermAndCondition.isChecked())
            strError = getString(R.string.error_not_agree_terms);
        if (TextUtils.isEmpty(strError))
            return true;
        else {
            Toast.makeText(getActivity(), strError, Toast.LENGTH_SHORT).show();
            return false;
        }
    }


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
            case CODE_REQUEST_AREA_FILTER:
                String area = Objects.requireNonNull(data.getExtras()).containsKey("data") ? data.getStringExtra("data") : "";
                String state = Objects.requireNonNull(data.getExtras()).containsKey("State") ? data.getStringExtra("State") : "";
                String City = Objects.requireNonNull(data.getExtras()).containsKey("City") ? data.getStringExtra("City") : "";
                areaId = data.getExtras().containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
                areaTv.setText(area);
                cityTV.setText(City);
                stateTV.setText(state);
                break;
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && !result.isEmpty()) {
            JSONObject jsonObject = new JSONObject(result);
            if (jsonObject.has("Status") && jsonObject.getBoolean("Status")) {
                switch (action) {
                    case Constant.UPLOAD_DOCS:
                        addImageNameInListFromServer(jsonObject);
                        break;
                    case Constant.DELETE_DOCS:
                        break;
                    case Constant.SIGNUP:
                        saveUserData(jsonObject);
                        break;
                }
            }
        }
    }

    private void addImageNameInListFromServer(JSONObject jsonObject) {
        try {
            if (docTypeEnum.equalsIgnoreCase(Constant.DL)) {
                ImageModel imageModel = new ImageModel();
                imageModel.setId(jsonObject.has("ID") ? jsonObject.getString("ID") : "");
                imageModel.setImageUrl(jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "");
                encodedImageDL.remove(encodedImageDL.size() - 1);
                encodedImageDL.add(imageModel);
                dlUploadedImageName = jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "";
            }else  if (docTypeEnum.equalsIgnoreCase(Constant.DL2)) {
                ImageModel imageModel = new ImageModel();
                imageModel.setId(jsonObject.has("ID") ? jsonObject.getString("ID") : "");
                imageModel.setImageUrl(jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "");
                encodedImageDL2.remove(encodedImageDL2.size() - 1);
                encodedImageDL2.add(imageModel);
                dl2UploadedImageName = jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "";
            } else if (docTypeEnum.equalsIgnoreCase(Constant.GST)) {
                ImageModel imageModel = new ImageModel();
                imageModel.setId(jsonObject.has("ID") ? jsonObject.getString("ID") : "");
                imageModel.setImageUrl(jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "");
                encodedImageGSTN.remove(encodedImageGSTN.size() - 1);
                encodedImageGSTN.add(imageModel);
                gstUploadedImageName = jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "";
            } else if (docTypeEnum.equalsIgnoreCase(Constant.FL)) {
                ImageModel imageModel = new ImageModel();
                imageModel.setId(jsonObject.has("ID") ? jsonObject.getString("ID") : "");
                imageModel.setImageUrl(jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "");
                encodedImageFL.remove(encodedImageFL.size() - 1);
                encodedImageFL.add(imageModel);
                flUploadedImageName = jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "";
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void saveUserData(JSONObject jsonObject) {
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
            parseUserDetails(profile, profileObject, baseUrl);
            response.setBaseUrl(baseUrl);
            response.setId(Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "Id", "0")));
            response.setProfile(profile);
            SharedPrefUtils.setString(getActivity(), KEY_USER, new Gson().toJson(response));
            Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
            addFragment(new LoginFragment(), false);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        switch (requestCode) {
            case REQUEST_PERMISSIONS:
                if (!hasPermissions(getActivity(), permissions)) {
                    if (hasRationalPermissions(getActivity(), permissions)) {
                        Toast.makeText(getActivity(), getResources().getString(R.string.enable_permission), Toast.LENGTH_LONG).show();
                        openDialog();
                    } else {
                        Toast.makeText(getActivity(), getResources().getString(R.string.enable_permission), Toast.LENGTH_LONG).show();
                    }
                }
                break;
            default:
                break;
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    private void openDialog() {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(getActivity());
        alertDialogBuilder.setMessage(getResources().getString(R.string.require_permission));
        alertDialogBuilder.setPositiveButton(getResources().getString(R.string.yes), (arg0, arg1) -> {
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", requireActivity().getPackageName(), null));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        });
        alertDialogBuilder.setNegativeButton(getResources().getString(R.string.no), (dialog, which) -> {
        });
        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.setCancelable(false);
        alertDialog.show();
    }

    public void setList(String imageByteArray, String type) {
        docTypeEnum = type;
        uploadDocsToServer(imageByteArray, type);
    }

    public int getListSize(String type) {
        int listSize = 0;
        switch (type) {
            case Constant.DL:
                listSize = encodedImageDL.size();
                break;
            case Constant.GST:
                listSize = encodedImageGSTN.size();
                break;
            case Constant.FL:
                listSize = encodedImageFL.size();
                break;
        }
        return listSize;
    }

    public void deleteList(String type, int position) {
        switch (type) {
            case Constant.DL:
                deleteUploadedDocsToServer(encodedImageDL.get(position));
                encodedImageDL.remove(position);
                dlUploadedImageName = "";
                break;
            case Constant.DL2:
                deleteUploadedDocsToServer(encodedImageDL2.get(position));
                encodedImageDL2.remove(position);
                dl2UploadedImageName = "";
                break;
            case Constant.GST:
                deleteUploadedDocsToServer(encodedImageGSTN.get(position));
                encodedImageGSTN.remove(position);
                gstUploadedImageName = "";
                break;
            case Constant.FL:
                deleteUploadedDocsToServer(encodedImageFL.get(position));
                encodedImageFL.remove(position);
                flUploadedImageName = "";
                break;
        }
    }

    private void uploadDocsToServer(String imageByteArray, String type) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("ID", "");
            jsonObject.put("mime", "image/jpeg");
            jsonObject.put("MOBILENO", Country_Code + Mobile_Number.getText().toString());
            jsonObject.put("IMAGETYPE", type);
            jsonObject.put("data", imageByteArray);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost("true").uploadDocs(requireActivity().getPackageName(), String.valueOf(jsonObject)), Constant.UPLOAD_DOCS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void deleteUploadedDocsToServer(ImageModel imageModel) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("ID", imageModel.getId());
            jsonObject.put("IMAGEURL", imageModel.getImageUrl());
//            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().deleteDocs(requireActivity().getPackageName(), String.valueOf(jsonObject)), Constant.DELETE_DOCS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void showImagePicker(String _docType) {
        List<String> permissionsToRequest = new ArrayList<>();
        permissionsToRequest.add(Manifest.permission.CAMERA);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { // Android 13+
            permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES);
        } else { // Android 12 and below
            permissionsToRequest.add(Manifest.permission.READ_EXTERNAL_STORAGE);
            // WRITE_EXTERNAL_STORAGE is only needed on very old versions.
            // TedImagePicker and modern APIs generally don't require it.
            // We can often omit it unless you are manually saving files to public directories.
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) { // Android 9 and below
                permissionsToRequest.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
            }
        }
        Dexter.withContext(getActivity()).withPermissions(permissionsToRequest).withListener(new MultiplePermissionsListener() {
            @Override
            public void onPermissionsChecked(MultiplePermissionsReport multiplePermissionsReport) {
                if (multiplePermissionsReport.areAllPermissionsGranted()) {
                    TedImagePicker.with(requireActivity()).start(uri -> {
                        try {
                            bitmap = MediaStore.Images.Media.getBitmap(requireActivity().getContentResolver(), uri);
                            model = new ImageModel();
                            model.setId("");
                            model.setImageUrl(String.valueOf(uri));
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                        switch (_docType) {
                            case Constant.DL:
                                encodedImageDL.add(model);
                                setContactImageAdapter(_rvPhoto, encodedImageDL, _docType, Integer.parseInt(getLicDetails().getDlcount()), encodedImageDL.size());
                                image_bg.setVisibility(View.GONE);
                                _rvPhoto.setVisibility(View.VISIBLE);
                                break;
                            case Constant.DL2:
                                encodedImageDL2.add(model);
                                setContactImageAdapter(_rvPhotoDL2, encodedImageDL2, _docType, Integer.parseInt(getLicDetails().getDlcount2()), encodedImageDL2.size());
                                imageBG2.setVisibility(View.GONE);
                                _rvPhotoDL2.setVisibility(View.VISIBLE);
                                break;

                            case Constant.GST:
                                encodedImageGSTN.add(model);
                                setContactImageAdapter(_rvPhoto_GSTN, encodedImageGSTN, _docType, Integer.parseInt(getLicDetails().getGstcount()), encodedImageGSTN.size());
                                image_bg_GSTN.setVisibility(View.GONE);
                                _rvPhoto_GSTN.setVisibility(View.VISIBLE);
                                break;
                            case Constant.FL:
                                encodedImageFL.add(model);
                                setContactImageAdapter(_rvPhoto_FL, encodedImageFL, _docType, Integer.parseInt(getLicDetails().getFlcount()), encodedImageFL.size());
                                image_bg_FL.setVisibility(View.GONE);
                                _rvPhoto_FL.setVisibility(View.VISIBLE);
                                break;
                        }
                        photoAdapter.notifyDataSetChanged();
                    });
                }
                if (multiplePermissionsReport.isAnyPermissionPermanentlyDenied()) {
                    // 3. Handle permanently denied permissions by showing a settings dialog
                    openDialog(); // Use your existing dialog
                }
            }

            @Override
            public void onPermissionRationaleShouldBeShown(List<PermissionRequest> list, PermissionToken permissionToken) {
                permissionToken.continuePermissionRequest();
            }
        }).withErrorListener(error -> {
            Toast.makeText(getActivity(), error.toString(), Toast.LENGTH_SHORT).show();
        }).onSameThread().check();
    }
}
