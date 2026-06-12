package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.StatementRowAdapters;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentSaleVoucherBinding;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link SaleVoucherFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class SaleVoucherFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    FragmentSaleVoucherBinding binding;
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    private String mParam1;
    private String mParam2;
    private String statementId, previousTitle="", keyEntrySrNo, isEntryRecord;
    private boolean isSalesMan;

    public static SaleVoucherFragment newInstance(String param1, String param2) {
        SaleVoucherFragment fragment = new SaleVoucherFragment();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mParam1 = getArguments().getString(ARG_PARAM1);
            mParam2 = getArguments().getString(ARG_PARAM2);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentSaleVoucherBinding.inflate(inflater, container, false);
        retrofitCallBackListener = this;
        previousTitle = NewMainActivity.binding.appBarNewMain.pageName.getText().toString();
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        getBundle();
        new Handler().postDelayed(() -> getAccountLedgerDetails(), 1000);
        return binding.getRoot();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        ((NewMainActivity) requireActivity()).setUpTitle(SaleVoucherFragment.this, previousTitle);
    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            String from = bundle.containsKey(Constant.FROM) ? bundle.getString(Constant.FROM) : "";
            statementId = bundle.containsKey(Constant.STATEMENT_ID) ? bundle.getString(Constant.STATEMENT_ID) : "";
            keyEntrySrNo = bundle.containsKey(Constant.KEY_ENTRY_SR_NO) ? bundle.getString(Constant.KEY_ENTRY_SR_NO) : "";
            isEntryRecord = bundle.containsKey(Constant.IS_ENTRY_RECORD) ? bundle.getString(Constant.IS_ENTRY_RECORD) : "";

        }
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        binding.nestedSv.setVisibility(View.GONE);
        binding.shareSaleInvoiceCard.setVisibility(View.GONE);
        binding.loadingView.setVisibility(View.VISIBLE);
        binding.noDataView.setVisibility(View.GONE);
        binding.tvDispatchDetail.setTextColor(getSecondHeaderTextColor());
        binding.tvTotalValueOfBill.setTextColor(getSecondHeaderTextColor());
        binding.tvBillDetails.setTextColor(getSecondHeaderTextColor());
        binding.tvOrderDetails.setTextColor(getSecondHeaderTextColor());
        binding.tvVoucherNumber.setTextColor(getSecondHeaderTextColor());
        binding.firmName.setTextColor(getSecondHeaderTextColor());
        binding.shareSaleInvoice.setCardBackgroundColor(getButtonColor());
        binding.tvTotalValueOfBillHeading.setTextColor(getSecondHeaderTextColor());
        binding.billDetailsRv.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
        binding.dispatchDetailsRv.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
        binding.adjustDetailsRv.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));

    }

    private void getAccountLedgerFile(String licNo) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", isSalesMan? getLicDetails().getLicno():ReckonUtils.nonNullNotEmptyString(getLicDetails().getLicno())?getLicDetails().getLicno():licNo);
            jsonObject.put("lKeyEntryNo", statementId);
            jsonObject.put("lKeyEntrySrNo", keyEntrySrNo);
            jsonObject.put("lIsEntryRecord", isEntryRecord);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().GetFile(String.valueOf(jsonObject)), Constant.GET_FILE, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    private void getAccountLedgerDetails() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lKeyEntryNo", statementId);
            jsonObject.put("lKeyEntrySrNo", keyEntrySrNo);
            jsonObject.put("lIsEntryRecord", isEntryRecord);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getAccountLedgerDetails(String.valueOf(jsonObject)), Constant.ACCOUNT_LEDGER_DETAILS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
            switch (action) {
                case Constant.ACCOUNT_LEDGER_DETAILS:
                    if (result != null && result.length() > 2) {
                    JSONObject jsonObject = new JSONObject(result);
                    if (!ReckonUtils.getJsonCheckedString(jsonObject, "number", "").isEmpty()) {
                        binding.nestedSv.setVisibility(View.VISIBLE);
                        binding.shareSaleInvoiceCard.setVisibility(View.VISIBLE);
                        binding.loadingView.setVisibility(View.GONE);
                        binding.noDataView.setVisibility(View.GONE);
                    } else {
                        binding.nestedSv.setVisibility(View.GONE);
                        binding.shareSaleInvoiceCard.setVisibility(View.VISIBLE);
                        binding.noDataView.setVisibility(View.VISIBLE);
                    }
                    ((NewMainActivity) requireActivity()).setUpTitle(SaleVoucherFragment.this, ReckonUtils.getJsonCheckedString(jsonObject, "transection_title", ""));
                    binding.firmName.setText(ReckonUtils.getJsonCheckedString(jsonObject, "acc_name", ""));
                    binding.tvAddress.setText(ReckonUtils.getJsonCheckedString(jsonObject, "acc_address", ""));
                    binding.tvLastPayment.setText(ReckonUtils.getJsonCheckedString(jsonObject, "transection_type", ""));
                    binding.tvVoucherNumber.setText(ReckonUtils.getJsonCheckedString(jsonObject, "number", ""));
                    binding.tvDate.setText(ReckonUtils.getJsonCheckedString(jsonObject, "date", ""));
                    binding.paymentStatus.setText(ReckonUtils.getJsonCheckedString(jsonObject, "payment", ""));

                    if (jsonObject.has("bill_details") && jsonObject.getJSONObject("bill_details").length() > 0) {
                        binding.billDetailsLL.setVisibility(View.VISIBLE);
                        JSONObject object = jsonObject.getJSONObject("bill_details");
                        binding.tvBillDetails.setText(ReckonUtils.getJsonCheckedString(object, "title", ""));
                        binding.tvBillDetails.setTextColor(!ReckonUtils.getJsonCheckedString(object, "title_color", "").isEmpty() ?
                                Color.parseColor(ReckonUtils.getJsonCheckedString(object, "title_color", "")) : getSecondHeaderTextColor());
                        binding.billDetailsRv.setAdapter(new StatementRowAdapters(this, parseStatementItemsJson(object, Constant.BILL_DETAILS) ));
                        if(object.has("total") && object.getJSONObject("total").length()>0){
                            JSONObject obj = object.getJSONObject("total");
                            binding.tvTotalBillDetails.setVisibility(View.VISIBLE);
                            binding.tvTotalValueOfBillHeading.setText(ReckonUtils.getJsonCheckedString(obj, "title", ""));
                            binding.tvTotalValueOfBill.setText(ReckonUtils.getJsonCheckedString(obj, "value", ""));
                        }else{
                            binding.tvTotalBillDetails.setVisibility(View.GONE);
                        }

                    } else {
                        binding.billDetailsLL.setVisibility(View.GONE);
                    }

                    if (jsonObject.has("dispatch_details") && jsonObject.getJSONObject("dispatch_details").length() > 0) {
                        binding.dispatchDetailsLL.setVisibility(View.VISIBLE);
                        JSONObject object = jsonObject.getJSONObject("dispatch_details");
                        binding.tvDispatchDetail.setText(ReckonUtils.getJsonCheckedString(object, "title", ""));
                        binding.tvDispatchDetail.setTextColor(!ReckonUtils.getJsonCheckedString(object, "title_color", "").isEmpty() ?
                                Color.parseColor(ReckonUtils.getJsonCheckedString(object, "title_color", "")) : getSecondHeaderTextColor());
                        binding.dispatchDetailsRv.setAdapter(new StatementRowAdapters(this, parseStatementItemsJson(object, Constant.DISPATCH_DETAILS) ));
                    } else {
                        binding.dispatchDetailsLL.setVisibility(View.GONE);
                    }

                    if (jsonObject.has("adjustment_details") && jsonObject.getJSONObject("adjustment_details").length() > 0) {
                        binding.adjustDetailsLL.setVisibility(View.VISIBLE);
                        JSONObject object = jsonObject.getJSONObject("adjustment_details");
                        binding.tvAdjustDetail.setText(ReckonUtils.getJsonCheckedString(object, "title", ""));
                        binding.tvAdjustDetail.setTextColor(!ReckonUtils.getJsonCheckedString(object, "title_color", "").isEmpty() ?
                                Color.parseColor(ReckonUtils.getJsonCheckedString(object, "title_color", "")) : getSecondHeaderTextColor());
                        binding.adjustDetailsRv.setAdapter(new StatementRowAdapters(this, parseStatementItemsJson(object, Constant.DISPATCH_DETAILS) ));
                    } else {
                        binding.adjustDetailsLL.setVisibility(View.GONE);
                    }
                    binding.shareSaleInvoiceCard.setOnClickListener(view1 -> {
                        getAccountLedgerFile(ReckonUtils.getJsonCheckedString(jsonObject, "LicNo", ""));
                    });
                    }
                    break;
                case Constant.GET_FILE:
                    String pdfLink = /*ReckonUtils.getJsonCheckedString(obj, "link", "")*/result;
                    if (ReckonUtils.isPDFValid(pdfLink)) {
//                        ReckonUtils.downloadAndSharePdf(pdfLink, requireActivity(), shareViaWhatsapp, docName);
                        ReckonUtils.viewPdf(requireActivity(), pdfLink);
                    } else {
                        Toast.makeText(requireActivity(), getResources().getString(R.string.fill_not_found), Toast.LENGTH_LONG).show();
                    }
                    break;
        }/*else{
            binding.loadingView.setVisibility(View.GONE);
            binding.noDataView.setVisibility(View.VISIBLE);
            binding.nestedSv.setVisibility(View.GONE);
            binding.shareSaleInvoiceCard.setVisibility(View.GONE);

        }*/
    }

}