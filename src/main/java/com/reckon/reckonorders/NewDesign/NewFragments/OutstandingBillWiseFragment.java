package com.reckon.reckonorders.NewDesign.NewFragments;

import static android.view.View.GONE;
import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.widget.NestedScrollView;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.google.gson.Gson;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.AreaOutletAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.InvoiceModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.StorePartyPickerDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentOutletDetailsBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.DecimalFormat;
import java.util.ArrayList;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link OutstandingBillWiseFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class OutstandingBillWiseFragment extends BaseFragment implements RetrofitCallBackListener {
    FragmentOutletDetailsBinding detailsBinding;
    private RetrofitCallBackListener retrofitCallBackListener;
    private int totalListCount = 0;
    ArrayList<InvoiceModel> outstandingDataList = new ArrayList<>();
    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    ArrayList<String> ids;
    // TODO: Rename and change types of parameters
    private String mParam1, accountName, accountAddress, accountCode;
    private String mParam2, previousTitle = "", firmName = "";
    public String firmCode="";
    private int PAGE_NUM = 1;
    private LinearLayoutManager mlayoutManager;
    private boolean isSalesMan;
    private ArrayList<InvoiceModel> selectedTaggedDataList = new ArrayList<>();
    private View view = null;
    private boolean isFirst = true;
    private boolean isShareEnabled = false;
    private StoreDetailObjectModel selectedFirmObj;


    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param param1 Parameter 1.
     * @param param2 Parameter 2.
     * @return A new instance of fragment OutletDetailsFragment.
     */
    // TODO: Rename and change types and number of parameters
    public static OutstandingBillWiseFragment newInstance(String param1, String param2) {
        OutstandingBillWiseFragment fragment = new OutstandingBillWiseFragment();
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
            mParam1 = getArguments().getString(ARG_PARAM1);
            mParam2 = getArguments().getString(ARG_PARAM2);
            getBundle();
        }

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        if (view == null) {
            detailsBinding = FragmentOutletDetailsBinding.inflate(inflater, container, false);
            view = inflater.inflate(R.layout.fragment_outlet_details, container, false);
            initViews();
        }
        return detailsBinding.getRoot();
    }

    private void initViews() {
        mlayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        detailsBinding.outletRecycler.setLayoutManager(mlayoutManager);
        detailsBinding.outletRecycler.setNestedScrollingEnabled(false);
        detailsBinding.tvProceedToPayment.setText(isSalesMan ? getResources().getString(R.string.receipt_entry) : getResources().getString(R.string.pay_this_bill));
        detailsBinding.tvHeadingPartyName.setTextColor(getSecondHeaderTextColor());
        detailsBinding.tvHeadingPartyName.setText(accountName);
        detailsBinding.tvFirmName.setText(ReckonUtils.nonNullNotEmptyString(firmName)?firmName:getResources().getString(R.string.select_your_firm));
        detailsBinding.tvHeadingAddress.setText(accountAddress);
        detailsBinding.sendReminder.setText(isSalesMan ? getResources().getString(R.string.share) : getResources().getString(R.string.pay_this_bill));
        detailsBinding.sendReminder.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isSalesMan) {
                    getOutstandingData(1, true);
                } else {
                    Toast.makeText(requireActivity(), getResources().getString(R.string.workOnProgress), Toast.LENGTH_LONG).show();
                }
            }
        });
        detailsBinding.tvProceedToPayment.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isSalesMan) {
                    Bundle bundle = new Bundle();
                    bundle.putString("name", accountName);
                    bundle.putString("Code", accountCode);
                    bundle.putString("firm_name", firmName);
                    bundle.putString("firm_code", firmCode);
                    bundle.putString(Constant.SELECTED_ACCOUNT_LIST, new Gson().toJson(selectedTaggedDataList));
                    bundle.putString("from", Constant.OUTSTANDING);
                    try {
                        double amt = 0.0;
                        for (InvoiceModel item : selectedTaggedDataList) {
                            amt = amt + Double.parseDouble(item.getAmount());
                        }
                        bundle.putString("receipt_amount", String.valueOf(amt));
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    Navigation.findNavController(v).navigate(R.id.nav_receipt, bundle);
                    isFirst = false;
                } else {
                    Toast.makeText(requireActivity(), getResources().getString(R.string.workOnProgress), Toast.LENGTH_LONG).show();
                }
            }
        });

        detailsBinding.outletDesignScroller.setOnScrollChangeListener((NestedScrollView.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
            if (v.getChildAt(v.getChildCount() - 1) != null) {
                if ((scrollY >= (v.getChildAt(v.getChildCount() - 1).getMeasuredHeight() - v.getMeasuredHeight())) &&
                        scrollY > oldScrollY) {
                    int visibleItemCount = mlayoutManager.getChildCount();
                    int totalItemCount = mlayoutManager.getItemCount();
                    int pastVisiblesItems = mlayoutManager.findFirstVisibleItemPosition();
                    if ((visibleItemCount + pastVisiblesItems) >= totalItemCount) {
                        if (totalListCount > outstandingDataList.size()) {
                            getOutstandingData(++PAGE_NUM, false);
                        }
                    }
                }
            }
        });
        new Handler().postDelayed(() -> getOutstandingData(PAGE_NUM, false), 200);
        detailsBinding.selectFirmCv.setVisibility(getStoreListData()!=null && getStoreListData().size()>1?View.VISIBLE:View.GONE);
        detailsBinding.selectFirmCv.setOnClickListener(view1 -> {
            StorePartyPickerDialog dialog = new StorePartyPickerDialog(getActivity(), getString(R.string.select_your_firm), Constant.FIRM, Constant.CREATE_RECEIPT, selectedFirmObj);
            dialog.setOnItemClickListenerDialog(data -> {
                if (data != null) {
                    selectedFirmObj = data;
                    firmName = data.getName();
                    detailsBinding.tvFirmName.setText(data.getName());
                    firmCode = data.getFirmCode();
                    PAGE_NUM = 1;
                    getOutstandingData(PAGE_NUM, false);
                    detailsBinding.ivClearFirm.setVisibility(View.VISIBLE);
                }
            });
            dialog.show();
        });
        detailsBinding.ivClearFirm.setOnClickListener(v -> {
            selectedFirmObj = null;
            firmName = "";
            firmCode = "";
            detailsBinding.tvFirmName.setText(getResources().getString(R.string.select_your_firm));
            PAGE_NUM = 1;
            getOutstandingData(PAGE_NUM, false);
            detailsBinding.ivClearFirm.setVisibility(GONE);
        });
    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            String from = bundle.containsKey(Constant.FROM) ? bundle.getString(Constant.FROM) : "";
            accountName = bundle.containsKey("name") ? bundle.getString("name") : "";
            accountCode = bundle.containsKey("Code") ? bundle.getString("Code") : "";
            firmName = bundle.containsKey("firm_name") ? bundle.getString("firm_name") : "";
            firmCode = bundle.containsKey("firm_code") ? bundle.getString("firm_code") : "";
            accountAddress = bundle.containsKey("address") ? bundle.getString("address") : "";
        }
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        ((NewMainActivity) getActivity()).setUpTitle(OutstandingBillWiseFragment.this, getString(R.string.outstanding));
    }

    @Override
    public void onResume() {
        super.onResume();
        if (!isFirst) {
            new Handler().postDelayed(() -> getOutstandingData(1, false), 200);
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        ((NewMainActivity) requireActivity()).setUpTitle(this, previousTitle);
    }
    String getFirmCode() {
        return isSalesMan ?(getStoreListData().size()>1 ? firmCode: getSelectedStoreDetailsFromPicker().getFirmCode()) : getLicDetails().getFirmcode();
    }
    private void getOutstandingData(int PAGE_NUM, boolean forPDF) {
        try {
            isShareEnabled = forPDF;
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lAcNo", isSalesMan ? accountCode : SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
            jsonObject.put("lPageNo", String.valueOf(PAGE_NUM));
            jsonObject.put("lSize", String.valueOf(30));
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lFromDate", "");
            jsonObject.put("lTillDate", "");
            jsonObject.put("lAcId", "");
            jsonObject.put("lSearchFieldValue", "");
            jsonObject.put("firm_code", getFirmCode());
            jsonObject.put("lSharePdf", String.valueOf(forPDF));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            jsonObject.put("lFirmCode", getFirmCode());
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getOutstanding(String.valueOf(jsonObject)), Constant.OUTSTANDING, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void setVisibilityOfActionCard(ArrayList<InvoiceModel> taggedDataList) {
            if (taggedDataList != null && !taggedDataList.isEmpty()) {
                selectedTaggedDataList = taggedDataList;
                double amt = 0.0;
                for (InvoiceModel item : taggedDataList) {
                    amt = amt + Double.parseDouble(item.getAmount());
                }
                detailsBinding.tvTaggedPaymentTotal.setText("Total: " + getLicDetails().getCurrency() + amt);
                detailsBinding.taggedPaymentShowCard.setVisibility(View.VISIBLE);
                detailsBinding.sendReminderCard.setVisibility(View.GONE);
            } else {
                detailsBinding.taggedPaymentShowCard.setVisibility(View.GONE);
                detailsBinding.sendReminderCard.setVisibility(View.VISIBLE);
            }

    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 1) {
            if(isShareEnabled){
                try{
                    JSONObject jsonObject = new JSONObject(result);
                    boolean sharePDF = jsonObject.has("share_pdf") && jsonObject.getBoolean("share_pdf");
                    if (sharePDF && jsonObject.has("data")) {
                        JSONObject obj = jsonObject.getJSONObject("data");
                        String pdfLink = ReckonUtils.getJsonCheckedString(obj, "link", "");
                        String docName = ReckonUtils.getJsonCheckedString(obj, "doc_name", "outstanding");
                        if (ReckonUtils.isPDFValid(pdfLink)) {
                            ReckonUtils.downloadAndSharePdf(pdfLink, requireActivity(), false, docName);
                        }else{
                            Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                        }
                    }else{
                        Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                    }
                }catch (Exception e){
                    e.printStackTrace();
                    if (ReckonUtils.isPDFValid(result)) {
                        ReckonUtils.downloadAndSharePdf(result, requireActivity(), false, "outstanding");
                    }else{
                        Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                    }
                }
            } else {
                JSONObject jsonObject = new JSONObject(result);
                switch (action) {
                    case Constant.OUTSTANDING:
                        try {
                            if (PAGE_NUM == 1) {
                                if (!outstandingDataList.isEmpty()) {
                                    outstandingDataList.clear();
                                }
                                selectedTaggedDataList = new ArrayList<>();
                                setVisibilityOfActionCard(selectedTaggedDataList);
                                detailsBinding.outletDesignScroller.scrollTo(0, 0);
                            }
                            String accName = ReckonUtils.getJsonCheckedString(jsonObject, "acc_name", "");
                            if (!accName.isEmpty()) {
                                if (isSalesMan) {
                                    detailsBinding.tvHeadingPartyName.setText(accName);
                                    detailsBinding.tvHeadingAddress.setText(ReckonUtils.getJsonCheckedString(jsonObject, "acc_address", ""));
                                }
                                detailsBinding.tvLastPaymentValue.setText(ReckonUtils.getJsonCheckedString(jsonObject, "last_payment_date", ""));
                                detailsBinding.outstandingBalance.setText(getLicDetails().getCurrency() + new DecimalFormat("#.00").format(Double.parseDouble(ReckonUtils.getJsonCheckedString(jsonObject, "outstanding_amount", ""))));
//                                detailsBinding.lastPaymentLl.setVisibility(!detailsBinding.tvLastPaymentValue.getText().toString().isEmpty()?View.VISIBLE:View.GONE);
                                detailsBinding.outstandingAmt.setVisibility(!detailsBinding.outstandingBalance.getText().toString().isEmpty() ? View.VISIBLE : View.GONE);
                                totalListCount = Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "total_items", ""));
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
                                    outstandingDataList.add(model);
                                }
                                detailsBinding.outletRecycler.setAdapter(new AreaOutletAdapter(OutstandingBillWiseFragment.this, outstandingDataList, selectedTaggedDataList));
                            } else {
                                if (PAGE_NUM == 1) {
                                    requireActivity().onBackPressed();
                                    Toast.makeText(requireActivity(), getResources().getString(R.string.noRecordFound), Toast.LENGTH_LONG).show();
                                }
                            }

//                            binding.noRecordTV.setVisibility(outstandingDataList.isEmpty() ? View.VISIBLE : View.GONE);
                        } catch (Exception e) {
//                            showNoResultScreen();
                            e.printStackTrace();
                        }
                        break;

                }
            }
        } else {
//            showNoResultScreen();
        }

    }

}