package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.TOTAL_VALUE;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.GridLayoutManager;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.OrderDetailsModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.Model.TimeSlotModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.NewArrivalAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.Profile;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentDeliveryDetailsBinding;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;

public class DeliveryDetails extends BaseFragment {
    private RetrofitCallBackListener retrofitCallBackListener;
    NewArrivalAdapter adapter;
    FragmentDeliveryDetailsBinding binding;
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    ArrayList<String> dateList;
    String deliveryAddress = "", mobileNumber = "";
    double netValue = 0, discount = 0, deliveryCharges = 0, totalAmount = 0;
    private String selectedTimeSlot = "";
    private String nameAddress = "";
    private boolean isSalesMan;
    private Gson gson = new Gson();
    private StoreDetailObjectModel selectedPartyDataModel;
    private ArrayList<TimeSlotModel> timeSlot;

    public static DeliveryDetails newInstance(String param1, String param2) {
        DeliveryDetails fragment = new DeliveryDetails();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentDeliveryDetailsBinding.inflate(getLayoutInflater());
        retrofitCallBackListener = this;
        return binding.getRoot();
    }

    public void setLayoutManager(int column) {
        binding.recyclerDate.setLayoutManager(new GridLayoutManager(getActivity(), column));
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        String space = " ";

        ((NewMainActivity) requireActivity()).setUpTitle(DeliveryDetails.this, getString(R.string.delivery_details));
        binding.proceedSubmitCard.setBackgroundColor(getButtonColor());
        binding.coloredCardView.setCardBackgroundColor(getSecondHeaderTextColor());
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        Profile profile = getUserProfile();
        nameAddress = profile.getNAME();
        mobileNumber = profile.getMOBILENO();
        if (getArguments() != null) {
            netValue = Double.parseDouble(getArguments().getString(TOTAL_VALUE));
            selectedPartyDataModel = gson.fromJson(getArguments().getString(Constant.PARTY), new TypeToken<StoreDetailObjectModel>() {
            }.getType());
        }
        if (!isSalesMan) {
            binding.tvDefaultUserName.setText(profile.getNAME()!=null?profile.getNAME():"");
            binding.tvDefaultAddress.setText((profile.getADDRESS1() + space + profile.getAREA() + space + profile.getCITY() + space + profile.getSTATE() + space + profile.getPINCODE()).toUpperCase());
            binding.tvContactNumber.setText(getString(R.string.contact_number) + "\n" + "+" + profile.getMOBILENO()!=null?profile.getMOBILENO():"");
        } else {
            binding.tvDefaultUserName.setText(selectedPartyDataModel.getName()!=null?selectedPartyDataModel.getName():"");
            binding.tvDefaultAddress.setText(selectedPartyDataModel.getAdd1() + selectedPartyDataModel.getAdd2() + selectedPartyDataModel.getAdd3() + selectedPartyDataModel.getPinCode());
            binding.tvContactNumber.setText(getString(R.string.contact_number) + "\n" + "+" + selectedPartyDataModel.getMobile()!=null?selectedPartyDataModel.getMobile():"");
        }
        if (getStoreDetails() != null) {
            binding.cardPickupStore.setVisibility(View.VISIBLE);
            StoreDetailObjectModel storeDetails = getStoreDetails();
            binding.tvStoreName.setText(storeDetails.getName());
            binding.tvStoreAddress.setText(storeDetails.getAdd1());
            binding.tvStoreAddress2.setText(storeDetails.getAdd2());
            binding.tvStoreAddress3.setText(storeDetails.getAdd3());
            binding.tvStorePinCode.setText(storeDetails.getPinCode());
            binding.tvStoreName.setVisibility(storeDetails.getName().isEmpty()? View.GONE : View.VISIBLE);
            binding.tvStoreAddress.setVisibility(storeDetails.getAdd1().isEmpty() ? View.GONE : View.VISIBLE);
            binding.tvStoreAddress2.setVisibility(ReckonUtils.nonNullNotEmptyString(storeDetails.getAdd2()) ? View.VISIBLE : View.GONE);
            binding.tvStoreAddress3.setVisibility(storeDetails.getAdd3().isEmpty() ? View.GONE : View.VISIBLE);
            binding.tvStorePinCode.setVisibility(storeDetails.getPinCode().isEmpty() ? View.GONE : View.VISIBLE);
            binding.tvStoreContactNo.setText(storeDetails.getMobile());
            binding.tvStoreContactNo.setVisibility(storeDetails.getMobile().isEmpty() ? View.GONE : View.VISIBLE);
            binding.tvContact.setVisibility(storeDetails.getMobile().isEmpty() ? View.GONE : View.VISIBLE);
            binding.cvStoreAddress.setVisibility(storeDetails.getName().isEmpty() ? View.GONE : View.VISIBLE);
        }else{
            binding.cardPickupStore.setVisibility(View.GONE);
        }
        timeSlot = new ArrayList<>();
        try {
            JSONArray jsonArray = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.TIME_SLOT));
            for (int i = 0; i < jsonArray.length(); i++) {
                timeSlot.add(new TimeSlotModel(ReckonUtils.getJsonCheckedString(jsonArray.getJSONObject(i), "ODate", ""),
                        ReckonUtils.getJsonCheckedString(jsonArray.getJSONObject(i), "DayName", "")));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        binding.radioStoreAddress.setOnClickListener(v -> {
            binding.radioDefaultAddress.setChecked(false);
            binding.radioStoreAddress.setChecked(true);
            deliveryAddress = binding.radioStoreAddress.getText().toString();
            if(getStoreDetails()!=null){
                mobileNumber = getStoreDetails().getMobile()!=null?getStoreDetails().getMobile():"";
                nameAddress = getStoreDetails().getName()!=null?getStoreDetails().getName():"";
            }
        });
        binding.radioDefaultAddress.setOnClickListener(v -> {
            binding.radioStoreAddress.setChecked(false);
            binding.radioDefaultAddress.setChecked(true);
            deliveryAddress = binding.radioDefaultAddress.getText().toString();
            mobileNumber = getUserProfile().getMOBILENO()!=null?getUserProfile().getMOBILENO():"";
            nameAddress = getUserProfile().getNAME()!=null?getUserProfile().getNAME():"";
        });
        binding.deliverHeading.setText(getResources().getString(R.string.deliver_to_your_location));
        binding.deliverHeading.setTextColor(getSecondHeaderTextColor());
        selectedTimeSlot = !timeSlot.isEmpty() ? timeSlot.get(0).getDate() : "";
        adapter = new NewArrivalAdapter(DeliveryDetails.this, binding.recyclerDate.getWidth(), timeSlot, 0);
        binding.recyclerDate.setAdapter(adapter);
        binding.proceedToPayment.setOnClickListener(v -> {
            if (ReckonUtils.isRetailer(requireActivity())) {
                submitCartOrder();
            } else {
                if (!selectedTimeSlot.isEmpty())
                    submitCartOrder();
                else
                    Toast.makeText(getActivity(), getString(R.string.please_select_deliver_date), Toast.LENGTH_LONG).show();
            }

//            NavHostFragment.findNavController(DeliveryDetails.this).navigate(R.id.nav_payment_details);
        });
        binding.recyclerDate.getMeasuredWidth();
        binding.cardPickupStore.setVisibility(isSalesMan ? View.GONE :getStoreDetails()!=null? View.VISIBLE:View.GONE);
        getOrderDetails();
    }


