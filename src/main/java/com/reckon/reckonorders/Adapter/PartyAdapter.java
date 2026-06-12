package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.core.content.ContextCompat;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.reckon.reckonorders.Fragment.Home.PartyListingFragment;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.PartyDetailsListingLayoutBinding;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import butterknife.ButterKnife;

public class PartyAdapter extends RecyclerView.Adapter<PartyAdapter.SelectionSingleViewHolder> implements RetrofitCallBackListener {
    private final RetrofitCallBackListener retrofitCallBackListener;

    private List<LoginModel> data;
    private PartyListingFragment fragment;
    String type;
    private AlertDialog alertDialog = null;
    private LoginModel selectedModelData;
    private String selectiveAddress;
    private String sourceScreen;

    public PartyAdapter(PartyListingFragment fragment, ArrayList<LoginModel> data, String type, String _sourceScreen) {
        this.data = data;
        this.fragment = fragment;
        this.type = type;
        this.retrofitCallBackListener = this;
        this.sourceScreen = _sourceScreen;
    }


    @Override
    public SelectionSingleViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        return new SelectionSingleViewHolder(PartyDetailsListingLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
//        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.party_row_layout, parent, false);
//        return new SelectionSingleViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final SelectionSingleViewHolder holder, int position) {
        LoginModel dataPos = data.get(position);
        boolean AccStatusBan = ReckonUtils.nonNullNotEmptyString(dataPos.getAccountStatus()) && dataPos.getAccountStatus().equalsIgnoreCase("BAN");
        holder.binding.tvAccountName.setTextColor(AccStatusBan? fragment.getResources().getColor(R.color.red):fragment.getSecondHeaderTextColor());
        holder.binding.balance.setTextColor(fragment.getSecondHeaderTextColor());
        holder.binding.lastPaymentDate.setTextColor(fragment.getSecondHeaderTextColor());
        holder.binding.callButton.setTextColor(fragment.getSecondHeaderTextColor());

        //drawable code
        //TODO:Place Code For Drawable Tint
        for (Drawable drawable : holder.binding.callButton.getCompoundDrawables()) {
            if (drawable != null) {
                try {
                    drawable.setColorFilter(new PorterDuffColorFilter(ContextCompat.getColor(holder.binding.callButton.getContext(), fragment.getSecondHeaderTextColor()), PorterDuff.Mode.SRC_IN));
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

        if (dataPos.getCountry_name() != null && !dataPos.getCountry_name().isEmpty())
            holder.binding.tvAccountName.setText(dataPos.getCountry_name());
        else
            holder.binding.tvAccountName.setVisibility(View.GONE);

        holder.binding.distanceTv.setText(dataPos.getDistance() + " Km");
        holder.binding.distanceTv.setVisibility(ReckonUtils.nonNullNotEmptyString(dataPos.getDistance()) ? View.VISIBLE : View.GONE);

        if (dataPos.getMobile() != null && !dataPos.getMobile().isEmpty())
            holder.binding.tvMobileNumber.setText(dataPos.getMobile());
        else
            holder.binding.tvMobileNumber.setVisibility(View.GONE);
        if (dataPos.getGstNumber() != null && !dataPos.getGstNumber().isEmpty())
            holder.binding.tvGSTNumber.setText(dataPos.getGstNumber());
        else
            holder.binding.tvGSTNumber.setVisibility(View.GONE);
        if (dataPos.getAdd1() != null && !dataPos.getAdd1().isEmpty()) {
            String address = "";
            if (!dataPos.getAdd2().isEmpty() && !dataPos.getAdd3().isEmpty()) {
                address = dataPos.getAdd1() + ", " + dataPos.getAdd2() + ", " + dataPos.getAdd3();
            } else if (!dataPos.getAdd2().isEmpty()) {
                address = dataPos.getAdd1() + ", " + dataPos.getAdd2();
            } else {
                address = dataPos.getAdd1();
            }
            holder.binding.tvAddress.setText(address.trim());
            holder.binding.tvAddress.setVisibility(View.VISIBLE);
        } else {
            holder.binding.tvAddress.setVisibility(View.GONE);
        }
//        holder.binding.balanceLl.setVisibility(!dataPos.getClosingBalance().equalsIgnoreCase("") && !dataPos.getClosingBalance().equalsIgnoreCase("0")? View.VISIBLE: View.GONE);
        holder.binding.balance.setText(fragment.getLicDetails().getCurrency() + dataPos.getClosingBalance());

        //  holder.email_txt.setText(dataPos.getEmail());
        // holder.address_txt2.setText(dataPos.getAdd2());
        //  holder.address_txt3.setText(dataPos.getAdd3());`
        if (type.equalsIgnoreCase(Constant.FIRM)) {
            holder.binding.lastPaymentHolder.setVisibility(View.GONE);
            holder.binding.tvCustomerType.setVisibility(View.GONE);
            holder.binding.cardViewParty.setVisibility(View.GONE);
            holder.binding.updateLocationCv.setVisibility(View.GONE);
            holder.binding.goToGLocationCv.setVisibility(View.GONE);
        } else {
            holder.binding.lastPaymentHolder.setVisibility(View.VISIBLE);
            holder.binding.tvCustomerType.setVisibility(View.GONE);
            holder.binding.cardViewParty.setVisibility(View.VISIBLE);
            holder.binding.updateLocationCv.setVisibility(!dataPos.isShowUpdateLocation() ? View.VISIBLE : View.GONE);
            holder.binding.goToGLocationCv.setVisibility(ReckonUtils.nonNullNotEmptyString(dataPos.getLatitude()) ? View.VISIBLE : View.GONE);
        }
        holder.binding.locationBtnLl.setVisibility(SharedPrefUtils.getShowLocation(fragment.requireActivity()) ? View.VISIBLE : View.GONE);
        holder.binding.imageCall.setOnClickListener(v -> {
            if (!dataPos.getMobile().isEmpty())
                ReckonUtils.performCall(fragment.requireActivity(), dataPos.getMobile());
        });
        holder.binding.updateLocationCv.setOnClickListener(v -> {
            if (!dataPos.isShowUpdateLocation()) {
                showUpdateLocationDialog(dataPos, position);
            }
        });
        holder.binding.goToGLocationCv.setOnClickListener(v -> {
            if (fragment != null && ReckonUtils.nonNullNotEmptyString(dataPos.getLatitude()) && ReckonUtils.nonNullNotEmptyString(dataPos.getLongitude())) {
                ReckonUtils.openGoogleMapIntent(fragment.getActivity(), Double.parseDouble(dataPos.getLatitude()), Double.parseDouble(dataPos.getLongitude()), dataPos.getCountry_name());
            }
        });
        if (dataPos.getMobile().equalsIgnoreCase("")) {
            holder.binding.mobileHolder.setVisibility(View.GONE);
            holder.binding.imageCall.setVisibility(View.GONE);
        }
        if (dataPos.getGstNumber().isEmpty())
            holder.binding.gstHolder.setVisibility(View.GONE);
        if (dataPos.getPaymentDate() == null || dataPos.getPaymentDate().isEmpty()) {
            holder.binding.tvLastPayment.setVisibility(View.INVISIBLE);
            holder.binding.lastPaymentDate.setVisibility(View.INVISIBLE);
        }
        if (dataPos.getCustomerType() == null || dataPos.getCustomerType().isEmpty()) {
            holder.binding.tvCustomerType.setVisibility(View.GONE);
        }

//        if (dataPos.getEmail().equalsIgnoreCase(""))
//            holder.email_row_ll.setVisibility(View.GONE);
//        if (dataPos.getAdd2().equalsIgnoreCase(""))
//            holder.add2_ll.setVisibility(View.GONE);
//        if (dataPos.getAdd3().equalsIgnoreCase(""))
//            holder.add3_ll.setVisibility(View.GONE);

        holder.binding.viewParty.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Bundle bundle = new Bundle();
                bundle.putString(Constant.PARTY_LIST, new Gson().toJson(data.get(position)));
                Navigation.findNavController(v).navigate(R.id.nav_account_details, bundle);
            }
        });
        holder.itemView.setOnClickListener(v -> {
            selectiveAddress = holder.binding.tvAddress.getText().toString();
            selectedModelData = dataPos;
            getAccountStatusAPI(dataPos);
        });

        if (position == data.size() - 1) {
            ReckonUtils.setLastVisibleItemMargin(holder.binding.parentCv, 20, 20, 20, 150);
        }
    }

