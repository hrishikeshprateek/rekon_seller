package com.reckon.reckonorders.Adapter;

import static android.text.InputType.TYPE_CLASS_NUMBER;
import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.isTextEnterOn;
import static com.reckon.reckonorders.Utils.ReckonUtils.setDynamicMargin;

import android.app.Activity;
import android.app.ProgressDialog;
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
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.ListPopupWindow;
import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.bottomsheet.BottomSheetBehavior;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Fragment.Home.NewOrderFragment;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewModals.AddToCartModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.Debouncer;
import com.reckon.reckonorders.Utils.DecimalDigitsInputFilter;
import com.reckon.reckonorders.Utils.DecimalDigitsInputFilters;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

public class NewOrderProductsAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> implements RetrofitCallBackListener {
    private final RetrofitCallBackListener retrofitCallBackListener;
    private ArrayList<Integer> addItemToCart;
    int m = -1;
    private ListPopupWindow listPopupWindow;
    ArrayList<AddToCartModel> productCountList = new ArrayList<>();

    private final ArrayList<ProductModel> productArray;
    private final NewOrderFragment newOrderContext;
    private final String FROM;
    Gson gson = new Gson();
    private int selected_pos = -1;
    private String totalCalculatedPriceOfCartValue = "", enteredLocalQty;
    private final boolean isSalesMan;
    private boolean isPlusMinusClicked = false;
    private boolean isAddCartClicked = false;
    private ProgressDialog progress;
    private TextView tvGoodsValue, tvSchemeValue, tvDiscValue, tvGstValue, tvNetValue, showQtyErrorMsgTv, disPcsAmtTv, disPerAmtTv, disAddAmtTv, tvGstTitle;
    private EditText qtyEdt, discEdt;
    private boolean autoUpdateQty = false;
    private boolean openOptionQtyBottomSheet = true;
    final Debouncer debouncer = new Debouncer();
    private BottomSheetDialog dialog;


