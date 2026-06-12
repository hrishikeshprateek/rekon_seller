package com.reckon.reckonorders.Adapter;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Others.Constant.Constant.isTextEnterOn;
import static com.reckon.reckonorders.Utils.ReckonUtils.setDynamicMargin;

import android.app.Activity;
import android.app.ProgressDialog;
import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.InputType;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.TextWatcher;
import android.text.style.ForegroundColorSpan;
import android.text.style.RelativeSizeSpan;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
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

import com.google.gson.Gson;
import com.reckon.reckonorders.Fragment.Home.RecentOrderedProductsFragment;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewModals.AddToCartModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

public class RecentOrderedProductsAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> implements RetrofitCallBackListener {
    private final RetrofitCallBackListener retrofitCallBackListener;
    private ArrayList<Integer> addItemToCart;
    int m = -1;
    private ListPopupWindow listPopupWindow;
    ArrayList<AddToCartModel> productCountList = new ArrayList<>();

    private final ArrayList<ProductModel> productArray;
    private final RecentOrderedProductsFragment newOrderContext;
    private final String FROM;
    Gson gson = new Gson();
    private int selected_pos = -1;
    private String totalCalculatedPriceOfCartValue = "";
    private final boolean isSalesMan;
    private boolean isPlusMinusClicked = false;
    private boolean isAddCartClicked = false;
    private ProgressDialog progress;

