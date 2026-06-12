package com.reckon.reckonorders.Fragment.Home;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.cardview.widget.CardView;
import androidx.core.content.res.ResourcesCompat;
import androidx.navigation.Navigation;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import androidx.viewpager.widget.ViewPager;

import com.bumptech.glide.Glide;
import com.facebook.shimmer.ShimmerFrameLayout;
import com.google.gson.Gson;
import com.reckon.reckonorders.Adapter.BannerPagerAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.NewArrivalAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BannerListItem;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BrandListItem;
import com.reckon.reckonorders.NewDesign.NewModals.Home.MenuListItem;
import com.reckon.reckonorders.NewDesign.NewModals.Home.TestimonialsListItem;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.StorePartyPickerDialog;
import com.reckon.reckonorders.Others.view.AutoScrollViewPager;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

import butterknife.BindView;
import butterknife.ButterKnife;

public class HomeFragment extends BaseFragment implements RetrofitCallBackListener {

    @BindView(R.id.receipt_entry)
    TextView tvReceiptEntry;
    @BindView(R.id.receipt_voucher)
    TextView tvReceiptVoucher;
    @BindView(R.id.credit_note)
    TextView tvCreditNote;
    @BindView(R.id.orderHistoryTv)
    TextView orderHistoryTv;
    @BindView(R.id.orderStatusLl)
    LinearLayout orderStatusLl;
    @BindView(R.id.testimonialTv)
    TextView testimonialTv;
    @BindView(R.id.testimonialCardHolder)
    CardView testimonialCardHolder;
    @BindView(R.id.brandTitleTv)
    TextView brandTitleTv;
    @BindView(R.id.brandCardHolder)
    CardView brandCardHolder;
    @BindView(R.id.newArrivalTitleTv)
    TextView newArrivalTitleTv;
    @BindView(R.id.newArrivalCardHolder)
    CardView newArrivalCardHolder;
    @BindView(R.id.tvTotalOrder)
    TextView tvTotalOrder;
    @BindView(R.id.menuCardHolder)
    CardView menuCardHolder;
    @BindView(R.id.menuTitle)
    TextView menuTitle;
    @BindView(R.id.tvInvoiced)
    TextView tvInvoiced;
    @BindView(R.id.imgOrderStatus)
    ImageView imgOrderStatus;
    @BindView(R.id.tvBounced)
    TextView tvBounced;
    @BindView(R.id.newArrivalViewLL)
    CardView newArrivalViewLL;
    @BindView(R.id.mainLayout)
    LinearLayout mainLayout;
    @BindView(R.id.brandsViewCard)
    CardView brandsViewCard;
    @BindView(R.id.viewPagerCountDots)
    LinearLayout viewPagerCountDots;
    @BindView(R.id.orderHistoryCard)
    CardView orderHistoryCard;
    @BindView(R.id.bannerShimmer)
    ShimmerFrameLayout mShimmerViewContainer;
    @BindView(R.id.menuShimmer)
    ShimmerFrameLayout menuShimmer;
    @BindView(R.id.tvOrderDate)
    TextView tvOrderDate;
    @BindView(R.id.tvOrderAmount)
    TextView tvOrderAmount;
    @BindView(R.id.tvOrderId)
    TextView tvOrderId;
    @BindView(R.id.pager)
    AutoScrollViewPager pager;
    @BindView(R.id.bannerLl)
    LinearLayout bannerLl;
    @BindView(R.id.totalBounceAmount)
    TextView totalBounceAmount;
    @BindView(R.id.totalBounceCount)
    TextView totalBounceCount;
    @BindView(R.id.totalInvoiceAmount)
    TextView totalInvoiceAmount;
    @BindView(R.id.totalInvoiceCount)
    TextView totalInvoiceCount;
    @BindView(R.id.totalOrderAmount)
    TextView totalOrderAmount;
    @BindView(R.id.totalOrderCount)
    TextView totalOrderCount;
    @BindView(R.id.new_arrival_recycler)
    RecyclerView New_Arrival;
    @BindView(R.id.Brands_recycler)
    RecyclerView Brands_recycler;
    @BindView(R.id.testimonial_recycler)
    RecyclerView Testimonial_recycler;
    @BindView(R.id.menu_recycler)
    RecyclerView menuRecycler;
    @BindView(R.id.orderShipmentStatus)
    TextView orderShipmentStatus;
    @BindView(R.id.orderId)
    TextView orderId;
    @BindView(R.id.orderDate)
    TextView orderDate;
    @BindView(R.id.order_status_card)
    CardView OrderStatusCard;
    @BindView(R.id.orderAmount)
    TextView orderAmount;
    @BindView(R.id.llOrderHistory)
    LinearLayout llOrderHistory;
    @BindView(R.id.roleGroup)
    RadioGroup roleGroup;
    @BindView(R.id.rb_retailer)
    RadioButton rbRetailer;
    @BindView(R.id.rb_salesman)
    RadioButton rbSalesman;
    @BindView(R.id.pullToRefresh)
    SwipeRefreshLayout pullToRefresh;
    @BindView(R.id.order_status_title_txt)
    TextView orderStatusTitle;

