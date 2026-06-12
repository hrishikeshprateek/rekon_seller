package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_DISTRIBUTOR_FILTER;

import android.annotation.SuppressLint;
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
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
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
import com.reckon.reckonorders.Adapter.RecentOrderedProductsAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.Debouncer;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import butterknife.Unbinder;

public class RecentOrderedProductsFragment extends BaseFragment implements RetrofitCallBackListener {
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
    @BindView(R.id.select_store_ll)
    LinearLayout select_store_ll;

    @BindView(R.id.search_dis_tv)
    TextView search_dis_tv;

    @BindView(R.id.search_loc_et)
    public EditText search_loc_et;

    @BindView(R.id.scroll_view)
    NestedScrollView scroll_view;

    @BindView(R.id.clear_text_ll)
    LinearLayout clear_text_ll;

    @BindView(R.id.tvTotalAmountValue)
    TextView TotalPrice_tv;

    @BindView(R.id.tvTotalItemValue)
    TextView tvTotalItemValue;


    @BindView(R.id.totalOrderValueCard)
    CardView totalOrderValueCard;

    @BindView(R.id.pullToRefresh)
    SwipeRefreshLayout pullToRefresh;

    @BindView(R.id.actionbar_imgSearch)
    ImageView dropDownImg;

    @BindView(R.id.clearIv)
    ImageView clearIv;

    @BindView(R.id.ll_apply_filter)
    LinearLayout llApplyFilter;

    @BindView(R.id.ic_filter)
    ImageView icFilter;

    @BindView(R.id.imgView)
    ImageView imgView;

    @BindView(R.id.ll_dot)
    LinearLayout filterDot;


    private Bundle bundle;
    private final ArrayList<ProductModel> cartProductList = new ArrayList<>();
    private final ArrayList<ProductModel> productsList = new ArrayList<>();
    public ArrayList<Float> productAmountsList = new ArrayList<>();
    public RecentOrderedProductsAdapter newOrderProductsAdapter;
    private LinearLayoutManager mlayoutManager;
    private final Gson gson = new Gson();

