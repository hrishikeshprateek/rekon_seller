package com.reckon.reckonorders.Adapter;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.isTextEnterOn;
import static com.reckon.reckonorders.Utils.ReckonUtils.setDynamicMargin;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.InputFilter;
import android.text.InputType;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.TextWatcher;
import android.text.style.ForegroundColorSpan;
import android.text.style.RelativeSizeSpan;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.ListPopupWindow;
import androidx.cardview.widget.CardView;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.core.content.res.ResourcesCompat;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager.widget.ViewPager;

import com.google.android.material.bottomsheet.BottomSheetBehavior;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Fragment.Account.CommonListingFragment;
import com.reckon.reckonorders.Fragment.Home.CartFragment;
import com.reckon.reckonorders.Fragment.Home.NewOrderFragment;
import com.reckon.reckonorders.Fragment.Home.OrderDetailsFragment;
import com.reckon.reckonorders.Fragment.Home.RequestDistributorFragment;
import com.reckon.reckonorders.Fragment.Home.StatusDistributorFragment;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewModals.AddToCartModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.view.AutoScrollViewPager;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.Debouncer;
import com.reckon.reckonorders.Utils.DecimalDigitsInputFilter;
import com.reckon.reckonorders.Utils.DecimalDigitsInputFilters;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