    Bundle bundle;
    private ArrayList<SelectionModel> bannerData = new ArrayList<>();
    private int dotsCount;
    private ImageView[] dots;
    private BannerPagerAdapter bannerPagerAdapter;
    private String role = "", FirmName = "", FirmCode = "", ShowStock = "";
    private RetrofitCallBackListener retrofitCallBackListener;
    private boolean isUploadPrescription = false;
    private static final String ID = "id";
    private static final String NAME = "name";
    private String LicNo;
    private ArrayList<ProductModel> arrivalListItems = new ArrayList<>();
    private ArrayList<BrandListItem> brandListItems = new ArrayList<>();
    private ArrayList<TestimonialsListItem> testimonialList = new ArrayList<>();
    private ArrayList<MenuListItem> menus = new ArrayList<>();
    private NewArrivalAdapter newArrivalAdapter;
    private String bgColor;
    private boolean isRetailer = true;
    boolean isSalesMan = false;
    private View view = null;

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        //setHeaderColor("#ffffff","#303F9F",true,"#000000");
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        if (view == null) {
            view = inflater.inflate(R.layout.fragment_home1, container, false);
            ButterKnife.bind(this, view);
            retrofitCallBackListener = this;
        }
        return view;
    }

    @Override
    public void onViewCreated(View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        initialize(view);
    }

    private void initialize(View view) {
        setUpTestUi();
        if (getArguments() != null)
            bundle = getArguments();
        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        brandsViewCard.setOnClickListener(v -> NavHostFragment.findNavController(HomeFragment.this).navigate(R.id.nav_brands));
        newArrivalViewLL.setOnClickListener(v -> {
            if (isSalesMan) {
                Bundle bundle = new Bundle();
                bundle.putString("isNewArrival", "1");
                orderEntryClickHandling(v, Constant.NEW_ARRIVAL, bundle);
            } else {
                NavHostFragment.findNavController(HomeFragment.this).navigate(R.id.nav_new_arrival);
            }
        });
        mShimmerViewContainer.setVisibility(View.VISIBLE);
        menuShimmer.setVisibility(View.VISIBLE);
        OnBackPressedCallback callback = new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                getActivity().finish();
            }
        };
        requireActivity().getOnBackPressedDispatcher().addCallback(getViewLifecycleOwner(), callback);
        dismissLoading();
        isUploadPrescription = !SharedPrefUtils.getString(getActivity(), Constant.ISUPLOADPRESCRIPTION).equalsIgnoreCase("false");
        pager.startAutoScroll();
        pager.setInterval(5000);
        pager.setCycle(true);
        pager.setStopScrollWhenTouch(true);
        pager.setDrawingCacheEnabled(false);
        Animation animation = AnimationUtils.loadAnimation(getActivity(), android.R.anim.fade_out);
        animation.setDuration(500);
        pager.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
            }

            @Override
            public void onPageSelected(int position) {
                if (getContext() != null) {
                    for (int i = 0; i < dotsCount; i++) {
                        if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                            dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_peach_dot, null));
                        } else {
                            dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_dot, null));
                        }
                    }
                    if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                        dots[position].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem__red_dot, null));
                    } else {
                        dots[position].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem_dot, null));
                    }
                }
            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });
        manageRoleChange(view);
        if (getLicDetails().getRole().equalsIgnoreCase("SalesMan") && getSelectedStoreDetailsFromPicker() == null) {
            ArrayList<StoreDetailObjectModel> storeListData = getStoreListData() != null ? getStoreListData() : new ArrayList<>();
            if (storeListData != null && !storeListData.isEmpty() ) {
                for (StoreDetailObjectModel storeDetailObjectModel : storeListData) {
                    if(storeDetailObjectModel.isPrimary()){
                        localStorage.setSelectedStoreInfo(gson.toJson(storeDetailObjectModel));
                    }
                }
                new Handler().postDelayed(() -> NewMainActivity.binding.appBarNewMain.iconContainer.setOnClickListener(v -> {
                    NewMainActivity.binding.appBarNewMain.iconText.setText(getSelectedStoreDetailsFromPicker().getFirstChar());
                    String arrOfStr[] = getSelectedStoreDetailsFromPicker().getName().split(" ");
                    NewMainActivity.binding.appBarNewMain.tvWelcome.setText(arrOfStr.length > 1 ? (arrOfStr[0] + " " + arrOfStr[1]) : arrOfStr[0]);
                    if (NewMainActivity.binding.appBarNewMain.tvWelcome.getVisibility() == View.GONE)
                        NewMainActivity.binding.appBarNewMain.tvWelcome.setVisibility(View.VISIBLE);
                    if (NewMainActivity.binding.appBarNewMain.iconContainer.getVisibility() == View.GONE)
                        NewMainActivity.binding.appBarNewMain.iconContainer.setVisibility(View.GONE);
                }), 2000);

            } else {
//                openStoreDialog();
            }
        }
        pullToRefresh.setOnRefreshListener(() -> {
            getDashBoardData();
            pullToRefresh.setRefreshing(false);
        });
        new Handler().postDelayed(() -> NewMainActivity.binding.appBarNewMain.iconContainer.setOnClickListener(v -> {
            openStoreDialog();
        }), 10);
        getDashBoardData();
