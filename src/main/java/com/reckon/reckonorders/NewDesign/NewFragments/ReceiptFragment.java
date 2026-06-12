package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.app.AlertDialog;
import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ListPopupWindow;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;
import androidx.navigation.fragment.NavHostFragment;

import com.google.gson.reflect.TypeToken;
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
import com.reckon.reckonorders.databinding.FragmentReceiptBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link ReceiptFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class ReceiptFragment extends BaseFragment {
    ArrayList<String> paymentOption = new ArrayList<>();
    private RetrofitCallBackListener retrofitCallBackListener;


    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    FragmentReceiptBinding binding;

    // TODO: Rename and change types of parameters
    private String mParam1, accountName, accountCode, accountAddress, receiptAmount = "", amount = "", discAmount = "", firmCode="", firmName = "";
    private String mParam2;
    private View view = null;
    private ListPopupWindow listPopupWindow;
    private AlertDialog alertDialogShare;
    private boolean isSalesMan;
    private ArrayList<InvoiceModel> billsList = new ArrayList<>();
    private Bundle bundle;
    private String screen = "";
    private View view1;
    private StoreDetailObjectModel selectedFirmObj;

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param param1 Parameter 1.
     * @param param2 Parameter 2.
     * @return A new instance of fragment RecieptFragment.
     */
    // TODO: Rename and change types and number of parameters
    public static ReceiptFragment newInstance(String param1, String param2) {
        ReceiptFragment fragment = new ReceiptFragment();
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
        if (getArguments() != null) {
            mParam1 = getArguments().getString(ARG_PARAM1);
            mParam2 = getArguments().getString(ARG_PARAM2);
            getBundle();
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        if (view == null) {
            binding = FragmentReceiptBinding.inflate(getLayoutInflater(), container, false);
            view = inflater.inflate(R.layout.fragment_receipt, container, false);
            initViews();
        }
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        ((NewMainActivity) getActivity()).setUpTitle(ReceiptFragment.this, getString(R.string.create_receipt));
    }

    public void getBundle() {
        bundle = getArguments();
        if (bundle != null) {
            screen = bundle.containsKey(Constant.FROM) ? bundle.getString(Constant.FROM) : "";
            accountName = bundle.containsKey("name") ? bundle.getString("name") : "";
            accountCode = bundle.containsKey("Code") ? bundle.getString("Code") : "";
            firmName = bundle.containsKey("firm_name") ? bundle.getString("firm_name") : "";
            firmCode = bundle.containsKey("firm_code") ? bundle.getString("firm_code") : "";
            accountAddress = bundle.containsKey("address") ? bundle.getString("address") : "";
            receiptAmount = bundle.containsKey("receipt_amount") ? bundle.getString("receipt_amount") : "";
            amount = bundle.containsKey("amount") ? bundle.getString("amount") : "";
            discAmount = bundle.containsKey("disc_amount") ? bundle.getString("disc_amount") : "";

            if (bundle.containsKey(Constant.SELECTED_ACCOUNT_LIST)) {
                billsList = gson.fromJson(getArguments().getString(Constant.SELECTED_ACCOUNT_LIST), new TypeToken<ArrayList<InvoiceModel>>() {
                }.getType());
            }
        }
    }

    private void initViews() {
        paymentOption.add("Cash");
        paymentOption.add("Bank");
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        binding.shareReceiptVoucherCard.setCardBackgroundColor(getButtonColor());
        binding.entryDateTv.setText(ReckonUtils.getCurrentDate());
        binding.tvAccountName.setText(accountName != null && !accountName.isEmpty() ? accountName : "");
        binding.tvFirmName.setText(ReckonUtils.nonNullNotEmptyString(firmName)?firmName:"");
        binding.dropdownImg.setVisibility(enableSelectAccountView() ? View.VISIBLE : View.GONE);
        binding.firmDropDownImg.setVisibility(enableSelectFirmView() ? View.VISIBLE : View.GONE);
        if (screen.equalsIgnoreCase(Constant.OUTSTANDING)) {
            binding.amountEdt.setEnabled(false);
            binding.amountEdt.setTextColor(getResources().getColor(R.color.reconGrey));
            binding.amountEdt.setHintTextColor(getResources().getColor(R.color.reconGrey));
            binding.discAmountEdit.setVisibility(View.GONE);
        }

        binding.selectFirmCv.setVisibility(getStoreListData()!=null && getStoreListData().size()>1?View.VISIBLE:View.GONE);
        binding.selectFirmCv.setOnClickListener(v -> {
            if(enableSelectFirmView()){
                StorePartyPickerDialog dialog = new StorePartyPickerDialog(getActivity(), getString(R.string.select_your_firm), Constant.FIRM, Constant.CREATE_RECEIPT, selectedFirmObj);
                dialog.setOnItemClickListenerDialog(data -> {
                    if (data != null) {
                        selectedFirmObj = data;
                        firmName = data.getName();
                        binding.tvFirmName.setText(data.getName());
                        firmCode = data.getFirmCode();
                    }
                });
                dialog.show();
            }
        });
        binding.selectAccountCv.setOnClickListener(v -> {
            if (enableSelectAccountView()) {
                Bundle bundle = new Bundle();
                bundle.putString(Constant.FROM, Constant.CREATE_RECEIPT);
                bundle.putString(Constant.FIRM_NAME, firmName);
                bundle.putString(Constant.FIRM_CODE, firmCode);
                Navigation.findNavController(requireActivity(), R.id.select_account_cv).navigate(R.id.navPartyLisingFragment, bundle);
            }
        });
        binding.selectDateCv.setOnClickListener(v -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                ReckonUtils.getMyCalender(ReceiptFragment.this, binding.tvDocDate, null);
            }
        });
        binding.selectPaymentMode.setOnClickListener(v -> {
            setUpListPopUpWindow();
        });
        binding.submitReceiptCv.setOnClickListener(v -> {
            view1 = v;
            if (getStoreListData().size()>1 && !ReckonUtils.nonNullNotEmptyString(firmCode)) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_firm_first), Toast.LENGTH_SHORT).show();
            }else if (accountName == null) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_account_first), Toast.LENGTH_SHORT).show();
            } else if (binding.amountEdt.getText().toString().isEmpty()) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_insert_amount), Toast.LENGTH_SHORT).show();
            } else if (Double.parseDouble(binding.amountEdt.getText().toString()) <= 0) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.amount_cannot_zero), Toast.LENGTH_SHORT).show();
            } else if (binding.tvPayMode.getText().toString().isEmpty()) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_payment_mode), Toast.LENGTH_SHORT).show();
            } else if (binding.tvPayMode.getText().toString().equalsIgnoreCase("Bank") && binding.documentNoEdt.getText().toString().isEmpty()) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_enter_document_number), Toast.LENGTH_SHORT).show();
            } else if (binding.tvPayMode.getText().toString().equalsIgnoreCase("Bank") && binding.tvDocDate.getText().toString().isEmpty()) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_doc_date), Toast.LENGTH_SHORT).show();
            } else if (billsList.isEmpty()) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.select_add_bills), Toast.LENGTH_SHORT).show();
            } else {
                showPopUp(view);
            }
        });
        binding.addBillsCv.setVisibility(screen != null && !screen.equalsIgnoreCase(Constant.OUTSTANDING) ? View.VISIBLE : View.GONE);
        binding.addBillsCv.setOnClickListener(v -> {
            if (getStoreListData().size()>1 && !ReckonUtils.nonNullNotEmptyString(firmCode)) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_firm_first), Toast.LENGTH_SHORT).show();
            }else if (accountCode == null) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_account_first), Toast.LENGTH_SHORT).show();
            } else if (binding.amountEdt.getText().toString().isEmpty()) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_insert_amount), Toast.LENGTH_SHORT).show();
            } else if (Double.parseDouble(binding.amountEdt.getText().toString()) <= 0) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.amount_cannot_zero), Toast.LENGTH_SHORT).show();
            } else {
                Bundle bundle = new Bundle();
                bundle.putString("name", accountName);
                bundle.putString("Code", accountCode);
                bundle.putString("firm_code", firmCode);
                bundle.putString("firm_name", firmName);
                String receiptAmt = String.valueOf(Double.parseDouble(binding.amountEdt.getText().toString()) + Double.parseDouble(ReckonUtils.nonNullNotEmptyString(binding.discAmountEdt.getText().toString()) ? binding.discAmountEdt.getText().toString() : "0"));
                bundle.putString("receipt_amount", receiptAmt);
                bundle.putString("amount", binding.amountEdt.getText().toString());
                bundle.putString("disc_amount", binding.discAmountEdt.getText().toString());
                bundle.putString("address", accountAddress);
                bundle.putString("pay_mode", binding.tvPayMode.getText().toString());
                bundle.putString("doc_no", binding.documentNoEdt.getText().toString());
                bundle.putString("doc_date", binding.tvDocDate.getText().toString());
                bundle.putString("narration", binding.commentSection.getText().toString());
                bundle.putString("from", Constant.CREATE_RECEIPT);
                NavHostFragment.findNavController(ReceiptFragment.this).navigate(R.id.nav_add_bills, bundle);
            }
        });
        if (ReckonUtils.nonNullNotEmptyString(receiptAmount)) {
            binding.amountEdt.setText(receiptAmount);
        }
        if (!amount.isEmpty()) {
            binding.amountEdt.setText(amount);
        }
        if (!discAmount.isEmpty()) {
            binding.discAmountEdt.setText(discAmount);
        }
        binding.adjustmentLl.setVisibility(billsList != null && !billsList.isEmpty() ? View.VISIBLE : View.GONE);
        binding.outletRecycler.setAdapter(new AreaOutletAdapter(ReceiptFragment.this, billsList));
        if (bundle != null) {
            binding.tvPayMode.setText(bundle.containsKey("pay_mode") ? bundle.getString("pay_mode") : "");
            binding.tvDocDate.setText(bundle.containsKey("doc_date") ? bundle.getString("doc_date") : "");
            binding.documentNoEdt.setText(bundle.containsKey("doc_no") ? bundle.getString("doc_no") : "");
            binding.commentSection.setText(bundle.containsKey("narration") ? bundle.getString("narration") : "");

        }
