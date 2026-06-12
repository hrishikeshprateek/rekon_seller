package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_AREA_FILTER;
import static com.reckon.reckonorders.Utils.LocalStorage.KEY_USER;

import android.Manifest;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.text.Editable;
import android.text.InputFilter;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.DexterError;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.PermissionRequestErrorListener;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;
import com.reckon.reckonorders.Adapter.PhotosAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.ImageModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.Profile;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.ResponseFromRegistration;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.ConfirmDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentUserProfileBinding;
import com.reckon.reckonorders.databinding.ImageUploadLayoutBinding;
import com.reckon.reckonorders.databinding.MyProfileLayoutBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import gun0912.tedimagepicker.builder.TedImagePicker;

public class UserProfileFragment extends BaseFragment implements RetrofitCallBackListener {
    public FragmentUserProfileBinding binding;
    private static final String ARG_PARAM1 = "param1";
    String previousValue = "";
    int userID;
    private static final String ARG_PARAM2 = "param2";
    private String mParam1;
    private String mParam2;
    Profile profile, savedProfile;
    String json;
    JSONObject userInfo;
    String mobileNo, baseUrl, Mobile_Number, Country_Code = "91";
    int uriType = 0;
    ConfirmDialog confirmDialog;
    PhotosAdapter photoAdapter;

    private RetrofitCallBackListener retrofitCallBackListener;
    ArrayList<ImageModel> encodedImageGSTN = new ArrayList<>();
    ArrayList<ImageModel> encodedImageFL = new ArrayList<>();
    ArrayList<ImageModel> encodedImageDL = new ArrayList<>();
    ArrayList<ImageModel> encodedImageDL2 = new ArrayList<>();
    private String otpType, updatedArea = "";
    private String docTypeEnum, dlUploadedImageName = "", dl2UploadedImageName = "", gstUploadedImageName = "", flUploadedImageName = "";
    private ResponseFromRegistration response;
    private boolean isImageUploading = false;
    private View view = null;

    public static UserProfileFragment newInstance(String param1, String param2) {
        UserProfileFragment fragment = new UserProfileFragment();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        if (view == null) {
            retrofitCallBackListener = this;
            binding = FragmentUserProfileBinding.inflate(getLayoutInflater());
            view = inflater.inflate(R.layout.fragment_user_profile, container, false);
            gettingProfileData();
            getUserDataFromServer();
        }
        return binding.getRoot();
    }