    public RecentOrderedProductsAdapter(RecentOrderedProductsFragment context, ArrayList<ProductModel> arrayList, String _from) {
        retrofitCallBackListener = this;
        this.productArray = arrayList;
        this.newOrderContext = context;
        this.FROM = _from;
        isSalesMan = newOrderContext.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new OrderViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.recent_product_row_layout, parent, false));
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
        if (productCountList != null && productCountList.size() != 0) {
            for (AddToCartModel cartModel : productCountList) {
                if (cartModel.getId() == productArray.get(position).getProductIdCol()) {
                    productArray.get(position).setProductCount(cartModel.getItemCount());
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
                holder.itemCount.setInputType(InputType.TYPE_CLASS_NUMBER);
                if (productModel.getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                    holder.addEnteredValue.setEnabled(false);
                    holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                    holder.addEnteredValue.setVisibility(View.GONE);
                } else {
                    holder.addEnteredValue.setEnabled(true);
                    holder.addEnteredValue.setVisibility(View.VISIBLE);
                    holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.title_color_primary));
                }
            }

            if (position == productArray.size() - 1)
                holder.constraintLayoutNewOrder.setLayoutParams(setDynamicMargin(0, 0, 0, 20));
            if (productModel != null) {
                if (productModel.getProductpacking() != null && !productModel.getProductpacking().isEmpty()) {
                    final SpannableString text = new SpannableString(productModel.getProductName() + ", " + productModel.getProductpacking());
                    text.setSpan(new RelativeSizeSpan(0.8f), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    text.setSpan(new ForegroundColorSpan(newOrderContext.getResources().getColor(R.color.title_color_primary)), text.length() - productModel.getProductpacking().length(), text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    holder.tvProductName.setText(text);
                } else {
                    holder.tvProductName.setText(productModel.getProductName());
                }

                holder.tv_product_by.setText(productModel.getProductMfgComp());
                holder.tvRate.setText(String.valueOf(newOrderContext.getLicDetails().getCurrency() + productModel.getProductRate()));
                holder.tvRate.setVisibility(productModel.isShowRate() && productModel.getProductRate() != null && !productModel.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);
                holder.tvMRPValue.setText(String.valueOf("(MRP " + productModel.getProductMrp() + ")"));
                holder.tvMRPValue.setVisibility(productModel.isShowMrp() && productModel.getProductMrp() != null && !productModel.getProductMrp().isEmpty() ? View.VISIBLE : View.GONE);
                holder.tvGST.setText(String.valueOf("(GST " + productModel.getTax() + "%" + ")"));
                holder.tvGST.setVisibility(productModel.isShowRate() && productModel.getProductRate() != null && !productModel.getProductRate().isEmpty() ? View.VISIBLE : View.GONE);
                holder.tvProductScheme.setText(productModel.getScheme());
                holder.tvProductScheme.setVisibility(productModel.isShowScheme() && productModel.getScheme() != null && !productModel.getScheme().isEmpty() ? View.VISIBLE : View.GONE);
                holder.tvDistributorName.setText(productModel.getDistributor());
                holder.distributorRowLl.setVisibility(newOrderContext.getLicDetails().getFirmcode().isEmpty() && productModel.getDistributor() != null && !productModel.getDistributor().isEmpty() ? View.VISIBLE : View.GONE);
                holder.ratingTv.setText(String.valueOf(productModel.getRating()));
                holder.ratingCV.setVisibility(productModel.getRating() != 0 ? View.VISIBLE : View.GONE);
                holder.activeTv.setVisibility(!productModel.getActiveText().isEmpty() ? View.VISIBLE : View.GONE);
                holder.activeTv.setText("( " + String.valueOf(productModel.getActiveText()) + " )");
                holder.activeTv.setTextColor(productModel.getIsStockistActive()!=0?newOrderContext.getResources().getColor(R.color.darkGreen01):newOrderContext.getResources().getColor(R.color.red));
                if (productModel.isShowStock()) {
                    setStockWithValueView(holder, productModel);
                } else {
                    setStockView(holder, productModel);
                }

                if (ReckonUtils.nonNullNotEmptyString(productModel.getQtyOrdered()) && !productModel.getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                    holder.itemCount.setText(productModel.getQtyOrdered());
                    holder.cvAddToCart.setVisibility(View.GONE);
                    holder.addEnteredValue.setVisibility(View.VISIBLE);
                    holder.qty_ll.setVisibility(View.VISIBLE);
                } else {
                    holder.cvAddToCart.setVisibility(View.VISIBLE);
                    holder.addEnteredValue.setVisibility(View.GONE);
                    holder.qty_ll.setVisibility(View.GONE);
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
                return false;
            });
            holder.addEnteredValue.setOnClickListener(v -> {
                if(!isSalesMan && productModel.getIsStockistActive()==0){
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                }else{
                if (!holder.itemCount.getText().toString().isEmpty() && Integer.parseInt(holder.itemCount.getText().toString()) != 0) {
                    productArray.get(position).setProductCount(holder.itemCount.getText().toString());
                    UpdatingCartItems(position, productArray.get(position));
                    selected_pos = position;
                    AddProductInCart(productArray.get(position));
                    holder.addEnteredValue.setEnabled(false);
                    setConstantBundle(productArray.get(position), newOrderContext);
                    holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                }
                }
            });
            holder.itemView.setOnClickListener(v -> gotoProductDetails(v, productModel, productArray, position));
            holder.cvAddToCart.setOnClickListener(v -> {
                if(!isSalesMan && Objects.requireNonNull(productModel).getIsStockistActive()==0){
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                }else {
                    isAddCartClicked = true;
                    if (productArray.get(position).getProductStockType().equalsIgnoreCase("OUTSTOCK")) {
                        Toast.makeText(newOrderContext.getActivity(), "Under Development", Toast.LENGTH_SHORT).show();
                    } else {
                        holder.cvAddToCart.setVisibility(View.GONE);
                        holder.addEnteredValue.setVisibility(View.VISIBLE);
                        holder.qty_ll.setVisibility(productModel.getProductStockType().equalsIgnoreCase("OUTSTOCK") ? View.GONE : View.VISIBLE);

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
            });
            holder.plus_icon.setOnClickListener(v -> {
                if(!isSalesMan && productModel.getIsStockistActive()==0){
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                }else {
                    isPlusMinusClicked = true;
                    holder.addEnteredValue.setEnabled(false);
                    holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                    productModel.setProductCount(String.valueOf(Double.parseDouble(productArray.get(position).getQtyOrdered()) + 1));
                    UpdatingCartItems(position, productArray.get(position));
                    holder.itemCount.setText(productModel.getQtyOrdered());
                    selected_pos = position;
                    AddProductInCart(productArray.get(position));
                    setConstantBundle(productArray.get(position), newOrderContext);
                }
            });
            holder.minus_icon.setOnClickListener(v -> {
                if(!isSalesMan && productModel.getIsStockistActive()==0){
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                }else{
                isPlusMinusClicked = true;
                holder.addEnteredValue.setEnabled(false);
                holder.addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                if (!ReckonUtils.nonNullNotEmptyString(productModel.getQtyOrdered())) {
                    holder.cvAddToCart.setVisibility(View.VISIBLE);
                    holder.addEnteredValue.setVisibility(View.GONE);
                    holder.qty_ll.setVisibility(View.GONE);
                } else if (ReckonUtils.nonNullNotEmptyString(productModel.getQtyOrdered())) {
                    productModel.setProductCount(String.valueOf(Double.parseDouble(productArray.get(position).getQtyOrdered()) - 1));
                    UpdatingCartItems(position, productModel);
                    holder.itemCount.setText(productModel.getQtyOrdered());
                    selected_pos = position;
                    AddProductInCart(productModel);
                    setConstantBundle(productModel, newOrderContext);
                }
                }

            });
            if (productModel.getRating() > 0) {
                holder.ratingCV.setCardBackgroundColor((productModel.getRating() >= 2.5 && productModel.getRating() <= 3.9) ? newOrderContext.getResources().getColor(R.color.yellow) : productModel.getRating() < 2.5 ? newOrderContext.getResources().getColor(R.color.red) : newOrderContext.getResources().getColor(R.color.green));
            }
            holder.tvDaysAgo.setText(productModel.getDaysAgoOrder());
            holder.tvDaysAgo.setVisibility(productModel.getDaysAgoOrder() != null && !productModel.getDaysAgoOrder().isEmpty() ? View.VISIBLE : View.GONE);
            holder.addMoreParentCard.setVisibility(position == productArray.size() - 1 ? View.VISIBLE : View.GONE);
            holder.addMoreParentCard.setOnClickListener(v -> {
                newOrderContext.getActivity().onBackPressed();
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setStockWithValueView(OrderViewHolder holder, ProductModel productModel) {
        switch (productModel.getProductStockType()) {
            case "INSTOCK":
                holder.addToCart.setText(newOrderContext.getString(R.string.add));
                holder.tvStockIn.setText("Stock: " + productModel.getProductStock() + " Pcs");
                holder.tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.darkGreen01));
                break;
            case "OUTSTOCK":
                holder.addToCart.setText(newOrderContext.getString(R.string.notify));
                holder.cvAddToCart.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                holder.tvStockIn.setText(newOrderContext.getString(R.string.out_of_stock));
                holder.tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.text_color_level));
                break;
            case "LOWSTOCK":
                holder.addToCart.setText(newOrderContext.getString(R.string.add));
                holder.tvStockIn.setText("Stock: " + productModel.getProductStock() + " Pcs");
                holder.tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.yellow));
                break;
        }
    }

    private void setStockView(OrderViewHolder holder, ProductModel productModel) {
        switch (productModel.getProductStockType()) {
            case "INSTOCK":
                holder.addToCart.setText(newOrderContext.getString(R.string.add));
                holder.tvStockIn.setText(isSalesMan ? "Stock: " + productModel.getProductStock() + " Pcs" : newOrderContext.getString(R.string.available));
                holder.tvStockIn.setTextColor(/*newOrderContext.getThirdHeaderColor()*/newOrderContext.getResources().getColor(R.color.darkGreen01));
                break;
            case "OUTSTOCK":
                holder.addToCart.setText(newOrderContext.getString(R.string.notify));
                holder.cvAddToCart.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                holder.tvStockIn.setText(newOrderContext.getString(R.string.out_of_stock));
                holder.tvStockIn.setTextColor(/*newOrderContext.getThirdHeaderColor()*/newOrderContext.getResources().getColor(R.color.text_color_level));
                break;
            case "LOWSTOCK":
                holder.addToCart.setText(newOrderContext.getString(R.string.add));
                holder.tvStockIn.setText(isSalesMan ? "Stock: " + productModel.getProductStock() + " Pcs" : newOrderContext.getString(R.string.low_stock));
                holder.tvStockIn.setTextColor(newOrderContext.getResources().getColor(R.color.yellow));
                break;
        }
    }

    private void setTheme(OrderViewHolder holder) {
        holder.tvProductName.setTextColor(newOrderContext.getResources().getColor(R.color.text_color_level));
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
        cartModel.setItemCount(productModel.getQtyOrdered());
        productCountList.add(cartModel);
        setConstantBundle(productModel, newOrderContext);
        Bundle bundle1 = new Bundle();
        newOrderContext.searchedText = newOrderContext.search_loc_et.getText().toString();
        bundle1.putString("search_text", newOrderContext.search_loc_et.getText().toString());
        bundle1.putString("Lic_No", productModel.getFLicNo());
        bundle1.putString("Firm_Code", productModel.getFCode());
        Navigation.findNavController(v).navigate(R.id.toProductDetails, bundle1);
    }

    private void setConstantBundle(ProductModel productModel, RecentOrderedProductsFragment newOrderContext) {
        Constant.bundle = new Bundle();
        Constant.bundle.putString("id", String.valueOf(productModel.getProductIdCol()));
        Constant.bundle.putString("itemCount", productModel.getQtyOrdered());
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
        cartModel.setItemCount(productArray.get(position).getQtyOrdered());
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
                if(!isSalesMan && productModels.getIsStockistActive()==0){
                    Toast.makeText(newOrderContext.requireActivity(), newOrderContext.getString(R.string.store_is_not_active_msg), Toast.LENGTH_LONG).show();
                }else {
                    listPopupWindow.dismiss();
                    m = 1;
                    new Handler().postDelayed(() -> {
                        productModels.setProductCount(addItemToCart.get(i).toString());
                        UpdatingCartItems(position, productModels);
                        if (textView instanceof TextView)
                            ((TextView) textView).setText(productArray.get(position).getQtyOrdered());
                        else
                            ((EditText) textView).setText(productArray.get(position).getQtyOrdered());
                        selected_pos = position;
                        AddProductInCart(productModels);
                        Constant.bundle = new Bundle();
                        Constant.bundle.putString("id", String.valueOf(position));
                        Constant.bundle.putString("itemCount", productModels.getQtyOrdered());
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
        TextView tvStockIn, tvMRPValue, tvProductName, tvProductScheme, tvProductPacking, tvGST, tvRate, tv_product_by, tvDaysAgo, activeTv;
        LinearLayout qty_ll, distributorRowLl;
        TextView addToCart, tvDistributorName, ratingTv;
        EditText itemCount;
        ImageView plus_icon, minus_icon;
        LinearLayout constraintLayoutNewOrder;
        CardView cvAddToCart, addEnteredValue, ratingCV, addMoreParentCard;

        OrderViewHolder(View v) {
            super(v);
            itemCount = v.findViewById(R.id.item_number);
            addEnteredValue = v.findViewById(R.id.addEnteredValue);
            addEnteredValue.setVisibility(View.VISIBLE);
   /*         if (isTextEnterOn) {
                addEnteredValue.setEnabled(false);
                itemCount.setCompoundDrawables(null, null, null, null);
//                addEnteredValue.setVisibility(View.VISIBLE);
            } else {
                itemCount.setWidth(ViewGroup.LayoutParams.WRAP_CONTENT);
                addEnteredValue.setVisibility(View.GONE);
            }*/
            itemCount.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {
                }

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                    if (isAddCartClicked && !isPlusMinusClicked) {
                        productArray.get(selected_pos).setProductCount(!s.toString().isEmpty() ? s.toString() : "0");
                        if (!productArray.get(selected_pos).getProductCount().equalsIgnoreCase(productArray.get(selected_pos).getQtyOrdered())) {
                            addEnteredValue.setEnabled(true);
                            addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.title_color_primary));
                        } else {
                            addEnteredValue.setEnabled(false);
                            addEnteredValue.setCardBackgroundColor(newOrderContext.getResources().getColor(R.color.grey));
                        }
                    }
                }

                @Override
                public void afterTextChanged(Editable s) {

                }
            });
            constraintLayoutNewOrder = v.findViewById(R.id.constraintLayoutNewOrder);
            tvProductScheme = v.findViewById(R.id.tvProductScheme);
            tvProductPacking = v.findViewById(R.id.tvProductPacking);
            tvStockIn = v.findViewById(R.id.tvStockIn);
            tvDaysAgo = v.findViewById(R.id.tvDaysAgo);
            tvMRPValue = v.findViewById(R.id.tvMRPValue);
            tvProductName = v.findViewById(R.id.productName);
            plus_icon = v.findViewById(R.id.plus_icon);
            minus_icon = v.findViewById(R.id.minus_icon);
            cvAddToCart = v.findViewById(R.id.cvAddToCart);
            addToCart = v.findViewById(R.id.addToCart);
            qty_ll = v.findViewById(R.id.llQuantity);
            tvRate = v.findViewById(R.id.tvRate);
            tvGST = v.findViewById(R.id.tvGST);
            tv_product_by = v.findViewById(R.id.productCompanyName);
            distributorRowLl = v.findViewById(R.id.distributorRowLl);
            tvDistributorName = v.findViewById(R.id.tvDistributorName);
            ratingTv = v.findViewById(R.id.ratingTv);
            ratingCV = v.findViewById(R.id.ratingCV);
            addMoreParentCard = v.findViewById(R.id.addMoreParentCard);
            activeTv = v.findViewById(R.id.activeTv);

        }
    }

    private void AddProductInCart(ProductModel productModel) {
        try {
            showLoading(newOrderContext.requireActivity());
            boolean isSalesMan = newOrderContext.getLicDetails().getRole().equalsIgnoreCase("SalesMan");
            String firmCode = isSalesMan ? newOrderContext.getSelectedStoreDetailsFromPicker().getFirmCode() : newOrderContext.getLicDetails().getFirmcode();
            String acCode = SharedPrefUtils.getString(newOrderContext.getActivity(), FROM.equalsIgnoreCase(Constant.NEW_ORDER) ? Constant.AC_CODE : Constant.PARTY_CODE);
            JSONObject obj = new JSONObject();
            obj.put("UserId", SharedPrefUtils.getString(newOrderContext.getActivity(), Constant.USER_ID));
            obj.put("LicNo", isSalesMan ? newOrderContext.getLicDetails().getLicno() : productModel.getFLicNo() != null ? productModel.getFLicNo() : newOrderContext.getLicDetails().getLicno());
            obj.put("lFirmCode", isSalesMan ? firmCode : productModel.getFCode() != null ? productModel.getFCode() : newOrderContext.getLicDetails().getFirmcode());
            obj.put("AcCode", !acCode.isEmpty() ? acCode : newOrderContext.partyCode);
            obj.put("ItemCode", productModel.getProductCode());
            obj.put("ItemQty", productModel.getProductCount());
            obj.put("ItemRate", productModel.getProductRateA());
            obj.put("ItemSchQty", productModel.getSchQty());
            obj.put("ItemDSchQty", productModel.getDSchQty());
            obj.put("lApkName", newOrderContext.requireActivity().getPackageName());
            obj.put("IdCol", productModel.getProductIdCol());
            obj.put("cu_id", SharedPrefUtils.getString(newOrderContext.getActivity(), Constant.USER_ID_CU));
            obj.put("device_id", SharedPrefUtils.getString(newOrderContext.getActivity(), Constant.DEVICE_ID));
            obj.put("device_name", ReckonUtils.getDeviceName());
            obj.put("v_code", SharedPrefUtils.getVersionCode(newOrderContext.getActivity()));
            obj.put("version_name", SharedPrefUtils.getVersionName(newOrderContext.getActivity()));
            obj.put("app_role", SharedPrefUtils.getString( newOrderContext.getActivity(), Constant.ROLE));
            obj.put("insert_record", 1);
            new ConnectToRetrofit(retrofitCallBackListener, newOrderContext.getActivity(), getApiClientByPost().AddProductInCart(String.valueOf(obj)), Constant.ADD_PRODUCT, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        dismissLoading(newOrderContext.requireActivity());
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            if (jsonObject.length() > 0) {
                switch (action) {
                    case Constant.ADD_PRODUCT:
                        parseAddedProductData(jsonObject);
                        break;
                }
            }

        }
    }

    private void parseAddedProductData(JSONObject jsonObject) {
        isPlusMinusClicked = false;
        try {
            if (jsonObject.getBoolean("Status")) {
                KeyboardUtils.hideSoftKeyboard(newOrderContext.getActivity());
                Toast.makeText(newOrderContext.getActivity(), jsonObject.getString("Message"), Toast.LENGTH_LONG).show();
                productArray.get(selected_pos).setAmt(ReckonUtils.getJsonCheckedString(jsonObject, "Amt", "0.0"));
                productArray.get(selected_pos).setSchemeAmt(ReckonUtils.getJsonCheckedString(jsonObject, "ItemSchAmt", "0.0"));
                productArray.get(selected_pos).setProductDQty(productArray.get(selected_pos).getQtyOrdered());
                productArray.get(selected_pos).setQtyOrdered(productArray.get(selected_pos).getProductCount());

                newOrderContext.productAmountsList.add(Float.parseFloat(ReckonUtils.getJsonCheckedString(jsonObject, "Amt", "0.0")));
                totalCalculatedPriceOfCartValue = newOrderContext.calculatePrice(newOrderContext.productAmountsList);
                newOrderContext.updateCartValue(totalCalculatedPriceOfCartValue);
                newOrderContext.isSearched = true;
                newOrderContext.clearSearchText();
                newOrderContext.getProductList("", 1, false);
            } else {
                Toast.makeText(newOrderContext.getActivity(), jsonObject.getString("Message"), Toast.LENGTH_LONG).show();
                if (!productArray.get(selected_pos).getQtyOrdered().equalsIgnoreCase(productArray.get(selected_pos).getProductDQty())) {
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

}