    @Override
    public int getItemCount() {
        return data != null ? data.size() : 0;
    }

    static class SelectionSingleViewHolder extends RecyclerView.ViewHolder {
        PartyDetailsListingLayoutBinding binding;

        SelectionSingleViewHolder(PartyDetailsListingLayoutBinding binding) {
            super(binding.getRoot());
            this.binding = binding;
            ButterKnife.bind(this, itemView);
        }
    }

    private void showUpdateLocationDialog(LoginModel dataPos, int position) {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(fragment.requireActivity());
        alertDialogBuilder.setMessage(fragment.requireActivity().getString(R.string.location_update_msg));
        alertDialogBuilder.setPositiveButton("SEND",
                (arg0, arg1) -> {
                    fragment.fetchLocation(dataPos, position);
                    alertDialog.cancel();
                });
        alertDialogBuilder.setNegativeButton("CANCEL", (dialog, which) -> {
            alertDialog.cancel();
        });
        alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(fragment.getResources().getColor(R.color.black));
        alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(fragment.getResources().getColor(R.color.black));
    }

    private void getAccountStatusAPI(LoginModel dataPos) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", fragment.requireActivity().getPackageName());
            jsonObject.put("lLicNo", fragment.getLicDetails().getLicno());
            jsonObject.put("lUserId", SharedPrefUtils.getString(fragment.requireActivity(), Constant.USER_ID));
            jsonObject.put("account_id", dataPos.getAcIdCol());
            jsonObject.put("device_id", SharedPrefUtils.getString(fragment.requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(fragment.requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(fragment.requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(fragment.requireActivity(), Constant.ROLE));
            jsonObject.put("cu_id", SharedPrefUtils.getString(fragment.requireActivity(), Constant.USER_ID_CU));
            new ConnectToRetrofit(retrofitCallBackListener, fragment.requireActivity(), getApiClientByPost().getAccountStatus(String.valueOf(jsonObject)), Constant.GET_ACCOUNT_STATUS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            if (jsonObject.length() > 0) {
                switch (action) {
                    case Constant.GET_ACCOUNT_STATUS:
                        String msg = ReckonUtils.getJsonCheckedString(jsonObject, "Message", "");
                        if (sourceScreen.equalsIgnoreCase(Constant.NEW_ORDER) && ReckonUtils.nonNullNotEmptyString(msg)) {
                            showStatusDialog(msg, jsonObject.getBoolean("Status"));
                        }else{
                            fragment.getPartyData(selectedModelData.getCountry_id(), selectedModelData.getCountry_name(), selectedModelData.getShowStock(), selectiveAddress, new Gson().toJson(selectedModelData));
                        }
                        break;
                }
            }

        }
    }

    private void showStatusDialog(String msg, boolean status) {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(fragment.requireActivity());
//        alertDialogBuilder.setMessage(msg);
        alertDialogBuilder.setTitle(msg);
        alertDialogBuilder.setPositiveButton("Okay!",
                (arg0, arg1) -> {
                    if (status) {
                        fragment.getPartyData(selectedModelData.getCountry_id(), selectedModelData.getCountry_name(), selectedModelData.getShowStock(), selectiveAddress, new Gson().toJson(selectedModelData));
                    }
                    alertDialog.cancel();
                });
    /*    alertDialogBuilder.setNegativeButton("CANCEL", (dialog, which) -> {
            alertDialog.cancel();
        });*/
        alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(fragment.getResources().getColor(R.color.black));
        alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(fragment.getResources().getColor(R.color.black));
    }

}