//        if(Constant.APP_VERSION!=null && !Constant.APP_VERSION.equalsIgnoreCase("App_Version") && !Constant.APP_VERSION.equalsIgnoreCase(String.valueOf(BuildConfig.VERSION_CODE)))
//            updateAppVersionApi();
    }

    private void updateAppVersionApi() {
        Dialog dialog = new Dialog(getActivity(), android.R.style.Theme_Light);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCanceledOnTouchOutside(false);
        dialog.setCancelable(false);
        dialog.setContentView(R.layout.update_dialog_layout);
        Button updateBtn = dialog.findViewById(R.id.updateBtn);
        updateBtn.setOnClickListener(v -> ReckonUtils.redirectStore(requireActivity(), ReckonUtils.PLAY_STORE_APP_URL));
        dialog.show();
    }

    private void setUpTestUi() {
        tvReceiptEntry.setOnClickListener(v -> NavHostFragment.findNavController(HomeFragment.this).navigate(R.id.nav_receipt_entry));
        tvReceiptVoucher.setOnClickListener(v -> NavHostFragment.findNavController(HomeFragment.this).navigate(R.id.nav_receipt));
        tvCreditNote.setOnClickListener(v -> NavHostFragment.findNavController(HomeFragment.this).navigate(R.id.nav_credit_voucher));
    }

    private void manageRoleChange(View view) {
        if (SharedPrefUtils.getString(getActivity(), Constant.ROLE).equalsIgnoreCase(Constant.RETAILER)) {
            rbRetailer.setSelected(true);
            rbRetailer.setChecked(true);
            rbSalesman.setSelected(false);
            rbSalesman.setChecked(false);
        } else {
            rbRetailer.setSelected(false);
            rbRetailer.setChecked(false);
            rbSalesman.setSelected(true);
            rbSalesman.setChecked(true);
        }
        roleGroup.setOnCheckedChangeListener((group, checkedId) -> {
            RadioButton radioButton = view.findViewById(checkedId);
            SharedPrefUtils.setString(getActivity(), Constant.ROLE, radioButton.getId() == R.id.rb_retailer ? "Retailer" : "SalesMan");
            ReckonUtils.logoutAndRestartApp(getActivity());
        });
    }

    public void getDashBoardData() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("app_role", getLicDetails().getRole());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lFirmCode", isSalesMan ? getSelectedStoreDetailsFromPicker()!=null?getSelectedStoreDetailsFromPicker().getFirmCode(): getLicDetails().getFirmcode(): getLicDetails().getFirmcode());
            jsonObject.put("role_type", getLicDetails().getRetailerType());
            jsonObject.put("device_id", SharedPrefUtils.getString(getActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("lRole", getLicDetails().getRole());
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getDashBoard(String.valueOf(jsonObject)), Constant.DASHBOARD, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void getDistributorData() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lCityCode", "");
            jsonObject.put("lMapType", "MAP");
            jsonObject.put("lStatus", "1");
            jsonObject.put("lLock", "0");
            jsonObject.put("lBussinessType", "");
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostDistributorList(String.valueOf(jsonObject)), Constant.DISTRIBUTOR, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setMenuItemAdapter() {
        GridLayoutManager gridLayoutManager = new GridLayoutManager(getActivity(), 3);
        newArrivalAdapter = new NewArrivalAdapter(this, menus, brandListItems, testimonialList, arrivalListItems, bgColor, getString(R.string.menu));
        menuRecycler.setLayoutManager(gridLayoutManager);
        menuRecycler.setAdapter(newArrivalAdapter);
    }

    private void setTestimonialAdapter() {
        newArrivalAdapter = new NewArrivalAdapter(this, menus, brandListItems, testimonialList, arrivalListItems, bgColor, getString(R.string.testimonial));
        Testimonial_recycler.setAdapter(newArrivalAdapter);
    }

    private void setBrandsAdapter() {
        newArrivalAdapter = new NewArrivalAdapter(this, menus, brandListItems, testimonialList, arrivalListItems, bgColor, getString(R.string.Brands));
        Brands_recycler.setAdapter(newArrivalAdapter);
    }

    private void setNewArrivalAdapter() {
        newArrivalAdapter = new NewArrivalAdapter(this, menus, brandListItems, testimonialList, arrivalListItems, bgColor, getString(R.string.new_arrival));
        New_Arrival.setAdapter(newArrivalAdapter);
    }

    private void openStoreDialog() {
        StorePartyPickerDialog dialog = new StorePartyPickerDialog(requireActivity(), requireActivity().getString(R.string.select_your_firm), Constant.FIRM, Constant.HOME);
        dialog.setOnItemClickListenerDialog(data -> {
            getDashBoardData();
        });
        dialog.show();
    }
    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            try {
                JSONObject jsonObject = new JSONObject(result);
                if (action.equalsIgnoreCase(Constant.DISTRIBUTOR)) {
                    if (jsonObject.has("Distributor")) {
                        JSONArray jsonArray2 = jsonObject.getJSONArray("Distributor");
                        setDistributorListingAdapter(jsonArray2);
                    }
                } else {
                    if (jsonObject.getBoolean("status")) {
                        String color = ReckonUtils.getJsonCheckedString(jsonObject, "bg_color", "");
                        if (color.contains("#")) {
                            mainLayout.setBackgroundColor(Color.parseColor(color));
                        }
                        JSONObject orderStatusObject = jsonObject.getJSONObject("order_status");
                        setUpOrderCard(orderStatusObject);
                        JSONObject brandsObject = jsonObject.getJSONObject("brands");
                        JSONObject newArrivalObject = jsonObject.getJSONObject("new_arrival");
                        JSONObject testimonials = jsonObject.getJSONObject("testimonials");
                        prepareNewArrivalData(newArrivalObject, action);
                        setNewArrivalAdapter();
                        JSONObject menuObject = jsonObject.getJSONObject("Menu");
                        JSONObject orderHistoryObject = jsonObject.getJSONObject("order_history");
                        JSONArray bannerArray = jsonObject.getJSONArray("banner_list");
                        JSONArray Tags = jsonObject.getJSONArray("Tags");
                        prepareTagList(Tags);
                        prepareBannerData(bannerArray);
                        setUpOrderHistoryCard(orderHistoryObject);
                        prepareBrandData(brandsObject);
                        prepareMenuData(menuObject);
                        prepareTestimonialData(testimonials);
                        setMenuItemAdapter();
                        setBrandsAdapter();
                        setTestimonialAdapter();
                        if (jsonObject.has("TenentDetail")) {
                            setTenantDetailSettings(jsonObject.getJSONObject("TenentDetail"));
                        }
                    }
                    if (!isSalesMan && getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE)) {
                        getDistributorData();
                    }
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }


    }

    private void setTenantDetailSettings(JSONObject tenantDetailSettings) {
        SharedPrefUtils.setShowIncreaseDecreaseBtn(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_increase_decrease_button", false));
        SharedPrefUtils.setShowDiscountPcs(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_disc_pcs", false));
        SharedPrefUtils.setShowFreeQty(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_free_qty", false));
        SharedPrefUtils.setShowStock(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_stock", false));
        SharedPrefUtils.setShowRate(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_rate", false));
        SharedPrefUtils.setShowDiscountPer(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_disc_per", false));
        SharedPrefUtils.setShowMRP(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_mrp", false));
        SharedPrefUtils.setShowScheme(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_scheme", false));
        SharedPrefUtils.setShowEnablePriceEdt(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "enable_price", false));
        SharedPrefUtils.setShowItemRemark(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_item_remark", false));
//        SharedPrefUtils.setShowProductDiscount(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_product_desc", false));
        SharedPrefUtils.setShowManualScheme(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_manual_scheme", false));
        SharedPrefUtils.setShowAddDetailsBottomSheet(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_add_details_bottom_sheet", false));
        SharedPrefUtils.setShowAddDiscountPer(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_additional_discount", false));
        SharedPrefUtils.setShowItemRefNo(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_item_refnumber", false));
        SharedPrefUtils.setSearchFilterList(requireActivity(), ReckonUtils.getJsonCheckedString(tenantDetailSettings, "search_field_list", ""));
        SharedPrefUtils.setShowSaltComp(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_item_composition", false));
        SharedPrefUtils.setShowICompany(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_item_mfgcomp", false));
        SharedPrefUtils.setShowLocation(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_location", false));
        SharedPrefUtils.setShowItemCategory(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_item_category", false));
        SharedPrefUtils.setShowItemCategory(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "show_item_category", false));
        SharedPrefUtils.setEnableScreenshot(requireActivity(), ReckonUtils.getJsonCheckedBoolean(tenantDetailSettings, "enable_screenshot", false));

        if(!SharedPrefUtils.getEnableScreenshot(requireActivity())){
            requireActivity().getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
        }

//        "search_field_list" : "[{\"field_name\":\"Name\",\"field_value\":\"I_Name\"}]",
        //{"field_name":"Name","field_value":"I_Name"},{"field_name":"PartNo","field_value":"I_Ref_Number"}
        //{"field_name":"Name","field_value":"I_Name"},{"field_name":"PartNo","field_value":"I_Ref_Number"}

    }

    private void prepareTagList(JSONArray tags) {
        ArrayList<String> options = new ArrayList<>();
        for (int i = 0; i < tags.length(); i++) {
            try {
                String tag = tags.getString(i);
                options.add(tag);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        Gson gson = new Gson();
        LocalStorage.getInstance(getActivity()).setTags(gson.toJson(options));

    }

    private void prepareBannerData(JSONArray bannerArray) {
        mShimmerViewContainer.setVisibility(View.GONE);
        ArrayList<BannerListItem> bannerList = new ArrayList<>();
        for (int i = 0; i < bannerArray.length(); i++) {
            try {
                JSONObject bannerItem = bannerArray.getJSONObject(i);
                BannerListItem bannerListItem = new BannerListItem();
                bannerListItem.setId(Integer.parseInt(ReckonUtils.getJsonCheckedString(bannerItem, "id", "")));//getUserImageBaseUrl() +
                String image = ReckonUtils.getJsonCheckedString(bannerItem, "image_url", "");
                bannerListItem.setImageUrl(image.contains("https") || image.contains("http") ? image : getUserImageBaseUrl() + image);
                bannerList.add(bannerListItem);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        if (bannerList.size() > 0) {
            bannerPagerAdapter = new BannerPagerAdapter(HomeFragment.this, bannerList, getActivity(), pager);
            pager.setAdapter(bannerPagerAdapter);
            dotsCount = bannerPagerAdapter.getCount();
            dots = new ImageView[dotsCount];
            viewPagerCountDots.removeAllViews();//
            for (int i = 0; i < dotsCount; i++) {
                dots[i] = new ImageView(getActivity());
                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_peach_dot, null));
                } else {
                    dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_dot, null));
                }
                LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
                params.setMargins(4, 0, 4, 0);
                viewPagerCountDots.addView(dots[i], params);
            }
            if (dots.length > 0) {
                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    dots[0].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem__red_dot, null));
                } else {
                    dots[0].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem_dot, null));
                }
            }
            bannerPagerAdapter.notifyDataSetChanged();
        } else {
            bannerLl.setVisibility(View.GONE);
        }
    }

    private void setUpOrderHistoryCard(JSONObject orderHistoryObject) {
        try {
            if (orderHistoryObject.has("visible") && orderHistoryObject.getBoolean("visible")) {
                llOrderHistory.setVisibility(View.VISIBLE);
                orderHistoryTv.setText(ReckonUtils.getJsonCheckedString(orderHistoryObject, "title", "Order History").toUpperCase());
                String textColor = ReckonUtils.getJsonCheckedString(orderHistoryObject, "level_color", "#000000");
                totalBounceAmount.setText(ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(orderHistoryObject, "bounced_amount", "0.0")));
                totalBounceAmount.setTextColor(Color.parseColor(textColor));
                totalBounceCount.setText(ReckonUtils.getJsonCheckedString(orderHistoryObject, "bounced_count", "0"));
                totalBounceCount.setTextColor(Color.parseColor(textColor));
                totalInvoiceAmount.setText(ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(orderHistoryObject, "invoices_amount", "0.0")));
                totalInvoiceAmount.setTextColor(Color.parseColor(textColor));
                totalInvoiceCount.setText(ReckonUtils.getJsonCheckedString(orderHistoryObject, "invoices_count", "0"));
                totalInvoiceCount.setTextColor(Color.parseColor(textColor));
                totalOrderAmount.setText(ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(orderHistoryObject, "total_orders_amount", "0.0")));
                totalOrderAmount.setTextColor(Color.parseColor(textColor));
                totalOrderCount.setText(ReckonUtils.getJsonCheckedString(orderHistoryObject, "total_orders_count", "0"));
                totalOrderCount.setTextColor(Color.parseColor(textColor));

                llOrderHistory.setOnClickListener(v -> {
                    Navigation.findNavController(v).navigate(R.id.nav_order_history);
                });

                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    orderHistoryTv.setTextColor(getResources().getColor(R.color.text_color_level));
                    orderHistoryCard.setCardBackgroundColor(getResources().getColor(R.color.section_color_primary));
                    tvTotalOrder.setTextColor(getResources().getColor(R.color.text_color_level));
                    tvInvoiced.setTextColor(getResources().getColor(R.color.text_color_level));
                    tvBounced.setTextColor(getResources().getColor(R.color.text_color_level));
                } else {
                    orderHistoryCard.setCardBackgroundColor(Color.parseColor(ReckonUtils.getJsonCheckedString(orderHistoryObject, "bg_color", "#000000")));
                    orderHistoryTv.setTextColor(getResources().getColor(R.color.black));
                    tvTotalOrder.setTextColor(Color.parseColor(textColor));
                    tvInvoiced.setTextColor(Color.parseColor(textColor));
                    tvBounced.setTextColor(Color.parseColor(textColor));
                }

            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void setUpOrderCard(JSONObject orderStatusObject) {
        try {
            if (orderStatusObject.has("visible") && orderStatusObject.getBoolean("visible") && ReckonUtils.nonNullNotEmptyString(ReckonUtils.getJsonCheckedString(orderStatusObject, "id", ""))) {
                Glide.with(HomeFragment.this).load(ReckonUtils.getJsonCheckedString(orderStatusObject, "image", "")).error(R.mipmap.deliver_man).into(imgOrderStatus);
                orderId.setText("#"+ReckonUtils.getJsonCheckedString(orderStatusObject, "id", ""));
                orderAmount.setText(ReckonUtils.getJsonCheckedString(orderStatusObject, "currency", "₹") + ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(orderStatusObject, "amount", "0")));
                orderDate.setText(ReckonUtils.getJsonCheckedString(orderStatusObject, "date", ""));
                orderShipmentStatus.setText(ReckonUtils.getJsonCheckedString(orderStatusObject, "status", "").toUpperCase());
                orderStatusLl.setVisibility(orderId.getText().toString().trim().isEmpty() ? View.GONE : View.VISIBLE);
                orderStatusLl.setOnClickListener(v -> {
                    Bundle bundle = new Bundle();
                /*if (((OrderHistory) fragment).storeDetailObjectModel != null)
                    bundle.putString(Constant.PARTY, gson.toJson(((OrderHistory) fragment).storeDetailObjectModel));*/
                    bundle.putString(Constant.ORDER_ID, ReckonUtils.getJsonCheckedString(orderStatusObject, "id", ""));
                    Navigation.findNavController(v).navigate(R.id.nav_order_details, bundle);
                });
                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    OrderStatusCard.setCardBackgroundColor(getResources().getColor(R.color.section_color_primary));
                    orderStatusTitle.setTextColor(Color.parseColor(getResources().getString(R.string.text_color_level)));
                    tvOrderId.setTextColor(getResources().getColor(R.color.color));
                    tvOrderAmount.setTextColor(getResources().getColor(R.color.color));
                    tvOrderDate.setTextColor(getResources().getColor(R.color.color));
                    orderId.setTextColor(getResources().getColor(R.color.text_color_level));
                    orderAmount.setTextColor(getResources().getColor(R.color.text_color_level));
                    orderDate.setTextColor(getResources().getColor(R.color.text_color_level));
                } else {
                    OrderStatusCard.setCardBackgroundColor(Color.parseColor(ReckonUtils.getJsonCheckedString(orderStatusObject, "bg_color", "#ffffff")));
                    tvOrderId.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(orderStatusObject, "level_color", "#ffffff")));
                    tvOrderAmount.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(orderStatusObject, "level_color", "#ffffff")));
                    tvOrderDate.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(orderStatusObject, "level_color", "#ffffff")));
                    orderId.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(orderStatusObject, "level_color", "#ffffff")));
                    orderAmount.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(orderStatusObject, "level_color", "#ffffff")));
                    orderDate.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(orderStatusObject, "level_color", "#ffffff")));
                }
            }


        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void prepareMenuData(JSONObject menuObject) {
        menuShimmer.setVisibility(View.GONE);
        if (menus.size() != 0) {
            menus.clear();
        }
        try {
            if (menuObject.has("visible") && menuObject.getBoolean("visible")) {
                menuCardHolder.setVisibility(View.VISIBLE);
            }
            menuTitle.setText(ReckonUtils.getJsonCheckedString(menuObject, "title", "Menu").toUpperCase());
            if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                menuCardHolder.setCardBackgroundColor(getResources().getColor(R.color.section_color_primary));
                menuTitle.setTextColor(Color.parseColor(getResources().getString(R.string.text_color_level)));
            } else {
                menuCardHolder.setCardBackgroundColor(Color.parseColor(ReckonUtils.getJsonCheckedString(menuObject, "bg_color", "#ffffff")));
                menuTitle.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(menuObject, "level_color", "#000000")));
            }
            JSONArray menuArray = menuObject.getJSONArray("menu_list");
            for (int i = 0; i < menuArray.length(); i++) {
                JSONObject menuItem = null;
                menuItem = menuArray.getJSONObject(i);
                MenuListItem menuListItem = new MenuListItem();
                menuListItem.setBgCard(ReckonUtils.getJsonCheckedString(menuItem, "bg_card", "#ffffff"));
                menuListItem.setActive(menuItem.getBoolean("is_active"));
                menuListItem.setImage(ReckonUtils.getJsonCheckedString(menuItem, "image", ""));
                menuListItem.setVisible(menuItem.getBoolean("visible"));
                menuListItem.setScreenName(ReckonUtils.getJsonCheckedString(menuItem, "screen_name", ""));
                menuListItem.setId(menuItem.getInt("id"));
                menuListItem.setTitle(ReckonUtils.getJsonCheckedString(menuItem, "title", ""));
                menuListItem.setType(Integer.parseInt(ReckonUtils.getJsonCheckedString(menuItem, "type", "0")));
                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    menuListItem.setColorTitle(getResources().getString(R.string.text_color_level));
                } else {
                    menuListItem.setColorTitle(ReckonUtils.getJsonCheckedString(menuItem, "color_title", "#000000"));
                }
                if (menuListItem.isVisible()) {
                    menus.add(menuListItem);
                }

            }
            if (menus == null || menus.size() == 0)
                menuCardHolder.setVisibility(View.GONE);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void prepareTestimonialData(JSONObject testimonials) {
        if (testimonialList.size() != 0) {
            testimonialList.clear();
        }
        try {
            JSONArray testimonialArray = testimonials.getJSONArray("testimonials_list");
            if (testimonials.has("visible") && testimonials.getBoolean("visible")) {
                testimonialCardHolder.setVisibility(View.VISIBLE);
                testimonialTv.setText(ReckonUtils.getJsonCheckedString(testimonials, "title", "Testimonials").toUpperCase());
                testimonialTv.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(testimonials, "level_color", "#000000")));
                for (int i = 0; i < testimonialArray.length(); i++) {
                    JSONObject testimonialItem = null;
                    testimonialItem = testimonialArray.getJSONObject(i);
                    TestimonialsListItem listItem = new TestimonialsListItem();
                    listItem.setBusinessName(ReckonUtils.getJsonCheckedString(testimonialItem, "business_name", ""));
                    listItem.setDate(ReckonUtils.getJsonCheckedString(testimonialItem, "date", ""));
                    listItem.setDescriptions(ReckonUtils.getJsonCheckedString(testimonialItem, "descriptions", ""));
                    listItem.setId(String.valueOf(testimonialItem.getInt("id")));
                    listItem.setRating(testimonialItem.getString("rating"));
                    listItem.setName(testimonialItem.getString("name"));
                    listItem.setFontColor(ReckonUtils.getJsonCheckedString(testimonialItem, "level_color", "#000000"));
                    listItem.setBackgroundColorOfTestimonial(ReckonUtils.getJsonCheckedString(testimonialItem, "bg_color", "#ffffff"));
                    testimonialList.add(listItem);
                }
            }
            if (testimonialList.size() == 0)
                testimonialCardHolder.setVisibility(View.GONE);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void prepareNewArrivalData(JSONObject newArrivalObject, String action) {
        if (newArrivalObject.has("arrival_list")) {
            if (arrivalListItems.size() > 0) {
                arrivalListItems.clear();
            }
            try {
                bgColor = ReckonUtils.getJsonCheckedString(newArrivalObject, "bg_color", "#ffffff");
                newArrivalCardHolder.setCardBackgroundColor(Color.parseColor(bgColor));
                newArrivalTitleTv.setText(ReckonUtils.getJsonCheckedString(newArrivalObject, "title", getString(R.string.new_arrival)).toUpperCase());
                newArrivalTitleTv.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(newArrivalObject, "level_color", "#000000")));
                JSONArray newArrivalArray = newArrivalObject.getJSONArray("arrival_list");
                for (int j = 0; j < newArrivalArray.length(); j++) {
                    JSONObject newItem = newArrivalArray.getJSONObject(j);
                    arrivalListItems.add(parseProductJson(newItem, action));
                }
                newArrivalCardHolder.setVisibility(newArrivalObject.has("visible") && newArrivalObject.getBoolean("visible") && arrivalListItems.size() > 0 ? View.VISIBLE : View.GONE);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

    }

    private void prepareBrandData(JSONObject brandsObject) {
        if (brandListItems.size() != 0)
            brandListItems.clear();
        try {
            if (brandsObject.has("visible") && brandsObject.getBoolean("visible"))
                brandCardHolder.setVisibility(View.VISIBLE);
            bgColor = ReckonUtils.getJsonCheckedString(brandsObject, "bg_color", "#ffffff");
            brandTitleTv.setText(ReckonUtils.getJsonCheckedString(brandsObject, "title", "Brand").toUpperCase());
            brandTitleTv.setTextColor(Color.parseColor(ReckonUtils.getJsonCheckedString(brandsObject, "level_color", "#000000")));
            brandCardHolder.setCardBackgroundColor(Color.parseColor(ReckonUtils.getJsonCheckedString(brandsObject, "bg_color", "#ffffff")));
            JSONArray brandListArray = brandsObject.has("brand_list") ? brandsObject.getJSONArray("brand_list") : new JSONArray();
            for (int i = 0; i < brandListArray.length(); i++) {
                JSONObject item;
                item = brandListArray.getJSONObject(i);
                BrandListItem brandItem = new BrandListItem();
                brandItem.setTitle(ReckonUtils.getJsonCheckedString(item, "title", ""));
                brandItem.setDescription(ReckonUtils.getJsonCheckedString(item, "description", ""));
                brandItem.setImage(getUserImageBaseUrl() + ReckonUtils.getJsonCheckedString(item, "image", ""));
                brandItem.setBgColor(ReckonUtils.getJsonCheckedString(item, "bg_color", "#ffffff"));
                brandItem.setFontColor(ReckonUtils.getJsonCheckedString(item, "level_color", "#000000"));
                brandItem.setId(Integer.parseInt(ReckonUtils.getJsonCheckedString(item, "id", "0")));
                brandListItems.add(brandItem);
            }
            if (brandListItems == null || brandListItems.size() == 0)
                brandCardHolder.setVisibility(View.GONE);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onStart() {
        super.onStart();
        if (((NewMainActivity) getActivity()) != null) {
            ((NewMainActivity) getActivity()).setUpTitle(HomeFragment.this, getString(R.string.menu_home));
        }
    }

    private void setDistributorListingAdapter(JSONArray jsonArray) {
        try {
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                StoreDetailObjectModel model = new StoreDetailObjectModel();
                try {
                    model.setAdd1(ReckonUtils.getJsonCheckedString(jsonObject, "Add1", ""));
                    model.setName(ReckonUtils.getJsonCheckedString(jsonObject, "Name", ""));
                    model.setMobile(ReckonUtils.getJsonCheckedString(jsonObject, "Mobile", ""));
                    model.setPinCode(ReckonUtils.getJsonCheckedString(jsonObject, "PinCode", ""));
                    model.setFirmCode(ReckonUtils.getJsonCheckedString(jsonObject, "Code", ""));
                    model.setId(ReckonUtils.getJsonCheckedString(jsonObject, "id", ""));
                    model.setAcCode(ReckonUtils.getJsonCheckedString(jsonObject, "AcCode", ""));
                    model.setAcCode(ReckonUtils.getJsonCheckedString(jsonObject, "AcCode", ""));
                    model.setLicNo(ReckonUtils.getJsonCheckedString(jsonObject, "LicNo", ""));
                    model.setFirstChar(ReckonUtils.getFirstCharFromString(model.getName()));
                    String emailId = ReckonUtils.getJsonCheckedString(jsonObject, "Email", "");
                    model.setEmail(ReckonUtils.isValidEmail(emailId) ? emailId : "");
                    model.setCity(ReckonUtils.getJsonCheckedString(jsonObject, "City", ""));
                    model.setMid(ReckonUtils.getJsonCheckedString(jsonObject, "Mid", ""));
                    model.setMkey(ReckonUtils.getJsonCheckedString(jsonObject, "Mkey", ""));
                    localStorage.setDelStoreInfo(gson.toJson(model));
                    SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, model.getAcCode());

                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