public class CommonRowAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private CommonListingFragment context;
    private ArrayList<LoginModel> ccArray;
    ArrayList<Integer> addItemToCart;
    int m = -1;
    ArrayList<Double> totalCalculatedPriceOfCart = new ArrayList<>();
    private ListPopupWindow listPopupWindow;
    ArrayList<AddToCartModel> productCountList = new ArrayList<>();
    ArrayList<LoginModel> selectedItemList = new ArrayList<>();

    private ArrayList<ProductModel> productArray;
    private StatusDistributorFragment _context;
    private NewOrderFragment newOrderContext;
    private CartFragment cartFragment;
    private Fragment fragment;

    private String FROM;
    private Bundle bundle;
    private View view;
    Gson gson = new Gson();
    private AlertDialog alertDialog = null;
    private int selected_pos = -1;
    private String id = "";
    private String totalCalculatedPriceOfCartValue = "";
    private boolean isSalesMan = false, isPlusMinusClicked = false;
    private boolean isAddCartClicked = false;
    private boolean onQtyEdtTextClicked = false;
    private ProgressDialog progress;
    private TextView tvGoodsValue, tvSchemeValue, tvDiscValue, tvGstValue, tvNetValue, showQtyErrorMsgTv, disPcsAmtTv, disPerAmtTv, disAddAmtTv, tvGstTitle;
    private boolean openOptionQtyBottomSheet = true;
    private boolean autoUpdateQty = false;
    private  EditText discEdt;
    final Debouncer debouncer = new Debouncer();
    private BottomSheetDialog dialog;

    public CommonRowAdapter(CommonListingFragment context, ArrayList<LoginModel> arrayList, String _from) {
        this.ccArray = arrayList;
        this.context = context;
        this.FROM = _from;
    }


    public CommonRowAdapter(Fragment fragment, ArrayList<LoginModel> arrayList, String _from, String from) {
        this.ccArray = arrayList;
        this.fragment = fragment;
        this.FROM = _from;
    }

    public CommonRowAdapter(StatusDistributorFragment context, ArrayList<LoginModel> arrayList, String _from) {
        this.ccArray = arrayList;
        this._context = context;
        this.FROM = _from;
    }

    public CommonRowAdapter(NewOrderFragment context, ArrayList<ProductModel> arrayList, String _from, Bundle bundle) {
        retrofitCallBackListener = this;
        this.productArray = arrayList;
        this.newOrderContext = context;
        this.FROM = _from;
        this.bundle = bundle;
        isSalesMan = newOrderContext.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    public CommonRowAdapter(CartFragment context, ArrayList<ProductModel> arrayList, String _from) {
        retrofitCallBackListener = this;
        this.productArray = arrayList;
        this.cartFragment = context;
        this.FROM = _from;
        isSalesMan = cartFragment.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    public CommonRowAdapter(Fragment context, ArrayList<ProductModel> arrayList, String _from) {
        retrofitCallBackListener = this;
        this.productArray = arrayList;
        this.fragment = context;
        this.FROM = _from;
        isSalesMan = ((BaseFragment) fragment).getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        if (FROM.equalsIgnoreCase("CSC")) {
            return new ViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.cc_row_layout, parent, false));
        } else if (FROM.equalsIgnoreCase(Constant.NEW_ORDER) || FROM.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)) {
            view = LayoutInflater.from(parent.getContext()).inflate(R.layout.new_order_row_layout, parent, false);
            return new OrderViewHolder(view);
        } else if (FROM.equalsIgnoreCase(Constant.CART)) {
            return new CartViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.cart_fragment_item_layout, parent, false));
        } else if (FROM.equalsIgnoreCase(Constant.ORDER_DETAILS)) {
            return new PurchasedOrderHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.purchased_item_layout, parent, false));
        } else {
            return new DistributorViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.distributor_row_layout, parent, false));
        }
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, final int position) {
        if (holder instanceof ViewHolder) {
            onBindViewDataRendering(holder, position);
        } else if (holder instanceof DistributorViewHolder) {
            onBindViewDistributorDataRendering(holder, position);
        } else if (holder instanceof OrderViewHolder) {
            onBindViewNewOrderDataRendering(holder, position);
        } else if (holder instanceof CartViewHolder) {
            onBindViewCartDataRendering(holder, position);
        } else if (holder instanceof PurchasedOrderHolder) {
            onBindViewPurchasedOrderDataRendering(holder, position);
        }
    }

    private void onBindViewDataRendering(RecyclerView.ViewHolder holder, int position) {
        ViewHolder row = (ViewHolder) holder;
        try {
            row.cName.setText(ccArray.get(position).getCountry_name());
            row.rowLayout.setOnClickListener(v -> context.getID(ccArray.get(position).getCountry_id(), ccArray.get(position).getCountry_name(), ccArray.get(position).getState(), ccArray.get(position).getCity(), ccArray.get(position).getLicNo() != null ? ccArray.get(position).getLicNo() : "", ccArray.get(position).getShowStock(), ccArray.get(position).getRateType()));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onBindViewDistributorDataRendering(RecyclerView.ViewHolder holder, int position) {
        DistributorViewHolder row = (DistributorViewHolder) holder;
        try {
            row.cName.setText(ccArray.get(position).getCountry_name());
            row.businessTypeTv.setText(ccArray.get(position).getBusiness());
            row.businessTypeTv.setVisibility(!ccArray.get(position).getBusiness().trim().isEmpty() ? View.VISIBLE : View.GONE);
            row.tv_email.setText(ccArray.get(position).getEmail());
            row.tv_mobile_number.setText(ccArray.get(position).getMobile());
            row.tv_city.setText(ccArray.get(position).getCity());
            row.tv_address.setText(ccArray.get(position).getAdd1());
            row.city_ll.setVisibility(!ccArray.get(position).getCity().trim().isEmpty() ? View.VISIBLE : View.GONE);
            if (FROM.equalsIgnoreCase(Constant.DISTRIBUTOR_STATUS)) {
                row.statusBtn.setVisibility(View.VISIBLE);
                if (ccArray.get(position).getStatus().equalsIgnoreCase("0") && !ccArray.get(position).getLock().equalsIgnoreCase("1")) {
                    row.statusBtn.setBackground(_context.getResources().getDrawable(R.drawable.pending_button));
                } else if (ccArray.get(position).getStatus().equalsIgnoreCase("1") && !ccArray.get(position).getLock().equalsIgnoreCase("1")) {
                    row.statusBtn.setBackground(_context.getResources().getDrawable(R.drawable.accepted_button));
                    row.statusBtn.setText(_context.getResources().getString(R.string.active));
                } else if (ccArray.get(position).getStatus().equalsIgnoreCase("1") && ccArray.get(position).getLock().equalsIgnoreCase("1")) {
                    row.statusBtn.setBackground(_context.getResources().getDrawable(R.drawable.cancelled_btn));
                    row.statusBtn.setText(_context.getResources().getString(R.string.locked));
                } else if (ccArray.get(position).getStatus().equalsIgnoreCase("0") && ccArray.get(position).getLock().equalsIgnoreCase("1")) {
                    row.statusBtn.setBackground(_context.getResources().getDrawable(R.drawable.cancelled_btn));
                    row.statusBtn.setText(_context.getResources().getString(R.string.locked));
                } else {
                    row.statusBtn.setBackground(_context.getResources().getDrawable(R.drawable.pending_button));
                    row.statusBtn.setText(_context.getResources().getString(R.string.pending));
                }
            }
            if (fragment != null)
                row.parent_cv.setCardBackgroundColor(selectedItemList.contains(ccArray.get(position)) ? ((RequestDistributorFragment) fragment).getSecondHeaderTextColor() : (fragment.getResources().getColor(R.color.white)));
            row.rowLayout.setOnClickListener(v -> {
                if (FROM.equalsIgnoreCase(Constant.DISTRIBUTOR)) {
                    if (fragment != null && fragment instanceof RequestDistributorFragment) {
                        if (selectedItemList.contains(ccArray.get(position)))
                            selectedItemList.remove(ccArray.get(position));
                        else {
                            selectedItemList.add(ccArray.get(position));
                        }
                        ((RequestDistributorFragment) fragment).getSelectedDistributorItemData(ccArray.get(position), selectedItemList);
                    } else
                        context.getDisstributorData(ccArray.get(position));
                    notifyDataSetChanged();
                }
            });
            row.llMobileRow.setVisibility(ccArray.get(position).getMobile().isEmpty() ? View.INVISIBLE : View.VISIBLE);
            row.llEmailRow.setVisibility(ccArray.get(position).getEmail().isEmpty() ? View.GONE : View.GONE);

            row.callIv.setOnClickListener(v -> {
                if (_context != null) {
                    ReckonUtils.performCall(_context.requireActivity(), ccArray.get(position).getMobile());
                } else if (fragment != null) {
                    ReckonUtils.performCall(fragment.requireActivity(), ccArray.get(position).getMobile());
                } else if (context != null) {
                    ReckonUtils.performCall(context.requireActivity(), ccArray.get(position).getMobile());
                }
            });
            row.viewMoreLl.setOnClickListener(v -> {
                Bundle bundle = new Bundle();
                bundle.putString(Constant.ID, ccArray.get(position).getId());
                Navigation.findNavController(v).navigate(R.id.nav_distributor_details, bundle);
            });
            Fragment _fragment = null;
            if (_context != null) {
                _fragment = _context;
            } else if (fragment != null) {
                _fragment = fragment;
            } else if (context != null) {
                _fragment = context;
            }
            if (ccArray.get(position).getBannerList() != null && ccArray.get(position).getBannerList().size() > 0) {
                row.imageSlidesFL.setVisibility(View.VISIBLE);
                Fragment final_fragment = _fragment;
                BannerPagerAdapter bannerPagerAdapter = new BannerPagerAdapter(_fragment, ccArray.get(position).getBannerList(), _fragment.getActivity(), row.imageSlides);
                row.imageSlides.setAdapter(bannerPagerAdapter);
                int dotsCount = bannerPagerAdapter.getCount();
                ImageView[] dots = new ImageView[dotsCount];
                row.viewPagerCountDots.removeAllViews();//
                for (int i = 0; i < dotsCount; i++) {
                    dots[i] = new ImageView(final_fragment.getActivity());
                    if (final_fragment.requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                        dots[i].setImageDrawable(ResourcesCompat.getDrawable(final_fragment.getResources(), R.drawable.selecteditem_black_dot, null));
                    } else {
                        dots[i].setImageDrawable(ResourcesCompat.getDrawable(final_fragment.getResources(), R.drawable.nonselecteditem_dot, null));
                    }
                    LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
                    params.setMargins(4, 0, 4, 0);
                    row.viewPagerCountDots.addView(dots[i], params);
                }
                if (dots.length > 0) {
                    if (final_fragment.requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                        dots[0].setImageDrawable(ResourcesCompat.getDrawable(final_fragment.getResources(), R.drawable.selecteditem__red_dot, null));
                    } else {
                        dots[0].setImageDrawable(ResourcesCompat.getDrawable(final_fragment.getResources(), R.drawable.selecteditem_dot, null));
                    }
                }
                row.imageSlides.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
                    @Override
                    public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
                    }

                    @Override
                    public void onPageSelected(int position) {
                        for (int i = 0; i < dotsCount; i++) {
                            if (final_fragment.requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                                dots[i].setImageDrawable(ResourcesCompat.getDrawable(final_fragment.getResources(), R.drawable.selecteditem_black_dot, null));
                            } else {
                                dots[i].setImageDrawable(ResourcesCompat.getDrawable(final_fragment.getResources(), R.drawable.nonselecteditem_dot, null));
                            }
                        }
                        if (final_fragment.requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                            dots[position].setImageDrawable(ResourcesCompat.getDrawable(final_fragment.getResources(), R.drawable.selecteditem__red_dot, null));
                        } else {
                            dots[position].setImageDrawable(ResourcesCompat.getDrawable(final_fragment.getResources(), R.drawable.selecteditem_dot, null));
                        }

                    }

                    @Override
                    public void onPageScrollStateChanged(int state) {

                    }
                });
                bannerPagerAdapter.notifyDataSetChanged();
            } else {
                row.imageSlidesFL.setVisibility(View.GONE);
            }
            if (ccArray.get(position).getRating() != null && !ccArray.get(position).getRating().isEmpty()) {
                row.ratingCV.setVisibility(View.VISIBLE);
                row.ratingTv.setText(ccArray.get(position).getRating());
            } else {
                row.ratingCV.setVisibility(View.GONE);
            }
            if (_fragment != null) {
                row.cName.setTextColor(_fragment.getResources().getColor(R.color.text_color_level));
            }
            if (!ccArray.get(position).getRating().isEmpty() && Double.parseDouble(ccArray.get(position).getRating()) > 0) {
                row.ratingCV.setCardBackgroundColor((Double.parseDouble(ccArray.get(position).getRating()) >= 2.5 || Double.parseDouble(ccArray.get(position).getRating()) <= 3.9) ? _fragment.getResources().getColor(R.color.yellow) : Double.parseDouble(ccArray.get(position).getRating()) < 2.5 ? _fragment.getResources().getColor(R.color.red) : _fragment.getResources().getColor(R.color.green));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onBindViewPurchasedOrderDataRendering(RecyclerView.ViewHolder holder, int position) {
        final PurchasedOrderHolder row = (PurchasedOrderHolder) holder;
        final ProductModel productModel = productArray.get(position);
//        row.productName.setText(productModel.getProductName());
        if (productModel.getProductpacking() != null && !productModel.getProductpacking().isEmpty()) {
            final SpannableString text = new SpannableString(productModel.getProductName() + ", " + productModel.getProductpacking());
            text.setSpan(new RelativeSizeSpan(0.8f), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            text.setSpan(new ForegroundColorSpan(newOrderContext.getResources().getColor(R.color.title_color_primary)), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            row.productName.setText(text);
        } else {
            row.productName.setText(productModel.getProductName());
        }
        row.productName.setTextColor(((OrderDetailsFragment) fragment).getSecondHeaderTextColor());
        row.productName.setVisibility(productModel.getProductName().isEmpty() ? View.GONE : View.VISIBLE);
        row.productCompanyName.setText(productModel.getProductMfgComp());
        row.tvPriceValue.setText(((OrderDetailsFragment) fragment).getLicDetails().getCurrency() + productModel.getProductRateA());
        row.tvPriceValue.setTextColor(((OrderDetailsFragment) fragment).getSecondHeaderTextColor());
        row.productSalt.setText(productModel.getProductSalt());
        row.productSalt.setTextColor(((OrderDetailsFragment) fragment).getThirdHeaderColor());
        row.productSalt.setVisibility(productModel.getProductSalt().isEmpty() ? View.GONE : View.VISIBLE);
        row.tvValueAmount.setText(((OrderDetailsFragment) fragment).getLicDetails().getCurrency() + productModel.getAmt());
        row.tvValueAmount.setTextColor(((OrderDetailsFragment) fragment).getSecondHeaderTextColor());
        String orderQty = String.valueOf((Double.parseDouble(productModel.getProductDQty()) + Double.parseDouble(productModel.getFQty())));
        row.tvQuantityProduct.setText( ReckonUtils.roundTwoDecimals(orderQty) + " Unit");
        row.tvInvQty.setText(productModel.getInvoiceQty() + " Unit");
        row.tvBalQty.setText(productModel.getBalanceQty() + " Unit");


    }

    private void onBindViewCartDataRendering(RecyclerView.ViewHolder holder, int position) {
        final CartViewHolder row = (CartViewHolder) holder;
        final ProductModel productModel = productArray.get(position);
        if (position == productArray.size() - 1)
            row.constraintLayoutCart.setLayoutParams(setDynamicMargin(0, 0, 0, 20));
        row.productName.setTextColor(cartFragment.getSecondHeaderTextColor());
        row.tvProductScheme.setTextColor(cartFragment.getThirdHeaderColor());
        row.tvMRPValue.setTextColor(cartFragment.getSecondHeaderTextColor());
        row.tvPriceValue.setTextColor(cartFragment.getSecondHeaderTextColor());
        row.productValueTotal.setTextColor(cartFragment.getSecondHeaderTextColor());
        row.tvValueAmount.setTextColor(cartFragment.getThirdHeaderColor());
//        row.productName.setText(productModel.getProductName());
        if (productModel.getProductpacking() != null && !productModel.getProductpacking().isEmpty()) {
            final SpannableString text = new SpannableString(productModel.getProductName() + ", " + productModel.getProductpacking());
            text.setSpan(new RelativeSizeSpan(0.8f), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            text.setSpan(new ForegroundColorSpan(newOrderContext.getResources().getColor(R.color.title_color_primary)), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            row.productName.setText(text);
        } else {
            row.productName.setText(productModel.getProductName());
        }
        String currencySign = cartFragment.getLicDetails().getCurrency();

        row.tvProductScheme.setText(productModel.getScheme());
        row.tvProductScheme.setVisibility(productModel.getScheme() != null && !productModel.getScheme().isEmpty() ? View.VISIBLE : View.GONE);
        row.tvProductPacking.setText(productModel.getProductpacking());
        row.tvProductPacking.setVisibility(productModel.getProductpacking() != null && !productModel.getProductpacking().isEmpty() ? View.VISIBLE : View.GONE);
        if (SharedPrefUtils.getShowItemRefNo(cartFragment.requireActivity()) && ReckonUtils.nonNullNotEmptyString(productModel.getRefNumber())) {
            row.tvProductRefId.setText(productModel.getRefNumber());
            row.tvProductRefId.setVisibility(View.VISIBLE);
        } else {
            row.tvProductRefId.setVisibility(View.GONE);
        }
  /*      if (row.tvProductScheme.getVisibility() == View.GONE && row.tvProductPacking.getVisibility() == View.GONE)
            row.schemeLL.setVisibility(View.GONE);*/
        row.productCompanyName.setText(productModel.getProductMfgComp());
        row.tvMRPValue.setText(productModel.getProductMrp());
        row.productSalt.setVisibility(productModel.getProductMrp().isEmpty() ? View.GONE : View.VISIBLE);
        row.tvPriceValue.setText(currencySign + productModel.getProductRateA());
        row.productSalt.setText(productModel.getProductSalt());
        row.productSalt.setVisibility(productModel.getProductSalt().isEmpty() ? View.GONE : View.VISIBLE);
        row.tvQuantityProduct.setText(String.valueOf(productModel.getProductCount()));
//        row.schemeValueTotal.setText(currencySign + productModel.getSchemeAmt());
      /*  if (productModel.getSchemeAmt() == null || productModel.getSchemeAmt().isEmpty() || productModel.getSchemeAmt().equalsIgnoreCase("0.0")) {
            row.schemeValueTotal.setVisibility(View.GONE);
        } else {
            row.schemeValueTotal.setVisibility(View.VISIBLE);
        }*/
        if (productModel.isStockExist()) {
            row.cvOutOfStock.setVisibility(View.GONE);
            row.qtyPickerCV.setVisibility(View.VISIBLE);
            row.productAndScheme.setVisibility(View.VISIBLE);
            row.cardAddProduct.setCardBackgroundColor(cartFragment.getResources().getColor(R.color.white));
        } else {
            row.cvOutOfStock.setVisibility(View.VISIBLE);
            row.qtyPickerCV.setVisibility(View.GONE);
            row.productAndScheme.setVisibility(View.GONE);
            row.cardAddProduct.setCardBackgroundColor(cartFragment.getResources().getColor(R.color.new_light_grey));
        }
        if (!isTextEnterOn) {
            row.tvQuantityProduct.setInputType(InputType.TYPE_NULL);
            row.addEnteredValue.setVisibility(View.GONE);
        } else {
            row.tvQuantityProduct.setInputType(InputType.TYPE_CLASS_NUMBER);
            row.addEnteredValue.setVisibility(View.VISIBLE);
            row.addEnteredValue.setEnabled(false);
            row.addEnteredValue.setBackgroundColor(cartFragment.getResources().getColor(R.color.grey));
        }
   /*         row.productSpecifiedName.setText(productModel.getProductSalt());
            row.productSpecifiedName.setVisibility(!productModel.getProductSalt().isEmpty()?View.VISIBLE:View.GONE);*/
//            for (int i = 0; i < productArray.size(); i++)
//            if (cartFragment.isKeyBoardOpen && position == 0) {
//                row.tv_packing.setEnabled(true);
//                row.tv_packing.requestFocus();
        //           }
        addItemToCart = new ArrayList<>();
        try {
            for (int i = 0; i < productModel.getQuantityList().length(); i++) {
                addItemToCart.add(Integer.parseInt(productModel.getQuantityList().get(i).toString()));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(cartFragment.requireActivity())) {
            row.llQtyUpdateRow.setVisibility(View.VISIBLE);
            row.directQtyUpdateLL.setVisibility(View.GONE);
            row.tvAddedQty.setText(String.valueOf(productModel.getProductCount()));

            row.finalValuesLL.setVisibility(View.VISIBLE);

            if (ReckonUtils.nonNullNotEmptyString(productModel.getDisc2PerCart()) || ReckonUtils.nonNullNotEmptyString(productModel.getDiscPerCart()) || ReckonUtils.nonNullNotEmptyString(productModel.getDisc1PerCart())) {
                row.discountSectionLL.setVisibility(View.VISIBLE);
                if (ReckonUtils.nonNullNotEmptyString(productModel.getDisc2PerCart())) {
                    row.tvDisPcs.setText(productModel.getDisc2PerCart());
                }
                if (ReckonUtils.nonNullNotEmptyString(productModel.getDiscPerCart())) {
                    row.tvDisPer.setText(productModel.getDiscPerCart());
                }
                if (ReckonUtils.nonNullNotEmptyString(productModel.getDisc1PerCart())) {
                    row.tvAddDisPer.setText(productModel.getDisc1PerCart());
                }
                String discPcsAmt = "(" + currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDisc2AmtCart()) ? productModel.getDisc2AmtCart() : "0.0") + ")";
                String discPerAmt = "(" + currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDiscAmtCart()) ? productModel.getDiscAmtCart() : "0.0") + ")";
                String addDiscPerAmt = "(" + currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDisc1AmtCart()) ? productModel.getDisc1AmtCart() : "0.0") + ")";
                row.disPcsAmtTv.setText(discPcsAmt);
                row.disPerAmtTv.setText(discPerAmt);
                row.disAddAmtTv.setText(addDiscPerAmt);
            } else {
                row.discountSectionLL.setVisibility(View.GONE);

            }
            if (ReckonUtils.nonNullNotEmptyString(productModel.getDFQTYCart())) {
                row.fQtyTvLL.setVisibility(View.VISIBLE);
                row.tvAddedFQty.setText(String.valueOf(productModel.getDFQTYCart()));
            } else {
                row.fQtyTvLL.setVisibility(View.GONE);
            }
            row.productValueTotal.setText(currencySign + String.valueOf(new DecimalFormat("##.##").format(Double.parseDouble(productModel.getNetAmtCart().isEmpty() ? "0.0" : productModel.getNetAmtCart()))));
            row.tvValueAmount.setText(currencySign + productModel.getAmt());
            row.cvUpdateCartBtn.setOnClickListener(v -> {
                if (ReckonUtils.nonNullNotEmptyString(row.tvAddedQty.getText().toString())) {
                  /*  if(Objects.requireNonNull(productModel).getIsStockistActive() == 0){
                        Toast.makeText(cartFragment.requireActivity(), cartFragment.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                    }else{*/
                    if (productModel.getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                        Toast.makeText(cartFragment.getActivity(), "Under Development!!!", Toast.LENGTH_SHORT).show();
                    } else {
                        openOptionQtyBottomSheet = true;
                        openAddQtyBottomSheet(row, position, productModel, cartFragment);
                    }
//                    }
            /*        new Handler().postDelayed(() -> {
                        productModel.setProductCount(Integer.parseInt(row.tvQuantityProduct.getText().toString()));
                        UpdatingCartItems(position, productModel);
                        selected_pos = position;
                        AddProductInCart(productModel);
                        row.addEnteredValue.setEnabled(false);
                        row.addEnteredValue.setBackgroundColor(cartFragment.getResources().getColor(R.color.grey));
                    }, 50);*/
                } else {
                    Toast.makeText(cartFragment.getActivity(), "Please enter quantity first.", Toast.LENGTH_LONG).show();
                }
            });

        } else {
            row.tvValueAmount.setText(currencySign + productModel.getAmt());
            row.productValueTotal.setText(currencySign + String.valueOf(new DecimalFormat("##.##").format(Double.parseDouble(productModel.getNetAmtCart().isEmpty() ? "0.0" : productModel.getNetAmtCart()))));
            row.llQtyUpdateRow.setVisibility(View.GONE);
            row.directQtyUpdateLL.setVisibility(View.VISIBLE);
            row.discountSectionLL.setVisibility(View.GONE);
            row.finalValuesLL.setVisibility(View.VISIBLE);
        }
        String goodsValue = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getAmt()) ? productModel.getAmt() : "0.0");
        row.tvGoodsValue.setText(goodsValue);
        String schemeValue = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getItemSchAmtCart()) ? productModel.getItemSchAmtCart() : "0.0");
        row.schemeValueTotal.setText(schemeValue);
        String totalDiscount = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getTotalDiscCart()) ? productModel.getTotalDiscCart() : "0.0");
        row.tvDiscValue.setText(totalDiscount);
        String gstAmount = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getTaxAmtCart()) ? productModel.getTaxAmtCart() : "0.0");
        row.tvGstValue.setText(gstAmount);

        row.removeButton.setOnClickListener(v -> RemoveCartItemPopUp(productModel, position));
        row.tvQuantityProduct.setOnClickListener(v -> {
            if (!isTextEnterOn)
                setUpListPopUpWindow(cartFragment, row.cardQuantity, productModel, position, row.tvQuantityProduct, addItemToCart);
        });