    public String FirmCode, LicNo = "", searchedText = "", partyCode = "", partyName = "";
    private String distributorName = "", selectedFilters = "", from = "";
    public boolean isSearched = false, isRefreshed = false, flag = true;
    private String ID = "id";
    private String NAME = "name", FirmName = "";
    private boolean acceptClick = true, isSalesMan, isOpenedStoreFilter = false;
    private int PAGE_NUM = 1, keypadHeight = 0;
    private Unbinder unbinder;
    private int totalListCount = 0;
    private int offset = 0;
    final Debouncer debouncer = new Debouncer();


    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_recent_ordered_products, container, false);
        retrofitCallBackListener = this;
        unbinder = ButterKnife.bind(this, view);
        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        FirmCode = isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : getLicDetails().getFirmcode();
        FirmName = !isSalesMan ? getStoreDetails() != null ? getStoreDetails().getName() : "" : "";
        productShimmer.showShimmer(true);
        setupBackButton(view);
        setTitle(view, getString(R.string.recent_ordered_list).toUpperCase());
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
            String name = bundle.containsKey("data") ? bundle.getString("data") : "";
            if (name != null) {
                distributorName = name;
            }
            search_dis_tv.setText(distributorName);
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
                select_store_ll.setVisibility(View.VISIBLE);
                search_dis_tv.setHint(getResources().getString(R.string.serach_party));
                isSearched = true;
                PAGE_NUM = 1;
                if (!from.equalsIgnoreCase(Constant.PRODUCT_FILTER)) {
                    SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, partyCode);
                }
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
                        if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE)) {
                            FirmCode = getLicDetails().getFirmcode();
                            FirmName = getStoreDetails().getName();
                        }
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
                distributorName = FirmName;
                search_dis_tv.setText(distributorName);
                clearIv.setOnClickListener(v -> {
                    clearStoreFilter();
                });
                isOpenedStoreFilter = false;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
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
            ((NewMainActivity) requireActivity()).setUpTitle(RecentOrderedProductsFragment.this, getString(R.string.recent_ordered_list));
            keyboardListener();
            pullToRefreshExecution();
            totalLayout.setCardBackgroundColor(getButtonColor());
            if (!isSalesMan) {
                getCartItemList();
//                totalOrderValueCard.setVisibility(LocalStorage.getInstance(getActivity()).getCart() == null || Double.parseDouble(LocalStorage.getInstance(getActivity()).getCart()) == 0.0 ? View.GONE : View.VISIBLE);
            }
            if (getLicDetails() != null && getLicDetails().getFirmcode().isEmpty()) {
                select_store_ll.setVisibility(View.VISIBLE);
            }
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
                isOpenedStoreFilter = true;
                goToProductFilterScreen(view);
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void goToProductFilterScreen(View view) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.RECENT_ORDERED_PRODUCTS);
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
                        if (totalListCount > productsList.size()) {
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
                    debouncer.debounce(Void.class, () -> getProductList(s.toString(), PAGE_NUM, false), 500, TimeUnit.MILLISECONDS);
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
        mlayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
        rvProductListing.setLayoutManager(mlayoutManager);
        newOrderProductsAdapter = new RecentOrderedProductsAdapter(RecentOrderedProductsFragment.this, productsList, Constant.NEW_ORDER);//TODO: New Adapter
        rvProductListing.setAdapter(newOrderProductsAdapter);
        productShimmer.showShimmer(false);
        rvProductListing.setVisibility(View.VISIBLE);
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
            totalOrderValueCard.setVisibility(opened ? View.GONE : View.GONE);
        }
    }

    private void keyboardListener() {
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

    @OnClick({R.id.clear_text_ll, R.id.search_box_ll, R.id.actionbar_imgLogout, R.id.cart})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.cart:
                NavHostFragment.findNavController(RecentOrderedProductsFragment.this).navigate(R.id.nav_cart);
                break;
            case R.id.search_box_ll:
                isOpenedStoreFilter = true;
                GoToCommonListingFragment(select_store_ll, CODE_REQUEST_DISTRIBUTOR_FILTER, Constant.RECENT_ORDERED_PRODUCTS);
                break;
            case R.id.actionbar_imgLogout:
                GoToCartFragment();
                break;
            case R.id.clear_text_ll:
                clearSearchText();
                break;
        }
    }

    public void clearSearchText() {
        if (!search_loc_et.getText().toString().isEmpty()) {
            search_loc_et.getText().clear();
            clear_text_ll.setVisibility(View.INVISIBLE);
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
            bundle.putString(Constant.FROM, from);
            Navigation.findNavController(view).navigate(R.id.nav_common_listing, bundle);
        }
    }

    private void GoToCartFragment() {
        CartFragment fragment = new CartFragment();
        fragment.setTargetFragment(this, Constant.CODE_REQUEST_CART);
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.TOP_PRODUCT);
        bundle.putString(ID, LicNo);
        bundle.putString(NAME, FirmCode);
        bundle.putString("PARTYCODE", partyCode);
        fragment.setArguments(bundle);
        addFragment(fragment, true);
    }

    @Override
    public void onResume() {
        super.onResume();
        if (newOrderProductsAdapter != null)
            newOrderProductsAdapter.notifyDataSetChanged();
        if (isSalesMan) {
            search_dis_tv.setHint(getResources().getString(R.string.serach_party));
        }
    }

    public void getProductList(String searchCharacter, int page, boolean showLoader) {
        try {
            String acCode = SharedPrefUtils.getString(getActivity(), Constant.AC_CODE);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", LicNo);
            jsonObject.put("lFirmCode", FirmCode);
            jsonObject.put("lPageNo", String.valueOf(page));
            jsonObject.put("lSize", String.valueOf(30));
            jsonObject.put("lSearchFieldValue", searchCharacter);
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lExcludeId", "-1");
            jsonObject.put("Wsch", "0");
            jsonObject.put("AcCode", acCode);
            jsonObject.put("NewArrival", "0");
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
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostGetTopItemProductList(String.valueOf(jsonObject)), Constant.TOP_PRODUCT, showLoader);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.TOP_PRODUCT:
                    try {
                        if (jsonObject.has("Item")) {
                            setProductListData(jsonObject.getJSONArray("Item"), action);
                        }
                        if (!isSearched && !isSalesMan)//
                            getCartItemList();
                        String orderAmt = jsonObject.has("OAmt") ? jsonObject.getString("OAmt") : "";
//                        TotalPrice_tv.setText("₹" + orderAmt);
                        tvTotalItemValue.setText(jsonObject.has("ICount") ? jsonObject.getString("ICount") : "0");
                        totalOrderValueCard.setVisibility(orderAmt.isEmpty() ? View.GONE : View.GONE);
                        totalListCount = Integer.parseInt(jsonObject.has("ICount") ? jsonObject.getString("ICount") : "0");

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
                  /*  for (int i = 0; i < jsonArray.length(); i++) {
                        productAmountsList.add(Float.parseFloat(cartProductList.get(i).getAmt()));
                    }*/
//                    TotalPrice_tv.setText(getLicDetails().getCurrency() + calculatePrice(productAmountsList));
                    if (!isSalesMan && !isKeyboardShowing) {
//                        totalOrderValueCard.setVisibility(Double.parseDouble(calculatePrice(productAmountsList)) == 0.0 ? View.GONE : View.VISIBLE);
                    }
                    if (flag) {
                        isRefreshed = false;
                        ListSize(String.valueOf(productsList.size()), false, true);
                    } else ListSize(String.valueOf(productsList.size()), true, true);
                    break;
            }
        }
    }


    public void updateCartValue(String value) {
        TotalPrice_tv.setText(getLicDetails().getCurrency() + value);
    }

    public void ListSize(String size, boolean check, boolean b) {
        flag = b;
        isRefreshed = check;
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
            offset = offset + 30;
            Objects.requireNonNull(productsList).addAll(getParsedProductList(jsonArray, action));
          /*  for (int i = 0; i < jsonArray.length(); i++) {
                productAmountsList.add(Float.parseFloat(productsList.get(i).getAmt()));
            }*/
            setProductListAdapter();
            if (productsList.size() == 0) {
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

    @Override
    public void onDestroy() {
        super.onDestroy();
        clearData();
    }


    private void clearData() {
        if (!isOpenedStoreFilter && getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
            LicDetailObjectModel model = getLicDetails();
            model.setFirmcode("");
            model.setFirmName("");
            model.setFirmAdd("");
            localStorage.setLicDetails(gson.toJson(model));
            SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, "");
        }
    }
}