//        binding.docCV.setVisibility(binding.tvPayMode.getText().toString().equalsIgnoreCase("Cash") ? View.GONE:View.VISIBLE);
        binding.selectDateCv.setVisibility(binding.tvPayMode.getText().toString().equalsIgnoreCase("Cash") ? View.GONE : View.VISIBLE);
    }

    private void setUpListPopUpWindow() {
        try {
            listPopupWindow = new ListPopupWindow(requireActivity());
            listPopupWindow.setAdapter(new ArrayAdapter(requireActivity(), R.layout.cc_row_layout, R.id.tv_country, this.paymentOption));
            listPopupWindow.setAnchorView(binding.tvPayMode);
            listPopupWindow.setWidth(350);
            listPopupWindow.setHeight(androidx.appcompat.widget.ListPopupWindow.WRAP_CONTENT);
            listPopupWindow.setModal(true);
            listPopupWindow.setOnItemClickListener((adapterView, view, i, l) -> {
                listPopupWindow.dismiss();
                binding.tvPayMode.setText(paymentOption.get(i));
//                binding.docCV.setVisibility(isPaymentModeCash(i) ? View.GONE:View.VISIBLE);
                binding.selectDateCv.setVisibility(isPaymentModeCash(i) ? View.GONE : View.VISIBLE);
                if (isPaymentModeCash(i)) {
                    binding.documentNoEdt.getText().clear();
                    binding.tvDocDate.setText("");
                }
            });
            //    if (!isTextEnterOn)
            listPopupWindow.show();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    boolean isPaymentModeCash(int index) {
        return paymentOption != null && !paymentOption.isEmpty() && paymentOption.get(index).equalsIgnoreCase("Cash");
    }

    String getFirmCode() {
        return isSalesMan ?(getStoreListData().size()>1 /*&& !firmCode.isEmpty()*/? firmCode: getSelectedStoreDetailsFromPicker().getFirmCode()) : getLicDetails().getFirmcode();
    }
    private void saveReceiptEntry() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lAcNo", accountCode);
            jsonObject.put("receipt_status", "1");
            jsonObject.put("entry_date", binding.entryDateTv.getText().toString());
            jsonObject.put("receipt_date", binding.tvDocDate.getText().toString());
            jsonObject.put("amount", binding.amountEdt.getText().toString());
            jsonObject.put("disc_amount", binding.discAmountEdt.getText().toString());
            jsonObject.put("mode", binding.tvPayMode.getText().toString());
            jsonObject.put("doc_number", binding.documentNoEdt.getText().toString());
            jsonObject.put("narration", binding.commentSection.getText().toString());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lFirmCode", getFirmCode());
            try {
                JSONArray jsonArray = new JSONArray();
                for (InvoiceModel item : billsList) {
                    JSONObject object = new JSONObject();
                    object.put("bill_number", item.getEntryNo());
                    object.put("amount", item.getAdjustmentAmount() != null ? item.getAdjustmentAmount() : item.getAmount());
                    object.put("id", item.getKeyEntryNo());
                    jsonArray.put(object);
                }
                jsonObject.put("adjustment_details", jsonArray);
            } catch (Exception e) {
                e.printStackTrace();
            }
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().saveReceiptEntry(String.valueOf(jsonObject)), Constant.CREATE_RECEIPT, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        System.out.println("Result------------" + result);
        if (result != null && result.length() > 1) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.CREATE_RECEIPT:
                    try {
                        if (jsonObject.has("status") && jsonObject.getBoolean("status")) {
                            String id = ReckonUtils.getJsonCheckedString(jsonObject, "no", "");
                            if (!screen.equalsIgnoreCase(Constant.OUTSTANDING)) {
                                clearReceiptData();
                                gotoReceiptDetails(id);
                            } else {
                                clearReceiptData();
                                requireActivity().onBackPressed();
                                gotoReceiptDetails(id);
                            }
                        }
                        String msg = jsonObject.has("message") && !jsonObject.getString("message").isEmpty() ? jsonObject.getString("message") : getResources().getString(R.string.submit_successfully);
                        Toast.makeText(requireActivity(), msg, Toast.LENGTH_LONG).show();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;

            }
        }/* else {
            Toast.makeText(requireActivity(), getResources().getString(R.string.submit_successfully), Toast.LENGTH_LONG).show();
            clearReceiptData();
        }*/

    }

    private void clearReceiptData() {
        accountCode = null;
        accountName = null;
        firmCode = null;
        binding.tvAccountName.setText("");
        binding.tvFirmName.setText("");
        binding.amountEdt.setText("");
        binding.discAmountEdt.setText("");
        binding.tvPayMode.setText("");
        binding.documentNoEdt.setText("");
        binding.tvDocDate.setText("");
        binding.commentSection.setText("");
        billsList.clear();
        binding.adjustmentLl.setVisibility(View.GONE);
    }

    public void showPopUp(View view) {
        AlertDialog.Builder builder = new AlertDialog.Builder(requireActivity());
        ViewGroup viewGroup = view.findViewById(android.R.id.content);
        View dialogView = LayoutInflater.from(view.getContext()).inflate(R.layout.submit_receipt_dialog_view, viewGroup, false);
        builder.setView(dialogView);
        CardView submitCv = dialogView.findViewById(R.id.submitCv);
        CardView closeDialogCv = dialogView.findViewById(R.id.closeDialogCv);
        submitCv.setOnClickListener(v -> {
            saveReceiptEntry();
            if (alertDialogShare != null) {
                alertDialogShare.dismiss();
            }
        });
        closeDialogCv.setOnClickListener(v -> {
            if (alertDialogShare != null) {
                alertDialogShare.dismiss();
            }
        });
        alertDialogShare = builder.create();
        alertDialogShare.show();

    }

    void gotoReceiptDetails(String receiptId) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.ID, receiptId);
        Navigation.findNavController(view1).navigate(R.id.nav_receipt_details, bundle);
    }

    boolean enableSelectAccountView() {
        return !isSalesMan ? screen != null && !screen.equalsIgnoreCase(Constant.OUTSTANDING) && !getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE) : screen != null && !screen.equalsIgnoreCase(Constant.OUTSTANDING);
    }
    boolean enableSelectFirmView() {
        return !isSalesMan ? (screen != null && !screen.equalsIgnoreCase(Constant.OUTSTANDING) && !getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE)) : (ReckonUtils.nonNullNotEmptyString(screen) && screen.equalsIgnoreCase(Constant.OUTSTANDING) && ReckonUtils.nonNullNotEmptyString(firmCode))?false:true;
    }
}