//
//        row.qtyLL.setOnClickListener(v -> {
////                setUpListPopUpWindow(cartFragment, row.cardQuantity, productModel, position, row.tvQuantityProduct, addItemToCart);
////                qty = new int[]{Integer.parseInt(row.tvQuantityProduct.getText().toString())};
////                AddProductInCart(productModel);
//        });

        row.addEnteredValue.setOnClickListener(v -> {
            if (!row.tvQuantityProduct.getText().toString().isEmpty() && Integer.parseInt(row.tvQuantityProduct.getText().toString()) != 0) {
                new Handler().postDelayed(() -> {
                    productModel.setProductCount(row.tvQuantityProduct.getText().toString());
                    UpdatingCartItems(position, productModel);
                    selected_pos = position;
                    AddProductInCart(productModel, null, true);
                    row.addEnteredValue.setEnabled(false);
                    row.addEnteredValue.setBackgroundColor(cartFragment.getResources().getColor(R.color.grey));
                }, 50);
            } else
                Toast.makeText(cartFragment.getActivity(), "Please enter quantity first.", Toast.LENGTH_LONG).show();

        });
        row.tvQuantityProduct.setOnTouchListener((v, event) -> {
            onQtyEdtTextClicked = true;
//            row.tvQuantityProduct.setSelection(row.tvQuantityProduct.getText().length());
            return false;
        });
        row.tvQuantityProduct.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (onQtyEdtTextClicked) {
                    productArray.get(position).setProductCount(!s.toString().isEmpty() ? s.toString() : "0");
                    if (!productArray.get(position).getProductCount().equalsIgnoreCase(productArray.get(position).getProductDQty())) {
                        row.addEnteredValue.setEnabled(true);
                        row.addEnteredValue.setBackgroundColor(cartFragment.getThirdHeaderColor());
                    } else {
                        row.addEnteredValue.setEnabled(false);
                        row.addEnteredValue.setBackgroundColor(cartFragment.getResources().getColor(R.color.grey));
                    }
                }

            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
    }

    private void openAddQtyBottomSheet(CartViewHolder holder, int position, ProductModel productModel, CartFragment fragment) {
        dialog = new BottomSheetDialog(fragment.requireActivity());
        Window window = dialog.getWindow();
        window.setBackgroundDrawableResource(android.R.color.transparent);
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
        WindowManager.LayoutParams lp = window.getAttributes();
        lp.alpha = 1.0f;
        lp.dimAmount = 0.0f;
        window.setAttributes(lp);

        dialog.setContentView(R.layout.add_custom_qty_bottomsheet);
        dialog.setCancelable(false);
        dialog.findViewById(R.id.cvClose).setOnClickListener(view1 -> dialog.dismiss());

        TextView tvProductRefId = dialog.findViewById(R.id.tvProductRefId);
        TextView medicineName = dialog.findViewById(R.id.medicineName);
        TextView tvMRPValue = dialog.findViewById(R.id.tvMRPValue);
        TextView tvRate = dialog.findViewById(R.id.tvRate);
        TextView tvGST = dialog.findViewById(R.id.tvGST);
        TextView tvProductScheme = dialog.findViewById(R.id.tvProductScheme);
        TextView tvStockIn = dialog.findViewById(R.id.tvStockIn);
        LinearLayout llFQuantity = dialog.findViewById(R.id.llFQuantity);
        LinearLayout llManualScheme = dialog.findViewById(R.id.llManualScheme);
        LinearLayout llDiscountPer = dialog.findViewById(R.id.llDiscountPer);
        LinearLayout llDiscountPcs = dialog.findViewById(R.id.llDiscountPcs);
        LinearLayout llAddRemark = dialog.findViewById(R.id.llAddRemark);
        LinearLayout llScheme = dialog.findViewById(R.id.llScheme);
        LinearLayout llDiscount = dialog.findViewById(R.id.llDiscount);
        LinearLayout llQuantity = dialog.findViewById(R.id.llQuantity);
        LinearLayout llFQty = dialog.findViewById(R.id.llFQty);
        LinearLayout llAddDiscountPer = dialog.findViewById(R.id.llAddDiscountPer);

        ImageView decreaseQtyImv = dialog.findViewById(R.id.decreaseQtyImv);
        ImageView increaseQtyImv = dialog.findViewById(R.id.increaseQtyImv);
        ImageView decreaseFQty = dialog.findViewById(R.id.decreaseFQty);
        ImageView increaseFQty = dialog.findViewById(R.id.increaseFQty);
        EditText qtyEdt = dialog.findViewById(R.id.qtyEdt);
        qtyEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilter(5, 2)});
        qtyEdt.setFocusable(true);
        qtyEdt.requestFocus();
        qtyEdt.setSelection(qtyEdt.getText().length());
        EditText fQtyEdt = dialog.findViewById(R.id.fQtyEdt);
        EditText edtScheme = dialog.findViewById(R.id.edtScheme);
        ReckonUtils.enterNumbersOnly(edtScheme, 3);
        EditText edtDScheme = dialog.findViewById(R.id.edtDScheme);
        ReckonUtils.enterNumbersOnly(edtDScheme, 3);

        EditText priceEdt = dialog.findViewById(R.id.priceEdt);
        discEdt = dialog.findViewById(R.id.discEdt);
        discEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilters(2, 2)});
        EditText discPcsEdt = dialog.findViewById(R.id.discPcsEdt);
        discPcsEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilters(4, 2)});
        priceEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilter(5, 2)});

        EditText discAddEdt = dialog.findViewById(R.id.discAddEdt);
        discAddEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilters(2, 2)});

        EditText remarkEdt = dialog.findViewById(R.id.remarkEdt);
        tvGstTitle = dialog.findViewById(R.id.tvGstTitle);
        TextView tvDescription = dialog.findViewById(R.id.tvDescription);

        tvGoodsValue = dialog.findViewById(R.id.tvGoodsValue);
        tvSchemeValue = dialog.findViewById(R.id.tvSchemeValue);
        tvDiscValue = dialog.findViewById(R.id.tvDiscValue);
        tvGstValue = dialog.findViewById(R.id.tvGstValue);
        tvNetValue = dialog.findViewById(R.id.tvNetValue);
        disPcsAmtTv = dialog.findViewById(R.id.disPcsAmtTv);
        disPerAmtTv = dialog.findViewById(R.id.disPerAmtTv);
        disAddAmtTv = dialog.findViewById(R.id.disAddAmtTv);
        showQtyErrorMsgTv = dialog.findViewById(R.id.showQtyErrorMsgTv);
        autoUpdateQty = false;
        if (ReckonUtils.nonNullNotEmptyString(productModel.getDescription())) {
            tvDescription.setText(productModel.getDescription());
        } else {
            tvDescription.setVisibility(View.GONE);
        }
        String currencySign = fragment.getLicDetails().getCurrency();
        if (ReckonUtils.nonNullNotEmptyString(String.valueOf(productModel.getProductCount()))) {
            qtyEdt.setText(String.valueOf(productModel.getProductCount()));
        }
        if (ReckonUtils.nonNullNotEmptyString(productModel.getDFQTYCart())) {
            fQtyEdt.setText(productModel.getDFQTYCart());
        }
        fQtyEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilter(5, 2)});
        if (ReckonUtils.nonNullNotEmptyString(productModel.getDiscPerCart())) {
            discEdt.setText(productModel.getDiscPerCart());
        }
        if (ReckonUtils.nonNullNotEmptyString(productModel.getDisc2PerCart())) {
            discPcsEdt.setText(productModel.getDisc2PerCart());
        }
        if (ReckonUtils.nonNullNotEmptyString(productModel.getDisc1PerCart())) {
            discAddEdt.setText(productModel.getDisc1PerCart());
        }
        if (ReckonUtils.nonNullNotEmptyString(productModel.getDoRemarkCart())) {
            remarkEdt.setText(productModel.getDoRemarkCart());
        }

        String goodsValue = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getAmt()) ? productModel.getAmt() : "0.0");
        tvGoodsValue.setText(goodsValue);
        String schemeValue = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getItemSchAmtCart()) ? productModel.getItemSchAmtCart() : "0.0");
        tvSchemeValue.setText(schemeValue);
        String totalDiscount = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getTotalDiscCart()) ? productModel.getTotalDiscCart() : "0.0");
        tvDiscValue.setText(totalDiscount);
        String gstAmount = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getTaxAmtCart()) ? productModel.getTaxAmtCart() : "0.0");
        tvGstValue.setText(gstAmount);
        tvGstTitle.setText(ReckonUtils.nonNullNotEmptyString(productModel.getTaxAmtCart()) ? "GST % (Exclusive)" : "GST % (Inclusive)");
        String netValue = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getNetAmtCart()) ? productModel.getNetAmtCart() : "0.0");
        tvNetValue.setText(netValue);

        String discPcsAmt = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDisc2AmtCart()) ? productModel.getDisc2AmtCart() : "0.0");
        String discPerAmt = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDiscAmtCart()) ? productModel.getDiscAmtCart() : "0.0");
        String addDiscPerAmt = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDisc1AmtCart()) ? productModel.getDisc1AmtCart() : "0.0");
        disPcsAmtTv.setText(discPcsAmt);
        disPerAmtTv.setText(discPerAmt);
        disAddAmtTv.setText(addDiscPerAmt);

        if (SharedPrefUtils.getShowItemRefNo(fragment.requireActivity()) && ReckonUtils.nonNullNotEmptyString(productModel.getRefNumber())) {
            tvProductRefId.setText(productModel.getRefNumber());
            tvProductRefId.setVisibility(View.VISIBLE);
        } else {
            tvProductRefId.setVisibility(View.GONE);
        }
        llFQuantity.setVisibility(SharedPrefUtils.getShowFreeQty(fragment.requireActivity()) ? View.VISIBLE : View.GONE);
        if (!SharedPrefUtils.getShowIncreaseDecreaseBtn(fragment.requireActivity())) {
            decreaseQtyImv.setVisibility(View.GONE);
            increaseQtyImv.setVisibility(View.GONE);
            decreaseFQty.setVisibility(View.GONE);
            increaseFQty.setVisibility(View.GONE);
        } else {
       /*     LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.MATCH_PARENT);
            params.weight = 1.0f;
            params.gravity = Gravity.END;
            llQuantity.setLayoutParams(params);
            llFQty.setLayoutParams(params);

//            llQuantity.setGravity(Gravity.END);
//            llFQty.setGravity(Gravity.END);*/
        }
        if (!SharedPrefUtils.getShowManualScheme(fragment.requireActivity())) {
            llManualScheme.setVisibility(View.GONE);
        } else {
            if (ReckonUtils.nonNullNotEmptyString(productModel.getSchQty())) {
                edtScheme.setText(productModel.getSchQty().replace(".0", ""));
            }
            if (ReckonUtils.nonNullNotEmptyString(productModel.getDSchQty())) {
                edtDScheme.setText(productModel.getDSchQty().replace(".0", ""));
            }
        }
        String priceValue = /*fragment.getLicDetails().getCurrency() + */productModel.getProductRateA();
        priceEdt.setText(ReckonUtils.nonNullNotEmptyString(priceValue) ? priceValue : "");
        if (!SharedPrefUtils.getShowEnablePriceEdt(fragment.requireActivity())) {
            priceEdt.setEnabled(false);
        } else {
            priceEdt.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                }

                @Override
                public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                    callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);

                }

                @Override
                public void afterTextChanged(Editable editable) {

                }
            });
        }


        if (!SharedPrefUtils.getShowDiscountPer(fragment.requireActivity())) {
            llDiscountPer.setVisibility(View.GONE);
        }
        if (!SharedPrefUtils.getShowDiscountPcs(fragment.requireActivity())) {
            llDiscountPcs.setVisibility(View.GONE);
        }
        if (!SharedPrefUtils.getShowItemRemark(fragment.requireActivity())) {
            llAddRemark.setVisibility(View.GONE);
        }

        if (!SharedPrefUtils.getShowScheme(fragment.requireActivity())) {
            llScheme.setVisibility(View.GONE);
        }
        if (!SharedPrefUtils.getShowAddDiscountPer(fragment.requireActivity())) {
            llAddDiscountPer.setVisibility(View.GONE);
        }

      /*  if (productModel.isShowStock()) {
            setStockWithValueView(holder, productModel, tvStockIn, true);
        } else {
            setStockView(holder, productModel, tvStockIn, true);
        }*/

        setProductPricesValue(tvRate, tvMRPValue, tvGST, tvProductScheme, productModel);
        setProductNameRichText(medicineName, productModel);
        discEdt.setOnTouchListener((view, motionEvent) -> {
            autoUpdateQty = false;
            return false;
        });
        qtyEdt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
            }

            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
            }

            @Override
            public void afterTextChanged(Editable editable) {

            }
        });
        fQtyEdt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
            }

            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
            }

            @Override
            public void afterTextChanged(Editable editable) {

            }
        });
        editTextWatcher(edtScheme, qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        editTextWatcher(edtDScheme, qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        editTextWatcher(discPcsEdt, qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        editTextWatcher(discEdt, qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        editTextWatcher(discAddEdt, qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        dialog.findViewById(R.id.cvAddToCart).setOnClickListener(view1 -> {
            if (!isSalesMan && productModel.getIsStockistActive() == 0) {
                Toast.makeText(fragment.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
            } else {
                if (ReckonUtils.nonNullNotEmptyString(qtyEdt.getText().toString())) {
                    productArray.get(position).setProductCount(qtyEdt.getText().toString());
                    productModel.setProductCount(qtyEdt.getText().toString());
                    UpdatingCartItems(position, productArray.get(position));
                    selected_pos = position;
                    callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, true);
                    holder.addEnteredValue.setEnabled(false);
//                    setConstantBundle(productArray.get(position), fragment);
                    holder.addEnteredValue.setCardBackgroundColor(fragment.getResources().getColor(R.color.grey));
                }
            }
        });
        dialog.getBehavior().setState(BottomSheetBehavior.STATE_EXPANDED);
        dialog.show();
    }

    private void editTextWatcher(EditText editText, EditText qtyEdt, EditText fQtyEdt, EditText edtScheme, EditText edtDScheme, EditText priceEdt, EditText discEdt, EditText discPcsEdt, EditText discAddEdt, EditText remarkEdt, int position) {
        editText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
            }

            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                if (editText==discEdt){
                    if(!autoUpdateQty){
                        debouncer.debounce(Void.class, new Runnable() {
                            @Override public void run() {
                                callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
                            }
                        }, 3000, TimeUnit.MILLISECONDS);
                    }
                }else{
                    callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
                } }

            @Override
            public void afterTextChanged(Editable editable) {

            }
        });
    }

    private void setProductPricesValue(TextView tvRate, TextView tvMRPValue, TextView tvGST, TextView tvProductScheme, ProductModel productModel) {
        tvRate.setText(String.valueOf(cartFragment.getLicDetails().getCurrency() + productModel.getProductRateA()));
        tvRate.setVisibility(productModel.isShowRate() && productModel.getProductRateA() != null && !productModel.getProductRateA().isEmpty() ? View.VISIBLE : View.GONE);
        tvMRPValue.setText(String.valueOf("(MRP " + productModel.getProductMrp() + ")"));
        tvMRPValue.setVisibility(productModel.isShowMrp() && productModel.getProductMrp() != null && !productModel.getProductMrp().isEmpty() ? View.VISIBLE : View.GONE);
        tvGST.setText(String.valueOf("(GST " + productModel.getTax() + "%" + ")"));
        tvGST.setVisibility(productModel.isShowRate() && productModel.getProductRateA() != null && !productModel.getProductRateA().isEmpty() ? View.VISIBLE : View.GONE);

        tvProductScheme.setText("(" + productModel.getScheme() + ")");
        tvProductScheme.setVisibility(productModel.isShowScheme() && productModel.getScheme() != null && !productModel.getScheme().isEmpty() ? View.VISIBLE : View.GONE);
    }

    private void setProductNameRichText(TextView textView, ProductModel productModel) {
        textView.setTextColor(cartFragment.getResources().getColor(R.color.text_color_level));
        if (productModel.getProductpacking() != null && !productModel.getProductpacking().isEmpty()) {
            final SpannableString text = new SpannableString(productModel.getProductName() + ", " + productModel.getProductpacking());
            text.setSpan(new RelativeSizeSpan(0.8f), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            text.setSpan(new ForegroundColorSpan(cartFragment.getResources().getColor(R.color.title_color_primary)), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            textView.setText(text);
        } else {
            textView.setText(productModel.getProductName());
        }
    }

    private void callAddDraftOrderAPI(EditText qtyEdt, EditText fQtyEdt, EditText edtScheme, EditText edtDScheme, EditText priceEdt, EditText discEdt, EditText discPcsEdt, EditText discAddEdt, EditText remarkEdt, int position, boolean insertRecord) {
        try {
            JSONObject extendedObj = new JSONObject();
            extendedObj.put("ItemQty", ReckonUtils.nonNullNotEmptyString(qtyEdt.getText().toString()) ? qtyEdt.getText().toString().trim() : "0");
            extendedObj.put("ItemFQty", ReckonUtils.nonNullNotEmptyString(fQtyEdt.getText().toString()) ? fQtyEdt.getText().toString().trim() : "0");
            extendedObj.put("ItemSchQty", Integer.parseInt(ReckonUtils.nonNullNotEmptyString(edtScheme.getText().toString()) ? edtScheme.getText().toString().trim() : "0"));
            extendedObj.put("ItemDSchQty", Integer.parseInt(ReckonUtils.nonNullNotEmptyString(edtDScheme.getText().toString()) ? edtDScheme.getText().toString().trim() : "0"));
//            extendedObj.put("ItemAmt", Integer.parseInt(ReckonUtils.nonNullNotEmptyString(qtyEdt.getText().toString())? qtyEdt.getText().toString().trim():"0") * Double.parseDouble(ReckonUtils.nonNullNotEmptyString(priceEdt.getText().toString())? priceEdt.getText().toString().trim():"0"));
            extendedObj.put("discount_percentage", discEdt.getText().toString().trim());
            extendedObj.put("discount_pcs", discPcsEdt.getText().toString().trim());
            extendedObj.put("discount_percentage1", discAddEdt.getText().toString().trim());
            extendedObj.put("remark", remarkEdt.getText().toString());
            extendedObj.put("ItemRate", ReckonUtils.nonNullNotEmptyString(priceEdt.getText().toString()) ? priceEdt.getText().toString().trim() : "0");
            AddProductInCart(productArray.get(position), extendedObj, insertRecord);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onBindViewNewOrderDataRendering(RecyclerView.ViewHolder holder, int position) {
        if (Constant.bundle != null) {
            id = Constant.bundle.getString("id") != null ? Constant.bundle.getString("id") : "";
            productCountList = gson.fromJson(Constant.bundle.getString("ProductList"), new TypeToken<ArrayList<AddToCartModel>>() {
            }.getType());
        }
        if (productCountList != null && productCountList.size() != 0) {
            for (AddToCartModel cartModel : productCountList) {
                if (cartModel.getId() == productArray.get(position).getProductIdCol()) {
                    productArray.get(position).setProductCount(String.valueOf(cartModel.getItemCount()));
                }
            }
        }
        final ProductModel productModel = productArray.get(position);
        gson = new Gson();
        holder.setIsRecyclable(false);
        ((OrderViewHolder) holder).plus_icon.setColorFilter(newOrderContext.getSecondHeaderTextColor());
        ((OrderViewHolder) holder).minus_icon.setColorFilter(newOrderContext.getSecondHeaderTextColor());
        // ((OrderViewHolder) holder).addEnteredValue.setCardBackgroundColor(newOrderContext.getThirdHeaderColor());
        ((OrderViewHolder) holder).tvProductName.setTextColor(newOrderContext.getSecondHeaderTextColor());
        ((OrderViewHolder) holder).tvProductScheme.setTextColor(newOrderContext.getThirdHeaderColor());
        ((OrderViewHolder) holder).tvMRPValue.setTextColor(newOrderContext.getSecondHeaderTextColor());
        ((OrderViewHolder) holder).tvRate.setTextColor(newOrderContext.getSecondHeaderTextColor());
        ((OrderViewHolder) holder).tvSeeSimilar.setTextColor(newOrderContext.getSecondHeaderTextColor());
        ((OrderViewHolder) holder).productValueTotal.setTextColor(newOrderContext.getSecondHeaderTextColor());
        setUpTheme();
        try {
            if (!isTextEnterOn) {
                ((OrderViewHolder) holder).itemCount.setInputType(InputType.TYPE_NULL);
                ((OrderViewHolder) holder).addEnteredValue.setVisibility(View.GONE);
            } else {
                ((OrderViewHolder) holder).itemCount.setInputType(InputType.TYPE_CLASS_NUMBER);
                ((OrderViewHolder) holder).addEnteredValue.setVisibility(View.VISIBLE);
                ((OrderViewHolder) holder).addEnteredValue.setEnabled(false);
                ((OrderViewHolder) holder).addEnteredValue.setBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
            }
            if (position == productArray.size() - 1)
                ((OrderViewHolder) holder).constraintLayoutNewOrder.setLayoutParams(setDynamicMargin(0, 0, 0, 20));
            if (productModel != null) {
                ((OrderViewHolder) holder).tvProductName.setText(productModel.getProductName());
                ((OrderViewHolder) holder).tvRate.setText(newOrderContext.getLicDetails().getCurrency() + productModel.getProductRate());
                ((OrderViewHolder) holder).tvInclusiveGST.setText("(Exclusive GST " + productModel.getTax() + "%" + ")");
                ((OrderViewHolder) holder).tv_product_by.setText(productModel.getProductMfgComp());
                ((OrderViewHolder) holder).tvMRPValue.setText(newOrderContext.getLicDetails().getCurrency() + productModel.getProductMrp());
                //((OrderViewHolder) holder).tv_salt.setText(productModel.getProductSalt());
                ((OrderViewHolder) holder).tvProductScheme.setText(productModel.getScheme());
                ((OrderViewHolder) holder).tvProductScheme.setVisibility(productModel.getScheme() != null && !productModel.getScheme().isEmpty() ? View.VISIBLE : View.GONE);
                ((OrderViewHolder) holder).tvProductPacking.setText(productModel.getProductpacking());
                ((OrderViewHolder) holder).tvProductPacking.setVisibility(productModel.getProductpacking() != null && !productModel.getProductpacking().isEmpty() ? View.VISIBLE : View.GONE);
                ((OrderViewHolder) holder).productSalt.setText(productModel.getProductSalt());
                ((OrderViewHolder) holder).productSalt.setVisibility(!productModel.getProductSalt().isEmpty() ? View.VISIBLE : View.GONE);
                Double discount = Double.parseDouble(productModel.getProductRate()) / Double.parseDouble(productModel.getProductMrp());
                int disc = (int) (100 - (discount * 100));
                ((OrderViewHolder) holder).tvDiscountValue.setText(disc + "%");
                if (productModel.getSCName().isEmpty()) {
                    ((OrderViewHolder) holder).cardHolderSalt.setVisibility(View.GONE);
                } else
                    ((OrderViewHolder) holder).tvSalt.setText(productModel.getSCName());

                switch (productModel.getProductStockType()) {
                    case "INSTOCK":
                        ((OrderViewHolder) holder).addToCart.setText(newOrderContext.getString(R.string.addToCart));
                        ((OrderViewHolder) holder).cvAddToCart.setCardBackgroundColor(newOrderContext.getThirdHeaderColor());
                        ((OrderViewHolder) holder).tvStockIn.setText(isSalesMan ? "Stock: " + productModel.getProductStock() + " Pcs" : newOrderContext.getString(R.string.in_stock));
                        ((OrderViewHolder) holder).tvStockIn.setTextColor(/*newOrderContext.getThirdHeaderColor()*/newOrderContext.getResources().getColor(R.color.green));
                        break;
                    case "OUTSTOCK":
                        ((OrderViewHolder) holder).tvStockIn.setText(isSalesMan ? "Stock: " + productModel.getProductStock() + " Pcs" : newOrderContext.getString(R.string.out_of_stock));
                        ((OrderViewHolder) holder).addToCart.setText(newOrderContext.getString(R.string.notify_me));
                        ((OrderViewHolder) holder).cvAddToCart.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.text_color_level));
                        break;
                    case "LOWSTOCK":
                        ((OrderViewHolder) holder).addToCart.setText(newOrderContext.getString(R.string.addToCart));
                        ((OrderViewHolder) holder).tvStockIn.setText(isSalesMan ? "Stock: " + productModel.getProductStock() + " Pcs" : newOrderContext.getString(R.string.low_stock));
                        ((OrderViewHolder) holder).tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.yellow));
                        ((OrderViewHolder) holder).cvAddToCart.setCardBackgroundColor(newOrderContext.getThirdHeaderColor());
                        break;
                }

                if (Double.parseDouble(productModel.getProductCount()) > 0) {
                    ((OrderViewHolder) holder).itemCount.setText(String.valueOf(productModel.getProductCount()));
                    ((OrderViewHolder) holder).cvAddToCart.setVisibility(View.GONE);
                    ((OrderViewHolder) holder).qty_ll.setVisibility(View.VISIBLE);
                    ((OrderViewHolder) holder).productAndScheme.setVisibility(View.VISIBLE);
                    ((OrderViewHolder) holder).tvSeeSimilar.setVisibility(View.GONE);
                    ((OrderViewHolder) holder).schemeValueTotal.setText(newOrderContext.getLicDetails().getCurrency() + productModel.getSchemeAmt());
                    if (productModel.getSchemeAmt() == null || productModel.getSchemeAmt().isEmpty() || productModel.getSchemeAmt().equalsIgnoreCase("0.0")) {
                        ((OrderViewHolder) holder).schemeValueTv.setVisibility(View.GONE);
                        ((OrderViewHolder) holder).schemeValueTotal.setVisibility(View.GONE);
                    } else {
                        ((OrderViewHolder) holder).schemeValueTv.setVisibility(View.VISIBLE);
                        ((OrderViewHolder) holder).schemeValueTotal.setVisibility(View.VISIBLE);
                    }
                    ((OrderViewHolder) holder).productValueTotal.setText(newOrderContext.getLicDetails().getCurrency() + String.valueOf(new DecimalFormat("##.##").format(Double.parseDouble(productModel.getAmt().isEmpty() ? "0.0" : productModel.getAmt()))));
                } else {
                    ((OrderViewHolder) holder).productAndScheme.setVisibility(View.GONE);
                    ((OrderViewHolder) holder).tvSeeSimilar.setVisibility(View.VISIBLE);
                }
            }
            addItemToCart = new ArrayList<>();
            if (isTextEnterOn)
                for (int i = 0; i < productModel.getQuantityList().length(); i++) {
                    addItemToCart.add(Integer.parseInt(productModel.getQuantityList().get(i).toString()));
                }

            ((OrderViewHolder) holder).itemCount.setOnTouchListener((v, event) -> {
                if (!isTextEnterOn)
                    setUpListPopUpWindow(newOrderContext, ((OrderViewHolder) holder).itemCount, productModel, position, ((OrderViewHolder) holder).itemCount, addItemToCart);
                else {
                    selected_pos = position;
                    isAddCartClicked = true;
                }
                return false;
            });
            ((OrderViewHolder) holder).addEnteredValue.setOnClickListener(v -> {
                if (!((OrderViewHolder) holder).itemCount.getText().toString().isEmpty() && Integer.parseInt(((OrderViewHolder) holder).itemCount.getText().toString()) != 0) {
                    productArray.get(position).setProductCount(((OrderViewHolder) holder).itemCount.getText().toString());
                    UpdatingCartItems(position, productArray.get(position));
                    selected_pos = position;
                    AddProductInCart(productArray.get(position), null, true);
                    ((OrderViewHolder) holder).addEnteredValue.setEnabled(false);
                    setConstantBundle(productArray.get(position), newOrderContext);
                    ((OrderViewHolder) holder).addEnteredValue.setBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                }
            });
            holder.itemView.setOnClickListener(v -> gotoProductDetails(v, productModel, productArray, position));
            ((OrderViewHolder) holder).cvAddToCart.setOnClickListener(v -> {
                isAddCartClicked = true;
                if (productArray.get(position).getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                    Toast.makeText(newOrderContext.getActivity(), "Under Development", Toast.LENGTH_SHORT).show();
                } else {
                    ((OrderViewHolder) holder).cvAddToCart.setVisibility(View.GONE);
                    ((OrderViewHolder) holder).qty_ll.setVisibility(View.VISIBLE);
                    new Handler().postDelayed(() -> {
                        if (!isTextEnterOn)
                            setUpListPopUpWindow(newOrderContext, ((OrderViewHolder) holder).itemCount, productModel, position, ((OrderViewHolder) holder).itemCount, addItemToCart);
                        else {
                            selected_pos = position;
                            isAddCartClicked = true;
                            ((OrderViewHolder) holder).itemCount.requestFocus();
                            ((OrderViewHolder) holder).itemCount.setFocusableInTouchMode(true);
                            KeyboardUtils.openSoftKeyboard(newOrderContext.getActivity(), ((OrderViewHolder) holder).itemCount);
                        }
                    }, 100);

                }
            });
            ((OrderViewHolder) holder).plus_icon.setOnClickListener(v -> {
                isPlusMinusClicked = true;
                ((OrderViewHolder) holder).addEnteredValue.setEnabled(false);
                ((OrderViewHolder) holder).addEnteredValue.setBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                productModel.setProductCount(ReckonUtils.roundTwoDecimals(String.valueOf(Double.parseDouble(productArray.get(position).getProductCount()) + 1)));
                UpdatingCartItems(position, productArray.get(position));
                ((OrderViewHolder) holder).itemCount.setText(String.valueOf(productModel.getProductCount()));
                selected_pos = position;
                AddProductInCart(productArray.get(position), null, true);
                setConstantBundle(productArray.get(position), newOrderContext);
            });
            ((OrderViewHolder) holder).minus_icon.setOnClickListener(v -> {
                isPlusMinusClicked = true;
                ((OrderViewHolder) holder).addEnteredValue.setEnabled(false);
                ((OrderViewHolder) holder).addEnteredValue.setBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                if (!ReckonUtils.nonNullNotEmptyString(productModel.getProductCount())) {
                    ((OrderViewHolder) holder).cvAddToCart.setVisibility(View.VISIBLE);
                    ((OrderViewHolder) holder).qty_ll.setVisibility(View.GONE);
                } else if (Double.parseDouble(productModel.getProductCount()) > 1) {
                    productModel.setProductCount(ReckonUtils.roundTwoDecimals(String.valueOf(Double.parseDouble(productArray.get(position).getProductCount()) - 1)));
                    UpdatingCartItems(position, productModel);
                    ((OrderViewHolder) holder).itemCount.setText(String.valueOf(productModel.getProductCount()));
                    selected_pos = position;
                    AddProductInCart(productModel, null, true);
                    setConstantBundle(productModel, newOrderContext);
                }

            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void gotoProductDetails(View v, ProductModel productModel, ArrayList<ProductModel> productArray, int position) {
        KeyboardUtils.hideSoftKeyboard(newOrderContext.getActivity());
        productModel.setProductId(productArray.get(position).getProductIdCol());
        if (productCountList == null) {
            productCountList = new ArrayList<>();
        }
        AddToCartModel cartModel = new AddToCartModel();
        cartModel.setId(productModel.getProductIdCol());
        cartModel.setProductName(productModel.getProductName());
        cartModel.setItemCount(productModel.getProductCount());
        productCountList.add(cartModel);
        setConstantBundle(productModel, newOrderContext);
        Bundle bundle1 = new Bundle();
        newOrderContext.searchedText = newOrderContext.search_loc_et.getText().toString();
        bundle1.putString("search_text", newOrderContext.search_loc_et.getText().toString());
        bundle1.putString("Lic_No", productModel.getFLicNo());
        bundle1.putString("Firm_Code", productModel.getFCode());
        Navigation.findNavController(v).navigate(R.id.toProductDetails, bundle1);
    }

    private void setUpTheme() {
    }

    private void setConstantBundle(ProductModel productModel, NewOrderFragment newOrderContext) {
        Constant.bundle = new Bundle();
        Constant.bundle.putString("id", String.valueOf(productModel.getProductIdCol()));
        Constant.bundle.putString("itemCount", String.valueOf(productModel.getProductCount()));
        Constant.bundle.putString("ProductList", gson.toJson(productCountList));
        Constant.bundle.putString("model", gson.toJson(productModel));
        Constant.bundle.putString("id_col", String.valueOf(productModel.getProductIdCol()));
        Constant.bundle.putString(Constant.SCREEN_NAME, Constant.PRODUCT);
        Constant.bundle.putString("totalCalculatedPriceOfCartValue", totalCalculatedPriceOfCartValue);
        if (newOrderContext != null) {
            newOrderContext.getCartItemList();
        }
    }

    private void UpdatingCartItems(int position, ProductModel model) {
        model.setProductId(model.getProductIdCol());
        AddToCartModel cartModel = new AddToCartModel();
        cartModel.setId(model.getProductIdCol());
        cartModel.setProductName(productArray.get(position).getProductName());
        cartModel.setItemCount(productArray.get(position).getProductCount());
        if (productCountList != null) {
            for (int i = 0; i < productCountList.size(); i++) {
                if (productCountList.get(i).getId() == model.getProductIdCol()) {
                    productCountList.remove(i);///TODO: this will crash,
                    productCountList.add(i, cartModel);
                }
            }
        }
    }

    private void setUpListPopUpWindow(Fragment fragment, View anchorView, ProductModel productModels, int position, View textView, ArrayList<Integer> addItemToCart) {
        try {
            m = 0;
            listPopupWindow = new ListPopupWindow(fragment.requireActivity());
            listPopupWindow.setAdapter(new ArrayAdapter(fragment.getActivity(), R.layout.cc_row_layout, R.id.tv_country, this.addItemToCart));
            listPopupWindow.setAnchorView(anchorView);
            listPopupWindow.setWidth(200);
            listPopupWindow.setHeight(ListPopupWindow.WRAP_CONTENT);
            listPopupWindow.setModal(true);
            listPopupWindow.setOnItemClickListener((adapterView, view, i, l) -> {
                listPopupWindow.dismiss();
                m = 1;
                new Handler().postDelayed(() -> {
                    productModels.setProductCount(addItemToCart.get(i).toString());
                    UpdatingCartItems(position, productModels);
                    if (textView instanceof TextView)
                        ((TextView) textView).setText(String.valueOf(productArray.get(position).getProductCount()));
                    else
                        ((EditText) textView).setText(String.valueOf(productArray.get(position).getProductCount()));
                    selected_pos = position;
                    AddProductInCart(productModels, null, true);
                    Constant.bundle = new Bundle();
                    Constant.bundle.putString("id", String.valueOf(position));
                    Constant.bundle.putString("itemCount", String.valueOf(productModels.getProductCount()));
                    Constant.bundle.putString("ProductList", gson.toJson(productCountList));
                    Constant.bundle.putString("model", gson.toJson(productModels));
                    Constant.bundle.putString("id_col", String.valueOf(productModels.getProductIdCol()));
                    Constant.bundle.putString(Constant.SCREEN_NAME, Constant.PRODUCT);
                    setConstantBundle(productArray.get(position), newOrderContext);
                }, 50);

            });
            listPopupWindow.show();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public int getItemCount() {
        return (FROM.equalsIgnoreCase(Constant.NEW_ORDER) || FROM.equalsIgnoreCase(Constant.CART) || FROM.equalsIgnoreCase(Constant.ORDER_DETAILS)) ? productArray != null ? productArray.size() : 0 : ccArray != null ? ccArray.size() : 0;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView cName;
        LinearLayout rowLayout;

        ViewHolder(View v) {
            super(v);
            cName = v.findViewById(R.id.tv_country);
            rowLayout = v.findViewById(R.id.row_layout);
        }
    }

    public static class DistributorViewHolder extends RecyclerView.ViewHolder {
        TextView cName, tv_email, tv_mobile_number, tv_city, tv_address, ratingTv, businessTypeTv;
        LinearLayout rowLayout, status_ll, city_ll, llMobileRow, llEmailRow, viewMoreLl, viewPagerCountDots;
        Button statusBtn;
        CardView parent_cv, ratingCV;
        AutoScrollViewPager imageSlides;
        ImageView callIv;
        FrameLayout imageSlidesFL;

        DistributorViewHolder(View v) {
            super(v);
            cName = v.findViewById(R.id.tv_country);
            tv_email = v.findViewById(R.id.tv_email);
            tv_mobile_number = v.findViewById(R.id.tv_mobile_number);
            rowLayout = v.findViewById(R.id.row_layout);
            tv_address = v.findViewById(R.id.tv_address);
            statusBtn = v.findViewById(R.id.statusBtn);
            status_ll = v.findViewById(R.id.status_ll);
            tv_city = v.findViewById(R.id.tv_city);
            parent_cv = v.findViewById(R.id.parent_cv);
            city_ll = v.findViewById(R.id.city_ll);
            callIv = v.findViewById(R.id.callIv);
            llMobileRow = v.findViewById(R.id.llMobileRow);
            llEmailRow = v.findViewById(R.id.llEmailRow);
            viewMoreLl = v.findViewById(R.id.viewMoreLl);
            imageSlides = v.findViewById(R.id.imageSlides);
            ratingCV = v.findViewById(R.id.ratingCV);
            ratingTv = v.findViewById(R.id.ratingTv);
            businessTypeTv = v.findViewById(R.id.businessTypeTv);
            viewPagerCountDots = v.findViewById(R.id.viewPagerCountDots);
            imageSlidesFL = v.findViewById(R.id.imageSlidesFL);
            imageSlides.setDrawingCacheEnabled(true);
        }
    }

    public class OrderViewHolder extends RecyclerView.ViewHolder {
        TextView tvStockIn, tvDiscountValue, tvMRPValue, tvProductName, tvProductScheme, tvSalt, tvProductPacking, productSalt, tv_view_more, tv_product_by, tv_added_quantity, tv_packing, tv_price, tv_stock, barcode_tv, tv_reference, tv_cat, tv_salt, tv_stock_, tv_scheme, tvInclusiveGST, tvRate;
        LinearLayout qty_ll, stock_ll, scheme_ll, rowLayout, status_ll, barcode_ll, ll_child, reference_row_ll, pack_row_ll, brand_row_ll, salt_row_ll, cat_row_ll;
        TextView addToCart, tvSeeSimilar, productValueTotal, schemeValueTotal, schemeValueTv;
        EditText qty_Txt, itemCount;
        ImageView plus_icon, minus_icon;
        ConstraintLayout constraintLayoutNewOrder, productAndScheme;
        CardView cvAddToCart, cardHolderSalt, addEnteredValue;

        OrderViewHolder(View v) {
            super(v);
            cardHolderSalt = v.findViewById(R.id.cardHolderSalt);
            itemCount = v.findViewById(R.id.item_number);
            tvSalt = v.findViewById(R.id.tv_salt);
            addEnteredValue = v.findViewById(R.id.addEnteredValue);
            if (isTextEnterOn) {
                addEnteredValue.setEnabled(false);
                itemCount.setCompoundDrawables(null, null, null, null);
                addEnteredValue.setVisibility(View.VISIBLE);
            } else {
                itemCount.setWidth(ViewGroup.LayoutParams.WRAP_CONTENT);
                addEnteredValue.setVisibility(View.GONE);
            }
            itemCount.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {
                }

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                    if (!SharedPrefUtils.getShowAddDetailsBottomSheet(newOrderContext.requireActivity())) {
                        if (isAddCartClicked && !isPlusMinusClicked) {
                            productArray.get(selected_pos).setProductCount(!s.toString().isEmpty() ? s.toString() : "0");
                            if (!productArray.get(selected_pos).getProductCount().equalsIgnoreCase(productArray.get(selected_pos).getProductDQty())) {
                                addEnteredValue.setEnabled(true);
                                addEnteredValue.setBackgroundColor(newOrderContext.getThirdHeaderColor());
                            } else {
                                addEnteredValue.setEnabled(false);
                                addEnteredValue.setBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                            }
                        }
                    }

                }

                @Override
                public void afterTextChanged(Editable s) {

                }
            });
            tvSeeSimilar = v.findViewById(R.id.tvSeeSimilar);
            productValueTotal = v.findViewById(R.id.productValueTotal);
            schemeValueTotal = v.findViewById(R.id.schemeValueTotal);
            schemeValueTv = v.findViewById(R.id.schemeValueTv);
            productAndScheme = v.findViewById(R.id.productAndScheme);
            constraintLayoutNewOrder = v.findViewById(R.id.constraintLayoutNewOrder);
            tvDiscountValue = v.findViewById(R.id.tvDiscountValue);
            tvProductScheme = v.findViewById(R.id.tvProductScheme);
            tvProductPacking = v.findViewById(R.id.tvProductPacking);
            productSalt = v.findViewById(R.id.productSalt);
            tvStockIn = v.findViewById(R.id.tvStockIn);
            tvMRPValue = v.findViewById(R.id.tvMRPValue);
            tvProductName = v.findViewById(R.id.productName);
            plus_icon = v.findViewById(R.id.plus_icon);
            minus_icon = v.findViewById(R.id.minus_icon);
            cvAddToCart = v.findViewById(R.id.cvAddToCart);
            addToCart = v.findViewById(R.id.addToCart);
            qty_ll = v.findViewById(R.id.llQuantity);
            tvRate = v.findViewById(R.id.tvRate);
            tvInclusiveGST = v.findViewById(R.id.tvInclusiveGST);
            salt_row_ll = v.findViewById(R.id.salt_row_ll);
            cat_row_ll = v.findViewById(R.id.cat_row_ll);
            tv_cat = v.findViewById(R.id.tv_cat);
            stock_ll = v.findViewById(R.id.stock_ll);
            tv_stock_ = v.findViewById(R.id.tv_stock_);
            tv_scheme = v.findViewById(R.id.tv_scheme);
            tv_product_by = v.findViewById(R.id.productCompanyName);
            tv_packing = v.findViewById(R.id.tv_packing);
            rowLayout = v.findViewById(R.id.row_layout);
            tv_view_more = v.findViewById(R.id.tv_view_more);
            status_ll = v.findViewById(R.id.status_ll);
            tv_price = v.findViewById(R.id.tv_price);
            tv_stock = v.findViewById(R.id.tv_stock);
            qty_Txt = v.findViewById(R.id.qty_Txt);
            barcode_tv = v.findViewById(R.id.barcode_tv);
            barcode_ll = v.findViewById(R.id.barcode_ll);
            reference_row_ll = v.findViewById(R.id.reference_row_ll);
            pack_row_ll = v.findViewById(R.id.pack_row_ll);
            brand_row_ll = v.findViewById(R.id.brand_row_ll);
            scheme_ll = v.findViewById(R.id.scheme_ll);
            tv_reference = v.findViewById(R.id.tv_reference);
            ll_child = v.findViewById(R.id.ll_child);
            tv_added_quantity = v.findViewById(R.id.tv_added_quantity);
        }
    }

    public static class CartViewHolder extends RecyclerView.ViewHolder {
        TextView tvGoodsValue,tvDiscValue,tvGstValue, productName, tvDisPcs, tvDisPer, disPcsAmtTv, disPerAmtTv, tvAddDisPer, disAddAmtTv, tvAddedQty, tvAddedFQty, tvSeeSimilar, tvProductPacking, tvProductRefId, tvProductScheme, productValueTotal, schemeValueTotal, productCompanyName, tvPriceValue, productSalt, tvMRPValue, tvValueAmount, barcode_tv, removeButton;
        LinearLayout qtyLL, llProductValueSeparator, schemeLL, directQtyUpdateLL, llQtyUpdateRow, fQtyTvLL, discountSectionLL, finalValuesLL;
        EditText tvQuantityProduct;
        ConstraintLayout constraintLayoutCart, productAndScheme;
        CardView cardQuantity, qtyPickerCV, cvOutOfStock, cardAddProduct, addEnteredValue, cvUpdateCartBtn;
        View productSpecifiedName;

        CartViewHolder(View v) {
            super(v);
            schemeLL = v.findViewById(R.id.schemeLL);
            removeButton = v.findViewById(R.id.removeButton);
            addEnteredValue = v.findViewById(R.id.addEnteredValue);
            qtyLL = v.findViewById(R.id.qtyLL);
            tvProductScheme = v.findViewById(R.id.tvProductScheme);
            tvProductPacking = v.findViewById(R.id.tvProductPacking);
            tvSeeSimilar = v.findViewById(R.id.tvSeeSimilar);
            productValueTotal = v.findViewById(R.id.productValueTotal);
            schemeValueTotal = v.findViewById(R.id.schemeValueTotal);
            productAndScheme = v.findViewById(R.id.productAndScheme);
            cardQuantity = v.findViewById(R.id.cardQuantity);
            constraintLayoutCart = v.findViewById(R.id.constraintLayoutCart);
            productName = v.findViewById(R.id.productName);
            tvQuantityProduct = v.findViewById(R.id.tvQuantityProduct);
            productSpecifiedName = v.findViewById(R.id.productSpecifiedName);
            productCompanyName = v.findViewById(R.id.productCompanyName);
            tvMRPValue = v.findViewById(R.id.tvMRPValue);
            tvValueAmount = v.findViewById(R.id.tvValueAmount);
            tvPriceValue = v.findViewById(R.id.tvPriceValue);
            productSalt = v.findViewById(R.id.productSalt);
            cvOutOfStock = v.findViewById(R.id.cvOutOfStock);
            qtyPickerCV = v.findViewById(R.id.qty_picker_cv);
            cardAddProduct = v.findViewById(R.id.cardAddProduct);
            if (isTextEnterOn) {
                addEnteredValue.setEnabled(false);
                tvQuantityProduct.setCompoundDrawables(null, null, null, null);
                addEnteredValue.setVisibility(View.VISIBLE);
            } else {
                tvQuantityProduct.setWidth(ViewGroup.LayoutParams.WRAP_CONTENT);
                addEnteredValue.setVisibility(View.GONE);
            }
            directQtyUpdateLL = v.findViewById(R.id.directQtyUpdateLL);
            llQtyUpdateRow = v.findViewById(R.id.llQtyUpdateRow);
            tvAddedQty = v.findViewById(R.id.tvAddedQty);
            tvAddedFQty = v.findViewById(R.id.tvAddedFQty);
            cvUpdateCartBtn = v.findViewById(R.id.cvUpdateCartBtn);
            fQtyTvLL = v.findViewById(R.id.fQtyTvLL);
            tvDisPcs = v.findViewById(R.id.tvDisPcs);
            tvDisPer = v.findViewById(R.id.tvDisPer);
            tvAddDisPer = v.findViewById(R.id.tvAddDisPer);
            discountSectionLL = v.findViewById(R.id.discountSectionLL);
            tvProductRefId = v.findViewById(R.id.tvProductRefId);
            disPcsAmtTv = v.findViewById(R.id.disPcsAmtTv);
            disPerAmtTv = v.findViewById(R.id.disPerAmtTv);
            disAddAmtTv = v.findViewById(R.id.disAddAmtTv);

            tvGoodsValue = v.findViewById(R.id.tvGoodsValue);
            tvDiscValue = v.findViewById(R.id.tvDiscValue);
            tvGstValue = v.findViewById(R.id.tvGstValue);
            finalValuesLL = v.findViewById(R.id.finalValuesLL);









        }
    }

    public static class PurchasedOrderHolder extends RecyclerView.ViewHolder {
        TextView productName, productCompanyName, tvPriceValue, productSalt, tvValueAmount, tvQuantityProduct, tvInvQty, tvBalQty;

        PurchasedOrderHolder(View v) {
            super(v);
            productName = v.findViewById(R.id.productName);
            productCompanyName = v.findViewById(R.id.productCompanyName);
            tvValueAmount = v.findViewById(R.id.tvValueAmount);
            tvPriceValue = v.findViewById(R.id.tvPriceValue);
            productSalt = v.findViewById(R.id.productSalt);
            tvQuantityProduct = v.findViewById(R.id.tvQuantityProduct);
            tvInvQty = v.findViewById(R.id.tvInvQty);
            tvBalQty = v.findViewById(R.id.tvBalQty);


        }
    }

    private void AddProductInCart(ProductModel productModel, JSONObject extendedObj, boolean insertRecord) {
        try {
          /*  if (insertRecord) {
                showLoading(Objects.requireNonNull(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity()));
            }*/
            boolean isSalesMan = FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getLicDetails().getRole().equalsIgnoreCase("SalesMan") : cartFragment.getLicDetails().getRole().equalsIgnoreCase("SalesMan");
            String firmCode = isSalesMan ? FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getSelectedStoreDetailsFromPicker().getFirmCode() : cartFragment.getSelectedStoreDetailsFromPicker().getFirmCode() : FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getLicDetails().getFirmcode() : cartFragment.getLicDetails().getFirmcode();
            String acCode = isSalesMan? (SharedPrefUtils.getString(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? Constant.AC_CODE : Constant.PARTY_CODE)):productModel.getAcCode();
            JSONObject obj = new JSONObject();
            obj.put("UserId", SharedPrefUtils.getString(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), Constant.USER_ID));
            obj.put("LicNo", FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getLicDetails().getLicno() : cartFragment.getLicDetails().getLicno());
            obj.put("lFirmCode", isSalesMan ? firmCode : FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getLicDetails().getFirmcode() : cartFragment.getLicDetails().getFirmcode());
            obj.put("AcCode", ReckonUtils.nonNullNotEmptyString(acCode)? acCode : FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.partyCode : ReckonUtils.nonNullNotEmptyString(cartFragment.partyCode)?cartFragment.partyCode:"");
            obj.put("ItemCode", productModel.getProductCode());
            obj.put("ItemQty", insertRecord ? productModel.getProductCount() : extendedObj != null ? extendedObj.getDouble("ItemQty") : 0);
            obj.put("lApkName", Objects.requireNonNull(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity()).getPackageName());
            obj.put("IdCol", productModel.getProductIdCol());
            obj.put("cu_id", SharedPrefUtils.getString(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), Constant.USER_ID_CU));
            obj.put("insert_record", insertRecord ? 1 : 0);
            if (extendedObj != null) {
                obj.put("ItemFQty", extendedObj.getDouble("ItemFQty"));
                obj.put("ItemSchQty",!SharedPrefUtils.getShowManualScheme(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity())?productModel.getSchQty() : extendedObj.getInt("ItemSchQty"));
                obj.put("ItemDSchQty",!SharedPrefUtils.getShowManualScheme(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity())?productModel.getDSchQty() : extendedObj.getInt("ItemDSchQty"));
                obj.put("discount_percentage", extendedObj.getString("discount_percentage"));
                obj.put("discount_pcs", extendedObj.getString("discount_pcs"));
                obj.put("discount_percentage1", extendedObj.getString("discount_percentage1"));
                obj.put("remark", extendedObj.getString("remark"));
                obj.put("ItemRate", extendedObj.getString("ItemRate"));
            } else {
                obj.put("ItemRate", productModel.getProductRateA());
                obj.put("ItemSchQty", productModel.getSchQty());
                obj.put("ItemDSchQty", productModel.getDSchQty());
            }
            obj.put("device_id", SharedPrefUtils.getString(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), Constant.DEVICE_ID));
            obj.put("device_name", ReckonUtils.getDeviceName());
            obj.put("default_hit", openOptionQtyBottomSheet);
            obj.put("v_code", SharedPrefUtils.getVersionCode(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity()));
            obj.put("version_name", SharedPrefUtils.getVersionName(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity()));
            obj.put("app_role", SharedPrefUtils.getString(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), getApiClientByPost().AddProductInCart(String.valueOf(obj)), insertRecord ? Constant.ADD_PRODUCT : Constant.GET_ADD_PRODUCT_CAL, insertRecord);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        openOptionQtyBottomSheet = false;
//        dismissLoading(Objects.requireNonNull(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity()));
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            if (jsonObject.length() > 0) {
                switch (action) {
                    case Constant.ADD_PRODUCT:
                    case Constant.GET_ADD_PRODUCT_CAL:
                        parseAddedProductData(jsonObject, action);
                        break;
                    case Constant.DELETE_CART:
                        onQtyEdtTextClicked = false;
                        if (jsonObject.has("Status") && jsonObject.getBoolean("Status")) {
                            productArray.remove(selected_pos);
                            cartFragment.productAmountsList.remove(selected_pos);
                            notifyDataSetChanged();
                            Toast.makeText(cartFragment.getActivity(), ReckonUtils.getJsonCheckedString(jsonObject, "Message", ""), Toast.LENGTH_SHORT).show();
                            cartFragment.ListSize(String.valueOf(productArray.size()), true, true);
                            cartFragment.getCartItemList();
                            cartFragment.calculatePrice(cartFragment.productAmountsList);
                        } else
                            Toast.makeText(cartFragment.getActivity(), ReckonUtils.getJsonCheckedString(jsonObject, "Message", ""), Toast.LENGTH_SHORT).show();
                        break;
                }
            }

        }
    }

    private void parseAddedProductData(JSONObject jsonObject, String action) {
        isPlusMinusClicked = false;
        try {
            if (jsonObject.getBoolean("Status")) {
                String _goodsValue = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "Amt", "0.0")) ;
                String _schemeValue = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemSchAmt", "0.0")) ;
                String _totalDiscount = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "totalDisc", "0.0")) ;
                String _netValue = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemNetAmt", "0.0")) ;
                String _itemTaxAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemTaxAmt", "0.0")) ;
                String _itemDiscPer = ReckonUtils.getJsonCheckedString(jsonObject, "ItemDiscPer", "").replace(".00","");
                String _itemDisc2Per = ReckonUtils.getJsonCheckedString(jsonObject, "ItemDisc2Per", "").replace(".00","");
                String _temDisc1Per = ReckonUtils.getJsonCheckedString(jsonObject, "ItemDisc1Per", "").replace(".00","");
                String _discPcsAmt =  ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemDisc2Amt", "0.0"));
                String _discPerAmt =  ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemDiscAmt", "0.0"));
                String _addDiscPerAmt =  ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemDisc1Amt", "0.0"));
                String _qty = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "Qty", "0"));
                String _fQty = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "DQty", "0"));
                String _schQty = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemSchQty", "0"));
                String _dSchQty = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemDSchQty", "0"));
                String _rate = ReckonUtils.getJsonCheckedString(jsonObject, "Rate", "0.0").replace(".00","0");

                if (FROM.equalsIgnoreCase(Constant.NEW_ORDER)) {
                    Toast.makeText(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), jsonObject.getString("Message"), Toast.LENGTH_LONG).show();
                    KeyboardUtils.hideSoftKeyboard(newOrderContext.getActivity());
                    productArray.get(selected_pos).setAmt(_goodsValue);
                    productArray.get(selected_pos).setSchemeAmt(_schemeValue);
                    productArray.get(selected_pos).setProductDQty(productArray.get(selected_pos).getProductCount());
                    newOrderContext.productAmountsList.add(Float.parseFloat(_goodsValue));
                    totalCalculatedPriceOfCartValue = newOrderContext.calculatePrice(newOrderContext.productAmountsList);
                } else {
                    if (action.equalsIgnoreCase(Constant.ADD_PRODUCT)) {
                        Toast.makeText(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), jsonObject.getString("Message"), Toast.LENGTH_LONG).show();
                        KeyboardUtils.hideSoftKeyboard(cartFragment.getActivity());
                        cartFragment.ListSize(String.valueOf(productArray.size()), true, false);
                        cartFragment.getCartItemList();
                        cartFragment.calculatePrice(cartFragment.productAmountsList);
                        dialog.dismiss();
                    } else if (action.equalsIgnoreCase(Constant.GET_ADD_PRODUCT_CAL)) {
                        String currencySign = cartFragment.getLicDetails().getCurrency();
                        String goodsValue = currencySign + _goodsValue;
                        String schemeValue = currencySign + _schemeValue;
                        String totalDiscount = currencySign + _totalDiscount;
                        String gstValue = currencySign + _itemTaxAmt;
                        String netValue = currencySign + _netValue;
                        String discPcsAmt = currencySign + _discPcsAmt;
                        String discPerAmt = currencySign + _discPerAmt;
                        String addDiscPerAmt = currencySign + _addDiscPerAmt;
                        tvGoodsValue.setText(goodsValue);
                        tvSchemeValue.setText(schemeValue);
                        tvDiscValue.setText(totalDiscount);
                        tvGstValue.setText(gstValue);
                        tvNetValue.setText(netValue);
                        disPcsAmtTv.setText(discPcsAmt);
                        disPerAmtTv.setText(discPerAmt);
                        disAddAmtTv.setText(addDiscPerAmt);
                        tvGstTitle.setText(ReckonUtils.nonNullNotEmptyString(_itemTaxAmt) ? "GST % (Exclusive)" : "GST % (Inclusive)");
                        autoUpdateQty = true;
                        discEdt.setText(_itemDiscPer);
                        discEdt.setSelection(discEdt.getText().length());
                        debouncer.debounce(Void.class, new Runnable() {
                            @Override public void run() {
                                autoUpdateQty = false;
                            }
                        }, 500, TimeUnit.MILLISECONDS);

                    }
                }
            } else {
                Toast.makeText(FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? newOrderContext.getActivity() : cartFragment.getActivity(), jsonObject.getString("Message"), Toast.LENGTH_LONG).show();
                if (!productArray.get(selected_pos).getProductCount().equalsIgnoreCase(productArray.get(selected_pos).getProductDQty())) {
                    productArray.get(selected_pos).setProductCount(productArray.get(selected_pos).getProductDQty());
                }
            }
            notifyItemChanged(selected_pos, productArray.get(selected_pos));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void RemoveCartItemPopUp(ProductModel productModel, int position) {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(cartFragment.getActivity());
        alertDialogBuilder.setMessage("Do you want to Remove this item?");
        alertDialogBuilder.setPositiveButton("REMOVE",
                (arg0, arg1) -> {
                    alertDialog.cancel();
                    selected_pos = position;
                    deleteItem(String.valueOf(productModel.getProductIdCol()));
                });

        alertDialogBuilder.setNegativeButton("Cancel", (dialog, which) -> {
            alertDialog.cancel();
        });
        alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(cartFragment.getResources().getColor(R.color.black));
        alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(cartFragment.getResources().getColor(R.color.black));
    }

    private void deleteItem(final String order_id) {
        try {
            boolean isSalesMan = cartFragment.getLicDetails().getRole().equalsIgnoreCase("SalesMan");
            String acCode = SharedPrefUtils.getString(cartFragment.getActivity(), isSalesMan ? Constant.PARTY_CODE : Constant.AC_CODE);
            String firmCode = isSalesMan ? cartFragment.getSelectedStoreDetailsFromPicker() != null ? cartFragment.getSelectedStoreDetailsFromPicker().getFirmCode() : "" : cartFragment.getLicDetails().getFirmcode();
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", cartFragment.getActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(cartFragment.getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", cartFragment.getLicDetails().getLicno());
            jsonObject.put("lFirmCode", isSalesMan ? firmCode : cartFragment.getLicDetails().getFirmcode());
            jsonObject.put("lIdCol", order_id);
            jsonObject.put("AcCode", acCode);
            jsonObject.put("device_id", SharedPrefUtils.getString(cartFragment.getActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(cartFragment.getActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(cartFragment.getActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(cartFragment.getActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(cartFragment.getActivity(), Constant.ROLE));

            new ConnectToRetrofit(retrofitCallBackListener, cartFragment.getActivity(), getApiClientByPost().RemoveItemFromCart(String.valueOf(jsonObject)), Constant.DELETE_CART, true);
            removeFromConstantBundle(order_id);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void removeFromConstantBundle(String order_id) {
        productCountList = gson.fromJson(Constant.bundle.getString("ProductList"), new TypeToken<ArrayList<AddToCartModel>>() {
        }.getType());
        if (productCountList != null) {
            for (AddToCartModel addToCartModel : productCountList) {
                if (String.valueOf(addToCartModel.getId()).equals(order_id)) {
                    productCountList.remove(addToCartModel);
                }
            }
        }
    }

    private void showLoading(Activity mContext) {
        if (!mContext.isFinishing() && progress != null) {
            progress.show();
        } else {
            progress = new ProgressDialog(mContext);
            progress.setCanceledOnTouchOutside(false);
            progress.setMessage(mContext.getString(R.string.loading));
            progress.show();
        }
    }

    private void dismissLoading(Activity mContext) {
        if (!mContext.isFinishing() && progress != null) {
            progress.dismiss();
        }
    }

}
