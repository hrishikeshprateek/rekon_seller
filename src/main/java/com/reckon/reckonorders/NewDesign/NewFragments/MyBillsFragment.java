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
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.Model.OrderDetailsModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.NewArrivalAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.StorePartyPickerDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentMyBillsBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

public class MyBillsFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    FragmentMyBillsBinding binding;
    ArrayList<OrderDetailsModel> myBillsList = new ArrayList<>();
    ArrayList<DateRangeModel> dateRangeDataList = new ArrayList<>();

    private String status = "-1";
    private String mParam1;
    private String mParam2, fromDate = "", tillDate = "";
    private boolean isSalesMan;
    public StoreDetailObjectModel storeDetailObjectModel;
    private boolean partyPickerCalled = false;
    private AlertDialog alertDialogShare;
    private int PAGE_NUM = 1;
    private DateRangeModel dateRangeModel;
    private BottomSheetDialog bottomSheetDialog;
    private View view = null;
    private boolean isFirst = true;


    public static MyBillsFragment newInstance(String param1, String param2) {
        MyBillsFragment fragment = new MyBillsFragment();
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
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        if (view == null) {
            binding = FragmentMyBillsBinding.inflate(getLayoutInflater());
            view = inflater.inflate(R.layout.fragment_my_bills, container, false);
            initViews(binding.getRoot());
        }
        return binding.getRoot();
    }

    private void initViews(View view) {
        retrofitCallBackListener = this;
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        ((NewMainActivity) requireActivity()).setUpTitle(MyBillsFragment.this, getString(R.string.my_bills));
        binding.tvAddress.setVisibility(binding.tvAddress.getText().toString().isEmpty() ? View.GONE : View.VISIBLE);
        binding.ivClearFilter.setVisibility(binding.tvAccountName.getText().toString().equalsIgnoreCase(getResources().getString(R.string.selectParty)) ? View.GONE : View.VISIBLE);
        clearData();
        new Handler().postDelayed(this::getMyOrderList, 1000);
        getDateRange();
        binding.parentCv.setOnClickListener(v -> {
            if (isSalesMan) {
                openPartyPickerDialog();
            } else {
                Bundle bundle = new Bundle();
                orderEntryClickHandling(v, Constant.MYORDERLIST, bundle);
                isFirst = false;
            }
        });
        binding.ivClearFilter.setOnClickListener(v -> {
            partyPickerCalled = false;
            clearData();
            getMyOrderList();
            binding.tvAccountName.setText(getResources().getString(R.string.selectParty));
            binding.ivClearFilter.setVisibility(GONE);
            binding.tvAddress.setVisibility(View.GONE);
        });
        binding.openCalenderFab.setOnClickListener(v -> showBottomSheetDialog());

    }

    private void clearData() {
        if (!isSalesMan && getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
            LicDetailObjectModel model = getLicDetails();
            model.setFirmcode("");
            model.setFirmName("");
            model.setFirmAdd("");
            model.setLicno("");
            localStorage.setLicDetails(gson.toJson(model));
            SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, "");
        }
    }

    private void showBottomSheetDialog() {
        bottomSheetDialog = new BottomSheetDialog(requireActivity());
        bottomSheetDialog.setContentView(R.layout.bottom_sheet_dialog_layout);
        RecyclerView recyclerView = bottomSheetDialog.findViewById(R.id.dateRv);
        recyclerView.setAdapter(new DateRangePickerAdapter(dateRangeDataList, MyBillsFragment.this, dateRangeModel));
        bottomSheetDialog.findViewById(R.id.closeDialogImv).setOnClickListener(v -> bottomSheetDialog.dismiss());
        CardView clearCv = bottomSheetDialog.findViewById(R.id.clearDateCv);
        clearCv.setVisibility(dateRangeModel == null ? GONE : View.VISIBLE);
        clearCv.setOnClickListener(v -> {
            binding.tvSelectedDate.setText("");
            binding.tvSelectedDate.setVisibility(GONE);
            dateRangeModel = null;
            fromDate = "";
            tillDate = "";
            getMyOrderList();
            bottomSheetDialog.dismiss();
        });
        bottomSheetDialog.show();
    }

    private void openPartyPickerDialog() {
        partyPickerCalled = true;
        StorePartyPickerDialog dialog = new StorePartyPickerDialog(getActivity(), getString(R.string.select_party), Constant.MYORDERLIST, Constant.ORDER_LIST);
//        binding.parentCv.setVisibility(GONE);
        dialog.setOnItemClickListenerDialog(data -> {
            if (data != null) {
                binding.parentCv.setVisibility(View.VISIBLE);
                storeDetailObjectModel = data;
                binding.tvAccountName.setText(data.getName());
                binding.tvAddress.setText(data.getAdd1() + data.getAdd2() + data.getAdd3());
                binding.tvAddress.setVisibility(View.VISIBLE);
                binding.ivClearFilter.setVisibility(View.VISIBLE);
                getMyOrderList();
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
            getMyOrderList();
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
            getMyOrderList();

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
            getMyOrderList();
        });
    }

    private void getMyOrderList() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lSize", String.valueOf(2000));
            jsonObject.put("lPageNo", String.valueOf(PAGE_NUM));
            jsonObject.put("from_date", fromDate);
            jsonObject.put("till_date", tillDate);
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lFirmCode", isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : getLicDetails().getFirmcode());
            jsonObject.put("lStatus", status);
            jsonObject.put("AcCode", isSalesMan ? (partyPickerCalled ? SharedPrefUtils.getString(getActivity(), Constant.PARTY_CODE) : "") : SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("lRole", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().MyOrderList(String.valueOf(jsonObject)), Constant.MYORDERLIST, true);
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
                case Constant.MYORDERLIST:
                    try {
                        if (jsonObject.getBoolean("Status")) {
                            setMyOrderListData(jsonObject.getJSONArray("Item"));
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
            if (myBillsList != null && myBillsList.size() > 0)
                myBillsList.clear();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                OrderDetailsModel myOrderModel = new OrderDetailsModel();
                myOrderModel.setOrderId(ReckonUtils.getJsonCheckedString(jsonObject, "OrderId", ""));
                myOrderModel.setPlacedOn(ReckonUtils.getJsonCheckedString(jsonObject, "PlacedOn", ""));
                myOrderModel.setOrderStatus(ReckonUtils.getJsonCheckedString(jsonObject, "OrderStatus", ""));
                myOrderModel.setOrderValue(ReckonUtils.getJsonCheckedString(jsonObject, "OrderValue", "0.0"));
                myOrderModel.setPaymentMode(ReckonUtils.getJsonCheckedString(jsonObject, "PaymentMode", ""));
                myOrderModel.setDeliveryDate(ReckonUtils.getJsonCheckedString(jsonObject, "DeliveryDate", ""));
                myOrderModel.setDeliveryMode(ReckonUtils.getJsonCheckedString(jsonObject, "DeliveryMode", ""));
                myOrderModel.setNoOfItem(ReckonUtils.getJsonCheckedString(jsonObject, "NoOfItem", "0"));
                myOrderModel.setAccountName(ReckonUtils.getJsonCheckedString(jsonObject, "AcName", ""));
                myOrderModel.setAccountId(ReckonUtils.getJsonCheckedString(jsonObject, "AcIdCol", ""));
                myBillsList.add(myOrderModel);
            }
            binding.noRecordTV.setVisibility(myBillsList.size() == 0 ? View.VISIBLE : View.GONE);
            binding.myBillsRecycler.setAdapter(new NewArrivalAdapter(MyBillsFragment.this, myBillsList));
            String showListSizeTxt = "(" + myBillsList.size() + ")";
            binding.allCountTv.setText(showListSizeTxt);
            binding.recentCountTv.setText(showListSizeTxt);
            binding.cancelledCountTv.setText(showListSizeTxt);
            binding.openCalenderFab.setVisibility(dateRangeDataList.size() > 0 ? View.VISIBLE : GONE);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setDateRangeData(JSONArray jsonArray) {
        try {
            if (dateRangeDataList != null && dateRangeDataList.size() > 0)
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
            binding.openCalenderFab.setVisibility(dateRangeDataList.size() > 0 ? View.VISIBLE : GONE);
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
                getMyOrderList();
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
                ReckonUtils.getMyCalender(MyBillsFragment.this, dateStartDialog, null);
            }
        });

        endDateCv.setOnClickListener(v -> {
            if (!dateStartDialog.getText().toString().isEmpty()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    ReckonUtils.getMyCalender(MyBillsFragment.this, dateEndDialog, itemListenerDialog);
                }
            } else {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_from_date), Toast.LENGTH_SHORT).show();
            }
        });
        doneCv.setOnClickListener(v -> {
            if (!dateStartDialog.getText().toString().isEmpty() && !dateEndDialog.getText().toString().isEmpty()) {
                fromDate = dateStartDialog.getText().toString();
                tillDate = dateEndDialog.getText().toString();
                binding.tvSelectedDate.setVisibility(View.VISIBLE);
                binding.tvSelectedDate.setText(fromDate + "  -  " + tillDate);
                getMyOrderList();
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

    @Override
    public void onResume() {
        super.onResume();
        if (!isSalesMan && !isFirst) {
            binding.tvAccountName.setText(getLicDetails().getFirmName());
            binding.tvAddress.setText(getLicDetails().getFirmAdd());
            binding.tvAddress.setVisibility(View.VISIBLE);
            binding.ivClearFilter.setVisibility(View.VISIBLE);
            getMyOrderList();
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        clearData();
    }
}