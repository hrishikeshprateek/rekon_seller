package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_CART;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_DISTRIBUTOR_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_FIRM_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_PARTY_FILTER;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.graphics.BlendMode;
import android.graphics.BlendModeColorFilter;
import android.graphics.PorterDuff;
import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.cardview.widget.CardView;
import androidx.core.widget.NestedScrollView;
import androidx.navigation.Navigation;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.facebook.shimmer.ShimmerFrameLayout;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Adapter.CommonRowAdapter;
import com.reckon.reckonorders.Adapter.NewOrderProductsAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.SelectSinglePopup;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.Debouncer;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import butterknife.Unbinder;

public class NewOrderFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;

    @BindView(R.id.new_order_container)
    LinearLayout newOrderContainer;
    @BindView(R.id.rv_product_listing)
    public RecyclerView rvProductListing;
    @BindView(R.id.noRecordTV)
    LinearLayout noRecordTV;
    @BindView(R.id.totalLayout)
    CardView totalLayout;
    @BindView(R.id.productShimmer)
    ShimmerFrameLayout productShimmer;
    @BindView(R.id.order_via_distributor_rl)
    RelativeLayout order_via_distributor_rl;
    @BindView(R.id.order_via_product_rl)
    RelativeLayout order_via_product_rl;
    @BindView(R.id.order_via_product_view)
    View order_via_product_view;
    @BindView(R.id.order_via_distributor_view)
    View order_via_distributor_view;
    @BindView(R.id.select_store_ll)
    LinearLayout select_store_ll;
    @BindView(R.id.search_box_ll)
    LinearLayout search_box_ll;
    @BindView(R.id.search_dis_tv)
    TextView search_dis_tv;
    @BindView(R.id.search_loc_et)
    public EditText search_loc_et;
    @BindView(R.id.scroll_view)
    NestedScrollView scroll_view;
    @BindView(R.id.fragmentMyVendor_imgSortVendors)
    ImageView imgSortVendors;
    @BindView(R.id.clear_text_ll)
    LinearLayout clear_text_ll;
    @BindView(R.id.header_switch)
    LinearLayout header_switch;
    @BindView(R.id.search_Firm_ll)
    LinearLayout search_Firm_ll;
    @BindView(R.id.search_firm_tv)
    TextView search_firm_tv;
    @BindView(R.id.cart)
    TextView cart;
    @BindView(R.id.fragmentMyVendor_tvCount)
    TextView tvCount;
    @BindView(R.id.tvTotalAmountValue)
    TextView TotalPrice_tv;
    @BindView(R.id.totalOrderValueCard)
    CardView totalOrderValueCard;
    @BindView(R.id.pullToRefresh)
    SwipeRefreshLayout pullToRefresh;
    @BindView(R.id.actionbar_imgSearch)
    ImageView dropDownImg;

    @BindView(R.id.llSearchFilter)
    LinearLayout llSearchFilter;

    @BindView(R.id.clearIv)
    ImageView clearIv;

    public boolean isRefreshed = false, flag = true;
    Bundle bundle;
    private Unbinder unbinder;
    boolean isFirstTabSelected = true;
    private final ArrayList<ProductModel> productsList = new ArrayList<>();
    private final ArrayList<ProductModel> cartProductList = new ArrayList<>();
    private List<SelectionModel> dataSortDistributors = new ArrayList<>();
    private List<SelectionModel> data = new ArrayList<>();
    public String FirmCode, LicNo, SortByValue = "", searchFilterId = "";
    private String distributorName = "", selectedFilters = "";
    private int PAGE_NUM = 1;
    private int pageCount = 30;
    LinearLayoutManager mlayoutManager;
    public boolean isSearched = false;
    private SelectSinglePopup popupSortVendors;
    private SelectionModel selectedSortVendors;
    public CommonRowAdapter commonRowAdapter;
    public NewOrderProductsAdapter newOrderProductsAdapter;
    @BindView(R.id.ll_apply_filter)
    LinearLayout llApplyFilter;

    @BindView(R.id.ic_filter)
    ImageView icFilter;

    @BindView(R.id.imgView)
    ImageView imgView;

    @BindView(R.id.recentProductsCV)
    CardView recentProductsCV;

    @BindView(R.id.ll_dot)
    LinearLayout filterDot;

    public String ShowStock = "";
    private boolean IsFirst = false;
    public String partyCode = "", partyName = "";
    private String ID = "id";
    private String brandNameSearchId = "", isNewArrival = "";
    private String NAME = "name", FirmName = "", withScheme = "0";
    private boolean acceptClick = true;
    public ArrayList<Float> productAmountsList = new ArrayList<>();
    private boolean isSalesMan;
    private final Gson gson = new Gson();
    String from = "";
    private int keypadHeight = 0;
    public String searchedText = "";
    private boolean isOrderExist = false;
    private final ArrayList<SelectionModel> searchFilterListData = new ArrayList<>();
    final Debouncer debouncer = new Debouncer();

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        Constant.model = new ProductModel();
        View view = inflater.inflate(R.layout.fragment_new_order, container, false);
        requireActivity().getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_PAN);
        retrofitCallBackListener = this;
        unbinder = ButterKnife.bind(this, view);
        LicNo = getLicDetails().getLicno();
        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        FirmCode = isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : getLicDetails().getFirmcode();
        FirmName = !isSalesMan ? getStoreDetails() != null ? getStoreDetails().getName() : "" : "";
        productShimmer.showShimmer(true);
        setupBackButton(view);
        setTitle(view, getString(R.string.new_order).toUpperCase());
        getBundle();
        setupUI(view);
        return view;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        unbinder.unbind();
    }

    public void getBundle() {
        bundle = getArguments();
        if (bundle != null) {
            from = bundle.containsKey("from") ? bundle.getString("from") : "";
         /*   if(from.equalsIgnoreCase(Constant.PRODUCT_DETAILS)){

            }else{*/
            brandNameSearchId = bundle.containsKey("BrandItemId") ? bundle.getString("BrandItemId") : "";
            isNewArrival = bundle.containsKey("isNewArrival") ? bundle.getString("isNewArrival") : "";
            withScheme = bundle.containsKey("withScheme") ? bundle.getString("withScheme") : "";
            String name = bundle.containsKey("data") ? bundle.getString("data") : "";
            if (name != null) {
                distributorName = name;
            }
            search_dis_tv.setText(distributorName);
            if (from.equalsIgnoreCase(Constant.SCHEME)) {
                withScheme = "1";
            }
        }
        try {
            if (isSalesMan) {
                if (from.equalsIgnoreCase(Constant.PARTY)) {
                    partyCode = bundle.containsKey("Code") ? bundle.getString("Code") : "";
                    partyName = bundle.containsKey("name") ? bundle.getString("name") : "";
                } else if (from.equalsIgnoreCase(Constant.CART)) {
                    StoreDetailObjectModel selectedPartyDataModel = gson.fromJson(getArguments().getString(Constant.PARTY), new TypeToken<StoreDetailObjectModel>() {
                    }.getType());
                    partyCode = selectedPartyDataModel.getFirmCode();
                    partyName = selectedPartyDataModel.getName();
                }
                FirmCode = getSelectedStoreDetailsFromPicker().getFirmCode();
                FirmName = getSelectedStoreDetailsFromPicker().getName();
                search_dis_tv.setText(partyName);
                search_Firm_ll.setVisibility(View.GONE);
                select_store_ll.setVisibility(View.VISIBLE);
                search_dis_tv.setHint(getResources().getString(R.string.serach_party));
                isSearched = true;
                PAGE_NUM = 1;
                IsFirst = true;
                if (!from.equalsIgnoreCase(Constant.PRODUCT_FILTER)) {
                    SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, partyCode);
                }
                search_firm_tv.setText(FirmName);
            } else {
                select_store_ll.setVisibility(View.VISIBLE);
                FirmCode = bundle.containsKey(Constant.SELECTED_ID) ? bundle.getString(Constant.SELECTED_ID) : "";
                FirmName = bundle.containsKey("name") ? bundle.getString("name") : "";
                LicNo = getLicDetails().getLicno();
                StoreDetailObjectModel selectedPartyDataModel;
                if (from.equalsIgnoreCase(Constant.CART)) {
                    FirmCode = getLicDetails().getFirmcode();
                    FirmName = getLicDetails().getFirmName();
                    if(!ReckonUtils.nonNullNotEmptyString(FirmCode) || !ReckonUtils.nonNullNotEmptyString(FirmName)){
                         selectedPartyDataModel = gson.fromJson(getArguments().getString(Constant.PARTY), new TypeToken<StoreDetailObjectModel>() {
                        }.getType());
                        FirmCode = selectedPartyDataModel.getFirmCode();
                        FirmName = selectedPartyDataModel.getName();
                    }

                } else if (FirmCode.isEmpty()) {
                    String OPEN_PRODUCT_LIST_DIRECT = bundle.containsKey(Constant.OPEN_PRODUCT_LIST_DIRECT) ? bundle.getString(Constant.OPEN_PRODUCT_LIST_DIRECT) : "";
                    if (OPEN_PRODUCT_LIST_DIRECT.equalsIgnoreCase(Constant.YES)) {
                        LicNo = "";
                    } else {
                        FirmCode = getLicDetails().getFirmcode();
                        FirmName = getStoreDetails().getName();
                    }
                    dropDownImg.setVisibility(View.GONE);
                }
                if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE)) {
                    clearIv.setVisibility(View.GONE);
                    dropDownImg.setVisibility(View.GONE);
                }else{
                    clearIv.setVisibility(FirmCode.isEmpty() ? View.GONE : View.VISIBLE);
                }

                isSearched = true;
                PAGE_NUM = 1;
                IsFirst = true;
                search_firm_tv.setText(FirmName);
                distributorName = FirmName;
                search_dis_tv.setText(distributorName);
                clearIv.setOnClickListener(v -> {
                    clearStoreFilter();
                });
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

