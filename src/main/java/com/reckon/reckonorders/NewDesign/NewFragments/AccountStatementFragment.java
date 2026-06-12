package com.reckon.reckonorders.NewDesign.NewFragments;

import static android.view.View.GONE;
import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.core.widget.NestedScrollView;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Adapter.DateRangePickerAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Interfaces.ItemListener;
import com.reckon.reckonorders.Model.DateRangeModel;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.AreaOutletAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.InvoiceModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.StorePartyPickerDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentAccountStatementBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link AccountStatementFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class AccountStatementFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    FragmentAccountStatementBinding binding;
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    ArrayList<String> searchList = new ArrayList<>();
    ArrayList<InvoiceModel> invoiceList = new ArrayList<>();
    private String mParam1, accountName, accountCode, accountAddress, accountMobile;
    private String mParam2;
    private ArrayList<String> invoiceNumber;
    private int i = 0;
    private int keypadHeight = 0;
    private int pageCount = 30;
    private int PAGE_NUM = 1;
    private boolean acceptClick = true;
    private LinearLayoutManager mlayoutManager;
    private int totalListCount = 0;
    private TextView dateStartDialog, dateEndDialog;
    public boolean isSearched = false;
    private String previousTitle = "", selectedStationId, selectedStationName, selectedAreaId, selectedAreaName, source, data, firmCode = "", firmName = "";
    private AlertDialog alertDialogShare;
    private View view = null;
    private EditText searchBox;
    private BottomSheetDialog bottomSheetDialog;
    private ArrayList<DateRangeModel> dateRangeDataList = new ArrayList<>();
    private DateRangeModel dateRangeModel;
    private boolean isSalesMan;
    private boolean shareViaWhatsapp = false;
    private boolean isShareEnabled = false;
    private StoreDetailObjectModel selectedFirmObj;

    public static AccountStatementFragment newInstance(String param1, String param2) {
        AccountStatementFragment fragment = new AccountStatementFragment();
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
        retrofitCallBackListener = this;
        previousTitle = NewMainActivity.binding.appBarNewMain.pageName.getText().toString();
        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        getBundle();
        isSearched = true;
        new Handler().postDelayed(() -> {
            KeyboardUtils.hideSoftKeyboard(getActivity());
            getAccountLedger("", PAGE_NUM, true, false);
        }, 1000);

    }

    public void setSearchText(String text) {
        searchBox.setText(text);
        binding.listOfData.setVisibility(View.GONE);
        i = 1;
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        if (view == null) {
            binding = FragmentAccountStatementBinding.inflate(inflater, container, false);
            view = inflater.inflate(R.layout.fragment_account_statement, container, false);
            searchBox = view.findViewById(R.id.searchBox);
            initViews(binding.getRoot());
        }
        return binding.getRoot();
    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            String from = bundle.containsKey(Constant.FROM) ? bundle.getString(Constant.FROM) : "";
            accountName = bundle.containsKey("name") ? bundle.getString("name") : "";
            accountCode = bundle.containsKey("Code") ? bundle.getString("Code") : "";
            accountAddress = bundle.containsKey("address") ? bundle.getString("address") : "";
            accountMobile = bundle.containsKey("Mobile") ? bundle.getString("Mobile") : "";
            selectedStationId = bundle.containsKey("selected_station_id") ? bundle.getString("selected_station_id") : "";
            selectedStationName = bundle.containsKey("selected_station_name") ? bundle.getString("selected_station_name") : "";
            selectedAreaId = bundle.containsKey("selected_area_id") ? bundle.getString("selected_area_id") : "";
            selectedAreaName = bundle.containsKey("selected_area_name") ? bundle.getString("selected_area_name") : "";
            source = bundle.containsKey("source") ? bundle.getString("source") : "";
            try {
                data = bundle.containsKey(Constant.PARTY_LIST) ? bundle.getString(Constant.PARTY_LIST) : "";
                LoginModel model = gson.fromJson(data, new TypeToken<LoginModel>() {
                }.getType());
                SharedPrefUtils.setString(getActivity(), Constant.SELECTED_AC_MOBILE_NUMBER, model.getMobile());
                localStorage.setSelectedAcMobile(model.getMobile());
                localStorage.getSelectedAcMobile();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        ((NewMainActivity) requireActivity()).setUpTitle(this, previousTitle);
    }

    private void initViews(View view) {
        ((NewMainActivity) requireActivity()).setUpTitle(AccountStatementFragment.this, getString(R.string.account_statement));
        keyboardListener();
        getDateRange();
        invoiceNumber = new ArrayList<>();
        binding.shareStatement.setCardBackgroundColor(getButtonColor());
//        binding.tvHeadingAddress.setTextColor(getThirdHeaderColor());
        binding.startDateCalenderCard.setCardBackgroundColor(getThirdHeaderColor());
        binding.accountNameList.setCardBackgroundColor(getThirdHeaderColor());
        binding.endDateCalenderCard.setCardBackgroundColor(getThirdHeaderColor());
        binding.tvToDate.setTextColor(getThirdHeaderColor());
        binding.calendarEnd.setColorFilter(getThirdHeaderColor());
        binding.calendarStart.setColorFilter(getThirdHeaderColor());
        binding.openingBalanceCardLl.setBackgroundColor(getButtonColor());
        binding.closingBalanceLL.setBackgroundColor(getButtonColor());
        binding.tvHeadingPartyName.setTextColor(getSecondHeaderTextColor());
//        binding.openingBalance.setTextColor(getThirdHeaderColor());
//        binding.tvOpeningBalance.setTextColor(getThirdHeaderColor());
//        binding.closingBalance.setTextColor(getThirdHeaderColor());
//        binding.tvClosingBalance.setTextColor(getThirdHeaderColor());

        binding.tvHeadingPartyName.setText(accountName);
        binding.tvHeadingAddress.setText(accountAddress);
        mlayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
        binding.invoiceRecycler.setLayoutManager(mlayoutManager);
        binding.invoiceRecycler.setNestedScrollingEnabled(false);
        binding.scrollView.setOnTouchListener((v, event) -> {
            InputMethodManager imm = (InputMethodManager) requireActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
            return false;
        });
        binding.scrollView.setOnScrollChangeListener((View.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
            InputMethodManager imm = (InputMethodManager) requireActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
        });
        searchBox.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                binding.shareStatementCard.setVisibility(View.GONE);
                binding.openingBalanceCard.setVisibility(View.GONE);
                isSearched = true;
                PAGE_NUM = 1;
                if (s.toString().isEmpty()) {
                    new Handler().postDelayed(() -> {
                        getAccountLedger("", 1, false, false);
                    }, 500);
                } else if (acceptClick) {
                    acceptClick = false;
                    getAccountLedger(s.toString(), PAGE_NUM, false, false);
                    new Handler().postDelayed(() -> acceptClick = true, 500);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });

        binding.scrollView.setOnScrollChangeListener((NestedScrollView.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
            if (v.getChildAt(v.getChildCount() - 1) != null) {
                if ((scrollY >= (v.getChildAt(v.getChildCount() - 1).getMeasuredHeight() - v.getMeasuredHeight())) &&
                        scrollY > oldScrollY) {
                    int visibleItemCount = mlayoutManager.getChildCount();
                    int totalItemCount = mlayoutManager.getItemCount();
                    int pastVisiblesItems = mlayoutManager.findFirstVisibleItemPosition();
                    if ((visibleItemCount + pastVisiblesItems) >= totalItemCount) {
                        if (totalListCount > invoiceList.size()) {
                            isSearched = false;
                            getAccountLedger(searchBox.getText().toString(), ++PAGE_NUM, true, false);
                        }
                    }
                }
            }
        });
        binding.calendarStart.setOnClickListener(v -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                ReckonUtils.getMyCalender(AccountStatementFragment.this, binding.dateStart, null);
            }
        });
        binding.infoImv.setOnClickListener(v -> {
            Bundle bundle = new Bundle();
            bundle.putString(Constant.PARTY_LIST, data);
            Navigation.findNavController(v).navigate(R.id.nav_account_details, bundle);
        });


        binding.calendarEnd.setOnClickListener(v -> {
            if (!binding.dateStart.getText().toString().isEmpty()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    ReckonUtils.getMyCalender(AccountStatementFragment.this, binding.dateEnd, itemListener);
                }
            } else {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_from_date), Toast.LENGTH_SHORT).show();
            }

        });
        binding.ivOkDateFilter.setOnClickListener(v -> {
            binding.ivClearDateFilter.setVisibility(View.VISIBLE);
            binding.ivOkDateFilter.setVisibility(View.GONE);
            isSearched = true;
            PAGE_NUM = 1;
            getAccountLedger("", PAGE_NUM, true, false);
        });
        binding.ivClearDateFilter.setOnClickListener(v -> {
            binding.ivClearDateFilter.setVisibility(View.GONE);
            binding.ivOkDateFilter.setVisibility(View.GONE);
            binding.dateStart.setText("");
            binding.dateEnd.setText("");
            isSearched = true;
            PAGE_NUM = 1;
            getAccountLedger("", PAGE_NUM, true, false);
        });
        binding.shareLl.setVisibility(isSalesMan ? View.VISIBLE : GONE);
        binding.share.setOnClickListener(v -> {
            shareViaWhatsapp = false;
            showPopUp(view);
        });
        binding.shareViaWhatsappIv.setOnClickListener(v -> {
            shareViaWhatsapp = true;
            showPopUp(view);
        });

        binding.openCalenderFab.setOnClickListener(v -> showBottomSheetDialog());

        binding.pullToRefresh.setOnRefreshListener(() -> {
            PAGE_NUM = 1;
            isSearched = true;
            getAccountLedger("", PAGE_NUM, true, false);
            binding.pullToRefresh.setRefreshing(false);
        });
        binding.seeOutStandingTv.setOnClickListener(v -> gotoOutstanding());
        binding.selectFirmCv.setVisibility(getStoreListData() != null && getStoreListData().size() > 1 ? View.VISIBLE : View.GONE);
        binding.selectFirmCv.setOnClickListener(view1 -> {
            StorePartyPickerDialog dialog = new StorePartyPickerDialog(getActivity(), getString(R.string.select_your_firm), Constant.FIRM, Constant.CREATE_RECEIPT, selectedFirmObj);
            dialog.setOnItemClickListenerDialog(data -> {
                if (data != null) {
                    selectedFirmObj = data;
                    firmName = data.getName();
                    binding.tvFirmName.setText(data.getName());
                    firmCode = data.getFirmCode();
                    isSearched = true;
                    PAGE_NUM = 1;
                    getAccountLedger("", PAGE_NUM, true, false);
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
            isSearched = true;
            PAGE_NUM = 1;
            getAccountLedger("", PAGE_NUM, true, false);
            binding.ivClearFirm.setVisibility(GONE);
        });

    }

    private void showBottomSheetDialog() {
        bottomSheetDialog = new BottomSheetDialog(requireActivity());
        bottomSheetDialog.setContentView(R.layout.bottom_sheet_dialog_layout);
        RecyclerView recyclerView = bottomSheetDialog.findViewById(R.id.dateRv);
        recyclerView.setAdapter(new DateRangePickerAdapter(dateRangeDataList, AccountStatementFragment.this, dateRangeModel));
        bottomSheetDialog.findViewById(R.id.closeDialogImv).setOnClickListener(v -> bottomSheetDialog.dismiss());
        CardView clearCv = bottomSheetDialog.findViewById(R.id.clearDateCv);
        clearCv.setVisibility(dateRangeModel == null ? GONE : View.VISIBLE);
        clearCv.setOnClickListener(v -> {
            binding.tvSelectedDate.setText("");
            binding.tvSelectedDate.setVisibility(GONE);
            dateRangeModel = null;
            binding.dateStart.setText("");
            binding.dateEnd.setText("");
            isSearched = true;
            PAGE_NUM = 1;
            getAccountLedger("", PAGE_NUM, true, false);
            bottomSheetDialog.dismiss();
        });
        bottomSheetDialog.show();
    }

    public void executeClick(DateRangeModel mModel) {
        bottomSheetDialog.dismiss();
        if (mModel != null) {
            dateRangeModel = mModel;
            binding.dateStart.setText(dateRangeModel.getFromDate());
            binding.dateEnd.setText(dateRangeModel.getTillDate());
            if (dateRangeModel.getFromDate().isEmpty() || dateRangeModel.getTillDate().isEmpty()) {
                showDatePopUp(binding.getRoot());
            } else {
                isSearched = true;
                binding.tvSelectedDate.setVisibility(View.VISIBLE);
                binding.tvSelectedDate.setText(dateRangeModel.getFromDate() + "  -  " + dateRangeModel.getTillDate());
                PAGE_NUM = 1;
                getAccountLedger("", PAGE_NUM, true, false);
            }
        }

    }

    public void showDatePopUp(View view) {
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
                ReckonUtils.getMyCalender(AccountStatementFragment.this, dateStartDialog, null);
            }
        });

        endDateCv.setOnClickListener(v -> {
            if (!dateStartDialog.getText().toString().isEmpty()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    ReckonUtils.getMyCalender(AccountStatementFragment.this, dateEndDialog, itemListenerDialog);
                }
            } else {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_from_date), Toast.LENGTH_SHORT).show();
            }
        });
        doneCv.setOnClickListener(v -> {
            if (!dateStartDialog.getText().toString().isEmpty() && !dateEndDialog.getText().toString().isEmpty()) {
                isSearched = true;
                binding.dateStart.setText(dateStartDialog.getText().toString());
                binding.dateEnd.setText(dateEndDialog.getText().toString());
                binding.tvSelectedDate.setVisibility(View.VISIBLE);
                binding.tvSelectedDate.setText(dateStartDialog.getText().toString() + "  -  " + dateEndDialog.getText().toString());
                PAGE_NUM = 1;
                getAccountLedger("", PAGE_NUM, true, false);
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


    public void showPopUp(View view) {
        AlertDialog.Builder builder = new AlertDialog.Builder(requireActivity());
        ViewGroup viewGroup = view.findViewById(android.R.id.content);
        View dialogView = LayoutInflater.from(view.getContext()).inflate(R.layout.customview, viewGroup, false);
        builder.setView(dialogView);
        dateStartDialog = dialogView.findViewById(R.id.dateStart);
        dateEndDialog = dialogView.findViewById(R.id.dateEnd);
        CardView startDateCv = dialogView.findViewById(R.id.startDateCalenderCard);
        CardView endDateCv = dialogView.findViewById(R.id.endDateCalenderCard);
        CardView shareStatement = dialogView.findViewById(R.id.shareStatement);
        CardView closeDialogCv = dialogView.findViewById(R.id.closeDialogCv);

        dateStartDialog.setText(binding.dateStart.getText().toString());
        dateEndDialog.setText(binding.dateEnd.getText().toString());
        startDateCv.setOnClickListener(v -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                ReckonUtils.getMyCalender(AccountStatementFragment.this, dateStartDialog, null);
            }
        });

        endDateCv.setOnClickListener(v -> {
            if (!dateStartDialog.getText().toString().isEmpty()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    ReckonUtils.getMyCalender(AccountStatementFragment.this, dateEndDialog, itemListenerDialog);
                }
            } else {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_from_date), Toast.LENGTH_SHORT).show();
            }
        });
        shareStatement.setOnClickListener(v -> {
//            if (!dateStartDialog.getText().toString().isEmpty() && !dateEndDialog.getText().toString().isEmpty()) {
            isSearched = true;
            PAGE_NUM = 1;
            getAccountLedger("", PAGE_NUM, true, true);
            if (alertDialogShare != null) {
                alertDialogShare.dismiss();
            }
//            } else {
//                Toast.makeText(requireActivity(), requireActivity().getString(R.string.please_select_date), Toast.LENGTH_SHORT).show();
//            }
        });
        closeDialogCv.setOnClickListener(v -> {
            if (alertDialogShare != null) {
                alertDialogShare.dismiss();
            }
        });

        alertDialogShare = builder.create();
        alertDialogShare.show();

    }

    private final ItemListener itemListener = position -> {
        binding.ivClearDateFilter.setVisibility(View.VISIBLE);
        binding.ivOkDateFilter.setVisibility(View.GONE);
        isSearched = true;
        PAGE_NUM = 1;
        getAccountLedger("", PAGE_NUM, true, false);
    };
    private final ItemListener itemListenerDialog = position -> {

    };
    boolean isKeyboardShowing = false;

    void onKeyboardVisibilityChanged(boolean opened) {
        binding.shareStatementCard.setVisibility(opened ? View.GONE : View.VISIBLE);
        binding.openingBalanceCard.setVisibility(opened ? View.GONE : View.VISIBLE);
    }

    @Override
    public void onResume() {
        super.onResume();
        System.out.println("test----resume");
    }

    private void keyboardListener() {
        // ContentView is the root view of the layout of this activity/fragment
        binding.parentRlContainer.getViewTreeObserver().addOnGlobalLayoutListener(
                () -> {
                    Rect r = new Rect();
                    binding.parentRlContainer.getWindowVisibleDisplayFrame(r);
                    int screenHeight = binding.parentRlContainer.getRootView().getHeight();
                    // r.bottom is the position above soft keypad or device button.
                    // if keypad is shown, the r.bottom is smaller than that before.
                    keypadHeight = screenHeight - r.bottom;
                    if (keypadHeight > screenHeight * 0.15) { // 0.15 ratio is perhaps enough to determine keypad height.
                        if (!isKeyboardShowing) {// keyboard is opened
                            isKeyboardShowing = true;
                            onKeyboardVisibilityChanged(true);
                        }
                    } else { // keyboard is closed
                        if (isKeyboardShowing) {
                            isKeyboardShowing = false;
                            onKeyboardVisibilityChanged(false);
                        }
                    }
                });
    }

    String getFirmCode() {
        return isSalesMan ? (getStoreListData().size() > 1 ? firmCode : getSelectedStoreDetailsFromPicker().getFirmCode()) : getLicDetails().getFirmcode();
    }

    private void getAccountLedger(String s, int PAGE_NUM, boolean isLoader, boolean forPDF) {
        try {
            isShareEnabled = forPDF;
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lAcNo", isSalesMan ? accountCode : SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
            jsonObject.put("lFromDate", forPDF ? dateStartDialog.getText().toString() : binding.dateStart.getText().toString());
            jsonObject.put("lTillDate", forPDF ? dateEndDialog.getText().toString() : binding.dateEnd.getText().toString());
            jsonObject.put("lAcId", "");
            jsonObject.put("lPageNo", String.valueOf(PAGE_NUM));
            jsonObject.put("lSize", String.valueOf(pageCount));
            jsonObject.put("lSearchFieldValue", s);
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lSharePdf", String.valueOf(forPDF));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            jsonObject.put("lFirmCode", getFirmCode());
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getAccountLedger(String.valueOf(jsonObject)), Constant.ACCOUNT_LEDGER, isLoader);
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
        if (result != null && result.length() > 1) {
            if (isShareEnabled) {
                try {
                    JSONObject jsonObject = new JSONObject(result);
                    boolean sharePDF = jsonObject.has("share_pdf") && jsonObject.getBoolean("share_pdf");
                    if (sharePDF && jsonObject.has("data")) {
                        JSONObject obj = jsonObject.getJSONObject("data");
                        String pdfLink = ReckonUtils.getJsonCheckedString(obj, "link", "");
                        String docName = ReckonUtils.getJsonCheckedString(obj, "doc_name", "statement");
                        if (ReckonUtils.isPDFValid(pdfLink)) {
                            ReckonUtils.downloadAndSharePdf(pdfLink, requireActivity(), shareViaWhatsapp, docName);
                        } else {
                            Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                        }
                    } else {
                        Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    if (ReckonUtils.isPDFValid(result)) {
                        ReckonUtils.downloadAndSharePdf(result, requireActivity(), shareViaWhatsapp, "statement");
                    } else {
                        Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                    }
                }
            } else {
                JSONObject jsonObject = new JSONObject(result);
                switch (action) {
                    case Constant.ACCOUNT_LEDGER:
                        try {
                            if (isSearched && !invoiceList.isEmpty()) {
                                isSearched = false;
                                invoiceList.clear();
                            }
                            JSONArray jsonArray = jsonObject.getJSONArray("Ledger");
                            for (int i = 0; i < jsonArray.length(); i++) {
                                JSONObject object = jsonArray.getJSONObject(i);
                                InvoiceModel model = new InvoiceModel();
                                model.setTranType(ReckonUtils.getJsonCheckedString(object, "TranType", ""));
                                model.setOppBal(ReckonUtils.getJsonCheckedString(object, "OppBal", ""));
                                model.setTranFirm(ReckonUtils.getJsonCheckedString(object, "TranFirm", ""));
                                model.setEntryNo(ReckonUtils.getJsonCheckedString(object, "EntryNo", ""));
                                model.setDrAmt(ReckonUtils.getJsonCheckedString(object, "DrAmt", ""));
                                model.setTranNumber(ReckonUtils.getJsonCheckedString(object, "TranNumber", ""));
                                model.setTranId(ReckonUtils.getJsonCheckedString(object, "TranId", ""));
                                model.setCrAmt(ReckonUtils.getJsonCheckedString(object, "CrAmt", ""));
                                model.setDate(ReckonUtils.getJsonCheckedString(object, "Date", ""));
                                model.setRunningAmt(ReckonUtils.getJsonCheckedString(object, "RunningAmt", ""));
                                model.setKeyEntryNo(ReckonUtils.getJsonCheckedString(object, "KeyEntryNo", ""));
                                model.setKeyEntrySrNo(ReckonUtils.getJsonCheckedString(object, "KeyEntrySrNo", ""));
                                model.setIsEntryRecord(ReckonUtils.getJsonCheckedString(object, "IsEntryRecord", ""));
                                model.setAmountColor(ReckonUtils.getJsonCheckedString(object, "amount_color", "#000000"));
                                totalListCount = Integer.parseInt(ReckonUtils.getJsonCheckedString(object, "RCount", ""));
                                invoiceList.add(model);
                            }
                            if (invoiceList != null && !invoiceList.isEmpty()) {
                                String openingBal = ReckonUtils.getJsonCheckedString(jsonObject, "OppBal", "");
                                String closingBal = ReckonUtils.getJsonCheckedString(jsonObject, "ClosingBal", "");
                                binding.openingBalance.setText(getLicDetails().getCurrency() + openingBal);
                                binding.closingBalance.setText(getLicDetails().getCurrency() + closingBal);
                                binding.openingBalanceCard.setVisibility(!searchBox.getText().toString().isEmpty() || isKeyboardShowing ? View.GONE : View.VISIBLE);
                                binding.shareStatementCard.setVisibility(!searchBox.getText().toString().isEmpty() || isKeyboardShowing ? View.GONE : View.VISIBLE);
                                binding.shareLl.setVisibility(isSalesMan ? View.VISIBLE : GONE);
                                binding.invoiceRecycler.setVisibility(View.VISIBLE);
                                binding.noRecordTV.setVisibility(View.GONE);
                                binding.pullToRefresh.setVisibility(View.VISIBLE);
                                binding.invoiceRecycler.setAdapter(new AreaOutletAdapter(AccountStatementFragment.this, invoiceList, "main", searchList));
                            } else {
                                binding.openingBalanceCard.setVisibility(View.GONE);
                                binding.shareStatementCard.setVisibility(View.GONE);
                                binding.shareLl.setVisibility(GONE);
                                binding.invoiceRecycler.setVisibility(GONE);
                                binding.noRecordTV.setVisibility(View.VISIBLE);
                                binding.pullToRefresh.setVisibility(View.VISIBLE);
                            }
                        } catch (Exception e) {
                            showNoResultScreen();
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
        } else {
            showNoResultScreen();
        }
    }

    private void showNoResultScreen() {
        if (!invoiceList.isEmpty()) {
            invoiceList.clear();
        }
        binding.invoiceRecycler.setAdapter(new AreaOutletAdapter(AccountStatementFragment.this, invoiceList, "main", searchList));
        binding.noRecordTV.setVisibility(View.VISIBLE);
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
            if (dateRangeDataList.size() > 0) {
                binding.openCalenderFab.setVisibility(View.VISIBLE);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void gotoOutstanding() {
        Bundle bundle = new Bundle();
        bundle.putString("name", accountName);
        bundle.putString("Code", isSalesMan ? accountCode : SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
        bundle.putString("address", accountAddress);
        bundle.putString("from", Constant.PARTY);
        bundle.putString("firm_name", isSalesMan? firmName:getLicDetails().getFirmName());
        bundle.putString("firm_code",isSalesMan? firmCode:getLicDetails().getFirmcode());
        NavHostFragment.findNavController(this).navigate(R.id.nav_outlet_details, bundle);
    }

}