    private void submitCartOrder() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lFirmCode", isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : getLicDetails().getFirmcode());
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            jsonObject.put("lNote", binding.etComment.getText().toString());
            jsonObject.put("lSlotTime", selectedTimeSlot);
            jsonObject.put("lDelAdd", getSelectedDelAdd());
            jsonObject.put("lTotalAmt", totalAmount);
            jsonObject.put("AcCode", isSalesMan ? SharedPrefUtils.getString(getActivity(), Constant.PARTY_CODE) : SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
            jsonObject.put("lDelMode", binding.radioStoreAddress.isChecked() ? "1" : "0");
            jsonObject.put("device_id", SharedPrefUtils.getString(getActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("lUserRole", getLicDetails().getRole());
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().SubmitItemFromCart(String.valueOf(jsonObject)), Constant.SUBMITCART, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void getOrderDetails() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("AcCode", isSalesMan ? SharedPrefUtils.getString(getActivity(), Constant.PARTY_CODE) : SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
            jsonObject.put("lFirmCode", isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : getLicDetails().getFirmcode());
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostDraftOrderDetails(String.valueOf(jsonObject)), Constant.DRAFT_ORDER_DETAILS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void getSlotTime(String dates) {
        selectedTimeSlot = dates;
    }

    private String getSelectedDelAdd() {//2023-12-07
        String add = "";
        if (binding.radioDefaultAddress.isChecked()) {
            add = binding.tvDefaultAddress.getText().toString();
        } else if (binding.radioStoreAddress.isChecked()) {
            add = binding.tvStoreAddress.getText().toString()
                    + (!binding.tvStoreAddress2.getText().toString().isEmpty() ? (", " + binding.tvStoreAddress2.getText().toString()) : "")
                    + (!binding.tvStoreAddress3.getText().toString().isEmpty() ? (", " + binding.tvStoreAddress3.getText().toString()) : "")
                    + (!binding.tvStorePinCode.getText().toString().isEmpty() ? (", " + binding.tvStorePinCode.getText().toString()) : "");
            //         + (!mobileNumber.isEmpty() ? (", " + mobileNumber) : "");
        }
        return add;
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) {
        if (result != null) {
            try {
                JSONObject jsonObj = new JSONObject(result);
                switch (action) {
                    case Constant.SUBMITCART:
                        if (jsonObj.getString("Status").equalsIgnoreCase("true")) {
                            ArrayList<OrderDetailsModel> arrayList = new ArrayList();
                            JSONArray jsonArray = jsonObj.has("Orders") ? jsonObj.getJSONArray("Orders") : new JSONArray();
                            for (int i = 0; i < jsonArray.length(); i++) {
                                OrderDetailsModel myOrderModel = new OrderDetailsModel();
                                JSONObject jsonObj1 = jsonArray.getJSONObject(i);
                                myOrderModel.setOrderId(ReckonUtils.getJsonCheckedString(jsonObj1, "OrderId", ""));
                                myOrderModel.setPlacedOn(ReckonUtils.getJsonCheckedString(jsonObj1, "PlacedOn", ""));
                                myOrderModel.setOrderStatus(ReckonUtils.getJsonCheckedString(jsonObj1, "OrderStatus", ""));
                                myOrderModel.setOrderValue(ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObj1, "OrderValue", "0.0")));
                                myOrderModel.setPaymentMode(ReckonUtils.getJsonCheckedString(jsonObj1, "PaymentMode", ""));
                                myOrderModel.setDeliveryDate(ReckonUtils.getJsonCheckedString(jsonObj1, "DeliveryDate", ""));
                                myOrderModel.setDeliveryMode(ReckonUtils.getJsonCheckedString(jsonObj1, "DeliveryMode", ""));
                                myOrderModel.setNoOfItem(ReckonUtils.getJsonCheckedString(jsonObj1, "NoOfItem", "0"));
                                myOrderModel.setDeliveryAddress(ReckonUtils.getJsonCheckedString(jsonObj1, "DelAdd", ""));
                                myOrderModel.setStatue(ReckonUtils.getJsonCheckedString(jsonObj1, "Status", ""));
                                myOrderModel.setMessage(ReckonUtils.getJsonCheckedString(jsonObj1, "Message", ""));
                                myOrderModel.setFirmName(ReckonUtils.getJsonCheckedString(jsonObj1, "firm_name", ""));
/*
                                        "DiscAmt": 0,
                                        "Disc1Amt": 0,
                                        "Disc2Amt": 0,
                                        "ItemAmt": 3136.14,
                                        "SchAmt": 0,
                                        "TaxAmt": 564.51,
                                        "SlotTime": "2025-01-10",
                                        */
                                arrayList.add(myOrderModel);
                            }
                            Gson gson = new Gson();
                            Bundle bundle = new Bundle();
                            bundle.putString("orderModel", gson.toJson(arrayList));
                            bundle.putString("mobileNumber", mobileNumber);
                            bundle.putString("nameAddress", nameAddress);
                            bundle.putString(Constant.PARTY, gson.toJson(selectedPartyDataModel));
                            NavHostFragment.findNavController(DeliveryDetails.this).navigate(R.id.nav_order_confirmation, bundle);
                            Toast.makeText(getActivity(), jsonObj.getString("Message"), Toast.LENGTH_LONG).show();
                        } else {
                            Toast.makeText(getActivity(), jsonObj.getString("Message"), Toast.LENGTH_LONG).show();
                            if (!ReckonUtils.getJsonCheckedBoolean(jsonObj, "IsStockExist", false)) {
                                requireActivity().onBackPressed();
                            }
                        }
                        break;
                    case Constant.DRAFT_ORDER_DETAILS:
                        if (jsonObj.getString("Status").equalsIgnoreCase("true")) {
                            String totalAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObj, "NetAmt", "0"));
                            String amt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObj, "Amt", "0"));
                            String gstAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObj, "TaxAmt", "0"));
                            String schCharges = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObj, "SchAmt", "0"));
                            String Disc1Amt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObj, "Disc1Amt", "0.0"));
                            String DiscAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObj, "DiscAmt", "0.0"));
                            String discount = "0";
                            try {
                                discount = ReckonUtils.roundTwoDecimals(String.valueOf((Double.parseDouble(Disc1Amt) + Double.parseDouble(DiscAmt))));
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                            binding.paymentDetailCardIncluder.tvDiscountCharges.setText(getLicDetails().getCurrency() + discount);
                            binding.paymentDetailCardIncluder.netValueAmount.setText(getLicDetails().getCurrency() + amt);
                            binding.paymentDetailCardIncluder.discountAmount.setText(getLicDetails().getCurrency() + schCharges);
                            binding.paymentDetailCardIncluder.deliveryCharges.setText(getLicDetails().getCurrency() + deliveryCharges);
                            binding.paymentDetailCardIncluder.gstAmount.setText(getLicDetails().getCurrency() + (ReckonUtils.nonNullNotEmptyString(gstAmt) ? gstAmt : "0"));
                            binding.paymentDetailCardIncluder.tvTotalAmount.setText(getLicDetails().getCurrency() + totalAmt);
                        }
                        break;
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}