//        }
        if (from.equalsIgnoreCase(Constant.PRODUCT_FILTER)) {
            selectedFilters = bundle.containsKey(Constant.APPLIED_FILTERS) ? bundle.getString(Constant.APPLIED_FILTERS) : "";
            filterDot.setVisibility(!selectedFilters.isEmpty() ? View.VISIBLE : View.GONE);
        }
        getProductList(searchedText, PAGE_NUM, true);
    }

    private void clearStoreFilter() {
        FirmCode = "";
        FirmName = "";
        LicNo = "";
        distributorName = "";
        PAGE_NUM = 1;
        productsList.clear();
        search_firm_tv.setText(FirmName);
        search_dis_tv.setText(distributorName);
        clearIv.setVisibility(View.GONE);
        LicDetailObjectModel model = getLicDetails();
        model.setFirmcode("");
        model.setFirmName("");
        model.setFirmAdd("");
        localStorage.setLicDetails(gson.toJson(model));
        getProductList("", PAGE_NUM, true);
    }

    private void setupUI(View view) {
        try {
            ((NewMainActivity) requireActivity()).setUpTitle(NewOrderFragment.this, getString(R.string.order_entry));
            keyboardListener();
            pullToRefreshExecution();
            totalLayout.setCardBackgroundColor(getButtonColor());
            if (!isSalesMan) {
                getCartItemList();
                totalOrderValueCard.setVisibility(LocalStorage.getInstance(getActivity()).getCart() == null || Double.parseDouble(LocalStorage.getInstance(getActivity()).getCart()) == 0.0 ? View.GONE : View.VISIBLE);
            }
            if (getLicDetails() != null && getLicDetails().getFirmcode().isEmpty()) {
                select_store_ll.setVisibility(View.VISIBLE);
            }
            unUsedData();
            clear_text_ll.setVisibility(View.INVISIBLE);
            search_loc_et.setHint(getResources().getString(R.string.search_product_name));
            imgView.setImageResource(R.mipmap.cart_icon);
            imgView.getLayoutParams().height = 90;
            imgView.getLayoutParams().width = 90;
            imgView.requestLayout();
            setProductListAdapter();
            searchWatcherListener();
            scrollChangeListener();

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                icFilter.setColorFilter(new BlendModeColorFilter(getThirdHeaderColor(), BlendMode.SRC_ATOP));
            } else {
                icFilter.setColorFilter(getThirdHeaderColor(), PorterDuff.Mode.SRC_ATOP);
            }
            llApplyFilter.setOnClickListener(v -> {
                goToProductFilterScreen(view);
            });
            recentProductsCV.setOnClickListener(v -> {
                Bundle mBuldle = new Bundle();
                mBuldle.putString(Constant.OPEN_PRODUCT_LIST_DIRECT, Constant.YES);
                Navigation.findNavController(v).navigate(R.id.nav_Recent_Ordered_Products, mBuldle);
            });
            try {
                if(!searchFilterListData.isEmpty()){
                    searchFilterListData.clear();
                }
                ArrayList<StoreDetailObjectModel> searchFilterList = SharedPrefUtils.getSearchFilterList(requireActivity()) != null ? SharedPrefUtils.getSearchFilterList(requireActivity()) : new ArrayList<>();
                for (int i = 0; i < searchFilterList.size(); i++) {
                    searchFilterListData.add(new SelectionModel(searchFilterList.get(i).getField_value(), searchFilterList.get(i).getField_name(), "false"));
                }
                llSearchFilter.setVisibility(searchFilterListData.isEmpty() ? View.GONE : View.VISIBLE);
            } catch (Exception e) {
                llSearchFilter.setVisibility(View.GONE);
            }
            mlayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
            rvProductListing.setLayoutManager(mlayoutManager);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void goToProductFilterScreen(View view) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.NEW_ORDER);
        bundle.putString(Constant.APPLIED_FILTERS, selectedFilters);
        bundle.putString(Constant.FILTER_TYPE, "Item");
        Navigation.findNavController(view).navigate(R.id.action_go_to_product_filter, bundle);
    }

    @SuppressLint("ClickableViewAccessibility")
    private void scrollChangeListener() {
        rvProductListing.setOnTouchListener((v, event) -> {
            KeyboardUtils.hideSoftKeyboard(getActivity());
            return false;
        });
        scroll_view.setOnScrollChangeListener((NestedScrollView.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
            if (v.getChildAt(v.getChildCount() - 1) != null) {
                if ((scrollY >= (v.getChildAt(v.getChildCount() - 1).getMeasuredHeight() - v.getMeasuredHeight())) &&
                        scrollY > oldScrollY) {
                    int visibleItemCount = mlayoutManager.getChildCount();
                    int totalItemCount = mlayoutManager.getItemCount();
                    int pastVisiblesItems = mlayoutManager.findFirstVisibleItemPosition();
                    if ((visibleItemCount + pastVisiblesItems) >= totalItemCount) {
                        if (totalCount > productsList.size()) {
                            isSearched = false;
                            getProductList(search_loc_et.getText().toString(), ++PAGE_NUM, true);
                        }
                    }
                }
            }


        });
    }

    private void searchWatcherListener() {
        search_loc_et.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (!isSalesMan)
                    totalOrderValueCard.setVisibility(View.GONE);
                clear_text_ll.setVisibility(!search_loc_et.getText().toString().isEmpty() ? View.VISIBLE : View.INVISIBLE);
                isSearched = true;
                PAGE_NUM = 1;
                if (s.toString().isEmpty()) {
                    getProductList("", 1, false);
                } else {
                    debouncer.debounce(Void.class, new Runnable() {
                        @Override public void run() {
                            getProductList(s.toString(), PAGE_NUM, false);
                          /*  if(!productsList.isEmpty()){
                                productsList.clear();
                            }*/
                        }
                    }, 500, TimeUnit.MILLISECONDS);
                }
                scroll_view.scrollTo(0, 0);
            }

            @Override
            public void afterTextChanged(Editable s) {
                isSearched = true;
            }
        });
    }

    private void setProductListAdapter() {
        productShimmer.showShimmer(false);
        rvProductListing.setVisibility(View.VISIBLE);
/*        commonRowAdapter = new CommonRowAdapter(NewOrderFragment.this, productsList, Constant.NEW_ORDER, bundle);//TODO: OLD Adapter
        rvProductListing.setAdapter(commonRowAdapter);*/
        newOrderProductsAdapter = new NewOrderProductsAdapter(NewOrderFragment.this, productsList, Constant.NEW_ORDER, bundle);//TODO: New Adapter
        rvProductListing.setAdapter(newOrderProductsAdapter);
    }


    private void pullToRefreshExecution() {
        pullToRefresh.setOnRefreshListener(() -> {
            productsList.clear();
            getProductList(search_loc_et.getText().toString(), 1, true);
            pullToRefresh.setRefreshing(false);
        });
    }

    boolean isKeyboardShowing = false;

    void onKeyboardVisibilityChanged(boolean opened) {
        if (!isSalesMan) {
            totalOrderValueCard.setVisibility(opened ? View.GONE : View.VISIBLE);
        }
    }

    private void keyboardListener() {
        // ContentView is the root view of the layout of this activity/fragment
        if (newOrderContainer != null)
            newOrderContainer.getViewTreeObserver().addOnGlobalLayoutListener(
                    () -> {
                        if (newOrderContainer != null) {
                            Rect r = new Rect();
                            newOrderContainer.getWindowVisibleDisplayFrame(r);
                            int screenHeight = newOrderContainer.getRootView().getHeight();
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
                        }
                    });
    }

    @OnClick({R.id.clear_text_ll, R.id.main_order_via_distributor_rl, R.id.main_order_via_product_rl, R.id.search_box_ll, R.id.actionbar_imgLogout, R.id.search_Firm_ll, R.id.cart, R.id.llSearchFilter})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.cart:
                NavHostFragment.findNavController(NewOrderFragment.this).navigate(R.id.nav_cart);
            case R.id.main_order_via_distributor_rl:
                isFirstTabSelected = true;
                break;
            case R.id.main_order_via_product_rl://ONS05735
                isFirstTabSelected = false;
                break;
            case R.id.search_box_ll:
                if (isSalesMan)
                    GoToPartyListingFragment(Constant.NEW_ORDER);
                else
                    GoToCommonListingFragment(select_store_ll, CODE_REQUEST_DISTRIBUTOR_FILTER, Constant.NEW_ORDER);
                break;
            case R.id.actionbar_imgLogout:
