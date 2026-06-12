package com.reckon.reckonorders.NewDesign.NewFragments;

import static android.view.View.GONE;
import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.app.AlertDialog;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ListPopupWindow;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.reckon.reckonorders.Adapter.DateRangePickerAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Interfaces.ItemListener;
import com.reckon.reckonorders.Model.DateRangeModel;
import com.reckon.reckonorders.Model.ReceiptBookModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.ReceiptBookListAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.StorePartyPickerDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentReceiptBookBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.DecimalFormat;
import java.util.ArrayList;

public class ReceiptBook extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    FragmentReceiptBookBinding binding;
    ArrayList<ReceiptBookModel> receiptBookList = new ArrayList<>();
    ArrayList<DateRangeModel> dateRangeDataList = new ArrayList<>();

    private String status = "-1";
    private String fromDate = "", tillDate = "", firmCode = "", firmName = "";
    private boolean isSalesMan;
    public StoreDetailObjectModel storeDetailObjectModel;
    private boolean partyPickerCalled = false;
    private AlertDialog alertDialogShare;
    private int PAGE_NUM = 1;
    private DateRangeModel dateRangeModel;
    private BottomSheetDialog bottomSheetDialog;
    private View view = null;
    ArrayList<String> paymentOption = new ArrayList<>();
    private ListPopupWindow listPopupWindow;
    private StoreDetailObjectModel selectedFirmObj;


    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        if (view == null) {
            binding = FragmentReceiptBookBinding.inflate(getLayoutInflater());
            view = inflater.inflate(R.layout.fragment_receipt_book, container, false);
            initViews(binding.getRoot());
        }
        return binding.getRoot();
    }

    private void initViews(View view) {
        paymentOption.add("All");
        paymentOption.add("Cash");
        paymentOption.add("Bank");
        binding.tvPayMode.setText(paymentOption.get(0));
        retrofitCallBackListener = this;
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        ((NewMainActivity) getActivity()).setUpTitle(ReceiptBook.this, getString(R.string.receipt_book));
        if (isSalesMan) {
            binding.tvAddress.setVisibility(binding.tvAddress.getText().toString().isEmpty() ? View.GONE : View.VISIBLE);
            binding.ivClearFilter.setVisibility(binding.tvAccountName.getText().toString().equalsIgnoreCase(getResources().getString(R.string.selectParty)) ? View.GONE : View.VISIBLE);

            new Handler().postDelayed(this::getReceiptBookData, 1000);
            binding.parentCv.setOnClickListener(v -> openPartyPickerDialog());
            binding.ivClearFilter.setOnClickListener(v -> {
                partyPickerCalled = false;
                getReceiptBookData();
                binding.tvAccountName.setText(getResources().getString(R.string.selectParty));
                binding.ivClearFilter.setVisibility(GONE);
                binding.tvAddress.setVisibility(View.GONE);
            });
            binding.openCalenderFab.setOnClickListener(v -> showBottomSheetDialog());
            binding.selectFirmCv.setVisibility(getStoreListData() != null && getStoreListData().size() > 1 ? View.VISIBLE : View.GONE);
            binding.selectFirmCv.setOnClickListener(v -> {
                StorePartyPickerDialog dialog = new StorePartyPickerDialog(getActivity(), getString(R.string.select_your_firm), Constant.FIRM, Constant.CREATE_RECEIPT, selectedFirmObj);
                dialog.setOnItemClickListenerDialog(data -> {
                    if (data != null) {
                        selectedFirmObj = data;
                        firmName = data.getName();
                        binding.tvFirmName.setText(data.getName());
                        firmCode = data.getFirmCode();
                        getReceiptBookData();
                        binding.ivClearFirm.setVisibility(View.VISIBLE);
                    }
                });
                dialog.show();
            });
            binding.ivClearFirm.setOnClickListener(v -> {
                selectedFirmObj = null;
                firmName = "";
                firmCode = "";
                binding.tvFirmName.setText(getResources().getString(R.string.select_your_firm));
                getReceiptBookData();
                binding.ivClearFirm.setVisibility(GONE);
            });


        } else {
            new Handler().postDelayed(this::getReceiptBookData, 1000);
            binding.parentCv.setVisibility(GONE);
        }

        binding.payModelCv.setOnClickListener(v -> {
            setUpListPopUpWindow();
        });
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
                PAGE_NUM = 1;
                getReceiptBookData();
            });
            listPopupWindow.show();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void showBottomSheetDialog() {
        bottomSheetDialog = new BottomSheetDialog(requireActivity());
        bottomSheetDialog.setContentView(R.layout.bottom_sheet_dialog_layout);
        RecyclerView recyclerView = bottomSheetDialog.findViewById(R.id.dateRv);
        if (recyclerView != null) {
            recyclerView.setAdapter(new DateRangePickerAdapter(dateRangeDataList, ReceiptBook.this, dateRangeModel));
        }
        bottomSheetDialog.findViewById(R.id.closeDialogImv).setOnClickListener(v -> bottomSheetDialog.dismiss());
        CardView clearCv = bottomSheetDialog.findViewById(R.id.clearDateCv);
        clearCv.setVisibility(dateRangeModel == null ? GONE : View.VISIBLE);
        clearCv.setOnClickListener(v -> {
            binding.tvSelectedDate.setText("");
            binding.tvSelectedDate.setVisibility(GONE);
            dateRangeModel = null;
            fromDate = "";
            tillDate = "";
            getReceiptBookData();
            bottomSheetDialog.dismiss();
        });
        bottomSheetDialog.show();
    }

    private void openPartyPickerDialog() {
        partyPickerCalled = true;
        StorePartyPickerDialog dialog = new StorePartyPickerDialog(getActivity(), getString(R.string.select_party), Constant.RECEIPT_BOOK, Constant.RECEIPT_BOOK);
        dialog.setOnItemClickListenerDialog(data -> {
            if (data != null) {
                binding.parentCv.setVisibility(View.VISIBLE);
                storeDetailObjectModel = data;
                binding.tvAccountName.setText(data.getName());
                binding.tvAddress.setText(data.getAdd1() + data.getAdd2() + data.getAdd3());
                binding.tvAddress.setVisibility(View.VISIBLE);
                binding.ivClearFilter.setVisibility(View.VISIBLE);
                getReceiptBookData();
            }
        });
        dialog.show();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        binding.tvRecentOrders.setTextColor(getSecondHeaderTextColor());
        binding.recentCountTv.setVisibility(View.VISIBLE);
        binding.tvAllOrders.setOnClickListener(v -> {
            status = "-1";
            binding.tvAllOrders.setTextColor(getSecondHeaderTextColor());
            binding.tvRecentOrders.setTextColor(getResources().getColor(R.color.reconGrey));
            binding.tvCanceledOrders.setTextColor(getResources().getColor(R.color.reconGrey));
            binding.allCountTv.setVisibility(View.VISIBLE);
            binding.recentCountTv.setVisibility(GONE);
            binding.cancelledCountTv.setVisibility(View.GONE);
            binding.scrollView.scrollTo(0, 0);
            getReceiptBookData();
        });
        binding.tvRecentOrders.setOnClickListener(v -> {
            status = "-2";
            binding.tvRecentOrders.setTextColor(getSecondHeaderTextColor());
            binding.tvAllOrders.setTextColor(getResources().getColor(R.color.reconGrey));
            binding.tvCanceledOrders.setTextColor(getResources().getColor(R.color.reconGrey));
            binding.allCountTv.setVisibility(View.GONE);
            binding.recentCountTv.setVisibility(View.VISIBLE);
            binding.cancelledCountTv.setVisibility(View.GONE);
            binding.scrollView.scrollTo(0, 0);
            getReceiptBookData();

        });
        binding.tvCanceledOrders.setOnClickListener(v -> {
            status = "4";
            binding.tvCanceledOrders.setTextColor(getSecondHeaderTextColor());
            binding.tvAllOrders.setTextColor(getResources().getColor(R.color.reconGrey));
            binding.tvRecentOrders.setTextColor(getResources().getColor(R.color.reconGrey));
            binding.allCountTv.setVisibility(View.GONE);
            binding.recentCountTv.setVisibility(View.GONE);
            binding.cancelledCountTv.setVisibility(View.VISIBLE);
            binding.scrollView.scrollTo(0, 0);
            getReceiptBookData();
        });
    }

    String getFirmCode() {
        return isSalesMan ? (getStoreListData().size() > 1 /*&& !firmCode.isEmpty()*/ ? firmCode : getSelectedStoreDetailsFromPicker().getFirmCode()) : getLicDetails().getFirmcode();
    }

    private void getReceiptBookData() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lSize", String.valueOf(2000));
            jsonObject.put("lPageNo", String.valueOf(PAGE_NUM));
            jsonObject.put("from_date", fromDate);
            jsonObject.put("till_date", tillDate);
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lFirmCode", getFirmCode());
            jsonObject.put("lStatus", status);
            jsonObject.put("mode", binding.tvPayMode.getText().toString());
            jsonObject.put("AcCode", isSalesMan ? partyPickerCalled ? SharedPrefUtils.getString(getActivity(), Constant.PARTY_CODE) : "" : SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getReceiptBook(String.valueOf(jsonObject)), Constant.RECEIPT_BOOK, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void getDateRange() {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getDateRange(), Constant.DATE_RANGE, false);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.RECEIPT_BOOK:
                    try {
                        if (jsonObject.getBoolean("Status")) {
                            setMyOrderListData(jsonObject.getJSONArray("Item"));
                            getDateRange();
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
                case Constant.DATE_RANGE:
                    try {
                        if (jsonObject.getBoolean("status")) {
                            setDateRangeData(jsonObject.getJSONArray("items"));
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
            }


        }
    }

    private void setMyOrderListData(JSONArray jsonArray) {
        try {
            if (receiptBookList != null && !receiptBookList.isEmpty())
                receiptBookList.clear();

            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                ReceiptBookModel model = new ReceiptBookModel();
                model.setId(ReckonUtils.getJsonCheckedString(jsonObject, "id", ""));
                model.setCreatedDate(ReckonUtils.getJsonCheckedString(jsonObject, "date", ""));
                model.setReceiptDate(ReckonUtils.getJsonCheckedString(jsonObject, "docdt", ""));
                model.setDocumentNo(ReckonUtils.getJsonCheckedString(jsonObject, "docno", "0.0"));
                model.setPaymentMode(ReckonUtils.getJsonCheckedString(jsonObject, "type", ""));
                model.setAmount(ReckonUtils.getJsonCheckedString(jsonObject, "amount", ""));
                model.setAccountName(ReckonUtils.getJsonCheckedString(jsonObject, "acName", ""));
                model.setNarration(ReckonUtils.getJsonCheckedString(jsonObject, "narration", ""));
                receiptBookList.add(model);
            }
            binding.noRecordTV.setVisibility(receiptBookList.isEmpty() ? View.VISIBLE : View.GONE);
            binding.recordsUI.setVisibility(!receiptBookList.isEmpty() ? View.VISIBLE : View.GONE);
            binding.orderHistoryRecycler.setAdapter(new ReceiptBookListAdapter(ReceiptBook.this, receiptBookList));
            String showListSizeTxt = "(" + receiptBookList.size() + ")";
            binding.allCountTv.setText(showListSizeTxt);
            binding.recentCountTv.setText(showListSizeTxt);
            binding.cancelledCountTv.setText(showListSizeTxt);
            double amt = 0.0;
            for (ReceiptBookModel item : receiptBookList) {
                amt = amt + Double.parseDouble(item.getAmount());
            }
            binding.tvTaggedPaymentTotal.setText("Total: " + getLicDetails().getCurrency() + new DecimalFormat("#.00").format(amt));
            binding.taggedPaymentShowCard.setVisibility(amt != 0 ? View.VISIBLE : GONE);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setDateRangeData(JSONArray jsonArray) {
        try {
            if (dateRangeDataList != null && !dateRangeDataList.isEmpty())
                dateRangeDataList.clear();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                DateRangeModel model = new DateRangeModel();
                model.setTitle(ReckonUtils.getJsonCheckedString(jsonObject, "title", ""));
                model.setId(ReckonUtils.getJsonCheckedString(jsonObject, "id", ""));
                model.setFromDate(ReckonUtils.getJsonCheckedString(jsonObject, "from_date", ""));
                model.setTillDate(ReckonUtils.getJsonCheckedString(jsonObject, "till_date", ""));
                dateRangeDataList.add(model);
            }
            binding.openCalenderFab.setVisibility(!receiptBookList.isEmpty() && !dateRangeDataList.isEmpty() ? View.VISIBLE: GONE);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void executeClick(DateRangeModel mModel) {
        bottomSheetDialog.dismiss();
        if (mModel != null) {
            dateRangeModel = mModel;
            fromDate = dateRangeModel.getFromDate();
            tillDate = dateRangeModel.getTillDate();
            if (fromDate.isEmpty() || tillDate.isEmpty()) {
                showPopUp(binding.getRoot());
            } else {
                binding.tvSelectedDate.setVisibility(View.VISIBLE);
                binding.tvSelectedDate.setText(fromDate + "  -  " + tillDate);
                getReceiptBookData();
            }
        }

    }

    public void showPopUp(View view) {
        AlertDialog.Builder builder = new AlertDialog.Builder(requireActivity());
        ViewGroup viewGroup = view.findViewById(android.R.id.content);
        View dialogView = LayoutInflater.from(view.getContext()).inflate(R.layout.custom_date_view, viewGroup, false);
        builder.setView(dialogView);
        TextView dateStartDialog = dialogView.findViewById(R.id.dateStart);
        TextView dateEndDialog = dialogView.findViewById(R.id.dateEnd);
        CardView startDateCv = dialogView.findViewById(R.id.startDateCalenderCard);
        CardView endDateCv = dialogView.findViewById(R.id.endDateCalenderCard);
        CardView doneCv = dialogView.findViewById(R.id.doneCv);
        CardView closeDialogCv = dialogView.findViewById(R.id.closeDialogCv);

        startDateCv.setOnClickListener(v -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                ReckonUtils.getMyCalender(ReceiptBook.this, dateStartDialog, null);
            }
        });

        endDateCv.setOnClickListener(v -> {
            if (!dateStartDialog.getText().toString().isEmpty()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    ReckonUtils.getMyCalender(ReceiptBook.this, dateEndDialog, itemListenerDialog);
                }
            } else {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_from_date), Toast.LENGTH_SHORT).show();
            }
        });
        doneCv.setOnClickListener(v -> {
            if (!dateStartDialog.getText().toString().isEmpty() && !dateEndDialog.getText().toString().isEmpty()) {
                fromDate = dateStartDialog.getText().toString() + " 00:00:00";
                tillDate = dateEndDialog.getText().toString() + " 23:59:59";
                binding.tvSelectedDate.setVisibility(View.VISIBLE);
                binding.tvSelectedDate.setText(fromDate + "  -  " + tillDate);
                getReceiptBookData();
                if (alertDialogShare != null) {
                    alertDialogShare.dismiss();
                }
            } else {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_date), Toast.LENGTH_SHORT).show();
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

    private final ItemListener itemListenerDialog = position -> {

    };

}