    public NewOrderProductsAdapter(NewOrderFragment context, ArrayList<ProductModel> arrayList, String _from, Bundle bundle) {
        retrofitCallBackListener = this;
        this.productArray = arrayList;
        this.newOrderContext = context;
        this.FROM = _from;
        isSalesMan = newOrderContext.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.new_product_row_layout, parent, false);
        return new OrderViewHolder(view);
    }

    @Override
    public int getItemCount() {
        return productArray != null ? productArray.size() : 0;
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, final int position) {
        if (holder instanceof OrderViewHolder) {
            onBindViewNewOrderDataRendering((OrderViewHolder) holder, position);
        }
    }

    private void onBindViewNewOrderDataRendering(OrderViewHolder holder, int position) {
        gson = new Gson();
        if (Constant.bundle != null) {
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
        holder.setIsRecyclable(false);
        setTheme(holder);
        try {
            if (!isTextEnterOn) {
                holder.itemCount.setInputType(InputType.TYPE_NULL);
                holder.addEnteredValue.setVisibility(View.GONE);
            } else {
                holder.itemCount.setInputType(TYPE_CLASS_NUMBER);
//                holder.addEnteredValue.setVisibility(View.VISIBLE);
                holder.addEnteredValue.setEnabled(false);
                holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
            }

            if (position == productArray.size() - 1)
                holder.constraintLayoutNewOrder.setLayoutParams(setDynamicMargin(0, 0, 0, 20));
            if (productModel != null) {
                if (SharedPrefUtils.getShowItemRefNo(newOrderContext.requireActivity()) && ReckonUtils.nonNullNotEmptyString(productModel.getRefNumber())) {
                    holder.tvProductRefId.setText(productModel.getRefNumber());
                    holder.tvProductRefId.setVisibility(View.VISIBLE);
                } else {
                    holder.tvProductRefId.setVisibility(View.GONE);
                }
                setProductNameRichText(holder.tvProductName, productModel);
                holder.tv_product_by.setText(productModel.getProductMfgComp());
                holder.tv_product_by.setVisibility(SharedPrefUtils.getShowICompany(newOrderContext.requireActivity())&& ReckonUtils.nonNullNotEmptyString(productModel.getProductMfgComp()) ? View.VISIBLE : View.GONE);
                holder.productSaltTv.setText(productModel.getProductSalt());
                holder.productSaltTv.setVisibility(SharedPrefUtils.getShowSaltComp(newOrderContext.requireActivity()) && ReckonUtils.nonNullNotEmptyString(productModel.getProductSalt()) ? View.VISIBLE : View.GONE);
                holder.iGroupTv.setText(productModel.getProductIGroup());
                holder.iGroupTv.setVisibility(SharedPrefUtils.getShowItemCategory(newOrderContext.requireActivity()) && ReckonUtils.nonNullNotEmptyString(productModel.getProductIGroup()) ? View.VISIBLE : View.GONE);

                setProductPricesValue(holder.tvRate, holder.tvMRPValue, holder.tvGST, holder.tvProductScheme, productModel);
                holder.tvDistributorName.setText(productModel.getDistributor());
                holder.distributorRowLl.setVisibility(newOrderContext.getLicDetails().getFirmcode().isEmpty() && productModel.getDistributor() != null && !productModel.getDistributor().isEmpty() ? View.VISIBLE : View.GONE);
                holder.ratingTv.setText(String.valueOf(productModel.getRating()));
                holder.ratingCV.setVisibility(productModel.getRating() != 0 ? View.VISIBLE : View.GONE);
                holder.activeTv.setVisibility(!isSalesMan && !productModel.getActiveText().isEmpty() ? View.VISIBLE : View.GONE);
                holder.activeTv.setText(productModel.getActiveText());
                holder.activeTv.setTextColor(productModel.getIsStockistActive() != 0 ? newOrderContext.getResources().getColor(R.color.darkGreen01) : newOrderContext.getResources().getColor(R.color.red));

                if (productModel.isShowStock()) {
                    setStockWithValueView(holder, productModel, holder.tvStockIn, false);
                } else {
                    setStockView(holder, productModel, holder.tvStockIn, false);
                }
                if (Double.parseDouble(productModel.getProductCount()) > 0) {
                    holder.itemCount.setText(String.valueOf(productModel.getProductCount()));
                    holder.tvAddedQty.setText(String.valueOf(productModel.getProductCount()));
                    if(ReckonUtils.nonNullNotEmptyString(productModel.getDFQTYCart())){
                        holder.fQtyTvLL.setVisibility(View.VISIBLE);
                        holder.tvAddedFQty.setText(String.valueOf(productModel.getDFQTYCart()));
                    }else{
                        holder.fQtyTvLL.setVisibility(View.GONE);
                    }
                    String netValue = newOrderContext.getLicDetails().getCurrency() + productModel.getNetAmtCart();
                    holder.tvNetValue.setText(netValue);
                    holder.cvAddToCart.setVisibility(View.GONE);
                    holder.addEnteredValue.setVisibility(isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(newOrderContext.requireActivity()) ? View.GONE : View.VISIBLE);
                    holder.qty_ll.setVisibility(View.VISIBLE);
                    holder.tvStockIn.setVisibility(View.GONE);
                } else {
                    holder.cvAddToCart.setVisibility(View.VISIBLE);
                    holder.addEnteredValue.setVisibility(View.GONE);
                    holder.qty_ll.setVisibility(View.GONE);
                    holder.tvStockIn.setVisibility(View.VISIBLE);
                }
            }

            addItemToCart = new ArrayList<>();
            if (isTextEnterOn)
                for (int i = 0; i < productModel.getQuantityList().length(); i++) {
                    addItemToCart.add(Integer.parseInt(productModel.getQuantityList().get(i).toString()));
                }

            holder.itemCount.setOnTouchListener((v, event) -> {
                if (!isTextEnterOn)
                    setUpListPopUpWindow(newOrderContext, holder.itemCount, productModel, position, holder.itemCount, addItemToCart);
                else {
                    selected_pos = position;
                    isAddCartClicked = true;
                }
//                holder.itemCount.setSelection(holder.itemCount.getText().length());

                return false;
            });
            holder.addEnteredValue.setOnClickListener(v -> {
                if (!isSalesMan && productModel.getIsStockistActive() == 0) {
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                } else {
                    if (ReckonUtils.nonNullNotEmptyString(holder.itemCount.getText().toString())) {
                        productArray.get(position).setProductCount(holder.itemCount.getText().toString());
                        UpdatingCartItems(position, productArray.get(position));
                        selected_pos = position;
                        AddProductInCart(productArray.get(position), null, true);
                        holder.addEnteredValue.setEnabled(false);
                        setConstantBundle(productArray.get(position), newOrderContext);
                        holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                    }
                }
            });
            holder.itemView.setOnClickListener(v -> gotoProductDetails(v, productModel, productArray, position));
            holder.cvAddToCart.setOnClickListener(v -> {
                if (!isSalesMan && Objects.requireNonNull(productModel).getIsStockistActive() == 0) {
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                } else {
                    isAddCartClicked = true;
                    if (productArray.get(position).getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                        Toast.makeText(newOrderContext.getActivity(), "Under Development!!!", Toast.LENGTH_SHORT).show();
                    } else {
                        if (isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(newOrderContext.requireActivity())) {
                            openOptionQtyBottomSheet = true;
                            openAddQtyBottomSheet(holder, position, productModel);
                        } else {
                            holder.cvAddToCart.setVisibility(View.GONE);
                            holder.addEnteredValue.setVisibility(View.VISIBLE);
                            holder.qty_ll.setVisibility(View.VISIBLE);
                            holder.tvStockIn.setVisibility(View.GONE);
                            new Handler().postDelayed(() -> {
                                if (!isTextEnterOn)
                                    setUpListPopUpWindow(newOrderContext, holder.itemCount, productModel, position, holder.itemCount, addItemToCart);
                                else {
                                    selected_pos = position;
                                    isAddCartClicked = true;
                                    holder.itemCount.requestFocus();
                                    holder.itemCount.setFocusableInTouchMode(true);
                                    KeyboardUtils.openSoftKeyboard(newOrderContext.getActivity(), holder.itemCount);
                                }
                            }, 100);

                        }
                    }
                }

            });
            holder.cvUpdateCartBtn.setOnClickListener(view -> {
                if (!isSalesMan && Objects.requireNonNull(productModel).getIsStockistActive() == 0) {
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                } else {
                    isAddCartClicked = true;
               /*     if (productArray.get(position).getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                        Toast.makeText(newOrderContext.getActivity(), "Under Development!!!", Toast.LENGTH_SHORT).show();
                    } else {*/
                    if (isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(newOrderContext.requireActivity())) {
                        openOptionQtyBottomSheet = true;
                        openAddQtyBottomSheet(holder, position, productModel);
                    }
//                    }
                }
            });
            if (isSalesMan && SharedPrefUtils.getShowAddDetailsBottomSheet(newOrderContext.requireActivity())) {
                assert productModel != null;
                if (Double.parseDouble(productModel.getProductCount()) > 0) {
                    holder.plus_icon.setVisibility(View.GONE);
                    holder.minus_icon.setVisibility(View.GONE);
                    holder.llNetValueRow.setVisibility(View.VISIBLE);
                    holder.qty_ll.setVisibility(View.GONE);
                    holder.cvUpdateCartBtn.setVisibility(View.VISIBLE);
                    holder.netValueRowLL.setVisibility(View.VISIBLE);
                }else{
                    holder.llNetValueRow.setVisibility(View.GONE);
                    holder.cvUpdateCartBtn.setVisibility(View.GONE);
                    holder.netValueRowLL.setVisibility(View.GONE);

                }
            } else {
              /*  if(isSalesMan){
                    holder.plus_icon.setVisibility(View.VISIBLE);
                    holder.minus_icon.setVisibility(View.VISIBLE);
                    holder.qty_ll.setVisibility(View.VISIBLE);
                    holder.llNetValueRow.setVisibility(View.GONE);
                    holder.cvUpdateCartBtn.setVisibility(View.GONE);
                    holder.netValueRowLL.setVisibility(View.GONE);
                }*/

            }
            holder.plus_icon.setOnClickListener(v -> {
                increaseDecreaseQty(holder, productModel, position, true);
            });
            holder.minus_icon.setOnClickListener(v -> {
                increaseDecreaseQty(holder, productModel, position, false);
            });
            if (productModel.getRating() > 0) {
                holder.ratingCV.setCardBackgroundColor((productModel.getRating() >= 2.5 && productModel.getRating() <= 3.9) ? newOrderContext.getResources().getColor(R.color.yellow) : productModel.getRating() < 2.5 ? newOrderContext.getResources().getColor(R.color.red) : newOrderContext.getResources().getColor(R.color.green));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void increaseDecreaseQty(OrderViewHolder holder, ProductModel productModel, int position, boolean isPlusIconClicked) {
        if (!isSalesMan && Objects.requireNonNull(productModel).getIsStockistActive() == 0) {
            Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
        } else {
            isPlusMinusClicked = true;
            holder.addEnteredValue.setEnabled(false);
            holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
            if (!isPlusIconClicked && !ReckonUtils.nonNullNotEmptyString(productModel.getProductCount())) {
                holder.cvAddToCart.setVisibility(View.VISIBLE);
                holder.addEnteredValue.setVisibility(View.GONE);
                holder.qty_ll.setVisibility(View.GONE);
                holder.tvStockIn.setVisibility(View.VISIBLE);
            } else {
                String _addedQty = String.valueOf(isPlusIconClicked ? (Double.parseDouble(productArray.get(position).getProductCount()) + 1) : Double.parseDouble(productModel.getProductCount()) > 1 ? Double.parseDouble(productArray.get(position).getProductCount()) - 1 : 0);
                productModel.setProductCount(ReckonUtils.roundTwoDecimals(_addedQty));
                UpdatingCartItems(position, isPlusIconClicked ? productArray.get(position) : productModel);
                holder.itemCount.setText(String.valueOf(productModel.getProductCount()));
                holder.tvAddedQty.setText(String.valueOf(productModel.getProductCount()));
                if(ReckonUtils.nonNullNotEmptyString(productModel.getDFQTYCart())){
                    holder.fQtyTvLL.setVisibility(View.VISIBLE);
                    holder.tvAddedFQty.setText(String.valueOf(productModel.getDFQTYCart()));
                }else{
                    holder.fQtyTvLL.setVisibility(View.GONE);
                }
                String netValue = newOrderContext.getLicDetails().getCurrency() + productModel.getNetAmtCart();
                holder.tvNetValue.setText(netValue);
                selected_pos = position;
                AddProductInCart(isPlusIconClicked ? productArray.get(position) : productModel, null, true);
                setConstantBundle(isPlusIconClicked ? productArray.get(position) : productModel, newOrderContext);
            }
        }


    }

    private void setProductPricesValue(TextView tvRate, TextView tvMRPValue, TextView tvGST, TextView tvProductScheme, ProductModel productModel) {
        tvRate.setText(String.valueOf(newOrderContext.getLicDetails().getCurrency() + productModel.getProductRate()));
        tvRate.setVisibility(productModel.isShowRate() && productModel.getProductRate() != null && !productModel.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);
        tvMRPValue.setText(String.valueOf("(MRP " + productModel.getProductMrp() + ")"));
        tvMRPValue.setVisibility(productModel.isShowMrp() && productModel.getProductMrp() != null && !productModel.getProductMrp().isEmpty() ? View.VISIBLE : View.GONE);
        tvGST.setText(String.valueOf("(GST " + productModel.getTax() + "%" + ")"));
        tvGST.setVisibility(productModel.isShowRate() && productModel.getProductRate() != null && !productModel.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);

        tvProductScheme.setText("(" + productModel.getScheme() + ")");
        tvProductScheme.setVisibility(productModel.isShowScheme() && productModel.getScheme() != null && !productModel.getScheme().isEmpty() ? View.VISIBLE : View.GONE);
    }

    private void setProductNameRichText(TextView textView, ProductModel productModel) {
        textView.setTextColor(newOrderContext.getResources().getColor(R.color.text_color_level));
        if (productModel.getProductpacking() != null && !productModel.getProductpacking().isEmpty()) {
            final SpannableString text = new SpannableString(productModel.getProductName() + ", " + productModel.getProductpacking());
            text.setSpan(new RelativeSizeSpan(0.8f), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            text.setSpan(new ForegroundColorSpan(newOrderContext.getResources().getColor(R.color.title_color_primary)), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            textView.setText(text);
        } else {
            textView.setText(productModel.getProductName());
        }
    }


    private void setStockWithValueView(OrderViewHolder holder, ProductModel productModel, TextView tvStockIn, boolean isBottomSheet) {
        switch (productModel.getProductStockType()) {
            case "INSTOCK":
                if (!isBottomSheet) {
                    holder.addToCart.setText(newOrderContext.getString(R.string.add));
                }
                tvStockIn.setText("Stock: " + productModel.getProductStock() + " Pcs");
                tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.darkGreen01));
                break;
            case "OUTSTOCK":
                if (!isBottomSheet) {
                    holder.addToCart.setText(newOrderContext.getString(R.string.notify));
                    holder.cvAddToCart.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                }
                tvStockIn.setText(newOrderContext.getString(R.string.out_of_stock));
                tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.text_color_level));
                break;
            case "LOWSTOCK":
                if (!isBottomSheet) {
                    holder.addToCart.setText(newOrderContext.getString(R.string.add));
                }
                tvStockIn.setText("Stock: " + productModel.getProductStock() + " Pcs");
                tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.yellow));
                break;
        }
    }

    private void setStockView(OrderViewHolder holder, ProductModel productModel, TextView tvStockIn, boolean isBottomSheet) {
        switch (productModel.getProductStockType()) {
            case "INSTOCK":
                if (!isBottomSheet) {
                    holder.addToCart.setText(newOrderContext.getString(R.string.add));
                }
                tvStockIn.setText(isSalesMan ? "Stock: " + productModel.getProductStock() + " Pcs" : newOrderContext.getString(R.string.available));
                tvStockIn.setTextColor(/*newOrderContext.getThirdHeaderColor()*/newOrderContext.getResources().getColor(R.color.darkGreen01));
                break;
            case "OUTSTOCK":
                if (!isBottomSheet) {
                    holder.addToCart.setText(newOrderContext.getString(R.string.notify));
                    holder.cvAddToCart.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                }
                tvStockIn.setText(newOrderContext.getString(R.string.out_of_stock));
                tvStockIn.setTextColor(/*newOrderContext.getThirdHeaderColor()*/newOrderContext.getResources().getColor(R.color.text_color_level));
                break;
            case "LOWSTOCK":
                if (!isBottomSheet) {
                    holder.addToCart.setText(newOrderContext.getString(R.string.add));
                }
                tvStockIn.setText(isSalesMan ? "Stock: " + productModel.getProductStock() + " Pcs" : newOrderContext.getString(R.string.low_stock));
                tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.yellow));
                break;
        }
    }

    private void setTheme(OrderViewHolder holder) {
//        holder.plus_icon.setColorFilter(newOrderContext.getSecondHeaderTextColor());
//        holder.minus_icon.setColorFilter(newOrderContext.getSecondHeaderTextColor());
//        holder.tvProductName.setTextColor(newOrderContext.getResources().getColor(R.color.text_color_level));
//        holder.tvProductScheme.setTextColor(newOrderContext.getThirdHeaderColor());
        holder.tvRate.setTextColor(newOrderContext.getResources().getColor(R.color.text_color_level));
        holder.tvMRPValue.setTextColor(newOrderContext.getResources().getColor(R.color.text_color_level));
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
                if (!isSalesMan && productModels.getIsStockistActive() == 0) {
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                } else {
                    listPopupWindow.dismiss();
                    m = 1;
                    new Handler().postDelayed(() -> {
                        productModels.setProductCount(String.valueOf(addItemToCart.get(i)));
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
                }
            });
            listPopupWindow.show();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public class OrderViewHolder extends RecyclerView.ViewHolder {
        TextView tvStockIn, tvMRPValue, tvProductName, tvProductRefId, tvProductScheme, tvProductPacking, tvGST, tvRate, tv_product_by, activeTv, productSaltTv, iGroupTv;
        LinearLayout qty_ll, distributorRowLl, llNetValueRow, fQtyTvLL, netValueRowLL;
        TextView addToCart, tvDistributorName, ratingTv, tvAddedQty,tvAddedFQty, tvNetValue;
        EditText itemCount;
        ImageView plus_icon, minus_icon;
        LinearLayout constraintLayoutNewOrder;
        CardView cvAddToCart, addEnteredValue, ratingCV, cvUpdateCartBtn;

        OrderViewHolder(View v) {
            super(v);
            itemCount = v.findViewById(R.id.item_number);
            addEnteredValue = v.findViewById(R.id.addEnteredValue);
            if (isTextEnterOn) {
                addEnteredValue.setEnabled(false);
                itemCount.setCompoundDrawables(null, null, null, null);
//                addEnteredValue.setVisibility(View.VISIBLE);
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
                                addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.new_blue));
                            } else {
                                addEnteredValue.setEnabled(false);
                                addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                            }
                        }  }

                }

                @Override
                public void afterTextChanged(Editable s) {

                }
            });
            constraintLayoutNewOrder = v.findViewById(R.id.constraintLayoutNewOrder);
            tvProductScheme = v.findViewById(R.id.tvProductScheme);
            tvProductPacking = v.findViewById(R.id.tvProductPacking);
            tvStockIn = v.findViewById(R.id.tvStockIn);
            tvMRPValue = v.findViewById(R.id.tvMRPValue);
            tvProductName = v.findViewById(R.id.productName);
            tvProductRefId = v.findViewById(R.id.tvProductRefId);
            plus_icon = v.findViewById(R.id.plus_icon);
            minus_icon = v.findViewById(R.id.minus_icon);
            tvAddedQty = v.findViewById(R.id.tvAddedQty);
            llNetValueRow = v.findViewById(R.id.llNetValueRow);
            netValueRowLL = v.findViewById(R.id.netValueRowLL);
            tvNetValue = v.findViewById(R.id.tvNetValue);
            cvAddToCart = v.findViewById(R.id.cvAddToCart);
            cvUpdateCartBtn = v.findViewById(R.id.cvUpdateCartBtn);
            addToCart = v.findViewById(R.id.addToCart);
            qty_ll = v.findViewById(R.id.llQuantity);
            tvRate = v.findViewById(R.id.tvRate);
            tvGST = v.findViewById(R.id.tvGST);
            tv_product_by = v.findViewById(R.id.productCompanyName);
            distributorRowLl = v.findViewById(R.id.distributorRowLl);
            tvDistributorName = v.findViewById(R.id.tvDistributorName);
            ratingTv = v.findViewById(R.id.ratingTv);
            ratingCV = v.findViewById(R.id.ratingCV);
            activeTv = v.findViewById(R.id.activeTv);
            tvAddedFQty = v.findViewById(R.id.tvAddedFQty);
            fQtyTvLL = v.findViewById(R.id.fQtyTvLL);
            iGroupTv = v.findViewById(R.id.iGroupTv);
            productSaltTv = v.findViewById(R.id.productSaltTv);



        }
    }

    private void AddProductInCart(ProductModel productModel, JSONObject extendedObj, boolean insertRecord) {
        try {
          /*  if (insertRecord) {
                showLoading(newOrderContext.requireActivity());
            }*/
            boolean isSalesMan = newOrderContext.getLicDetails().getRole().equalsIgnoreCase("SalesMan");
            String firmCode = isSalesMan ? newOrderContext.getSelectedStoreDetailsFromPicker().getFirmCode() : newOrderContext.getLicDetails().getFirmcode();
            String acCode = isSalesMan ? (SharedPrefUtils.getString(newOrderContext.getActivity(), FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? Constant.AC_CODE : Constant.PARTY_CODE)):productModel.getAcCode();
            JSONObject obj = new JSONObject();
            obj.put("UserId", SharedPrefUtils.getString(newOrderContext.getActivity(), Constant.USER_ID));
            obj.put("LicNo", isSalesMan ? newOrderContext.getLicDetails().getLicno() : productModel.getFLicNo() != null ? productModel.getFLicNo() : newOrderContext.getLicDetails().getLicno());
            obj.put("lFirmCode", isSalesMan ? firmCode : productModel.getFCode() != null ? productModel.getFCode() : newOrderContext.getLicDetails().getFirmcode());
            obj.put("AcCode", !acCode.isEmpty() ? acCode : newOrderContext.partyCode);
            obj.put("ItemCode", productModel.getProductCode());
            obj.put("ItemQty", insertRecord ? productModel.getProductCount() : extendedObj != null ? extendedObj.getDouble("ItemQty") : 0);
            obj.put("lApkName", newOrderContext.requireActivity().getPackageName());
            obj.put("IdCol", productModel.getProductIdCol());
            obj.put("cu_id", SharedPrefUtils.getString(newOrderContext.getActivity(), Constant.USER_ID_CU));
            obj.put("insert_record", insertRecord ? 1 : 0);
            if (extendedObj != null) {
                obj.put("ItemFQty", extendedObj.getDouble("ItemFQty"));
                obj.put("ItemSchQty",!SharedPrefUtils.getShowManualScheme(newOrderContext.requireActivity())?productModel.getSchQty() : extendedObj.getInt("ItemSchQty"));
                obj.put("ItemDSchQty",!SharedPrefUtils.getShowManualScheme(newOrderContext.requireActivity())?productModel.getDSchQty() : extendedObj.getInt("ItemDSchQty"));
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
            obj.put("device_id", SharedPrefUtils.getString(newOrderContext.getActivity(), Constant.DEVICE_ID));
            obj.put("device_name", ReckonUtils.getDeviceName());
            obj.put("default_hit", openOptionQtyBottomSheet);
            obj.put("v_code", SharedPrefUtils.getVersionCode(newOrderContext.getActivity()));
            obj.put("version_name", SharedPrefUtils.getVersionName(newOrderContext.getActivity()));
            obj.put("app_role", SharedPrefUtils.getString(newOrderContext.getActivity(), Constant.ROLE));

            new ConnectToRetrofit(retrofitCallBackListener, newOrderContext.getActivity(), getApiClientByPost().AddProductInCart(String.valueOf(obj)), insertRecord ? Constant.ADD_PRODUCT : Constant.GET_ADD_PRODUCT_CAL, insertRecord);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            if (jsonObject.length() > 0) {
                switch (action) {
                    case Constant.ADD_PRODUCT:
                    case Constant.GET_ADD_PRODUCT_CAL:
                        parseAddedProductData(jsonObject, action);
                        break;
                }
            }

        }
    }

    private void parseAddedProductData(JSONObject jsonObject, String action) {
        isPlusMinusClicked = false;
        openOptionQtyBottomSheet = false;
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

                if (action.equalsIgnoreCase(Constant.ADD_PRODUCT)) {
                    KeyboardUtils.hideSoftKeyboard(newOrderContext.getActivity());
                    Toast.makeText(newOrderContext.getActivity(), jsonObject.getString("Message"), Toast.LENGTH_LONG).show();
                    productArray.get(selected_pos).setProductRate(_rate);
                    productArray.get(selected_pos).setAmt(_goodsValue);
                    productArray.get(selected_pos).setSchemeAmt(_schemeValue);
                    productArray.get(selected_pos).setNetAmtCart(_netValue);
                    productArray.get(selected_pos).setDFQTYCart(_fQty);
                    productArray.get(selected_pos).setDisc2PerCart(_itemDisc2Per);
                    productArray.get(selected_pos).setDiscPerCart(_itemDiscPer);
                    productArray.get(selected_pos).setDisc1PerCart(_temDisc1Per);
                    productArray.get(selected_pos).setDoRemarkCart(ReckonUtils.getJsonCheckedString(jsonObject, "Remark", ""));
                    productArray.get(selected_pos).setTotalDiscCart(_totalDiscount);
                    productArray.get(selected_pos).setTaxAmtCart(_itemTaxAmt);
                    productArray.get(selected_pos).setSchQty(_schQty);
                    productArray.get(selected_pos).setDSchQty(_dSchQty);
                    productArray.get(selected_pos).setProductCount(_qty);
                    productArray.get(selected_pos).setProductDQty("" + productArray.get(selected_pos).getProductCount());
                    productArray.get(selected_pos).setDisc2AmtCart(_discPcsAmt);
                    productArray.get(selected_pos).setDiscAmtCart(_discPerAmt);
                    productArray.get(selected_pos).setDisc1AmtCart(_addDiscPerAmt);
                    newOrderContext.productAmountsList.add(Float.parseFloat(_goodsValue));
                    totalCalculatedPriceOfCartValue = newOrderContext.calculatePrice(newOrderContext.productAmountsList);
                    dialog.dismiss();
                } else if (action.equalsIgnoreCase(Constant.GET_ADD_PRODUCT_CAL)) {
                    String currencySign = newOrderContext.getLicDetails().getCurrency();
                    String goodsValue = currencySign + _goodsValue ;
                    String schemeValue = currencySign + _schemeValue ;
                    String totalDiscount = currencySign + _totalDiscount ;
                    String netValue = currencySign + _netValue ;
                    String gstValue = currencySign + _itemTaxAmt;
                    autoUpdateQty = true;
                    discEdt.setText(_itemDiscPer);
                    discEdt.setSelection(discEdt.getText().length());
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
                    tvGstTitle.setText(ReckonUtils.nonNullNotEmptyString(_itemTaxAmt)?"GST % (Exclusive)":"GST % (Inclusive)");
                    debouncer.debounce(Void.class, new Runnable() {
                        @Override public void run() {
                            autoUpdateQty = false;
                        }
                    }, 500, TimeUnit.MILLISECONDS);
                    //                    productArray.get(selected_pos).setDiscPerCart(_itemDiscPer);
//                    productArray.get(selected_pos).setProductCount(_qty);
//                    qtyEdt.setText(_qty);
                }

            } else {
                Toast.makeText(newOrderContext.getActivity(), jsonObject.getString("Message"), Toast.LENGTH_LONG).show();
                if (!productArray.get(selected_pos).getProductCount().equalsIgnoreCase(productArray.get(selected_pos).getProductDQty())) {
                    productArray.get(selected_pos).setProductCount(productArray.get(selected_pos).getProductDQty());
                }
            }
            notifyItemChanged(selected_pos, productArray.get(selected_pos));
        } catch (Exception e) {
            e.printStackTrace();
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

    private void openAddQtyBottomSheet(OrderViewHolder holder, int position, ProductModel productModel) {
        dialog = new BottomSheetDialog(newOrderContext.requireActivity());
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
        qtyEdt = dialog.findViewById(R.id.qtyEdt);
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
        EditText discPcsEdt = dialog.findViewById(R.id.discPcsEdt);
//        discPcsEdt.addTextChangedListener(new DecimalFilter(discPcsEdt, newOrderContext.requireActivity()));
        discPcsEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilters(4, 2)});
        priceEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilter(5, 2)});

       /* discPcsEdt.setInputType(TYPE_NUMBER_FLAG_DECIMAL | TYPE_CLASS_NUMBER);
        discPcsEdt.setKeyListener(DigitsKeyListener.getInstance("0123456789."));
        discPcsEdt.setFilters(new InputFilter[] {new DecimalDigitsInputFilter(5,2)});*/
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
        String currencySign = newOrderContext.getLicDetails().getCurrency();
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
        discEdt.setFilters(new InputFilter[]{new DecimalDigitsInputFilters(2, 2)});
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
        tvGstTitle.setText(ReckonUtils.nonNullNotEmptyString(productModel.getTaxAmtCart())?"GST % (Exclusive)":"GST % (Inclusive)");

        String netValue = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getNetAmtCart()) ? productModel.getNetAmtCart() : "0.0");
        tvNetValue.setText(netValue);

        String discPcsAmt = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDisc2AmtCart()) ? productModel.getDisc2AmtCart() : "0.0");
        String discPerAmt = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDiscAmtCart()) ? productModel.getDiscAmtCart() : "0.0");
        String addDiscPerAmt = currencySign + (ReckonUtils.nonNullNotEmptyString(productModel.getDisc1AmtCart()) ? productModel.getDisc1AmtCart() : "0.0");
        disPcsAmtTv.setText(discPcsAmt);
        disPerAmtTv.setText(discPerAmt);
        disAddAmtTv.setText(addDiscPerAmt);

        if (SharedPrefUtils.getShowItemRefNo(newOrderContext.requireActivity()) && ReckonUtils.nonNullNotEmptyString(productModel.getRefNumber())) {
            tvProductRefId.setText(productModel.getRefNumber());
            tvProductRefId.setVisibility(View.VISIBLE);
        } else {
            tvProductRefId.setVisibility(View.GONE);
        }
        llFQuantity.setVisibility(SharedPrefUtils.getShowFreeQty(newOrderContext.requireActivity()) ? View.VISIBLE : View.GONE);
        if (!SharedPrefUtils.getShowIncreaseDecreaseBtn(newOrderContext.requireActivity())) {
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
        if (!SharedPrefUtils.getShowManualScheme(newOrderContext.requireActivity())) {
            llManualScheme.setVisibility(View.GONE);
        } else {
            if (ReckonUtils.nonNullNotEmptyString(productModel.getSchQty())) {
                edtScheme.setText(productModel.getSchQty().replace(".0",""));
            }
            if (ReckonUtils.nonNullNotEmptyString(productModel.getDSchQty())) {
                edtDScheme.setText(productModel.getDSchQty().replace(".0",""));
            }
        }
        String priceValue = productModel.getProductRate();
        priceEdt.setText(ReckonUtils.nonNullNotEmptyString(priceValue)?priceValue:"");
        if (!SharedPrefUtils.getShowEnablePriceEdt(newOrderContext.requireActivity())) {
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


        if (!SharedPrefUtils.getShowDiscountPer(newOrderContext.requireActivity())) {
            llDiscountPer.setVisibility(View.GONE);
        }
        if (!SharedPrefUtils.getShowDiscountPcs(newOrderContext.requireActivity())) {
            llDiscountPcs.setVisibility(View.GONE);
        }
        if (!SharedPrefUtils.getShowItemRemark(newOrderContext.requireActivity())) {
            llAddRemark.setVisibility(View.GONE);
        }

        if (!SharedPrefUtils.getShowScheme(newOrderContext.requireActivity())) {
            llScheme.setVisibility(View.GONE);
        }

        if (!SharedPrefUtils.getShowAddDiscountPer(newOrderContext.requireActivity())) {
            llAddDiscountPer.setVisibility(View.GONE);
        }

        if (productModel.isShowStock()) {
            setStockWithValueView(holder, productModel, tvStockIn, true);
        } else {
            setStockView(holder, productModel, tvStockIn, true);
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
                        @Override public void run() {
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
                debouncer.debounce(Void.class, new Runnable() {
                    @Override public void run() {
                        callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
                    }
                }, 500, TimeUnit.MILLISECONDS);
            }

            @Override
            public void afterTextChanged(Editable editable) {

            }
        });

        editTextWatcher(edtScheme, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        editTextWatcher(edtDScheme, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        editTextWatcher(discPcsEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        editTextWatcher(discEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        editTextWatcher(discAddEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position);

        dialog.findViewById(R.id.cvAddToCart).setOnClickListener(view1 -> {
            if (!isSalesMan && productModel.getIsStockistActive() == 0) {
                Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
            } else {
                if (ReckonUtils.nonNullNotEmptyString(qtyEdt.getText().toString())) {
                    productArray.get(position).setProductCount(qtyEdt.getText().toString());
                    UpdatingCartItems(position, productArray.get(position));
                    selected_pos = position;
                    callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, true);
                    holder.addEnteredValue.setEnabled(false);
                    setConstantBundle(productArray.get(position), newOrderContext);
                    holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                }
            }
        });
        callAddDraftOrderAPI(qtyEdt, fQtyEdt, edtScheme, edtDScheme, priceEdt, discEdt, discPcsEdt, discAddEdt, remarkEdt, position, false);
        dialog.getBehavior().setState(BottomSheetBehavior.STATE_EXPANDED);
        dialog.show();
    }

    private void editTextWatcher(EditText editText, EditText fQtyEdt, EditText edtScheme, EditText edtDScheme, EditText priceEdt, EditText discEdt, EditText discPcsEdt, EditText discAddEdt, EditText remarkEdt, int position) {
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
            extendedObj.put("ItemQty", ReckonUtils.nonNullNotEmptyString(qtyEdt.getText().toString()/*enteredLocalQty*/) ? /*enteredLocalQty*/qtyEdt.getText().toString() : "0");
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


}