//                addFragment(CartFragment.newInstance(LicNo, FirmCode), true);
                GoToCartFragment();
                break;
            case R.id.clear_text_ll:
                if (!search_loc_et.getText().toString().isEmpty()) {
                    search_loc_et.getText().clear();
                    clear_text_ll.setVisibility(View.INVISIBLE);
                }
                break;
            case R.id.search_Firm_ll:
                GoToPartyListingFragment(Constant.FIRM);
                break;
            case R.id.llSearchFilter:
                showSearchFilterPopup();
                popupSortVendors.showAsDropDown(view, 0, 1);
                break;

        }
    }

    public void getCartItemList() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", LicNo);
            jsonObject.put("lFirmCode", FirmCode);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostCartItemList(String.valueOf(jsonObject)), Constant.CART, false);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    private void GoToCommonListingFragment(View view, int codeRequest, String from) {
        if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
            Bundle bundle = new Bundle();
            bundle.putString("withScheme", withScheme);
            bundle.putString(Constant.FROM, from);
            Navigation.findNavController(view).navigate(R.id.nav_common_listing, bundle);
        }
    }

    private void GoToPartyListingFragment(String FROM) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, FROM);
        bundle.putString("name", FirmName);
        bundle.putString("Code", FirmCode);
        bundle.putString("withScheme", withScheme);
        Navigation.findNavController(search_Firm_ll).navigate(R.id.navPartyLisingFragment, bundle);
    }

    private void GoToCartFragment() {
        CartFragment fragment = new CartFragment();
        fragment.setTargetFragment(this, Constant.CODE_REQUEST_CART);
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.PRODUCT);
        bundle.putString(ID, LicNo);
        bundle.putString(NAME, FirmCode);
        bundle.putString("PARTYCODE", partyCode);
        fragment.setArguments(bundle);
        addFragment(fragment, true);
    }

    @Override
    public void onResume() {
        super.onResume();
        if (commonRowAdapter != null)
            commonRowAdapter.notifyDataSetChanged();
        if (newOrderProductsAdapter != null)
            newOrderProductsAdapter.notifyDataSetChanged();
        if (isSalesMan) {
            header_switch.setVisibility(View.GONE);
            search_dis_tv.setHint(getResources().getString(R.string.serach_party));
        }
    }


    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        switch (requestCode) {
            case CODE_REQUEST_DISTRIBUTOR_FILTER:
                try {
                    if (dataSortDistributors != null && dataSortDistributors.size() > 0)
                        dataSortDistributors.clear();
                    JSONArray jsonArray1 = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.HelpField));
                    for (int i = 0; i < jsonArray1.length(); i++) {
                        dataSortDistributors.add(new SelectionModel(jsonArray1.getJSONObject(i).getString("Code"), jsonArray1.getJSONObject(i).getString("Code1"), "false"));
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
                String distributor_name = Objects.requireNonNull(data.getExtras()).containsKey("data") ? data.getStringExtra("data") : "";
                FirmCode = data.getExtras().containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
                LicNo = data.getExtras().containsKey("LicNo") ? data.getStringExtra("LicNo") : "";
                ShowStock = data.getExtras().containsKey("ShowStock") ? data.getStringExtra("ShowStock") : "";
                search_dis_tv.setText(distributor_name);
                search_dis_tv.setTextColor(getResources().getColor(R.color.white));
                search_box_ll.setBackgroundResource(R.color.gray93);
                if (productsList != null && productsList.size() > 0)
                    productsList.clear();
                PAGE_NUM = 1;
                SortByValue = SharedPrefUtils.getString(getActivity(), Constant.HELP_KEY);
                getProductList("", PAGE_NUM, true);
                IsFirst = true;

                break;
            case CODE_REQUEST_CART:
                FirmCode = Objects.requireNonNull(data.getExtras()).containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
                LicNo = data.getExtras().containsKey("LicNo") ? data.getStringExtra("LicNo") : "";
                if (productsList != null && productsList.size() > 0)
                    productsList.clear();
                PAGE_NUM = 1;
                SortByValue = SharedPrefUtils.getString(getActivity(), Constant.HELP_KEY);
                getProductList("", PAGE_NUM, true);
                IsFirst = true;
                break;

            case CODE_REQUEST_PARTY_FILTER:
                String partyName = data.getExtras().containsKey("name") ? data.getStringExtra("name") : "";
                partyCode = data.getExtras().containsKey("Code") ? data.getStringExtra("Code") : "";
                search_dis_tv.setText(partyName);
                header_switch.setVisibility(View.GONE);
                search_Firm_ll.setVisibility(View.VISIBLE);
                search_dis_tv.setHint(getResources().getString(R.string.serach_party));
                isSearched = true;
//                hitDataForSalesMan();
                break;
            case CODE_REQUEST_FIRM_FILTER:
                String FirmName = data.getExtras().containsKey("name") ? data.getStringExtra("name") : "";
                FirmCode = data.getExtras().containsKey("Code") ? data.getStringExtra("Code") : "";
                ShowStock = data.getExtras().containsKey("Stock") ? data.getStringExtra("Stock") : "";
                search_firm_tv.setText(FirmName);
                isSearched = true;
//                hitDataForSalesMan();
                break;
        }
    }

    private void getProductList(String searchCharacter, int page, boolean showLoader) {
        try {
            String acCode = SharedPrefUtils.getString(getActivity(), Constant.AC_CODE);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", LicNo);
            jsonObject.put("lFirmCode", FirmCode);
            jsonObject.put("lPageNo", String.valueOf(page));
            jsonObject.put("lSize", String.valueOf(pageCount));
            jsonObject.put("lSearchFieldValue", searchCharacter);
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lExcludeId", "-1");
            jsonObject.put("Wsch", withScheme.isEmpty() ? "0" : withScheme);
            if (brandNameSearchId != null && !brandNameSearchId.isEmpty())
                jsonObject.put("MCIDCOL", brandNameSearchId);
            jsonObject.put("AcCode", acCode);
            jsonObject.put("NewArrival", isNewArrival.isEmpty() ? "0" : isNewArrival);
            jsonObject.put("lSearchFieldName", searchFilterId);
            try {
                if (!selectedFilters.isEmpty()) {
                    JSONArray jsonArray = new JSONArray(selectedFilters);
                    jsonObject.put("filters", jsonArray);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("app_role", getLicDetails().getRole());
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostProductList(String.valueOf(jsonObject)), Constant.PRODUCT, showLoader);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.PRODUCT:
                    try {
                        if (jsonObject.has("Item")) {
                            setProductListData(jsonObject.getJSONArray("Item"), action);
                        }
                        if (!isSearched && !isSalesMan)
                            getCartItemList();

                        isOrderExist = ReckonUtils.getJsonCheckedBoolean(jsonObject, "OrderExist", false);
                        recentProductsCV.setVisibility(isOrderExist ? View.VISIBLE : View.GONE);
                    } catch (Exception e) {
                        e.printStackTrace();
                        if (productsList.size() == 0) {
                            pullToRefresh.setVisibility(View.GONE);
                            noRecordTV.setVisibility(View.VISIBLE);
                        } else {
                            pullToRefresh.setVisibility(View.VISIBLE);
                            noRecordTV.setVisibility(View.GONE);
                        }
                    }
                    break;
                case Constant.CART:
                    JSONArray jsonArray = jsonObject.has("DraftOrder") ? jsonObject.getJSONArray("DraftOrder") : new JSONArray();
                    clearLists();
                    Objects.requireNonNull(cartProductList).addAll(getParsedProductList(jsonArray, action));
                    for (int i = 0; i < jsonArray.length(); i++) {
                        productAmountsList.add(Float.parseFloat(cartProductList.get(i).getAmt()));
                    }
                    TotalPrice_tv.setText(getLicDetails().getCurrency() +ReckonUtils.roundTwoDecimals(calculatePrice(productAmountsList)));
                    if (!isSalesMan && !isKeyboardShowing) {
                        totalOrderValueCard.setVisibility(Double.parseDouble(calculatePrice(productAmountsList)) == 0.0 ? View.GONE : View.VISIBLE);
                    }
                    if (flag) {
                        isRefreshed = false;
                        ListSize(String.valueOf(productsList.size()), false, true);
                    } else ListSize(String.valueOf(productsList.size()), true, true);
                    break;
            }
        }
    }

    public void ListSize(String size, boolean check, boolean b) {
        flag = b;
        isRefreshed = check;
        //  TotalItem_tv.setText(String.valueOf("ITEM" + " (" + size + ")"));
    }

    private void clearLists() {
        if (cartProductList.size() > 0)
            cartProductList.clear();
        if (productAmountsList != null && productAmountsList.size() > 0)
            productAmountsList.clear();
    }

    private void setProductListData(JSONArray jsonArray, String action) {
        try {
            if (isSearched && !productsList.isEmpty()) {
                isSearched = false;
                productsList.clear();
                productAmountsList.clear();
            }
            Objects.requireNonNull(productsList).addAll(getParsedProductList(jsonArray, action));
            setProductListAdapter();
            for (int i = 0; i < jsonArray.length(); i++) {
                productAmountsList.add(Float.parseFloat(productsList.get(i).getAmt()));
            }
          /*  if (IsFirst) {
                IsFirst = false;
                tvCount.setText(String.valueOf(SharedPrefUtils.getString(getActivity(), Constant.HELP_Name) + " (" + productsList.size() + ")"));
                search_loc_et.getText().clear();
            }*/
            //     LocalStorage.getInstance(getActivity()).setCart(calculatePrice(productAmountsList));
//            TotalPrice_tv.setText(getLicDetails().getCurrency() + calculatePrice(productAmountsList));
//            totalOrderValueCard.setVisibility(Double.parseDouble(calculatePrice(productAmountsList)) == 0.0 ? View.GONE : View.VISIBLE);
            if (productsList.isEmpty()) {
                pullToRefresh.setVisibility(View.GONE);
                noRecordTV.setVisibility(View.VISIBLE);
            } else {
                pullToRefresh.setVisibility(View.VISIBLE);
                noRecordTV.setVisibility(View.GONE);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void unUsedData() {
        try {
            tvCount.setSelected(true);
            JSONArray jsonArray1 = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.HelpField));
            for (int i = 0; i < jsonArray1.length(); i++) {
                dataSortDistributors.add(new SelectionModel(jsonArray1.getJSONObject(i).getString("Code"), jsonArray1.getJSONObject(i).getString("Code1"), "false"));
            }
            for (int j = 0; j < dataSortDistributors.size(); j++) {
                if (SharedPrefUtils.getString(getActivity(), Constant.ItemHelpIndex).equalsIgnoreCase(dataSortDistributors.get(j).getItemId())) {
                    SharedPrefUtils.setString(getActivity(), Constant.HELP_KEY, dataSortDistributors.get(j).getItemId());
                    SharedPrefUtils.setString(getActivity(), Constant.HELP_Name, dataSortDistributors.get(j).getName());
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        try {
            JSONArray jsonArray = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.SearchType));
            for (int i = 0; i < jsonArray.length(); i++) {
                data.add(new SelectionModel(jsonArray.getJSONObject(i).getString("Code"), jsonArray.getJSONObject(i).getString("Code1"), "false"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        selectedSortVendors = new SelectionModel(1, dataSortDistributors.get(0).getName());
    }

    @OnClick(R.id.fragmentMyVendor_frmSortVendor)
    public void onViewClicked(View view) {
        if (!search_dis_tv.getText().toString().equalsIgnoreCase("") || isSalesMan) {
            imgSortVendors.setImageResource(R.drawable.ic_select_up);
            createPopupSortVendors();
            popupSortVendors.showAsDropDown(view, 0, 1);
        }

    }

    private void createPopupSortVendors() {
        if (popupSortVendors == null) {
            popupSortVendors = new SelectSinglePopup(getActivity(), dataSortDistributors, false);
            popupSortVendors.setOnItemListener(position -> {
                if (position < dataSortDistributors.size()) {
                    selectedSortVendors = dataSortDistributors.get(position);
//                    tvCount.setText((position != 0 ? selectedSortVendors.getName() : dataSortDistributors.get(0).getName()) + " (" + productsList.size() + ")");//data.size()
                    tvCount.setText(String.valueOf(dataSortDistributors.get(position).getName() + " (" + productsList.size() + ")"));//data.size()
                    SortByValue = String.valueOf(dataSortDistributors.get(position).getItemId());
                    PAGE_NUM = 1;
                    isSearched = true;
                    getProductList("", PAGE_NUM, true);
                    search_loc_et.getText().clear();
                    search_loc_et.setHint("Search By " + dataSortDistributors.get(position).getName());
                }
            });
            popupSortVendors.setOnDismissListener(() -> imgSortVendors.setImageResource(R.drawable.ic_select_down));
        }
    }

    private void showSearchFilterPopup() {
        if (popupSortVendors == null) {
            popupSortVendors = new SelectSinglePopup(getActivity(), searchFilterListData, false);
            popupSortVendors.setOnItemListener(position -> {
                if (position < searchFilterListData.size()) {
                    searchFilterId = String.valueOf(searchFilterListData.get(position).getItemId());
                    PAGE_NUM = 1;
                    isSearched = true;
                    getProductList("", PAGE_NUM, true);
                    search_loc_et.getText().clear();
                    search_loc_et.setHint("Search By " + searchFilterListData.get(position).getName());
                }
            });
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        clearData();
    }

    private void clearData() {
        if (!isSalesMan && getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
/*            LicDetailObjectModel model = getLicDetails();
            model.setFirmcode("");
            model.setFirmName("");
            model.setFirmAdd("");
            localStorage.setLicDetails(gson.toJson(model));
            SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, "");*/
        }
    }
}
