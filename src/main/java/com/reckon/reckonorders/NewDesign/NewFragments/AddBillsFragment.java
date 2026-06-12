package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.navigation.fragment.NavHostFragment;

import com.google.gson.Gson;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.AreaOutletAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.InvoiceModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentAddBillsBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link AddBillsFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class AddBillsFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private ArrayList<InvoiceModel> outstandingDataList = new ArrayList<>();

    // TODO: Rename parameter arguments, choose names that match
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    FragmentAddBillsBinding binding;
    private String previousTitle = "", accountName, accountCode, paymentMode = "", docNo, docDate, narration, firmCode="", firmName = "";
    private double receiptAmt = 0, adjustedAmt = 0, pendingAmt = 0, amount=0, discAmount=0;
    private AreaOutletAdapter areaOutletAdapter;

    public static AddBillsFragment newInstance(String param1, String param2) {
        AddBillsFragment fragment = new AddBillsFragment();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        retrofitCallBackListener = this;
        previousTitle = NewMainActivity.binding.appBarNewMain.pageName.getText().toString();
        if (getArguments() != null) {

        }
        getBundle();

    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            String from = bundle.containsKey(Constant.FROM) ? bundle.getString(Constant.FROM) : "";
            accountName = bundle.containsKey("name") ? bundle.getString("name") : "";
            accountCode = bundle.containsKey("Code") ? bundle.getString("Code") : "";
            firmName = bundle.containsKey("firm_name") ? bundle.getString("firm_name") : "";
            firmCode = bundle.containsKey("firm_code") ? bundle.getString("firm_code") : "";
            paymentMode = bundle.containsKey("pay_mode") ? bundle.getString("pay_mode") : "";
            docNo = bundle.containsKey("doc_no") ? bundle.getString("doc_no") : "";
            docDate = bundle.containsKey("doc_date") ? bundle.getString("doc_date") : "";
            narration = bundle.containsKey("narration") ? bundle.getString("narration") : "";
            receiptAmt = Double.parseDouble(bundle.containsKey("receipt_amount") ? bundle.getString("receipt_amount") : "0");
            amount = Double.parseDouble(bundle.containsKey("amount") ? bundle.getString("amount") : "0");
            discAmount = Double.parseDouble(bundle.containsKey("disc_amount") && ReckonUtils.nonNullNotEmptyString(bundle.getString("disc_amount")) ? bundle.getString("disc_amount") : "0");

            pendingAmt = receiptAmt;
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentAddBillsBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setUpUi();
    }

    private void setUpUi() {
        ((NewMainActivity) requireActivity()).setUpTitle(AddBillsFragment.this, getString(R.string.add_bills));
        binding.saveAndShareInnerCard.setCardBackgroundColor(getButtonColor());
        binding.receiptAmtTv.setText(getLicDetails().getCurrency() + receiptAmt);
        binding.adjustedAmtTv.setText(getLicDetails().getCurrency() + adjustedAmt);
        binding.pendingAmtTv.setText(getLicDetails().getCurrency() + pendingAmt);
        new Handler().postDelayed(this::getOutstandingData, 200);

        binding.autoAdjustCv.setOnClickListener(v -> {
            if(areaOutletAdapter!=null){
                clearValue();
                areaOutletAdapter.executeAutoAdjust();
            }
        });
        binding.clearAllCv.setOnClickListener(v -> {
            if (adjustedAmt > 0 && areaOutletAdapter!=null) {
                clearValue();
                areaOutletAdapter.notifyDataSetChanged();
            }
        });
        binding.saveAndAddCard.setOnClickListener(v -> {
            if (adjustedAmt > 0) {
                Bundle bundle = new Bundle();
                bundle.putString("name", accountName);
                bundle.putString("Code", accountCode);
                bundle.putString("firm_name", firmName);
                bundle.putString("firm_code", firmCode);
                bundle.putString("receipt_amount", "" + receiptAmt);
                bundle.putString("amount", "" + amount);
                bundle.putString("disc_amount", "" + discAmount);
                bundle.putString("pay_mode", paymentMode);
                bundle.putString("doc_no", docNo);
                bundle.putString("doc_date", docDate);
                bundle.putString("narration", narration);
                if(areaOutletAdapter!=null){
                    bundle.putString(Constant.SELECTED_ACCOUNT_LIST, new Gson().toJson(areaOutletAdapter.taggedDataList));
                }
                NavHostFragment.findNavController(this).navigate(R.id.action_back_to_receipt_entry_page, bundle);
//                Navigation.findNavController(requireActivity(), R.id.select_account_cv).navigate(R.id.navPartyLisingFragment, bundle);
//                Toast.makeText(requireActivity(), requireActivity().getString(R.string.workOnProgress), Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.selection_msg), Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void clearValue() {
        adjustedAmt = 0;
        pendingAmt = receiptAmt;
        binding.adjustedAmtTv.setText(getLicDetails().getCurrency() + adjustedAmt);
        binding.pendingAmtTv.setText(getLicDetails().getCurrency() + pendingAmt);
        if(areaOutletAdapter!=null){
            areaOutletAdapter.taggedDataList.clear();
        }
        for(InvoiceModel item : outstandingDataList){
            item.setAdjustmentAmount("");
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        ((NewMainActivity) requireActivity()).setUpTitle(this, previousTitle);
    }

    private void getOutstandingData() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lAcNo", accountCode);
            jsonObject.put("lPageNo", String.valueOf(1));
            jsonObject.put("lSize", String.valueOf(300));
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lFromDate", "");
            jsonObject.put("lTillDate", "");
            jsonObject.put("lAcId", "");
            jsonObject.put("firm_code", firmCode);
            jsonObject.put("lSearchFieldValue", "");
            jsonObject.put("lSharePdf", "false");
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getOutstanding(String.valueOf(jsonObject)), Constant.OUTSTANDING, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 1) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.OUTSTANDING:
                    try {
                        if (jsonObject.has("status") && jsonObject.getBoolean("status")) {
                        }
                        String msg = jsonObject.has("message") && !jsonObject.getString("message").isEmpty() ? jsonObject.getString("message") : getResources().getString(R.string.submit_successfully);
                        if (!outstandingDataList.isEmpty()) {
                            outstandingDataList.clear();
                        }
                        String outstanding = getLicDetails().getCurrency() + ReckonUtils.getJsonCheckedString(jsonObject, "outstanding_amount", "");
                        int totalListCount = Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "total_items", ""));

                        JSONArray jsonArray = jsonObject.getJSONArray("Items");
                        for (int i = 0; i < jsonArray.length(); i++) {
                            JSONObject object = jsonArray.getJSONObject(i);
                            InvoiceModel model = new InvoiceModel();
                            model.setEntryNo(ReckonUtils.getJsonCheckedString(object, "entryNo", ""));
                            model.setDate(ReckonUtils.getJsonCheckedString(object, "date", ""));
                            model.setAmount(ReckonUtils.getJsonCheckedString(object, "amount", ""));
                            model.setKeyEntryNo(ReckonUtils.getJsonCheckedString(object, "keyentryno", ""));
                            model.setDueDate(ReckonUtils.getJsonCheckedString(object, "due_date", ""));
                            model.setOverDue(ReckonUtils.getJsonCheckedString(object, "Over_due", ""));
                            model.setTranType(ReckonUtils.getJsonCheckedString(object, "trantype", ""));
                            model.setAdjustmentAmount("");
                            outstandingDataList.add(model);
                        }
                        areaOutletAdapter = new AreaOutletAdapter(AddBillsFragment.this, outstandingDataList);
                        binding.outletRecycler.setAdapter(areaOutletAdapter);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;

            }
        }

    }

    public void setVisibilityOfActionCard(ArrayList<InvoiceModel> taggedDataList, double mAdjustedAmt) {
        if (taggedDataList != null) {
            adjustedAmt = mAdjustedAmt;
            pendingAmt = (receiptAmt - mAdjustedAmt);
            binding.adjustedAmtTv.setText(getLicDetails().getCurrency() + adjustedAmt);
            binding.pendingAmtTv.setText(getLicDetails().getCurrency() + pendingAmt);
        }
    }

    public double getReceiptAmount() {
        return receiptAmt;
    }

    public double getAdjustmentAmount() {
        return adjustedAmt;
    }

}