    @Override
    public void onResume() {
        super.onResume();
        ((NewMainActivity) getActivity()).setUpTitle(UserProfileFragment.this, getString(R.string.my_profile));
        settingAllHint();
        getBundle();
        settingAllClicks();
        binding.drug.edtName.setFilters(new InputFilter[]{new InputFilter.AllCaps()});
        binding.drug2.edtName.setFilters(new InputFilter[]{new InputFilter.AllCaps()});
        binding.foodLl.edtName.setFilters(new InputFilter[]{new InputFilter.AllCaps()});
        binding.gst.edtName.setFilters(new InputFilter[]{new InputFilter.AllCaps(), new InputFilter.LengthFilter(15)});
        binding.foodLl.edtName.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.length() == 6 && encodedImageFL.size() == 0) {
                    binding.flBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
        binding.drug.edtName.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.length() == 6 && encodedImageDL.size() == 0) {
                    binding.dlBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
        binding.drug2.edtName.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.length() == 6 && encodedImageDL2.size() == 0) {
                    binding.dl2BgImage.bgUploadLayout.setVisibility(View.VISIBLE);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
        binding.gst.edtName.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.length() == 6 && encodedImageGSTN.size() == 0) {
                    binding.gstBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
        binding.mobileChange.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //         confirmDialog=new ConfirmDialog(UserProfileFragment.this);
                SendOTPDialog(getActivity(), requireActivity().getResources().getString(R.string.update_mobile), getActivity().getResources().getString(R.string.enter_your_mobile_number_to_create), "0");

            }
        });
        binding.updateProfile.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                updatedArea = "";
                updateUserProfileOnServer();
            }
        });


        binding.mobile.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.length() == 12) {
                    mobileNo = binding.mobile.getText().toString();
                }
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
    }

    private void getBundle() {
        if (getArguments() != null) {
            Bundle data = getArguments();
            updatedArea = data.getString("data");
            String state = data.getString("State");
            String City = data.getString("City");
//            int areaId = data.getInt(Constant.SELECTED_ID);
            if (!savedProfile.getAREA().equals(updatedArea)) {
                checkValidationInputData2(true);
            }
            binding.area.edtName.setText(updatedArea);
            binding.city.edtName.setText(City);
            binding.state.edtName.setText(state);
            binding.postal.edtName.setText(getArguments().getString(Constant.PIN_CODE));


        }
    }

    private void setContactImageAdapter(RecyclerView rvPhoto, ArrayList<ImageModel> imageUrl, String type, int maxImage, int uriType) {
        rvPhoto.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.HORIZONTAL, false));
        photoAdapter = new PhotosAdapter(UserProfileFragment.this, baseUrl, imageUrl, type, maxImage, uriType);
        rvPhoto.setNestedScrollingEnabled(false);
        rvPhoto.setAdapter(photoAdapter);
        rvPhoto.hasFixedSize();
    }

    private void getUserDataFromServer() {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getUserProfile(requireActivity().getPackageName(), mobileNo), Constant.USERDATA, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void gettingProfileData() {
//        savedProfile=ReckonUtils.gettingProfile(getActivity());
//        userInfo = ReckonUtils.gettingProfileData(getActivity(),savedProfile);
        json = SharedPrefUtils.getString(getActivity(), KEY_USER);
        Gson gson = new Gson();
        ResponseFromRegistration response = gson.fromJson(json, ResponseFromRegistration.class);
        if (response != null) {
            savedProfile = response.getProfile();
            userInfo = new JSONObject();
            try {
                JSONArray dlImageList = new JSONArray();
                for (ImageModel imageModel : savedProfile.getDLIMAGEPATH()) {
                    JSONObject imagesObj = new JSONObject();
                    imagesObj.put("ID", imageModel.getId());
                    imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                    dlImageList.put(imagesObj);
                }

                JSONArray dl2ImageList = new JSONArray();
                for (ImageModel imageModel : savedProfile.getDL2IMAGEPATH()) {
                    JSONObject imagesObj = new JSONObject();
                    imagesObj.put("ID", imageModel.getId());
                    imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                    dl2ImageList.put(imagesObj);
                }

                JSONArray gstImageList = new JSONArray();
                for (ImageModel imageModel : savedProfile.getGSTIMAGEPATH()) {
                    JSONObject gstImagesObj = new JSONObject();
                    gstImagesObj.put("ID", imageModel.getId());
                    gstImagesObj.put("IMAGEURL", imageModel.getImageUrl());
                    gstImageList.put(gstImagesObj);
                }

                JSONArray flImageList = new JSONArray();
                for (ImageModel imageModel : savedProfile.getFLIMAGEPATH()) {
                    JSONObject imagesObj = new JSONObject();
                    imagesObj.put("ID", imageModel.getId());
                    imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                    flImageList.put(imagesObj);
                }
                userInfo.put("DLIMAGEPATH", dlImageList);
                userInfo.put("DL2IMAGEPATH", dl2ImageList);
                userInfo.put("FLIMAGEPATH", flImageList);
                userInfo.put("GSTIMAGEPATH", gstImageList);
                userInfo.put("AREA", savedProfile.getAREA());
                userInfo.put("CITY", savedProfile.getCITY());
                userInfo.put("DLNO1", savedProfile.getDLNO1());
                userInfo.put("DLNO2", savedProfile.getDLNO2());
                userInfo.put("FOODLICNO", savedProfile.getFOODLICNO());
                userInfo.put("GSTNUMBER", savedProfile.getGSTNUMBER());
                userInfo.put("CUID", savedProfile.getCUID());
                userInfo.put("ADDRESS1", savedProfile.getADDRESS1());
                userInfo.put("ADDRESS2", savedProfile.getADDRESS2());
                userInfo.put("MOBILENO", savedProfile.getMOBILENO());
                userInfo.put("NAME", savedProfile.getNAME());
                userInfo.put("PINCODE", savedProfile.getPINCODE());
                userInfo.put("STATE", savedProfile.getSTATE());

                userInfo.put("DL1IMAGEURL", savedProfile.getDL1IMAGEURL());
                userInfo.put("DL2IMAGEURL", savedProfile.getDL2IMAGEURL());
                userInfo.put("GST1IMAGEURL", savedProfile.getGST1IMAGEURL());
                userInfo.put("FL1IMAGEURL", savedProfile.getFL1IMAGEURL());
            } catch (Exception e) {
                e.printStackTrace();
            }
//            baseUrl = response.getBaseUrl();
            settingAllText(savedProfile);
//        }
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

    private void settingAllClicks() {
        setClick(binding.storeName);
        setClick(binding.address1);
        setClick(binding.address2);
        setClick(binding.area);
        setClick(binding.postal);
        setClick(binding.city);
        setClick(binding.state);
        setClick(binding.gst);
        setClick(binding.drug);
        setClick(binding.drug2);
        setClick(binding.foodLl);
        setBgImageClick(binding.gstBgImage, Constant.GST);
        setBgImageClick(binding.dlBgImage, Constant.DL);
        setBgImageClick(binding.dl2BgImage, Constant.DL2);
        setBgImageClick(binding.flBgImage, Constant.FL);
        if (binding.foodLl != null) {
            if (binding.foodLl.edtName.getText().length() == 0) {
                binding.flBgImage.bgUploadLayout.setVisibility(View.GONE);
            }
        }
        if (binding.drug != null) {
            if (binding.drug.edtName.getText().length() == 0) {
                binding.dlBgImage.bgUploadLayout.setVisibility(View.GONE);
            }
        }
        if (binding.drug2 != null) {
            if (binding.drug2.edtName.getText().length() == 0) {
                binding.dl2BgImage.bgUploadLayout.setVisibility(View.GONE);
            }
        }
        if (binding.gst != null) {
            if (binding.gst.edtName.getText().length() == 0) {
                binding.gstBgImage.bgUploadLayout.setVisibility(View.GONE);
            }
        }
    }

    private void setBgImageClick(@NonNull ImageUploadLayoutBinding bgImage, String _type) {
        bgImage.bgUploadLayout.setOnClickListener(v -> showImagePicker(_type));
    }

    private void settingAllText(Profile profile) {
        mobileNo = profile.getMOBILENO();
        binding.storeName.edtName.setText(profile.getNAME());
        binding.address1.edtName.setText(profile.getADDRESS1());
        binding.address2.edtName.setText(profile.getADDRESS2());
        if (!updatedArea.isEmpty() && !profile.getAREA().equalsIgnoreCase(updatedArea)) {
        } else {
            binding.area.edtName.setText(profile.getAREA());
            binding.state.edtName.setText(profile.getSTATE());
            binding.city.edtName.setText(profile.getCITY());
            binding.postal.edtName.setText(profile.getPINCODE());
        }
        binding.gst.edtName.setText(profile.getGSTNUMBER().toUpperCase());
        binding.drug.edtName.setText(profile.getDLNO1().toUpperCase());
        binding.drug2.edtName.setText(profile.getDLNO2().toUpperCase());
        binding.foodLl.edtName.setText(profile.getFOODLICNO().toUpperCase());
        binding.mobile.setText(mobileNo);
        binding.nameStore.setText(profile.getNAME());
        userID = profile.getCUID();
        encodedImageDL = profile.getDLIMAGEPATH();
        encodedImageDL2 = profile.getDL2IMAGEPATH();
        encodedImageGSTN = profile.getGSTIMAGEPATH();
        encodedImageFL = profile.getFLIMAGEPATH();
        setContactImageAdapter(binding.imageRecyclerDrug, encodedImageDL, Constant.DL, Integer.parseInt(getLicDetails().getDlcount()), uriType);
        setContactImageAdapter(binding.imageRecyclerDrug2, encodedImageDL2, Constant.DL2, Integer.parseInt(getLicDetails().getDlcount2()), uriType);
        setContactImageAdapter(binding.imageRecyclerGST, encodedImageGSTN, Constant.GST, Integer.parseInt(getLicDetails().getGstcount()), uriType);
        setContactImageAdapter(binding.imageRecyclerFood, encodedImageFL, Constant.FL, Integer.parseInt(getLicDetails().getFlcount()), uriType);
        if (encodedImageGSTN.size() != 0) {
            binding.gstBgImage.bgUploadLayout.setVisibility(View.GONE);
        } else {
            binding.gstBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
        }
        if (encodedImageFL.size() != 0) {
            binding.flBgImage.bgUploadLayout.setVisibility(View.GONE);
        } else {
            binding.flBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
        }
        if (encodedImageDL.size() != 0) {
            binding.dlBgImage.bgUploadLayout.setVisibility(View.GONE);
        } else {
            binding.dlBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
        }
        if (encodedImageDL2.size() != 0) {
            binding.dl2BgImage.bgUploadLayout.setVisibility(View.GONE);
        } else {
            binding.dl2BgImage.bgUploadLayout.setVisibility(View.VISIBLE);
        }
        if(updatedArea.isEmpty()){
            binding.updateProfile.setBackgroundColor(getResources().getColor(R.color.reconGrey));
            binding.updateProfile.setEnabled(false);
        }
        dlUploadedImageName = profile.getDL1IMAGEURL();
        dl2UploadedImageName = profile.getDL2IMAGEURL();
        gstUploadedImageName = profile.getGST1IMAGEURL();
        flUploadedImageName = profile.getFL1IMAGEURL();

    }

    private void settingAllHint() {
        binding.area.Name.setHint(getResources().getString(R.string.area));
        binding.city.Name.setHint(getResources().getString(R.string.city));
        binding.state.Name.setHint(getResources().getString(R.string.state));
        binding.gst.Name.setHint(getResources().getString(R.string.gstNumber));
        binding.gst.Name.setCounterMaxLength(15);
        binding.postal.Name.setHint(getResources().getString(R.string.postalCode));
        binding.storeName.Name.setHint(getResources().getString(R.string.storeName));
        binding.address1.Name.setHint(getResources().getString(R.string.addressLine1));
        binding.address2.Name.setHint(getResources().getString(R.string.addressLine2));
        binding.drug.Name.setHint(getResources().getString(R.string.drug_license_number1));
        binding.drug2.Name.setHint(getResources().getString(R.string.drug_license_number2));
        binding.foodLl.Name.setHint(getResources().getString(R.string.food_licence_number));

    }

    private void SendOTPDialog(final Context context, final String title, String content, final String OTPType) {
        otpType = OTPType;
        confirmDialog = new ConfirmDialog(context, title, content);
//        if (title.equalsIgnoreCase(getResources().getString(R.string.forgot_your_password)))
//            confirmDialog.setTextConfirm("Send Request");
//        else if (title.equalsIgnoreCase(getResources().getString(R.string.create_password))) {
//            confirmDialog.setTextConfirm("Submit");
//        } else {
        confirmDialog.setTextConfirm("Update");
        if (mobileNo.length() == 12)
            confirmDialog.setTextOfMobile(mobileNo.substring(Country_Code.length()));
        else
            confirmDialog.setTextOfMobile(mobileNo);
        // }
        confirmDialog.setOnItemClickListener(() -> {
            //    startSMSRetrieverClient();
            try {
//                if (title.equalsIgnoreCase(getResources().getString(R.string.create_password))) {
//                    String _edtPassword = confirmDialog._edtPassword.getText().toString();
//                    String _edtConfirmPass = confirmDialog._edtConfirmPass.getText().toString();
//                    if (_edtPassword.equalsIgnoreCase(""))
//                        Toast.makeText(getActivity(), getString(R.string.error_new_password_empty), Toast.LENGTH_SHORT).show();
//                    else if (_edtPassword.length() < 6)
//                        Toast.makeText(getActivity(), getString(R.string.error_length_password), Toast.LENGTH_SHORT).show();
//                    else if (_edtConfirmPass.equalsIgnoreCase(""))
//                        Toast.makeText(getActivity(), getString(R.string.error_confirm_password_empty), Toast.LENGTH_SHORT).show();
//                    else if (!_edtPassword.equalsIgnoreCase(_edtConfirmPass))
//                        Toast.makeText(getActivity(), getString(R.string.error_confirm_password), Toast.LENGTH_SHORT).show();
//                    else
//                        new ConnectToRetrofit(retrofitCallBackListenar, getActivity(), getApiClient_ByPost().postCreatePassword(requireActivity().getPackageName(), Mobile_Number, Country_Code, _edtPassword, "", "1"), Constant.CREATE_PASSWORD, true);
//
//                } else {
                Mobile_Number = confirmDialog.tvmobileNumber.getText().toString();
                Country_Code = confirmDialog.countryCodeAndroid;
                if (!Mobile_Number.equalsIgnoreCase("")) {
                    new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().sendOtp(requireActivity().getPackageName(), Mobile_Number, Country_Code, OTPType), Constant.SEND_OTP, true);
                } else
                    Toast.makeText(getActivity(), "Please enter your mobile number", Toast.LENGTH_SHORT).show();
                //}
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
            if (!confirmDialog.ed_OTP.getText().toString().equalsIgnoreCase("")){
                new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().verifyOtp(String.valueOf(getVerifyOtpObj())), Constant.VERIFY_OTP, true);
            }
            else
                Toast.makeText(getActivity(), "Please enter OTP.", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            e.printStackTrace();
        }
        confirmDialog.setOnItemClickListener(() -> {
            confirmDialog.tvConfirm.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    try {
                        if (!confirmDialog.ed_OTP.getText().toString().equalsIgnoreCase("")){
                            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().verifyOtp(String.valueOf(getVerifyOtpObj())), Constant.VERIFY_OTP, true);
                        }
                        else
                            Toast.makeText(getActivity(), "Please enter OTP.", Toast.LENGTH_SHORT).show();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }

                }
            });
            confirmDialog.resendbtn.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    try {
                        confirmDialog.resendbtn.setEnabled(false);
                        confirmDialog.resendbtn.setTextColor(getResources().getColor(R.color.red_wine));
                        if (!Mobile_Number.equalsIgnoreCase(""))
                            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().sendOtp(requireActivity().getPackageName(), Mobile_Number, Country_Code, otpType), Constant.SEND_OTP, true);
                        else
                            Toast.makeText(getActivity(), "Please enter your mobile number", Toast.LENGTH_SHORT).show();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
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
                    if (confirmDialog.ed_OTP.length() == 6){
                            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().verifyOtp(String.valueOf(getVerifyOtpObj())), Constant.VERIFY_OTP, true);
                    }
                }

                @Override
                public void afterTextChanged(Editable s) {

                }
            });
        confirmDialog.StartTimer();
    }

    JSONObject getVerifyOtpObj(){
        JSONObject object = new JSONObject();
        try {
            object.put("lApkName", requireActivity().getPackageName());
            object.put("MobileNo", Mobile_Number);
            object.put("OTP", confirmDialog.ed_OTP.getText().toString());
            object.put("CountryCode", Country_Code);
            object.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            object.put("device_name", ReckonUtils.getDeviceName());
            object.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return object;
    }

    private void GoToCommonListingFragment(int codeRequest, String from) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.AREA);
        bundle.putString("Update", "UPDATE");
        bundle.putString(Constant.PIN_CODE, binding.postal.edtName.getText().toString());
        Navigation.findNavController(binding.area.Name).navigate(R.id.nav_common_listing, bundle);
    }

    private void setClick(@NonNull MyProfileLayoutBinding profileLayoutBinding) {
        if (profileLayoutBinding == binding.city || profileLayoutBinding == binding.state || profileLayoutBinding == binding.area) {
            {
                binding.area.editButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        updatedArea = "";
                        if (binding.postal.edtName.getText().length() < 6) {
                            Toast.makeText(getActivity(), "Invalid PinCode", Toast.LENGTH_SHORT).show();
                        } else {
                            GoToCommonListingFragment(CODE_REQUEST_AREA_FILTER, Constant.AREA);
                        }
                    }
                });
                if (updatedArea.isEmpty()) {
                    checkValidationInputData2(false);
                }
                if (profileLayoutBinding == binding.city || profileLayoutBinding == binding.state) {
                    profileLayoutBinding.editButton.setVisibility(View.GONE);
                }
            }
        } else {
            profileLayoutBinding.edtName.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {

                }

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                    if (s.length() >= 1 && updatedArea.isEmpty()) {
                        profileLayoutBinding.crossBtn.setVisibility(View.VISIBLE);
                        checkValidationInputData2(false);
                    } else {
                        profileLayoutBinding.crossBtn.setVisibility(View.GONE);
                    }
                }

                @Override
                public void afterTextChanged(Editable s) {
                }
            });
            profileLayoutBinding.editButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (profileLayoutBinding == binding.postal) {
                        setClicking(profileLayoutBinding);
                        profileLayoutBinding.edtName.addTextChangedListener(new TextWatcher() {
                            @Override
                            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

                            }

                            @Override
                            public void onTextChanged(CharSequence s, int start, int before, int count) {
                                binding.city.edtName.setText("");
                                binding.state.edtName.setText("");
                                binding.area.edtName.setText("");
                                checkValidationInputData2(false);
                            }

                            @Override
                            public void afterTextChanged(Editable s) {

                            }
                        });
                    } else
                        setClicking(profileLayoutBinding);
                }
            });
        }
    }

    private void setClicking(MyProfileLayoutBinding profileLayoutBinding) {
        profileLayoutBinding.edtName.setEnabled(true);
        profileLayoutBinding.edtName.requestFocus();
        profileLayoutBinding.edtName.setSelection(profileLayoutBinding.edtName.getText().length());
        profileLayoutBinding.editLL.setVisibility(View.VISIBLE);
        profileLayoutBinding.editButton.setVisibility(View.GONE);
        if (profileLayoutBinding.edtName.getText().length() == 0) {
            profileLayoutBinding.crossBtn.setVisibility(View.GONE);
        }
        profileLayoutBinding.crossBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                profileLayoutBinding.edtName.setText("");
                profileLayoutBinding.crossBtn.setVisibility(View.GONE);
            }
        });
        profileLayoutBinding.saveBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                profileLayoutBinding.edtName.setEnabled(false);
                profileLayoutBinding.editLL.setVisibility(View.GONE);
                profileLayoutBinding.editButton.setVisibility(View.VISIBLE);
            }
        });
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && !result.isEmpty()) {
            JSONObject jsonObject = new JSONObject(result);
            jsonObject.put("Status", true);
            if (jsonObject.has("Status") && jsonObject.getBoolean("Status")) {
                response = new ResponseFromRegistration();
                profile = new Profile();
                switch (action) {
                    case Constant.SIGNUP:
                    case Constant.USERDATA:
                        setUserServerData(jsonObject);
                        break;
                    case Constant.UPLOAD_DOCS:
                        isImageUploading = false;
                        addImageNameInListFromServer(jsonObject);
                        break;
                    case Constant.DELETE_DOCS:
                        checkValidationInputData2(false);
                        break;
                    case Constant.VERIFY_OTP:
                        verifyOtpServerData(jsonObject);
                        break;
                    case Constant.SEND_OTP:
                        if (jsonObject.getString("Status").equalsIgnoreCase("false")) {
                            Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
                        } else {
                            Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
                            if (confirmDialog != null && confirmDialog.isShowing())
                                confirmDialog.dismiss();
                            VerifyOTPDialog(getActivity(), requireActivity().getResources().getString(R.string.mobile_verification), getActivity().getResources().getString(R.string.enter_otp));
                        }
                        break;
                    default:
                        Toast.makeText(getActivity(), "unknown", Toast.LENGTH_SHORT).show();
                }
            }
        }
    }

    private void verifyOtpServerData(JSONObject jsonObject) {
        try {
            if (jsonObject.getString("Status").equalsIgnoreCase("false"))
                Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
            else {
                if (jsonObject.getString("Message").equalsIgnoreCase("")) {
                    Toast.makeText(getActivity(), "Successfully verified.", Toast.LENGTH_SHORT).show();
                    mobileNo = Country_Code + Mobile_Number;
                    registerUserOnServer(updateProfile());
                    binding.mobile.setText(mobileNo);
                    if (confirmDialog != null && confirmDialog.isShowing())
                        confirmDialog.dismiss();
                } else
                    Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
                mobileNo = Country_Code + Mobile_Number;
                updateUserProfileOnServer();
                binding.mobile.setText(mobileNo);
                if (confirmDialog != null && confirmDialog.isShowing())
                    confirmDialog.dismiss();
                //  addFragment(RegisterFragment.newInstance(Mobile_Number, Country_Code), true);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setUserServerData(JSONObject jsonObject) {
        try {
            String baseUrl = jsonObject.has("BaseUrl") ? jsonObject.getString("BaseUrl") : "";
            if (TextUtils.isEmpty(baseUrl))
                baseUrl = "https://pwsorder.reckonsales.com/upload";
            baseUrl = baseUrl + "/";
            JSONObject profileObject = jsonObject.has("Profile") ? jsonObject.getJSONObject("Profile") : new JSONObject();
            parseUserDetails(profile, profileObject, baseUrl);
            response.setBaseUrl(baseUrl);
//            response.setId(jsonObject.getInt("Id"));
            response.setProfile(profile);
            Gson gson = new Gson();
            String json = gson.toJson(response);
            SharedPrefUtils.setString(getActivity(), KEY_USER, json);
            SharedPrefUtils.setString(getActivity(), Constant.USER_ID, ReckonUtils.getJsonCheckedString(jsonObject.getJSONObject("Profile"), "MOBILENO", ""));
            SharedPrefUtils.setString(getActivity(), Constant.USER_ID_CU, ReckonUtils.getJsonCheckedString(jsonObject.getJSONObject("Profile"), "CUID", ""));
//            Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
            gettingProfileData();
        } catch (Exception e) {
            e.printStackTrace();
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
                //   setContactImageAdapter(binding.imageRecyclerDrug, encodedImageDL, docTypeEnum, 3, uriType);
            } else if (docTypeEnum.equalsIgnoreCase(Constant.DL2)) {
                ImageModel imageModel = new ImageModel();
                imageModel.setId(jsonObject.has("ID") ? jsonObject.getString("ID") : "");
                imageModel.setImageUrl(jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "");
                encodedImageDL2.remove(encodedImageDL2.size() - 1);
                encodedImageDL2.add(imageModel);
                dl2UploadedImageName = jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "";
                //   setContactImageAdapter(binding.imageRecyclerDrug2, encodedImageDL, docTypeEnum, 3, uriType);
            } else if (docTypeEnum.equalsIgnoreCase(Constant.GST)) {
                ImageModel imageModel = new ImageModel();
                imageModel.setId(jsonObject.has("ID") ? jsonObject.getString("ID") : "");
                imageModel.setImageUrl(jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "");
                encodedImageGSTN.remove(encodedImageGSTN.size() - 1);
                encodedImageGSTN.add(imageModel);
                gstUploadedImageName = jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "";
                //   setContactImageAdapter(binding.imageRecyclerDrug, encodedImageGSTN, docTypeEnum, 4, uriType);
            } else if (docTypeEnum.equalsIgnoreCase(Constant.FL)) {
                ImageModel imageModel = new ImageModel();
                imageModel.setId(jsonObject.has("ID") ? jsonObject.getString("ID") : "");
                imageModel.setImageUrl(jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "");
                encodedImageFL.remove(encodedImageFL.size() - 1);
                encodedImageFL.add(imageModel);
                flUploadedImageName = jsonObject.has("ImageUrl") ? jsonObject.getString("ImageUrl") : "";
                //   setContactImageAdapter(binding.imageRecyclerFood, encodedImageFL, docTypeEnum, 5, uriType);
            }
            checkValidationInputData2(false);
            photoAdapter.notifyDataSetChanged();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void updateUserProfileOnServer() {
        if (checkValidationInputData())
            if (checkValidationInputData2(false))
                registerUserOnServer(updateProfile());

    }

    private JSONObject updateProfile() {

        JSONObject userInfo = new JSONObject();
        try {
            JSONArray dlImageList = new JSONArray();
            for (ImageModel imageModel : encodedImageDL) {
                JSONObject imagesObj = new JSONObject();
                imagesObj.put("ID", imageModel.getId());
                imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                dlImageList.put(imagesObj);
            }
            JSONArray dl2ImageList = new JSONArray();
            for (ImageModel imageModel : encodedImageDL2) {
                JSONObject imagesObj = new JSONObject();
                imagesObj.put("ID", imageModel.getId());
                imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                dl2ImageList.put(imagesObj);
            }
            JSONArray gstImageList = new JSONArray();
            for (ImageModel imageModel : encodedImageGSTN) {
                JSONObject gstImagesObj = new JSONObject();
                gstImagesObj.put("ID", imageModel.getId());
                gstImagesObj.put("IMAGEURL", imageModel.getImageUrl());
                gstImageList.put(gstImagesObj);
            }

            JSONArray flImageList = new JSONArray();
            for (ImageModel imageModel : encodedImageFL) {
                JSONObject imagesObj = new JSONObject();
                imagesObj.put("ID", imageModel.getId());
                imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                flImageList.put(imagesObj);
            }

            userInfo.put("DLIMAGEPATH", dlImageList);
            userInfo.put("DL2IMAGEPATH", dl2ImageList);
            userInfo.put("FLIMAGEPATH", flImageList);
            userInfo.put("GSTIMAGEPATH", gstImageList);
            userInfo.put("AREA", binding.area.edtName.getText().toString());
            userInfo.put("CITY", binding.city.edtName.getText().toString());
            userInfo.put("DLNO1", binding.drug.edtName.getText().toString());
            userInfo.put("DLNO2", binding.drug2.edtName.getText().toString());
            userInfo.put("FOODLICNO", binding.foodLl.edtName.getText().toString());
            userInfo.put("GSTNUMBER", binding.gst.edtName.getText().toString());
            userInfo.put("CUID", userID);
            userInfo.put("ADDRESS1", binding.address1.edtName.getText().toString());
            userInfo.put("ADDRESS2", binding.address2.edtName.getText().toString());
            userInfo.put("MOBILENO", mobileNo);
            userInfo.put("NAME", binding.storeName.edtName.getText().toString());
            userInfo.put("PINCODE", binding.postal.edtName.getText().toString());
            userInfo.put("STATE", binding.state.edtName.getText().toString());

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
        } catch (Exception e) {
            e.printStackTrace();
        }
        return userInfo;
        //     registerUserOnServer(userInfo);

    }

    private boolean checkValidationInputData2(boolean isAreaUpdate) {
        if (isAreaUpdate && !updatedArea.isEmpty() && !savedProfile.getAREA().equalsIgnoreCase(updatedArea)) {
            binding.updateProfile.setEnabled(true);
            binding.updateProfile.setBackgroundColor(getResources().getColor(R.color.new_blue));
            return true;
        }

        if (!this.userInfo.toString().equals(updateProfile().toString())) {
            binding.updateProfile.setEnabled(true);
            binding.updateProfile.setBackgroundColor(getResources().getColor(R.color.new_blue));
            return true;
        } else {
            binding.updateProfile.setEnabled(false);
            binding.updateProfile.setBackgroundColor(getResources().getColor(R.color.reconGrey));
            return false;
        }


    }

    private void registerUserOnServer(JSONObject userInfo) {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postUserRegister(requireActivity().getPackageName(), String.valueOf(userInfo)), Constant.SIGNUP, true);
            //       new ConnectToRetrofit(retrofitCallBackListenar, getActivity(), getApiClient_ByPost().postUserRegister(String.valueOf(userInfo)), Constant.SIGNUP, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private boolean checkValidationInputData() {
        String strError = "";
        if (TextUtils.isEmpty(binding.storeName.edtName.getText()))
            strError = getString(R.string.error_input_name);
        else if (TextUtils.isEmpty(binding.address1.edtName.getText()))
            strError = getString(R.string.error_address1);
        else if (TextUtils.isEmpty(binding.postal.edtName.getText()))
            strError = getString(R.string.error_pincode);
        else if (binding.postal.edtName.getText().length() < 6)
            strError = getString(R.string.error_pincode_length);
        else if (TextUtils.isEmpty(binding.area.edtName.getText()))
            strError = getString(R.string.please_select_area);
        else if (TextUtils.isEmpty(binding.drug.edtName.getText()))
            strError = getString(R.string.error_drug_license);
        else if (TextUtils.isEmpty(binding.drug2.edtName.getText()))
            strError = getString(R.string.error_drug_license2);
        else if (encodedImageDL.size() == 0)
            strError = getString(R.string.error_drug_image);
        else if (encodedImageDL2.size() == 0)
            strError = getString(R.string.error_drug_image2);
        else if (!TextUtils.isEmpty(binding.gst.edtName.getText()) && encodedImageGSTN.size() == 0)
            strError = getString(R.string.error_GSTN_image);
        else if (!TextUtils.isEmpty(binding.gst.edtName.getText()) && binding.gst.edtName.getText().length() < 15)
            strError = getString(R.string.invalid_gstn);

        else if (!TextUtils.isEmpty(binding.foodLl.edtName.getText()) && encodedImageFL.size() == 0) {
            strError = getString(R.string.error_Food_image);
        }
        if (TextUtils.isEmpty(strError))
            return true;
        else {
            Toast.makeText(getActivity(), strError, Toast.LENGTH_SHORT).show();
            return false;
        }
    }

    public void showImagePicker(String _type) {
        uriType = 1;
        Dexter.withContext(getActivity()).withPermissions(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.CAMERA).withListener(new MultiplePermissionsListener() {
            @Override
            public void onPermissionsChecked(MultiplePermissionsReport multiplePermissionsReport) {
                if (multiplePermissionsReport.areAllPermissionsGranted()) {
                    TedImagePicker.with(requireActivity()).start(uri -> {
                        switch (_type) {
                            case Constant.DL:
                                ImageModel model = new ImageModel();
                                model.setId("");
                                model.setImageUrl(uri.toString());
                                encodedImageDL.add(model);
                                binding.dlBgImage.bgUploadLayout.setVisibility(View.GONE);
                                setContactImageAdapter(binding.imageRecyclerDrug, encodedImageDL, _type, Integer.parseInt(getLicDetails().getDlcount()), encodedImageDL.size());
                                break;
                            case Constant.DL2:
                                ImageModel model2 = new ImageModel();
                                model2.setId("");
                                model2.setImageUrl(uri.toString());
                                encodedImageDL2.add(model2);
                                binding.dl2BgImage.bgUploadLayout.setVisibility(View.GONE);
                                setContactImageAdapter(binding.imageRecyclerDrug2, encodedImageDL2, _type, Integer.parseInt(getLicDetails().getDlcount2()), encodedImageDL2.size());
                                break;
                            case Constant.GST:
                                ImageModel modelGst = new ImageModel();
                                modelGst.setImageUrl(uri.toString());
                                modelGst.setId("");
                                encodedImageGSTN.add(modelGst);
                                binding.gstBgImage.bgUploadLayout.setVisibility(View.GONE);
                                setContactImageAdapter(binding.imageRecyclerGST, encodedImageGSTN, _type, Integer.parseInt(getLicDetails().getGstcount()), encodedImageGSTN.size());
                                break;
                            case Constant.FL:
                                ImageModel modelFL = new ImageModel();
                                modelFL.setImageUrl(uri.toString());
                                modelFL.setId("");
                                encodedImageFL.add(modelFL);
                                binding.flBgImage.bgUploadLayout.setVisibility(View.GONE);
                                setContactImageAdapter(binding.imageRecyclerFood, encodedImageFL, _type, Integer.parseInt(getLicDetails().getFlcount()), encodedImageFL.size());
                                break;
                        }
//                        photoAdapter.notifyDataSetChanged();
                    });
                } else if (multiplePermissionsReport.isAnyPermissionPermanentlyDenied()) {
                    showSettingsDialog();
                }
            }

            @Override
            public void onPermissionRationaleShouldBeShown(List<PermissionRequest> list, PermissionToken permissionToken) {
                permissionToken.continuePermissionRequest();
            }
        }).withErrorListener(new PermissionRequestErrorListener() {
            @Override
            public void onError(DexterError error) {
                // we are displaying a toast message for error message.
                Toast.makeText(getActivity(), error.toString(), Toast.LENGTH_SHORT).show();
            }
        }).onSameThread().check();
    }

    public void setList(String imageByteArray, String type) {
        if (!isImageUploading) {
            docTypeEnum = type;
            uploadDocsToServer(imageByteArray, docTypeEnum);
            photoAdapter.notifyDataSetChanged();
        }
    }

    private void uploadDocsToServer(String imageByteArray, String type) {
        try {
            isImageUploading = true;
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("ID", userID);
            jsonObject.put("MOBILENO", mobileNo);
            jsonObject.put("IMAGETYPE", type);
            jsonObject.put("mime", "image/jpeg");
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


    public void deleteList(String type, int position) {
        switch (type) {
            case Constant.DL:
                if (encodedImageDL != null && encodedImageDL.size() > 0) {
                    deleteUploadedDocsToServer(encodedImageDL.get(position));
                    encodedImageDL.remove(position);
                    dlUploadedImageName = "";
                }
                break;
            case Constant.DL2:
                if (encodedImageDL2 != null && encodedImageDL2.size() > 0) {
                    deleteUploadedDocsToServer(encodedImageDL2.get(position));
                    encodedImageDL2.remove(position);
                    dl2UploadedImageName = "";
                }
                break;
            case Constant.GST:
                if (encodedImageGSTN != null && encodedImageGSTN.size() > 0) {
                    deleteUploadedDocsToServer(encodedImageGSTN.get(position));
                    encodedImageGSTN.remove(position);
                    gstUploadedImageName = "";
                }
                break;
            case Constant.FL:
                if (encodedImageFL != null && encodedImageFL.size() > 0) {
                    deleteUploadedDocsToServer(encodedImageFL.get(position));
                    encodedImageFL.remove(position);
                    flUploadedImageName = "";
                }
                photoAdapter.notifyDataSetChanged();
                break;
        }
    }

    private void showSettingsDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        builder.setTitle("Need Permissions");
        builder.setMessage("This app needs permission to use this feature. You can grant them in app settings.");
        builder.setPositiveButton("GOTO SETTINGS", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
                Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                Uri uri = Uri.fromParts("package", getActivity().getPackageName(), null);
                intent.setData(uri);
                startActivityForResult(intent, 101);
            }
        });
        builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });
        builder.show();
    }
}







