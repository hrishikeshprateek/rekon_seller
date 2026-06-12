package com.reckon.reckonorders.NewDesign.NewFragments;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.databinding.FragmentAccountDetailsBinding;



public class AccountDetailsFragment extends BaseFragment {
    FragmentAccountDetailsBinding binding;
    LoginModel model = null;
    String details="";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentAccountDetailsBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        getBundle();
        setUpUi();
    }

    private void getBundle() {
        Gson gson = new Gson();
        if (getArguments() != null && !getArguments().isEmpty()) {
            model = gson.fromJson(getArguments().getString(Constant.PARTY_LIST), new TypeToken<LoginModel>() {
            }.getType());
        }
    }


    private void setUpUi() {
        ((NewMainActivity) requireActivity()).setUpTitle(AccountDetailsFragment.this, getString(R.string.account_deatils));
        binding.shareDetailsCard.setCardBackgroundColor(getButtonColor());
        binding.tvFirmName.setTextColor(getSecondHeaderTextColor());
        boolean AccStatusBan = ReckonUtils.nonNullNotEmptyString(model.getAccountStatus()) && model.getAccountStatus().equalsIgnoreCase("BAN");
        if (model.getCountry_name() != null && !model.getCountry_name().isEmpty()) {
            binding.firmName.setTextColor(AccStatusBan? getResources().getColor(R.color.red):getSecondHeaderTextColor());
            binding.firmName.setText(model.getCountry_name());
            binding.firmName.setVisibility(View.VISIBLE);
            binding.firmSeparatorView.setVisibility(View.VISIBLE);
            binding.tvFirmName.setVisibility(View.VISIBLE);
            details=getString(R.string.firm_name).concat(":").concat(model.getCountry_name());
        }
        if (model.getAdd1() != null && !model.getAdd1().isEmpty()) {
            if(model.getAdd2()!=null && model.getAdd3()!=null){
                binding.address.setText(model.getAdd1().trim() +"\n"+ model.getAdd2().trim()+"\n"+  model.getAdd3().trim());
                details=details+"\n"+getString(R.string.address).concat(getString(R.string.colon)).concat(model.getAdd1().concat(model.getAdd2() ) .concat(model.getAdd3()));
            }else if (model.getAdd2()!=null && model.getAdd3()==null){
                binding.address.setText(model.getAdd1().trim() +"\n"+ model.getAdd2().trim());
                details=details+"\n"+getString(R.string.address).concat(getString(R.string.colon)).concat(model.getAdd1().concat(model.getAdd2() ));
            }else if(model.getAdd2()==null && model.getAdd3()==null){
                binding.address.setText(model.getAdd1().trim());
                details=details+"\n"+getString(R.string.address).concat(getString(R.string.colon)).concat(model.getAdd1());
            }
            binding.address.setVisibility(View.VISIBLE);
            binding.addressSeparatorView.setVisibility(View.VISIBLE);
            binding.tvAddress.setVisibility(View.VISIBLE);
        }
        if (model.getPinCode() != null && !model.getPinCode().isEmpty()) {
            binding.pinCode.setText(model.getPinCode());
            binding.pinCode.setVisibility(View.VISIBLE);
            binding.pinCodeSeparatorView.setVisibility(View.VISIBLE);
            details=details+"\n"+getString(R.string.pinCode).concat(getString(R.string.colon)).concat(model.getPinCode());
        }
        if (model.getArea() != null && !model.getArea().isEmpty()) {
            binding.area.setText(model.getArea());
            binding.area.setVisibility(View.VISIBLE);
            binding.tvArea.setVisibility(View.VISIBLE);
            binding.areaSeparatorView.setVisibility(View.VISIBLE);
            details=details+"\n"+getString(R.string.area).concat(getString(R.string.colon)).concat(model.getArea());
        }

        if (model.getCity() != null && !model.getCity().isEmpty()) {
            binding.city.setText(model.getCity());
            binding.city.setVisibility(View.VISIBLE);
            binding.tvCity.setVisibility(View.VISIBLE);
            binding.citySeparatorView.setVisibility(View.VISIBLE);
            details=details+"\n"+getString(R.string.city).concat(getString(R.string.colon)).concat(model.getCity());
        }
        if (model.getState() != null && !model.getState().isEmpty()) {
            binding.state.setText(model.getState());
            binding.state.setVisibility(View.VISIBLE);
            binding.tvState.setVisibility(View.VISIBLE);
            binding.stateSeparatorView.setVisibility(View.VISIBLE);
            details=details+"\n"+getString(R.string.state).concat(getString(R.string.colon)).concat(model.getState());
        }

        if (model.getMobile() != null && !model.getMobile().isEmpty()) {
            binding.mobileNumber.setText(model.getMobile());
            binding.mobileNumber.setVisibility(View.VISIBLE);
            binding.tvMobile.setVisibility(View.VISIBLE);
            binding.mobileSeparatorView.setVisibility(View.VISIBLE);
            details=details+"\n"+getString(R.string.mobile).concat(getString(R.string.colon)).concat(model.getMobile());
        }
        if (model.getGstNumber() != null && !model.getGstNumber().isEmpty()) {
            binding.gstNumber.setText(model.getGstNumber());
            binding.tvGSTNumber.setVisibility(View.VISIBLE);
            binding.gstNumber.setVisibility(View.VISIBLE);
            binding.gstSeparatorView.setVisibility(View.VISIBLE);
            details=details+"\n"+getString(R.string.gst_number).concat(getString(R.string.colon)).concat(model.getGstNumber());
        }
        if (model.getEmail() != null && !model.getEmail().isEmpty()) {
            binding.emailTv.setText(model.getEmail());
            binding.tvEmail.setVisibility(View.VISIBLE);
            binding.emailTv.setVisibility(View.VISIBLE);
            binding.emailSeparatorView.setVisibility(View.VISIBLE);
            details=details+"\n"+getString(R.string.email_id).concat(getString(R.string.colon)).concat(model.getEmail());
        }

        if(ReckonUtils.nonNullNotEmptyString(model.getAccountCreditDays())){
            binding.creditDays.setText(model.getAccountCreditDays());
            binding.creditDaysSeparatorView.setVisibility(View.VISIBLE);
        }else{
            binding.creditDaysSeparatorView.setVisibility(View.GONE);
        }

        if(ReckonUtils.nonNullNotEmptyString(model.getAccountCreditLimit())){
            binding.creditLimit.setText(model.getAccountCreditLimit());
            binding.creditLimitSeparatorView.setVisibility(View.VISIBLE);
        }else{
            binding.creditLimitSeparatorView.setVisibility(View.GONE);
        }

        if(ReckonUtils.nonNullNotEmptyString(model.getAccountCreditBills())){
            binding.creditBills.setText(model.getAccountCreditBills());
            binding.creditBillsSeparatorView.setVisibility(View.VISIBLE);
        }else{
            binding.creditBillsSeparatorView.setVisibility(View.GONE);
        }


        binding.shareDetails.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(Intent.createChooser(new Intent().setAction(Intent.ACTION_SEND).putExtra(Intent.EXTRA_TEXT, details).setType("text/plain"), getResources().getText(R.string.send_to)));
            }
        });
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        ((NewMainActivity) requireActivity()).setUpTitle(AccountDetailsFragment.this, getString(R.string.account_statement));
    }
}