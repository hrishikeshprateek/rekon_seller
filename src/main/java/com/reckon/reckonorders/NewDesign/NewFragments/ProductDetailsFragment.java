package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.isTextEnterOn;

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
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.ListPopupWindow;
import androidx.core.widget.NestedScrollView;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.google.android.material.bottomsheet.BottomSheetBehavior;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Adapter.BannerPagerAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.NewArrivalAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.AddToCartModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.Debouncer;
import com.reckon.reckonorders.Utils.DecimalDigitsInputFilter;
import com.reckon.reckonorders.Utils.DecimalDigitsInputFilters;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentProductDetailsBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;
import java.util.concurrent.TimeUnit;


public class ProductDetailsFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    FragmentProductDetailsBinding binding;
    public ArrayList<Float> productAmountsList = new ArrayList<>();
    private static final String ARG_PARAM1 = "param1";
    public boolean isRefreshed = false, flag = true;
    private static final String ARG_PARAM2 = "param2";
    Gson gson;
    private final ArrayList<SelectionModel> bannerData = new ArrayList<>();
    private ArrayList<ProductModel> product_list = new ArrayList();
    private String id, productId, screenName;
    private int position = -1;
    private ArrayList<AddToCartModel> productCountList = new ArrayList<>();
    private ProductModel model;
    private ListPopupWindow listPopupWindow;
    private int PAGE_NUM = 1;
    private boolean isChecked = false;
    private int pageCount = 30;
    private String totalCalculatedPriceOfCartValue;
    private LinearLayoutManager mLayoutManager;
    private ArrayAdapter<String> dataAdapter;
    private boolean isSalesMan = false, isPlusMinusClicked = false;
    private String searchText = "", LicNo = "", FirmCode = "";
    private TextView tvGoodsValue, tvSchemeValue, tvDiscValue, tvGstValue, tvNetValue, showQtyErrorMsgTv, disPcsAmtTv, disPerAmtTv, disAddAmtTv, tvGstTitle;
    final Debouncer debouncer = new Debouncer();
    private boolean openOptionQtyBottomSheet = true;
    private boolean autoUpdateQty = false;
    private EditText discEdt;
    private BottomSheetDialog dialog;

    public static ProductDetailsFragment newInstance(String param1, String param2) {
        ProductDetailsFragment fragment = new ProductDetailsFragment();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentProductDetailsBinding.inflate(inflater, container, false);
        binding.getRoot().getRootView().setFocusableInTouchMode(true);
        binding.getRoot().getRootView().requestFocus();
        binding.getRoot().getRootView().setOnKeyListener((v, keyCode, event) -> {
            if (keyCode == KeyEvent.KEYCODE_BACK) {
                requireActivity().onBackPressed();
//                Constant.bundle.putString("from", Constant.PRODUCT_DETAILS);
//                NavHostFragment.findNavController(this).navigate(R.id.action_back_from_Details_to_order_entry, Constant.bundle);
                return true;
            }
            return false;
        });
        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        Bundle bundle = getArguments();
        if (bundle != null) {
            searchText = bundle.getString("search_text");
            LicNo = bundle.getString("Lic_No");
            FirmCode = bundle.getString("Firm_Code");
        }
        LicNo = isSalesMan ? getLicDetails().getLicno() : !LicNo.isEmpty() ? LicNo : getLicDetails().getLicno();
        FirmCode = isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : !FirmCode.isEmpty() ? FirmCode : getLicDetails().getFirmcode();
        return binding.getRoot();
    }


    @Override
    public void onViewCreated(View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        retrofitCallBackListener = this;
        binding.productName.setTextColor(getSecondHeaderTextColor());
        binding.tvProductScheme.setTextColor(getSecondHeaderTextColor());
        binding.tvStockIn.setTextColor(getThirdHeaderColor());
        binding.tvRate.setTextColor(getSecondHeaderTextColor());
        binding.tvMRPValue.setTextColor(getSecondHeaderTextColor());
        binding.plusIcon.setColorFilter(getSecondHeaderTextColor());
        binding.minusIcon.setColorFilter(getSecondHeaderTextColor());
        binding.cvAddToCart.setCardBackgroundColor(getThirdHeaderColor());
        binding.tvProductDescriptionHeading.setTextColor(getSecondHeaderTextColor());
        binding.addEnteredValue.setVisibility(isTextEnterOn ? View.VISIBLE : View.GONE);
        binding.itemNumber.setInputType(isTextEnterOn ? InputType.TYPE_CLASS_NUMBER : InputType.TYPE_NULL);
        if (isTextEnterOn)
            binding.itemNumber.setCompoundDrawables(null, null, null, null);

        binding.itemNumber.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (!isPlusMinusClicked) {
                    model.setProductCount(!binding.itemNumber.getText().toString().isEmpty() ? binding.itemNumber.getText().toString() : "0");
                    if (!model.getProductCount().equalsIgnoreCase(model.getProductDQty())) {
                        binding.addEnteredValue.setEnabled(true);
                        binding.addEnteredValue.setBackgroundColor(getThirdHeaderColor());
                    } else {
                        binding.addEnteredValue.setEnabled(false);
                        binding.addEnteredValue.setBackgroundColor(getResources().getColor(R.color.grey));
                    }
                }
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
        binding.cartCard.setBackgroundColor(getButtonColor());
        binding.cvAddToCart.setVisibility(View.VISIBLE);
        if (!isSalesMan)
            getCartItemList();
        if (!Constant.bundle.isEmpty()) {
            gson = new Gson();
            totalCalculatedPriceOfCartValue = Constant.bundle.getString("totalCalculatedPriceOfCartValue");
            productCountList = gson.fromJson(Constant.bundle.getString("ProductList"), new TypeToken<ArrayList<AddToCartModel>>() {
            }.getType());
            model = gson.fromJson(Constant.bundle.getString("model"), new TypeToken<ProductModel>() {
            }.getType());

            if (!ReckonUtils.nonNullNotEmptyString(model.getProductCount()) && model.getScheme() == null || model.getScheme().isEmpty()) {
                binding.separatorViewLine.setVisibility(View.GONE);
            }
            if (!ReckonUtils.nonNullNotEmptyString(model.getProductCount())) {
                binding.productValueTv.setVisibility(View.GONE);
                binding.productValueTotal.setVisibility(View.GONE);
            }
            if (!ReckonUtils.nonNullNotEmptyString(model.getSchemeAmt())) {
                binding.schemeValueTv.setVisibility(View.GONE);
                binding.schemeValueTotal.setVisibility(View.GONE);
            }
            //  binding.tvTotalAmountValue.setText(getLicDetails().getCurrency()+totalCalculatedPriceOfCartValue);
            id = Constant.bundle.getString("id") != null ? Constant.bundle.getString("id") : "";
            productId = Constant.bundle.getString("id_col") != null ? Constant.bundle.getString("id_col") : "";
            screenName = Constant.bundle.getString(Constant.SCREEN_NAME) != null ? Constant.bundle.getString(Constant.SCREEN_NAME) : "";
            Constant.bundle.putString("id_col", productId);
            Constant.bundle.putString("model", gson.toJson(model));
            if (productCountList != null)
                for (int i = 0; i < productCountList.size(); i++) {
                    if (productCountList.get(i).getId() == model.getProductIdCol()) {
                        position = i;
                    }
                }

            new Handler().postDelayed(this::getProductDetails, 1000);
            if (productCountList != null)
                Constant.bundle.putString("ProductList", gson.toJson(productCountList));
        }
        ((NewMainActivity) getActivity()).setUpTitle(ProductDetailsFragment.this, getString(R.string.productDetail));
        setUpUi();
        setBannerPagerAdapter();
    }

    private void setUpUi() {
        binding.cvAddToCart.setCardBackgroundColor(getButtonColor());
        binding.addEnteredValue.setCardBackgroundColor(getButtonColor());
        binding.tvSeeSimilar.setVisibility(View.GONE);
        ArrayList<String> itemCountList = new ArrayList<>();
        JSONArray qtyList = model.getQuantityList();
        for (int i = 0; i < qtyList.length(); i++) {
            try {
                itemCountList.add(String.valueOf((int) Double.parseDouble(qtyList.get(i).toString())));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        binding.cartCard.setOnClickListener(v -> {
            Bundle bundle = new Bundle();
            bundle.putString(Constant.FROM, Constant.PRODUCT_DETAILS);
//                    bundle.putString("PARTYCODE", partyCode);
            NavHostFragment.findNavController(ProductDetailsFragment.this).navigate(R.id.nav_cart);
        });
        if (model != null) {
            setDetailsData(model);
            try {
                dataAdapter = new ArrayAdapter<>(getActivity(), R.layout.cc_row_layout, R.id.tv_country, itemCountList);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        binding.addEnteredValue.setOnClickListener(v -> {
            if (!isSalesMan && Objects.requireNonNull(model).getIsStockistActive() == 0) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
            } else {
                model.setProductCount(binding.itemNumber.getText().toString().equals("") ? "" : binding.itemNumber.getText().toString());
                checkProductList();
                prepareAllTheDataForRendering();
                binding.addEnteredValue.setEnabled(false);
                binding.addEnteredValue.setBackgroundColor(getResources().getColor(R.color.grey));
            }
        });
        binding.plusIcon.setOnClickListener(v -> {
            if (!isSalesMan && Objects.requireNonNull(model).getIsStockistActive() == 0) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
            } else {
                isPlusMinusClicked = true;
                binding.addEnteredValue.setEnabled(false);
                binding.addEnteredValue.setBackgroundColor(getResources().getColor(R.color.grey));
                model.setProductCount(String.valueOf((Double.parseDouble(model.getProductCount())) + 1));
                checkProductList();
                prepareAllTheDataForRendering();
            }
        });
        binding.minusIcon.setOnClickListener(v -> {
            if (!isSalesMan && Objects.requireNonNull(model).getIsStockistActive() == 0) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
            } else {
                isPlusMinusClicked = true;
                binding.addEnteredValue.setEnabled(false);
                binding.addEnteredValue.setBackgroundColor(getResources().getColor(R.color.grey));
                if (Double.parseDouble(model.getProductCount()) == 1) {

                }
                if (Double.parseDouble(model.getProductCount()) > 1) {
                    model.setProductCount(String.valueOf(Double.parseDouble(model.getProductCount()) - 1));
                    checkProductList();
                    prepareAllTheDataForRendering();
                }
                if (!ReckonUtils.nonNullNotEmptyString(model.getProductCount())) {
                    AddToCartModel cartModel = new AddToCartModel();
                    cartModel.setId(Integer.parseInt(productId));
                    cartModel.setItemCount("0");
                    if (productCountList != null)
                        productCountList.remove(cartModel);
                    binding.llQuantity.setVisibility(View.GONE);
                    binding.cvAddToCart.setVisibility(View.VISIBLE);

                }
            }

        });
        binding.itemNumber.setOnTouchListener((view, motionEvent) -> {
//            binding.itemNumber.setSelection(binding.itemNumber.getText().length());
            return false;
        });
        binding.itemNumber.setOnClickListener(v -> {
            if (!isTextEnterOn)
                setUpListPopUpWindow(itemCountList);
            binding.itemNumber.setSelection(binding.itemNumber.getText().length());
//            else
//                KeyboardUtils.openSoftKeyboard(requireActivity(), binding.itemNumber);

        });
        binding.cvAddToCart.setOnClickListener(v -> {
            if (model != null) {
                if (!isSalesMan && Objects.requireNonNull(model).getIsStockistActive() == 0) {
                    Toast.makeText(requireActivity(), requireActivity().getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                } else {
                    if (model.getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                        Toast.makeText(getActivity(), "Under Development", Toast.LENGTH_SHORT).show();
                    } else {
                        if (isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(requireActivity())) {
                            openOptionQtyBottomSheet = true;
                            openAddQtyBottomSheet(model);
                        } else {
                            model.setProductCount("0");
                            binding.itemNumber.setText(ReckonUtils.nonNullNotEmptyString(model.getProductCount()) ? String.valueOf(model.getProductCount()) : "");
                            binding.cvAddToCart.setVisibility(View.GONE);
                            binding.llQuantity.setVisibility(View.VISIBLE);
                            Handler handler = new Handler();
                            handler.postDelayed(() -> {
                                if (!isTextEnterOn)
                                    setUpListPopUpWindow(itemCountList);
                            }, 0);
                            binding.itemNumber.requestFocus();
                            binding.itemNumber.setFocusableInTouchMode(true);
                            KeyboardUtils.openSoftKeyboard(getActivity(), binding.itemNumber);
                        }

                    }
                }
            }

        });
        binding.cvUpdateCartBtn.setOnClickListener(view -> {
            if (!isSalesMan && Objects.requireNonNull(model).getIsStockistActive() == 0) {
                Toast.makeText(requireActivity(), requireActivity().getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
            } else {
//                isAddCartClicked = true;
               /*     if (productArray.get(position).getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                        Toast.makeText(newOrderContext.getActivity(), "Under Development!!!", Toast.LENGTH_SHORT).show();
                    } else {*/
                if (isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(requireActivity())) {
                    openOptionQtyBottomSheet = true;
                    openAddQtyBottomSheet(model);
                }
//                    }
            }
        });
    }

    private void prepareAllTheDataForRendering() {
        binding.itemNumber.setText(ReckonUtils.roundTwoDecimals(ReckonUtils.nonNullNotEmptyString(model.getProductCount()) ? String.valueOf(model.getProductCount()) : "0"));
        binding.itemNumber.setSelection(binding.itemNumber.getText().length());
        setUpBackButtonBundleData();
        AddProductInCart(model, null, true);
        if (!isSalesMan)
            getCartItemList();
        setSchemeData();
    }

    private void checkProductList() {
        if (productCountList != null && position != -1)
            productCountList.get(position).setItemCount(model.getProductCount());
        else
            setFirstItemOfProductListCount(model);
        //    binding.productValueTotal.setText(getLicDetails().getCurrency() + Double.parseDouble(model.getProductRate())*model.getProductCount());
    }

    private void setUpListPopUpWindow(ArrayList<String> itemCountList) {
        listPopupWindow = new ListPopupWindow(getActivity());
        listPopupWindow.setAdapter(dataAdapter);
        listPopupWindow.setAnchorView(binding.itemNumber);
        listPopupWindow.setWidth(200);
        listPopupWindow.setHeight(ListPopupWindow.WRAP_CONTENT);
        listPopupWindow.setModal(true);
        listPopupWindow.setOnItemClickListener((adapterView, view, i, l) -> {
            listPopupWindow.dismiss();
            model.setProductCount(itemCountList.get(i));
            checkProductList();
            setSchemeData();
            prepareAllTheDataForRendering();
        });
        listPopupWindow.show();
    }

    private void setFirstItemOfProductListCount(ProductModel model) {
        AddToCartModel cartModel = new AddToCartModel();
        cartModel.setProductName(String.valueOf(model.getProductIdCol()));
        cartModel.setItemCount(model.getProductCount());
        if (productCountList != null)
            productCountList.add(cartModel);
    }

    private void setSchemeData() {
        binding.productValueTv.setVisibility(View.VISIBLE);
        binding.productValueTotal.setVisibility(View.VISIBLE);
        binding.separatorViewLine.setVisibility(View.VISIBLE);
        if (!ReckonUtils.nonNullNotEmptyString(model.getSchemeAmt())) {
            binding.schemeValueTv.setVisibility(View.GONE);
            binding.schemeValueTotal.setVisibility(View.GONE);
        } else {
            binding.schemeValueTv.setVisibility(View.VISIBLE);
            binding.schemeValueTotal.setVisibility(View.VISIBLE);
        }
        String netValue = getLicDetails().getCurrency() + (SharedPrefUtils.getShowAddDetailsBottomSheet(requireActivity()) ? model.getNetAmtCart() : model.getAmt());
        binding.schemeValueTotal.setText(getLicDetails().getCurrency() + model.getSchemeAmt());
        binding.productValueTotal.setText(netValue);
        //binding.productValueTotal.setText(getLicDetails().getCurrency() + Double.parseDouble(model.getProductRate())*model.getProductCount());
    }

    private void setDetailsData(ProductModel model) {
        if (isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(requireActivity())) {
            if (Double.parseDouble(model.getProductCount()) > 0) {
                binding.cvAddToCart.setVisibility(View.GONE);
                binding.llQuantity.setVisibility(View.GONE);
                binding.productAndScheme.setVisibility(View.VISIBLE);
                binding.tvSeeSimilar.setVisibility(View.GONE);
                binding.schemeValueTotal.setText(model.getSchemeAmt());
                String netValue = getLicDetails().getCurrency() + model.getNetAmtCart();
                binding.productValueTotal.setText(netValue);
                binding.llQtyUpdateRow.setVisibility(View.VISIBLE);
                binding.tvAddedQty.setText(ReckonUtils.nonNullNotEmptyString(model.getProductCount()) ? String.valueOf(model.getProductCount()) : "");
                if (ReckonUtils.nonNullNotEmptyString(model.getDFQTYCart())) {
                    binding.fQtyTvLL.setVisibility(View.VISIBLE);
                    binding.tvAddedFQty.setText(String.valueOf(model.getDFQTYCart()));
                } else {
                    binding.fQtyTvLL.setVisibility(View.GONE);
                }
            } else if (!ReckonUtils.nonNullNotEmptyString(model.getProductCount())) {
                binding.cvAddToCart.setVisibility(View.VISIBLE);
                binding.llQuantity.setVisibility(View.GONE);
                binding.llQtyUpdateRow.setVisibility(View.GONE);
            }
        } else {
            if (Double.parseDouble(model.getProductCount()) > 0) {
                binding.cvAddToCart.setVisibility(View.GONE);
                binding.llQuantity.setVisibility(View.VISIBLE);
                binding.productAndScheme.setVisibility(View.VISIBLE);
                binding.tvSeeSimilar.setVisibility(View.GONE);
                binding.schemeValueTotal.setText(model.getSchemeAmt());
                binding.productValueTotal.setText(model.getAmt());
                binding.llQtyUpdateRow.setVisibility(View.GONE);
            } else if (!ReckonUtils.nonNullNotEmptyString(model.getProductCount())) {
                binding.cvAddToCart.setVisibility(View.VISIBLE);
                binding.llQuantity.setVisibility(View.GONE);
                binding.llQtyUpdateRow.setVisibility(View.GONE);
            }
        }
        binding.goToCart.setOnClickListener(v -> NavHostFragment.findNavController(ProductDetailsFragment.this).navigate(R.id.nav_cart));
        binding.productName.setText(model.getProductName());
        if (SharedPrefUtils.getShowItemRefNo(requireActivity()) && ReckonUtils.nonNullNotEmptyString(model.getRefNumber())) {
            binding.tvProductRefId.setText(model.getRefNumber());
            binding.tvProductRefId.setVisibility(View.VISIBLE);
        } else {
            binding.tvProductRefId.setVisibility(View.GONE);
        }
        binding.productSalt.setText(model.getProductSalt());
        binding.productSalt.setVisibility(SharedPrefUtils.getShowSaltComp(requireActivity()) && ReckonUtils.nonNullNotEmptyString(model.getProductSalt()) ? View.VISIBLE : View.GONE);
        binding.tvRate.setText(getLicDetails().getCurrency() + model.getProductRate());
        binding.tvRate.setVisibility(model.isShowRate() && model.getProductRate() != null && !model.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);
        binding.tvPrice.setVisibility(model.isShowRate() && model.getProductRate() != null && !model.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);
        binding.tvInclusiveGST.setVisibility(model.isShowRate() && model.getProductRate() != null && !model.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);
        binding.productCompanyName.setText(model.getProductMfgComp());
        binding.productCompanyName.setVisibility(SharedPrefUtils.getShowICompany(requireActivity()) && ReckonUtils.nonNullNotEmptyString(model.getProductMfgComp()) ? View.VISIBLE : View.GONE);

        binding.iGroupTv.setText(model.getProductIGroup());
        binding.iGroupTv.setVisibility(SharedPrefUtils.getShowItemCategory(requireActivity()) && ReckonUtils.nonNullNotEmptyString(model.getProductIGroup()) ? View.VISIBLE : View.GONE);

        binding.tvMRPValue.setText(getLicDetails().getCurrency() + model.getProductMrp());
        binding.tvMRPValue.setVisibility(model.isShowMrp() && model.getProductMrp() != null && !model.getProductMrp().isEmpty() ? View.VISIBLE : View.GONE);
        binding.tvMRP.setVisibility(model.isShowMrp() && model.getProductMrp() != null && !model.getProductMrp().isEmpty() ? View.VISIBLE : View.GONE);
        binding.tvInclusiveGST.setText("(Exclusive GST " + model.getTax() + "%" + ")");
        if (model.getSCName().isEmpty()) {
            binding.cardHolderSalt.setVisibility(View.GONE);
        } else
            binding.tvSalt.setText(model.getSCName());
        int disc = (int) (100 - ((Double.parseDouble(model.getProductRate()) / Double.parseDouble(model.getProductMrp())) * 100));
        binding.tvDiscountValue.setText(String.valueOf(disc) + "%");
        binding.itemNumber.setText(ReckonUtils.nonNullNotEmptyString(model.getProductCount()) ? String.valueOf(model.getProductCount()) : "");
        binding.tvStockIn.setText(model.getProductStockType());
        binding.tvProductScheme.setText(model.getScheme());
//        binding.tvProductScheme.setText(model.getProductpacking());
        binding.tvProductScheme.setVisibility(model.isShowScheme() && model.getScheme() != null && !model.getScheme().isEmpty() ? View.VISIBLE : View.GONE);
        if (model.isShowStock()) {
            setStockWithValueView(model);
        } else {
            setStockView(model);
        }
        binding.cardImageScroller.setVisibility(model.getProductImage() == null ? View.GONE : View.VISIBLE);
        if (ReckonUtils.nonNullNotEmptyString(model.getProductImage()) && model.getImageUrl() != null && !model.getImageUrl().isEmpty()) {
            String _url = model.getProductImage().contains("http") ? model.getProductImage() : model.getImageUrl() + "/" + model.getProductImage();
            Glide.with(requireActivity()).load(_url).apply(RequestOptions.placeholderOf(R.drawable.photo_upload)).into(binding.productImage);
        } else
            binding.productImage.setImageDrawable(requireActivity().getResources().getDrawable(R.drawable.photo_upload));
        binding.cardProductDescription.setVisibility(ReckonUtils.nonNullNotEmptyString(model.getDescription()) ? View.VISIBLE : View.GONE);
        binding.tvProductDescription.setText(model.getDescription());
        if (screenName.equalsIgnoreCase(Constant.PRODUCT) || screenName.equalsIgnoreCase(Constant.CART)) {
            new Handler().postDelayed(() -> getProductList(PAGE_NUM), 1000);
        } else
            binding.cardAlternateBrand.setVisibility(View.GONE);
        mLayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
        binding.recyclerAlternateProducts.setLayoutManager(mLayoutManager);
        binding.scrollView.setOnScrollChangeListener((NestedScrollView.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
            if (v.getChildAt(v.getChildCount() - 1) != null) {
                if ((scrollY >= (v.getChildAt(v.getChildCount() - 1).getMeasuredHeight() - v.getMeasuredHeight())) &&
                        scrollY > oldScrollY) {
                    int visibleItemCount = mLayoutManager.getChildCount();
                    int totalItemCount = mLayoutManager.getItemCount();
                    int pastVisiblesItems = mLayoutManager.findFirstVisibleItemPosition();
                    if ((visibleItemCount + pastVisiblesItems) >= totalItemCount) {
                        if (product_list != null && product_list.size() < totalCount - 1) {
                            getProductList(++PAGE_NUM);
                        }
                    }
                }
            }
        });
        if (model.getImageUrl() != null && !model.getImageUrl().isEmpty())
            Glide.with(this).load(model.getImageUrl()).apply(RequestOptions.placeholderOf(R.drawable.photo_upload)).into(binding.productImage);
        else
            binding.productImage.setImageDrawable(this.getResources().getDrawable(R.drawable.photo_upload));

        binding.tvDistributorName.setText(model.getDistributor());
        binding.distributorRowLl.setVisibility(getLicDetails().getFirmcode().isEmpty() && model.getDistributor() != null && !model.getDistributor().isEmpty() ? View.VISIBLE : View.GONE);
        binding.ratingTv.setText(String.valueOf(model.getRating()));
        binding.ratingCV.setVisibility(model.getRating() != 0 ? View.VISIBLE : View.GONE);
        binding.activeTv.setVisibility(!isSalesMan && !model.getActiveText().isEmpty() ? View.VISIBLE : View.GONE);
        binding.activeTv.setText(model.getActiveText());
        binding.activeTv.setTextColor(model.getIsStockistActive() != 0 ? requireActivity().getResources().getColor(R.color.darkGreen01) : requireActivity().getResources().getColor(R.color.red));

    }

    private void setStockWithValueView(ProductModel model) {
        switch (model.getProductStockType()) {
            case "INSTOCK":
                binding.tvStockIn.setText("Stock: " + model.getProductStock() + " Pcs");
                binding.tvStockIn.setTextColor(getResources().getColor(R.color.darkGreen01));
                break;
            case "OUTSTOCK":
                binding.tvStockIn.setText(getString(R.string.out_of_stock));
                binding.addToCart.setText(getString(R.string.notify_me));
                binding.tvStockIn.setTextColor(getResources().getColor(R.color.text_color_level));
                break;
            case "LOWSTOCK":
                binding.tvStockIn.setText("Stock: " + model.getProductStock() + " Pcs");
                binding.tvStockIn.setTextColor(getResources().getColor(R.color.yellow));
                break;
        }
    }

    private void setStockView(ProductModel model) {
        switch (model.getProductStockType()) {
            case "INSTOCK":
                binding.tvStockIn.setText(isSalesMan ? "Stock: " + model.getProductStock() + " Pcs" : getString(R.string.in_stock));
                binding.tvStockIn.setTextColor(getResources().getColor(R.color.darkGreen01));
                break;
            case "OUTSTOCK":
                binding.tvStockIn.setText(getString(R.string.out_of_stock));
                binding.addToCart.setText(getString(R.string.notify_me));
                binding.tvStockIn.setTextColor(getResources().getColor(R.color.text_color_level));
                break;
            case "LOWSTOCK":
                binding.tvStockIn.setText(isSalesMan ? "Stock: " + model.getProductStock() + " Pcs" : getString(R.string.low_stock));
                binding.tvStockIn.setTextColor(getResources().getColor(R.color.yellow));
                break;
        }
    }

    public void setConstantModel() {
        Constant.model = model;
    }

    public void setUpBackButtonBundleData() {
        Constant.bundle.putString("model", gson.toJson(model));
        if (productCountList != null)
            Constant.bundle.putString("ProductList", gson.toJson(productCountList));
        Constant.bundle.putString("id_col", productId);
        if (Constant.bundle.getString(Constant.SCREEN_NAME).equals(Constant.PRODUCT_DETAILS)) {
            Constant.bundle.putString(Constant.SCREEN_NAME, Constant.PRODUCT);
        } else {
            Constant.bundle.putString(Constant.SCREEN_NAME, screenName);
        }

    }

    public void getProductDetails() {
        try {
            String acCode = SharedPrefUtils.getString(getActivity(), Constant.AC_CODE);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", LicNo);
            jsonObject.put("lFirmCode", FirmCode);
            jsonObject.put("IDCOL", productId);
            jsonObject.put("lRateType", "");
            jsonObject.put("AcCode", acCode);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostProductDetails(String.valueOf(jsonObject)), Constant.PRODUCT_DETAILS, true);
        } catch (Exception e) {
            e.printStackTrace();
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
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostCartItemList(String.valueOf(jsonObject)), Constant.CART, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void getProductList(int page) {
        try {
            String acCode = SharedPrefUtils.getString(getActivity(), Constant.AC_CODE);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", LicNo);
            jsonObject.put("lFirmCode", FirmCode);
            jsonObject.put("lPageNo", String.valueOf(page));
            jsonObject.put("lSize", String.valueOf(pageCount));
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("app_role", getLicDetails().getRole());
            jsonObject.put("lExcludeId", productId);
            jsonObject.put("AcCode", acCode);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("lUserRole", getLicDetails().getRole());
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostProductList(String.valueOf(jsonObject)), Constant.PRODUCT, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setBannerPagerAdapter() {
        try {
            if (bannerData.size() > 0)
                bannerData.clear();
            JSONArray jsonArray = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.ImageList));
            for (int i = 0; i < jsonArray.length(); i++) {
                bannerData.add(new SelectionModel(jsonArray.getJSONObject(i).getString("Code"), jsonArray.getJSONObject(i).getString("Code1"), "false"));
            }
            BannerPagerAdapter bannerPagerAdapter = new BannerPagerAdapter(ProductDetailsFragment.this, bannerData, getActivity(), binding.pager);
            binding.pager.setAdapter(bannerPagerAdapter);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        openOptionQtyBottomSheet = false;
        if (!requireActivity().isFinishing() && !requireActivity().isDestroyed()) {
            KeyboardUtils.hideSoftKeyboard(getActivity());
        }
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.PRODUCT:
                    try {
                        if (jsonObject.has("Item") && jsonObject.getJSONArray("Item").length() > 0)
                            setProductListData(jsonObject.getJSONArray("Item"), action);
                        else
                            binding.cardAlternateBrand.setVisibility(View.GONE);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
                case Constant.PRODUCT_DETAILS:
                    parseDetailsData(jsonObject, action);
                    break;
                case Constant.ADD_PRODUCT:
                case Constant.GET_ADD_PRODUCT_CAL:
                    parseAddedProductData(jsonObject, action);
                    break;
                case Constant.CART:
                    JSONArray jsonArray = jsonObject.has("DraftOrder") ? jsonObject.getJSONArray("DraftOrder") : new JSONArray();
                    clearLists();
                    Objects.requireNonNull(product_list).addAll(getParsedProductList(jsonArray, action));
                    for (int i = 0; i < jsonArray.length(); i++) {
                        productAmountsList.add(Float.parseFloat(product_list.get(i).getAmt()));
                    }
                    binding.tvTotalAmountValue.setText(getLicDetails().getCurrency() + calculatePrice(productAmountsList));
                    if (!isSalesMan)
                        binding.totalOrderValueCard.setVisibility(Double.parseDouble(calculatePrice(productAmountsList)) == 0.0 ? View.GONE : View.VISIBLE);

                    if (flag) {
                        isRefreshed = false;
                        ListSize(String.valueOf(product_list.size()), false, true);
                    } else ListSize(String.valueOf(product_list.size()), true, true);

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
        if (product_list != null && product_list.size() > 0)
            product_list.clear();
        if (productAmountsList != null && productAmountsList.size() > 0)
            productAmountsList.clear();
    }

    private void parseAddedProductData(JSONObject jsonObject, String action) {
        try {
            isPlusMinusClicked = false;
            if (jsonObject.getBoolean("Status")) {
//                        newOrderContext.isSearched = true;
//                        newOrderContext.getProductList(newOrderContext.SortByValue, "", 1, "", "", "", "");
//                        newOrderContext.search_loc_et.getText().clear();
//                    dialog.cancel();

                String _goodsValue = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "Amt", "0.0"));
                String _schemeValue = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemSchAmt", "0.0"));
                String _totalDiscount = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "totalDisc", "0.0"));
                String _netValue = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemNetAmt", "0.0"));
                String _itemTaxAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemTaxAmt", "0.0"));
                String _itemDiscPer = ReckonUtils.getJsonCheckedString(jsonObject, "ItemDiscPer", "").replace(".00", "");
                String _itemDisc2Per = ReckonUtils.getJsonCheckedString(jsonObject, "ItemDisc2Per", "").replace(".00", "");
                String _temDisc1Per = ReckonUtils.getJsonCheckedString(jsonObject, "ItemDisc1Per", "").replace(".00", "");
                String _discPcsAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemDisc2Amt", "0.0"));
                String _discPerAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemDiscAmt", "0.0"));
                String _addDiscPerAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemDisc1Amt", "0.0"));
                String _qty = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "Qty", "0"));
                String _fQty = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "DQty", "0"));
                String _schQty = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemSchQty", "0"));
                String _dSchQty = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemDSchQty", "0"));
                String _rate = ReckonUtils.getJsonCheckedString(jsonObject, "Rate", "0.0").replace(".00", "0");

                if (action.equalsIgnoreCase(Constant.ADD_PRODUCT)) {
                    KeyboardUtils.hideSoftKeyboard(getActivity());
                    dismissLoading();
                    Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_LONG).show();
                    model.setAmt(_goodsValue);
                    model.setProductRate(_rate);
                    model.setSchemeAmt(_schemeValue);
                    model.setNetAmtCart(_netValue);
                    model.setIsSchemeSelected(isChecked ? "Y" : "N");
                    setUpBackButtonBundleData();
                    setSchemeData();
                    binding.tvAddedQty.setText(ReckonUtils.nonNullNotEmptyString(model.getProductCount()) ? String.valueOf(model.getProductCount()) : "");
                    model.setDFQTYCart(_fQty);
                    model.setDisc2PerCart(_itemDisc2Per);
                    model.setDiscPerCart(_itemDiscPer);
                    model.setDisc1PerCart(_temDisc1Per);
                    model.setDoRemarkCart(ReckonUtils.getJsonCheckedString(jsonObject, "Remark", ""));
                    model.setTotalDiscCart(_totalDiscount);
                    model.setTaxAmtCart(_itemTaxAmt);
                    model.setSchQty(_schQty);
                    model.setDSchQty(_dSchQty);
                    model.setDisc2AmtCart(_discPcsAmt);
                    model.setDiscAmtCart(_discPerAmt);
                    model.setDisc1AmtCart(_addDiscPerAmt);
                    productAmountsList.add(Float.parseFloat(_goodsValue));
                    model.setProductCount(_qty);
                    model.setProductDQty(ReckonUtils.nonNullNotEmptyString(model.getProductCount()) ? model.getProductCount() : "0");
                    totalCalculatedPriceOfCartValue = calculatePrice(productAmountsList);
                    if (isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(requireActivity())) {
                        binding.llQtyUpdateRow.setVisibility(View.VISIBLE);
                        binding.llQuantity.setVisibility(View.GONE);
                        binding.cvAddToCart.setVisibility(View.GONE);
                        if (ReckonUtils.nonNullNotEmptyString(model.getDFQTYCart())) {
                            binding.fQtyTvLL.setVisibility(View.VISIBLE);
                            binding.tvAddedFQty.setText(String.valueOf(model.getDFQTYCart()));
                        } else {
                            binding.fQtyTvLL.setVisibility(View.GONE);
                        }
                    }else{
                        binding.llQtyUpdateRow.setVisibility(View.GONE);
                    }

                    dialog.dismiss();
                } else if (action.equalsIgnoreCase(Constant.GET_ADD_PRODUCT_CAL)) {
                    String currencySign = getLicDetails().getCurrency();
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
                        @Override
                        public void run() {
                            autoUpdateQty = false;
                        }
                    }, 500, TimeUnit.MILLISECONDS);

                }

            } else {
                Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void parseDetailsData(JSONObject jsonObject, String action) {
        try {
            if (jsonObject != null) {
                parseProductJson(jsonObject, action);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setProductListData(JSONArray jsonArray, String action) {
        try {
            binding.cardAlternateBrand.setVisibility(View.VISIBLE);
            Objects.requireNonNull(product_list).addAll(getParsedProductList(jsonArray, action));
            for (int i = 0; i < jsonArray.length(); i++) {
                productAmountsList.add(Float.parseFloat(product_list.get(i).getAmt()));
            }
            binding.recyclerAlternateProducts.setAdapter(new NewArrivalAdapter(ProductDetailsFragment.this, product_list));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void AddProductInCart(ProductModel productModel, JSONObject extendedObj, boolean insertRecord) {
        try {
          /*  if (insertRecord) {
                showLoading();
            }*/
            String acCode = isSalesMan?SharedPrefUtils.getString(getActivity(), Constant.AC_CODE):productModel.getAcCode();
            JSONObject obj = new JSONObject();
            obj.put("UserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            obj.put("LicNo", LicNo);
            obj.put("lFirmCode", FirmCode);
            obj.put("AcCode", acCode);
            obj.put("ItemCode", productModel.getProductCode());
            obj.put("ItemQty", /*insertRecord ? */extendedObj != null ? extendedObj.getDouble("ItemQty") : productModel.getProductCount() /*: 0*/);
            obj.put("lApkName", requireActivity().getPackageName());
            obj.put("IdCol", productModel.getProductIdCol());
            obj.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));

            obj.put("insert_record", insertRecord ? 1 : 0);
            if (extendedObj != null) {
                obj.put("ItemFQty", extendedObj.getDouble("ItemFQty"));
                obj.put("ItemSchQty",!SharedPrefUtils.getShowManualScheme(requireActivity())?productModel.getSchQty() : extendedObj.getInt("ItemSchQty"));
                obj.put("ItemDSchQty",!SharedPrefUtils.getShowManualScheme(requireActivity())?productModel.getDSchQty() : extendedObj.getInt("ItemDSchQty"));
//                obj.put("ItemAmt", extendedObj.getString("ItemAmt"));
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
            obj.put("device_id", SharedPrefUtils.getString(getActivity(), Constant.DEVICE_ID));
            obj.put("device_name", ReckonUtils.getDeviceName());
            obj.put("default_hit", openOptionQtyBottomSheet);
            obj.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            obj.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            obj.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().AddProductInCart(String.valueOf(obj)), insertRecord ? Constant.ADD_PRODUCT : Constant.GET_ADD_PRODUCT_CAL, insertRecord);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void openAddQtyBottomSheet(ProductModel productModel) {
        dialog = new BottomSheetDialog(requireActivity());
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
//        ReckonUtils.enterNumbersOnly(qtyEdt, 5);
        EditText fQtyEdt = dialog.findViewById(R.id.fQtyEdt);
//        ReckonUtils.enterNumbersOnly(fQtyEdt, 5);
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
        if (ReckonUtils.nonNullNotEmptyString(productModel.getDescription())) {
            tvDescription.setText(productModel.getDescription());
        } else {
            tvDescription.setVisibility(View.GONE);
        }
        String currencySign = getLicDetails().getCurrency();
        autoUpdateQty = false;

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

        if (SharedPrefUtils.getShowItemRefNo(requireActivity()) && ReckonUtils.nonNullNotEmptyString(productModel.getRefNumber())) {
            tvProductRefId.setText(productModel.getRefNumber());
            tvProductRefId.setVisibility(View.VISIBLE);
        } else {
            tvProductRefId.setVisibility(View.GONE);
        }
        llFQuantity.setVisibility(SharedPrefUtils.getShowFreeQty(requireActivity()) ? View.VISIBLE : View.GONE);
        if (!SharedPrefUtils.getShowIncreaseDecreaseBtn(requireActivity())) {
            decreaseQtyImv.setVisibility(View.GONE);
            increaseQtyImv.setVisibility(View.GONE);
            decreaseFQty.setVisibility(View.GONE);
            increaseFQty.setVisibility(View.GONE);
        } else {
        }
        if (!SharedPrefUtils.getShowManualScheme(requireActivity())) {
            llManualScheme.setVisibility(View.GONE);
        } else {
            if (ReckonUtils.nonNullNotEmptyString(productModel.getSchQty())) {
                edtScheme.setText(productModel.getSchQty().replace(".0", ""));
            }
            if (ReckonUtils.nonNullNotEmptyString(productModel.getDSchQty())) {
                edtDScheme.setText(productModel.getDSchQty().replace(".0", ""));
            }
        }
        String priceValue = productModel.getProductRate();
        priceEdt.setText(ReckonUtils.nonNullNotEmptyString(priceValue) ? priceValue : "");
        if (!SharedPrefUtils.getShowEnablePriceEdt(requireActivity())) {
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


        if (!SharedPrefUtils.getShowDiscountPer(requireActivity())) {
            llDiscountPer.setVisibility(View.GONE);
        }
        if (!SharedPrefUtils.getShowDiscountPcs(requireActivity())) {
            llDiscountPcs.setVisibility(View.GONE);
        }
        if (!SharedPrefUtils.getShowItemRemark(requireActivity())) {
            llAddRemark.setVisibility(View.GONE);
        }

        if (!SharedPrefUtils.getShowScheme(requireActivity())) {
            llScheme.setVisibility(View.GONE);
        }
        if (!SharedPrefUtils.getShowAddDiscountPer(requireActivity())) {
            llAddDiscountPer.setVisibility(View.GONE);
        }

        if (productModel.isShowStock()) {
            setStockWithValueView(productModel);
        } else {
            setStockView(productModel);
        }

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
                debouncer.debounce(Void.class, new Runnable() {
                    @Override
                    public void run() {
                        callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
                    }
                }, 500, TimeUnit.MILLISECONDS);
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
                autoUpdateQty = true;
                debouncer.debounce(Void.class, new Runnable() {
                    @Override
                    public void run() {
                        callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
                    }
                }, 500, TimeUnit.MILLISECONDS);
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
            if (model != null) {
                if (!isSalesMan && Objects.requireNonNull(model).getIsStockistActive() == 0) {
                    Toast.makeText(requireActivity(), requireActivity().getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                } else {
                    if (model.getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                        Toast.makeText(getActivity(), "Under Development", Toast.LENGTH_SHORT).show();
                    } else {
                        model.setProductCount("0");
                        binding.itemNumber.setText(ReckonUtils.nonNullNotEmptyString(model.getProductCount()) ? String.valueOf(model.getProductCount()) : "");
//                        binding.cvAddToCart.setVisibility(View.GONE);
//                        binding.llQuantity.setVisibility(View.VISIBLE);
                        model.setProductCount(qtyEdt.getText().toString());
                        checkProductList();
                        callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, true);
                        KeyboardUtils.openSoftKeyboard(getActivity(), binding.itemNumber);
                    }
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
                if (editText == discEdt) {
                    if (!autoUpdateQty) {
                        debouncer.debounce(Void.class, new Runnable() {
                            @Override
                            public void run() {
                                callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
                            }
                        }, 3000, TimeUnit.MILLISECONDS);
                    }
                } else {
                    callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
                }
            }

            @Override
            public void afterTextChanged(Editable editable) {

            }
        });
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
            AddProductInCart(model, extendedObj, insertRecord);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setProductPricesValue(TextView tvRate, TextView tvMRPValue, TextView tvGST, TextView tvProductScheme, ProductModel productModel) {
        tvRate.setText(String.valueOf(getLicDetails().getCurrency() + productModel.getProductRate()));
        tvRate.setVisibility(productModel.isShowRate() && productModel.getProductRate() != null && !productModel.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);
        tvMRPValue.setText(String.valueOf("(MRP " + productModel.getProductMrp() + ")"));
        tvMRPValue.setVisibility(productModel.isShowMrp() && productModel.getProductMrp() != null && !productModel.getProductMrp().isEmpty() ? View.VISIBLE : View.GONE);
        tvGST.setText(String.valueOf("(GST " + productModel.getTax() + "%" + ")"));
        tvGST.setVisibility(productModel.isShowRate() && productModel.getProductRate() != null && !productModel.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);

        tvProductScheme.setText("(" + productModel.getScheme() + ")");
        tvProductScheme.setVisibility(productModel.isShowScheme() && productModel.getScheme() != null && !productModel.getScheme().isEmpty() ? View.VISIBLE : View.GONE);
    }

    private void setProductNameRichText(TextView textView, ProductModel productModel) {
        textView.setTextColor(getResources().getColor(R.color.text_color_level));
        if (productModel.getProductpacking() != null && !productModel.getProductpacking().isEmpty()) {
            final SpannableString text = new SpannableString(productModel.getProductName() + ", " + productModel.getProductpacking());
            text.setSpan(new RelativeSizeSpan(0.8f), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            text.setSpan(new ForegroundColorSpan(getResources().getColor(R.color.title_color_primary)), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            textView.setText(text);
        } else {
            textView.setText(productModel.getProductName());
        }
    }
}