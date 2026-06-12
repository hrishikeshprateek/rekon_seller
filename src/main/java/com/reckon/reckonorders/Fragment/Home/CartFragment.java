package com.reckon.reckonorders.Fragment.Home;

import static android.view.View.GONE;
import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_DISTRIBUTOR_FILTER;
import static com.reckon.reckonorders.Others.Constant.Constant.TOTAL_VALUE;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.cardview.widget.CardView;
import androidx.core.widget.NestedScrollView;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.facebook.shimmer.ShimmerFrameLayout;
import com.google.gson.Gson;
import com.reckon.reckonorders.Adapter.CommonRowAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.Model.ProductModel;
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

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class CartFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    @BindView(R.id.proceedCard)
    CardView proceedCard;
    @BindView(R.id.newArrivalScrollView)
    NestedScrollView newArrivalScrollView;
    @BindView(R.id.newArrivalViewLL)
    CardView newArrivalViewLL;
    @BindView(R.id.proceed)
    TextView proceed;
    @BindView(R.id.emptyCartLayout)
    LinearLayout emptyCartLayout;
    @BindView(R.id.shopNowCard)
    CardView shopNowCard;
    @BindView(R.id.addMoreItemCard)
    CardView addMoreItemCard;
    @BindView(R.id.tvCartText)
    TextView tvCartText;
    @BindView(R.id.plus_icon)
    ImageView plus_icon;
    @BindView(R.id.addMoreItemCardLL)
    LinearLayout addMoreItemCardLL;
    @BindView(R.id.addMoreItem)
    LinearLayout addMoreItem;
    @BindView(R.id.newArrivalsRecycler)
    RecyclerView newArrivalsRecycler;
    @BindView(R.id.totalOrderValueCard)
    CardView totalOrderValueCard;
    @BindView(R.id.cartItems)
    NestedScrollView cartItems;
    @BindView(R.id.cartRecycler)
    RecyclerView cartRecycler;
    @BindView(R.id.cartItemShimmer)
    ShimmerFrameLayout cartItemShimmer;
    @BindView(R.id.tvTotalAmountValue)
    TextView TotalPrice_tv;
    @BindView(R.id.parent_cv)
    CardView parentCv;
    @BindView(R.id.tvAccountName)
    TextView tvAccountName;
    @BindView(R.id.tvAddress)
    TextView tvAddress;
    @BindView(R.id.new_arrival_title_tv)
    TextView newArrivalTitleTv;
    @BindView(R.id.cart_container_rl)
    RelativeLayout cartContainerRl;

    private AlertDialog alertDialog = null;
    private CommonRowAdapter cartAdapter;
    private ArrayList<ProductModel> product_list = new ArrayList();
    public String FirmCode, LicNo, partyCode;
    public boolean isRefreshed = false, flag = true;
    public ArrayList<Float> productAmountsList = new ArrayList<>();
    public ArrayList<ProductModel> arrivalListItems = new ArrayList<>();
    Bundle bundle;
    private boolean isSalesMan;
    private StoreDetailObjectModel storeDetailObjectModel;
    private Gson gson = new Gson();
    private View view;
    private int showTotalValueCard = 0;

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        view = inflater.inflate(R.layout.car_fragment_layout, container, false);
        ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        getBundle();
        setupUI();
        setTitle(view, getString(R.string.cart).toUpperCase());
        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        keyboardListener();
        proceedCard.setCardBackgroundColor(getButtonColor());
        addMoreItemCard.setBackgroundColor(getButtonColor());
        shopNowCard.setBackgroundColor(getButtonColor());
        newArrivalScrollView.setVisibility(GONE);
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        ((NewMainActivity) getActivity()).setUpTitle(CartFragment.this, getString(R.string.cart));
        newArrivalViewLL.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isSalesMan) {
                    Bundle bundle = new Bundle();
                    bundle.putString("isNewArrival", "1");
                    orderEntryClickHandling(v, Constant.NEW_ARRIVAL, bundle);
                } else {
                    NavHostFragment.findNavController(CartFragment.this).navigate(R.id.nav_new_arrival);
                }
            }
        });
        // newArrivalViewLL.setOnClickListener(v -> orderEntryClickHandling(v, Constant.NEW_ARRIVAL, bundle));
        cartRecycler.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
        cartRecycler.setAdapter(new CommonRowAdapter(CartFragment.this, product_list, Constant.CART));
        if (isSalesMan) {
            openPartyPickerDialog();
        } else if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
            openPartyPickerDialog();
        } else if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE)) {
            setDefaultData();
            StoreDetailObjectModel model = new StoreDetailObjectModel();
            try {
                LicDetailObjectModel model1 = getLicDetails();
                model.setAdd1(model1.getFirmAdd());
                model.setAcCode(SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
                model.setLicNo(model1.getLicno());
                model.setName(model1.getFirmName());
                model.setFirmCode(model1.getFirmcode());
                if (model1.getFirmName() != null && !model1.getFirmName().isEmpty()) {
                    model.setFirstChar(ReckonUtils.getFirstCharFromString(model1.getFirmName()));
                }
                storeDetailObjectModel = /*model*/getStoreDetails();
                getCartItemList();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
//        if (isSalesMan) {
//        openPartyPickerDialog();
/*        } else {
            new Handler().postDelayed(this::getCartItemList, 1000);
            parentCv.setVisibility(GONE);
//            tvAccountName.setText(data.getName());
//            tvAddress.setText(data.getAdd1() + data.getAdd2() + data.getAdd3());
            addMoreItemCardLL.setVisibility(GONE);
        }*/
    }

    boolean isKeyboardShowing = false;

    void onKeyboardVisibilityChanged(boolean opened) {
        totalOrderValueCard.setVisibility(opened ? View.GONE : View.VISIBLE);
    }

    private void keyboardListener() {
        // ContentView is the root view of the layout of this activity/fragment
        if (cartContainerRl != null)
            cartContainerRl.getViewTreeObserver().addOnGlobalLayoutListener(
                    () -> {
                        if (cartContainerRl != null) {
                            Rect r = new Rect();
                            cartContainerRl.getWindowVisibleDisplayFrame(r);
                            int screenHeight = cartContainerRl.getRootView().getHeight();
                            // r.bottom is the position above soft keypad or device button.
                            // if keypad is shown, the r.bottom is smaller than that before.
                            int keypadHeight = screenHeight - r.bottom;
                            if (keypadHeight > screenHeight * 0.15) { // 0.15 ratio is perhaps enough to determine keypad height.
                                // keyboard is opened
                                if (!isKeyboardShowing) {
                                    isKeyboardShowing = true;
                                    onKeyboardVisibilityChanged(true);
                                }
                            } else {
                                // keyboard is closed
                                if (isKeyboardShowing) {
                                    isKeyboardShowing = false;
                                    onKeyboardVisibilityChanged(false);
                                }
                            }
                        }
                    });
    }

    void setDefaultData() {
        tvAccountName.setVisibility(GONE);
        totalOrderValueCard.setVisibility(GONE);
        tvAddress.setVisibility(GONE);
        parentCv.setVisibility(GONE);
        emptyCartLayout.setVisibility(View.VISIBLE);
        if (arrivalListItems.size() > 0)
            newArrivalScrollView.setVisibility(View.VISIBLE);
        else
            newArrivalScrollView.setVisibility(GONE);
        cartItems.setVisibility(GONE);
        addMoreItem.setVisibility(GONE);
        addMoreItemCard.setVisibility(GONE);
        addMoreItemCardLL.setVisibility(GONE);
    }

    private void openPartyPickerDialog() {
        StorePartyPickerDialog dialog = new StorePartyPickerDialog(getActivity(), isSalesMan ? getString(R.string.select_party) : getString(R.string.select_distributor), isSalesMan ? Constant.PARTY : Constant.DISTRIBUTOR, Constant.CART_SCREEN);
        setDefaultData();
        dialog.setOnItemClickListenerDialog(data -> {
            if (data != null) {
                storeDetailObjectModel = data;
                tvAccountName.setText(data.getName());
                if (isSalesMan) {
                    tvAddress.setText(data.getAdd1() + data.getAdd2() + data.getAdd3());
                } else {
                    tvAddress.setText(data.getAdd1());
                    SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, data.getAcCode());
                    LicDetailObjectModel model = getLicDetails();
                    model.setFirmcode(data.getFirmCode());
                    model.setFirmName(data.getName());
                    model.setFirmAdd(data.getAdd1());
                    model.setLicno(data.getLicNo());
                    localStorage.setLicDetails(gson.toJson(model));
                }
                tvAccountName.setVisibility(View.VISIBLE);
                tvAddress.setVisibility(ReckonUtils.nonNullNotEmptyString(tvAddress.getText().toString().trim()) ? View.VISIBLE : GONE);
                parentCv.setVisibility(View.VISIBLE);
                cartItems.setVisibility(View.VISIBLE);
                addMoreItem.setVisibility(View.VISIBLE);
                addMoreItemCard.setVisibility(View.VISIBLE);
                addMoreItemCardLL.setVisibility(View.VISIBLE);
                emptyCartLayout.setVisibility(GONE);
                newArrivalScrollView.setVisibility(GONE);
                showTotalValueCard = 1;
            }
            getCartItemList();
        });
        if (storeDetailObjectModel == null) {
            getCartItemList();
        }
        dialog.show();
    }

    public void getCartItemList() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("AcCode", isSalesMan ? SharedPrefUtils.getString(getActivity(), Constant.PARTY_CODE) : storeDetailObjectModel != null ? storeDetailObjectModel.getAcCode() : "");
            jsonObject.put("lFirmCode", isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : storeDetailObjectModel != null ? storeDetailObjectModel.getFirmCode() : "");
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostCartItemList(String.valueOf(jsonObject)), Constant.CART, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void getBundle() {
        bundle = getArguments();
        /** will be uncommented when api will be available*/
        if (bundle != null) {
            partyCode = bundle.containsKey("PARTYCODE") ? bundle.getString("PARTYCODE") : "";
        }
    }


    @OnClick({R.id.addMoreItem, R.id.proceed, R.id.shopNowCard, R.id.removeButton, R.id.selectPartyLL})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.addMoreItem:
                gotoNewOrderScree(isSalesMan);
                break;
            case R.id.shopNowCard:
                if (isSalesMan)
                    orderEntryClickHandling(view, Constant.NEW_ORDER, new Bundle());
                else
                    gotoNewOrderScree(false);
                break;
            case R.id.proceed:
                getOrderDetails();
                break;
            case R.id.removeButton:
                RemoveCartItemPopUp();
                break;
            case R.id.selectPartyLL:
                if (isSalesMan) {
                    openPartyPickerDialog();
                } else if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
                    openPartyPickerDialog();
                }
                break;
        }
    }

    public void getOrderDetails() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("AcCode", isSalesMan ? SharedPrefUtils.getString(getActivity(), Constant.PARTY_CODE) : SharedPrefUtils.getString(getActivity(), Constant.AC_CODE));
            jsonObject.put("lFirmCode", isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : getLicDetails().getFirmcode());
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostDraftOrderDetails(String.valueOf(jsonObject)), Constant.DRAFT_ORDER_DETAILS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void gotoNewOrderScree(boolean isSalesMan) {
        Bundle mBundle = new Bundle();
        mBundle.putString(Constant.FROM, Constant.CART);
        if (/*isSalesMan && */storeDetailObjectModel != null)
            mBundle.putString(Constant.PARTY, gson.toJson(storeDetailObjectModel));
        NavHostFragment.findNavController(CartFragment.this).navigate(R.id.nav_Order_Entry, mBundle);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        switch (requestCode) {
            case CODE_REQUEST_DISTRIBUTOR_FILTER:
                FirmCode = data.getExtras().containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
                LicNo = data.getExtras().containsKey("LicNo") ? data.getStringExtra("LicNo") : "";
                new Handler().postDelayed(this::getCartItemList, 1000);
                break;
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) {
        try {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.CART:
                    cartItemShimmer.setVisibility(GONE);
                    JSONArray jsonArray = jsonObject.has("DraftOrder") ? jsonObject.getJSONArray("DraftOrder") : new JSONArray();
                    JSONArray jsonArrayNewArrival = jsonObject.has("NewArrivalList") ? jsonObject.getJSONArray("NewArrivalList") : new JSONArray();
                    clearLists();
                    Objects.requireNonNull(product_list).addAll(getParsedProductList(jsonArray, action));
                    Objects.requireNonNull(arrivalListItems).addAll(getParsedProductList(jsonArrayNewArrival, action));
                    if (!isSalesMan && getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE)) {
                        setSingleRetailerTypeData();
                    }
                    setUpNewArrivalRecyclerView();
                    for (int i = 0; i < jsonArray.length(); i++) {
                        productAmountsList.add(Float.parseFloat(product_list.get(i).getNetAmtCart()));
                    }
                    if (showTotalValueCard == 1)
                        setUIAfterResponse();
                    cartAdapter = new CommonRowAdapter(CartFragment.this, product_list, Constant.CART);
                    cartRecycler.setAdapter(cartAdapter);
                    if (flag) {
                        isRefreshed = false;
                        ListSize(String.valueOf(product_list.size()), false, true);
                    } else ListSize(String.valueOf(product_list.size()), true, true);

                    break;
                case Constant.DELETE_CART:
                    clearLists();
                    cartAdapter.notifyDataSetChanged();
                    setUIAfterResponse();
                    break;
                case Constant.DRAFT_ORDER_DETAILS:
                    gotoDeliveryDetails(jsonObject);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void gotoDeliveryDetails(JSONObject jsonObj) {
        try {
            if (jsonObj.getString("Status").equalsIgnoreCase("true")) {
                bundle = new Bundle();
                bundle.putString(TOTAL_VALUE, calculatePrice(productAmountsList));
                if (storeDetailObjectModel != null)
                    bundle.putString(Constant.PARTY, gson.toJson(storeDetailObjectModel));
                NavHostFragment.findNavController(CartFragment.this).navigate(R.id.nav_delivery_details, bundle);
            } else {
                Toast.makeText(getActivity(), jsonObj.getString("Message"), Toast.LENGTH_LONG).show();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setSingleRetailerTypeData() {
        tvAccountName.setVisibility(GONE);
        totalOrderValueCard.setVisibility(View.VISIBLE);
        tvAddress.setVisibility(GONE);
        parentCv.setVisibility(GONE);
        emptyCartLayout.setVisibility(GONE);
        newArrivalScrollView.setVisibility(GONE);
        cartItems.setVisibility(View.VISIBLE);
        addMoreItem.setVisibility(View.VISIBLE);
        addMoreItemCard.setVisibility(View.VISIBLE);
        addMoreItemCardLL.setVisibility(View.VISIBLE);
        showTotalValueCard = 1;
    }

    private void setUpNewArrivalRecyclerView() {
        newArrivalsRecycler.setAdapter(new NewArrivalAdapter(CartFragment.this, arrivalListItems, getString(R.string.new_arrival)));
        if (arrivalListItems != null && arrivalListItems.size() > 0) {
            newArrivalScrollView.setVisibility(View.VISIBLE);
            newArrivalTitleTv.setVisibility(View.VISIBLE);
        } else {
            newArrivalScrollView.setVisibility(GONE);
            newArrivalTitleTv.setVisibility(GONE);
            newArrivalViewLL.setVisibility(View.GONE);
        }
    }

    private void setUIAfterResponse() {
        if (product_list != null && product_list.size() > 0) {
            cartItems.setVisibility(View.VISIBLE);
            addMoreItemCard.setVisibility(View.VISIBLE);
            addMoreItemCardLL.setVisibility(View.VISIBLE);
            totalOrderValueCard.setVisibility(View.VISIBLE);
            newArrivalViewLL.setVisibility(View.GONE);
            newArrivalScrollView.setVisibility(GONE);
        } else {
            emptyCartLayout.setVisibility(View.VISIBLE);
            if (arrivalListItems.size() > 0) {
                newArrivalScrollView.setVisibility(View.VISIBLE);
                newArrivalViewLL.setVisibility(View.VISIBLE);
            } else {
                newArrivalScrollView.setVisibility(View.GONE);
                newArrivalViewLL.setVisibility(View.GONE);
            }
            totalOrderValueCard.setVisibility(GONE);
            cartItems.setVisibility(GONE);
            addMoreItemCard.setVisibility(GONE);
            addMoreItemCardLL.setVisibility(GONE);
        }
        TotalPrice_tv.setText(getLicDetails().getCurrency() + ReckonUtils.roundTwoDecimals(calculatePrice(productAmountsList)));
    }

    private void clearLists() {
        if (product_list != null && product_list.size() > 0)
            product_list.clear();
        if (productAmountsList != null && productAmountsList.size() > 0)
            productAmountsList.clear();
    }

    public void ListSize(String size, boolean check, boolean b) {
        flag = b;
        isRefreshed = check;
    }

    public void onBackPressed() {
        if (isRefreshed) {
            Intent intent = new Intent();
            intent.putExtra(Constant.SELECTED_ID, FirmCode);
            intent.putExtra("LicNo", LicNo);
            if (getTargetFragment() != null)
                getTargetFragment().onActivityResult(getTargetRequestCode(), 0, intent);
        }
        getActivity().onBackPressed();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (isRefreshed) {
            Intent intent = new Intent();
            intent.putExtra(Constant.SELECTED_ID, FirmCode);
            intent.putExtra("LicNo", LicNo);
            if (getTargetFragment() != null)
                getTargetFragment().onActivityResult(getTargetRequestCode(), 0, intent);
        }
    }

    private void RemoveCartItemPopUp() {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(getActivity());
        alertDialogBuilder.setMessage("Do You Want to Remove All Cart Item?");
        alertDialogBuilder.setPositiveButton("YES",
                (arg0, arg1) -> {
                    alertDialog.cancel();
                    deleteItem();
                });

        alertDialogBuilder.setNegativeButton("NO", (dialog, which) -> {
            alertDialog.cancel();
        });
        alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(getResources().getColor(R.color.black));
        alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(getResources().getColor(R.color.black));
    }

    private void deleteItem() {
        try {
            boolean isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
            String acCode = SharedPrefUtils.getString(getActivity(), isSalesMan ? Constant.PARTY_CODE : Constant.AC_CODE);
            String firmCode = isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : getLicDetails().getFirmcode();
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lFirmCode", firmCode);
            jsonObject.put("lIdCol", "");
            jsonObject.put("AcCode", acCode);
            jsonObject.put("device_id", SharedPrefUtils.getString(getActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().RemoveItemFromCart(String.valueOf(jsonObject)), Constant.DELETE_CART, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
