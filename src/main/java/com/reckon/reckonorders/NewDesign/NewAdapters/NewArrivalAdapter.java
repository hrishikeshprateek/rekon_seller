package com.reckon.reckonorders.NewDesign.NewAdapters;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.google.gson.Gson;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Fragment.Home.CartFragment;
import com.reckon.reckonorders.Fragment.Home.HomeFragment;
import com.reckon.reckonorders.Model.OrderDetailsModel;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.Model.TimeSlotModel;
import com.reckon.reckonorders.NewDesign.NewFragments.BrandsFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.DeliveryDetails;
import com.reckon.reckonorders.NewDesign.NewFragments.Feedback;
import com.reckon.reckonorders.NewDesign.NewFragments.MyBillsFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.NewArrivalFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.OrderHistory;
import com.reckon.reckonorders.NewDesign.NewFragments.ProductDetailsFragment;
import com.reckon.reckonorders.NewDesign.NewMenuEnums.MenuEnums;
import com.reckon.reckonorders.NewDesign.NewModals.AddToCartModel;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BrandListItem;
import com.reckon.reckonorders.NewDesign.NewModals.Home.MenuListItem;
import com.reckon.reckonorders.NewDesign.NewModals.Home.TestimonialsListItem;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.DeliveryDateTagLayoutBinding;
import com.reckon.reckonorders.databinding.FeedbackOptionsLayoutBinding;
import com.reckon.reckonorders.databinding.MyBillsRowLayoutBinding;
import com.reckon.reckonorders.databinding.OrderHistoryLayoutBinding;

import java.util.ArrayList;
/*changes*/

public class NewArrivalAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    ArrayList<TestimonialsListItem> testimonials;
    ArrayList<BrandListItem> brandListItems;
    ArrayList<ProductModel> productArrayList;
    Fragment fragment;
    String type;
    String allSelectedDate = "";
    String bgColor;
    int totalWidth = 0, parentWidth = 0, selectedTimeSlotPos = -1;
    int i = 0;
    ArrayList<MenuListItem> menus;
    ArrayList<String> options;
    private ArrayList<TimeSlotModel> timeSlotList;
    ArrayList<OrderDetailsModel> orderList;
    ArrayList<OrderDetailsModel> billsList;
    Context context;
    private Gson gson = new Gson();
    private boolean isSalesMan = false;

    public NewArrivalAdapter(DeliveryDetails fragment, int recyclerWidth, ArrayList<TimeSlotModel> timeSlotList, int selectedPos) {
        this.fragment = fragment;
        this.timeSlotList = timeSlotList;
        parentWidth = recyclerWidth;
        selectedTimeSlotPos = selectedPos;
    }

    public NewArrivalAdapter(Fragment fragment, ArrayList<String> options) {
        this.fragment = fragment;
        this.options = options;
        isSalesMan = ((BaseFragment) fragment).getLicDetails().getRole().equalsIgnoreCase("SalesMan");
    }

    public NewArrivalAdapter(OrderHistory fragment, ArrayList<OrderDetailsModel> orderList) {
        this.fragment = fragment;
        this.orderList = orderList;
        isSalesMan = fragment.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }
    public NewArrivalAdapter(MyBillsFragment fragment, ArrayList<OrderDetailsModel> billsList) {
        this.fragment = fragment;
        this.billsList = billsList;
        isSalesMan = fragment.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    public NewArrivalAdapter(HomeFragment fragment, ArrayList<MenuListItem> menu, ArrayList<BrandListItem> brandListItems, ArrayList<TestimonialsListItem> testimonial, ArrayList<ProductModel> arrivalListItems, String bgColor, String type) {
        this.productArrayList = arrivalListItems;
        this.fragment = fragment;
        this.type = type;
        this.menus = menu;
        this.bgColor = bgColor;
        this.brandListItems = brandListItems;
        this.testimonials = testimonial;
        isSalesMan = fragment.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    public NewArrivalAdapter(BrandsFragment fragment, ArrayList<BrandListItem> brandListItems, String type) {
        this.fragment = fragment;
        this.type = type;
        this.brandListItems = brandListItems;
        isSalesMan = fragment.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    public NewArrivalAdapter(Fragment fragment, ArrayList<ProductModel> arrivalListItems, String type) {
        this.fragment = fragment;
        this.type = type;
        this.productArrayList = arrivalListItems;
        isSalesMan = ((BaseFragment) fragment).getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    public NewArrivalAdapter(ProductDetailsFragment fragment, ArrayList<ProductModel> data) {
        this.productArrayList = data;
        this.fragment = fragment;
        isSalesMan = fragment.getLicDetails().getRole().equalsIgnoreCase("SalesMan");

    }

    public NewArrivalAdapter(Context context, ArrayList<String> options) {
        this.options = options;
        this.context = context;
    }


    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View itemView;
        if (fragment instanceof DeliveryDetails) {
            return new DateBinderHolder(DeliveryDateTagLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        } else if (fragment instanceof OrderHistory) {
            return new OrderHistoryHolder(OrderHistoryLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        } else if (fragment instanceof MyBillsFragment) {
            return new MyBillsHolder(MyBillsRowLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        } else if (fragment instanceof HomeFragment || fragment instanceof BrandsFragment || fragment instanceof NewArrivalFragment || fragment instanceof CartFragment) {
            if (type.equalsIgnoreCase(fragment.getString(R.string.menu))) {
                itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.menu_item_layout, parent, false);
            } else if (type.equalsIgnoreCase(fragment.getString(R.string.testimonial))) {
                itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.testimonial_layout, parent, false);
            } else if (type.equalsIgnoreCase(fragment.getString(R.string.new_arrival))) {
                itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.new_arrival_layout, parent, false);
            } else {
                itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.brands_layout, parent, false);
            }
            return new NewArrivalHolder(itemView);
        } else if (fragment instanceof ProductDetailsFragment) {
            itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.alternate_brands_layout, parent, false);
            return new NewArrivalHolder(itemView);
        } else {
            return new FeedbackOptionHolder(FeedbackOptionsLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        }
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        if (holder instanceof DateBinderHolder) {
            holder.itemView.post(() -> {
                int cellWidth = holder.itemView.getWidth();// this will give you cell width dynamically
                //    int cellHeight = holder.itemView.getHeight();// this will give you cell height dynamically
                totalWidth = totalWidth + cellWidth;
            });
            ((DateBinderHolder) holder).binding.tvDate.setTextColor(selectedTimeSlotPos != position ? fragment.getResources().getColor(R.color.black) : fragment.getResources().getColor(R.color.white));
            ((DateBinderHolder) holder).binding.tvDate.setText(timeSlotList.get(position).getDate());
            ((DateBinderHolder) holder).binding.dateCardHolder.setCardBackgroundColor(selectedTimeSlotPos != position ? fragment.getResources().getColor(R.color.white) : ((DeliveryDetails) fragment).getSecondHeaderTextColor());
            ((DateBinderHolder) holder).binding.dateCardHolder.setOnClickListener(v -> {
                if (selectedTimeSlotPos != position) {
                    selectedTimeSlotPos = position;
                    allSelectedDate = timeSlotList.get(position).getDate();
                    timeSlotList.get(position).setColor(fragment.getString(R.string.blue));
                    ((DateBinderHolder) holder).binding.dateCardHolder.setCardBackgroundColor(((DeliveryDetails) fragment).getSecondHeaderTextColor());
                } else {
                    allSelectedDate = "";
                    selectedTimeSlotPos = -1;
                    timeSlotList.get(position).setColor(fragment.getString(R.string.white));
                    ((DateBinderHolder) holder).binding.dateCardHolder.setCardBackgroundColor(fragment.getResources().getColor(R.color.white));
                }
                ((DeliveryDetails) fragment).getSlotTime(allSelectedDate);
                notifyDataSetChanged();

/*
                if (timeSlotList.get(position).getColor().equals(fragment.getString(R.string.blue))) {
                    timeSlotList.get(position).setColor(fragment.getString(R.string.white));
                    if (!allSelectedDate.isEmpty())
                        allSelectedDate = allSelectedDate + "," + timeSlotList.get(position).getDate();
                    else
                        allSelectedDate = timeSlotList.get(position).getDate();
                    ((DateBinderHolder) holder).binding.dateCardHolder.setCardBackgroundColor(fragment.getResources().getColor(R.color.white));
                } else {
                    timeSlotList.get(position).setColor(fragment.getString(R.string.blue));
                    String[] dateSelected = allSelectedDate.split(",");
                    allSelectedDate = "";
                    for (String date : dateSelected) {
                        if (!date.equals(timeSlotList.get(position).getDate())) {
                            if (!allSelectedDate.isEmpty())
                                allSelectedDate = allSelectedDate + "," + date;
                            else
                                allSelectedDate = date;
                        }
                    }
                    ((DateBinderHolder) holder).binding.dateCardHolder.setCardBackgroundColor(fragment.getResources().getColor(R.color.blue3));
                }*/
            });
            //       int h= ((DateBinderHolder) holder).binding.dateCardHolder.getLayoutParams().height ;
//            ViewTreeObserver viewTreeObserver = ((DateBinderHolder) holder).binding.dateCardHolder.getViewTreeObserver();
//            if (viewTreeObserver.isAlive()) {
//                viewTreeObserver.addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
//                    @Override
//                    public void onGlobalLayout() {
//                        ((DateBinderHolder) holder).binding.dateCardHolder.getViewTreeObserver().removeGlobalOnLayoutListener(this);
//                        totalWidth = ((DateBinderHolder) holder).binding.dateCardHolder.getWidth();
//                    }
//                });
//            }

        } else if (holder instanceof OrderHistoryHolder) {
            ((OrderHistoryHolder) holder).binding.orderId.setTextColor(((OrderHistory) fragment).getThirdHeaderColor());
            //    ((OrderHistoryHolder) holder).binding.tvOrderIdText.setTextColor(((OrderHistory)fragment).getThirdHeaderColor());
            ((OrderHistoryHolder) holder).binding.orderId.setText("#00" + orderList.get(position).getOrderId());
            //     ((OrderHistoryHolder) holder).binding.tvOrderIdText.setText("#00" + orderList.get(position).getOrderId());
            ((OrderHistoryHolder) holder).binding.orderPlacingDate.setText(orderList.get(position).getPlacedOn());
            ((OrderHistoryHolder) holder).binding.orderStatus.setText(orderList.get(position).getOrderStatus());
            ((OrderHistoryHolder) holder).binding.orderValue.setText(((OrderHistory) fragment).getLicDetails().getCurrency() + orderList.get(position).getOrderValue());
            ((OrderHistoryHolder) holder).binding.orderTotalItem.setText(orderList.get(position).getNoOfItem());
            ((OrderHistoryHolder) holder).binding.partyNameTxt.setText(orderList.get(position).getAccountName());
            ((OrderHistoryHolder) holder).binding.partyNameTxt.setVisibility(orderList.get(position).getAccountName().isEmpty() ? View.GONE : View.VISIBLE);
            ((OrderHistoryHolder) holder).binding.orderDetailsButtonCard.setCardBackgroundColor(((OrderHistory) fragment).getThirdHeaderColor());
            ((OrderHistoryHolder) holder).binding.orderStatus.setTextColor(((OrderHistory) fragment).getThirdHeaderColor());
            if (position == orderList.size() - 1) {
                ReckonUtils.setLastVisibleItemMargin(((OrderHistoryHolder) holder).binding.itemLl, 5, 5, 5, 250);
            }
            ((OrderHistoryHolder) holder).binding.orderDetailsCard.setOnClickListener(v -> {
                Bundle bundle = new Bundle();
                if (((OrderHistory) fragment).storeDetailObjectModel != null)
                    bundle.putString(Constant.PARTY, gson.toJson(((OrderHistory) fragment).storeDetailObjectModel));
                bundle.putString(Constant.ORDER_ID, orderList.get(position).getOrderId());
                Navigation.findNavController(v).navigate(R.id.nav_order_details, bundle);
            });
        } else if (holder instanceof MyBillsHolder) {
            ((MyBillsHolder) holder).binding.orderId.setTextColor(((MyBillsFragment) fragment).getThirdHeaderColor());
            //    ((MyBillsHolder) holder).binding.tvOrderIdText.setTextColor(((OrderHistory)fragment).getThirdHeaderColor());
            ((MyBillsHolder) holder).binding.orderId.setText("#00" + billsList.get(position).getOrderId());
            //     ((MyBillsHolder) holder).binding.tvOrderIdText.setText("#00" + billsList.get(position).getOrderId());
            ((MyBillsHolder) holder).binding.orderPlacingDate.setText(billsList.get(position).getPlacedOn());
            ((MyBillsHolder) holder).binding.orderStatus.setText(billsList.get(position).getOrderStatus());
            ((MyBillsHolder) holder).binding.orderValue.setText(((MyBillsFragment) fragment).getLicDetails().getCurrency() + billsList.get(position).getOrderValue());
            ((MyBillsHolder) holder).binding.orderTotalItem.setText(billsList.get(position).getNoOfItem());
            ((MyBillsHolder) holder).binding.partyNameTxt.setText(billsList.get(position).getAccountName());
            ((MyBillsHolder) holder).binding.partyNameTxt.setVisibility(billsList.get(position).getAccountName().isEmpty() ? View.GONE : View.VISIBLE);
            ((MyBillsHolder) holder).binding.orderDetailsButtonCard.setCardBackgroundColor(((MyBillsFragment) fragment).getThirdHeaderColor());
            ((MyBillsHolder) holder).binding.orderStatus.setTextColor(((MyBillsFragment) fragment).getThirdHeaderColor());
            if (position == billsList.size() - 1) {
                ReckonUtils.setLastVisibleItemMargin(((MyBillsHolder) holder).binding.itemLl, 5, 5, 5, 250);
            }
        } else if (holder instanceof NewArrivalHolder) {
            if (fragment instanceof HomeFragment || fragment instanceof BrandsFragment || fragment instanceof NewArrivalFragment || fragment instanceof CartFragment) {
                if (type.equalsIgnoreCase(fragment.getString(R.string.menu))) {
                    MenuListItem data = menus.get(position);
                    ((NewArrivalHolder) holder).rlMenuTile.setVisibility(data.isVisible() ? View.VISIBLE : View.GONE);
                    ((NewArrivalHolder) holder).menuCard.setCardBackgroundColor(Color.parseColor(data.getBgCard()));
                    ((NewArrivalHolder) holder).menuName.setText(data.getTitle());
                    ((NewArrivalHolder) holder).menuName.setTextColor(Color.parseColor(data.getColorTitle()));
                    Glide.with(fragment).load(data.getImage()).into(((NewArrivalHolder) holder).menuImage);
                    holder.itemView.setOnClickListener(v -> {
                        if (data.isActive()) {
                            if (data.getType() == MenuEnums.STATEMENT.getOrder()) {
                                ///TODO: Account Statement..............
                                Bundle bundle = new Bundle();
                                ((BaseFragment) fragment).orderEntryClickHandling(v, Constant.ACCOUNT_STATEMENT, bundle);
//                                Navigation.findNavController(v).navigate(R.id.nav_account_statement);
                            } else if (data.getType() == MenuEnums.PAYMENT.getOrder()) {
                                if (!isSalesMan && ((BaseFragment) fragment).getLicDetails().getRetailerType().equalsIgnoreCase(Constant.SINGLE)) {
                                    StoreDetailObjectModel store = ((BaseFragment) fragment).getStoreDetails();
                                    Bundle bundle = new Bundle();
                                    bundle.putString("name", store.getName());
                                    bundle.putString("Code", store.getFirmCode());
                                    bundle.putString("address", store.getAdd1());
                                    Navigation.findNavController(v).navigate(R.id.nav_receipt, bundle);
                                } else {
                                    Navigation.findNavController(v).navigate(R.id.nav_receipt);
                                }
                            } else if (data.getType() == MenuEnums.FIND_STOCKIST.getOrder()) {
                                Navigation.findNavController(v).navigate(R.id.nav_find_stockist);
                            } else if (data.getType() == MenuEnums.ORDER_ENTRY.getOrder()) {
                                Bundle bundle = new Bundle();
                                ((BaseFragment) fragment).orderEntryClickHandling(v, Constant.NEW_ORDER, bundle);
                            } else if (data.getType() == MenuEnums.CART.getOrder()) {
                                Navigation.findNavController(v).navigate(R.id.nav_cart);
                            } else if (data.getType() == MenuEnums.ORDER_HISTORY.getOrder()) {
                                Navigation.findNavController(v).navigate(R.id.nav_order_history);
                            } else if (data.getType() == MenuEnums.RECEIPT_BOOK.getOrder()) {
                                Navigation.findNavController(v).navigate(R.id.nav_receipt_book);
                            } else if (data.getType() == MenuEnums.OUTSTANDING.getOrder()) {
                                ///TODO: Outstanding Bill Wise..............
                                Bundle bundle = new Bundle();
                                ((BaseFragment) fragment).orderEntryClickHandling(v, Constant.OUTSTANDING, bundle);
//                                Navigation.findNavController(v).navigate(R.id.nav_outstanding);
                            } else if (data.getType() == MenuEnums.SCHEME.getOrder()) {
//                                if (isSalesMan) {
                                Bundle bundle = new Bundle();
                                bundle.putString("withScheme", "1");
                                ((BaseFragment) fragment).orderEntryClickHandling(v, Constant.NEW_ORDER, bundle);
                          /*      } else {
                                    Bundle bundle = new Bundle();
                                    bundle.putString(Constant.FROM, Constant.SCHEME);
                                    SharedPrefUtils.setString(fragment.getActivity(), Constant.AC_CODE, "");
                                    Navigation.findNavController(v).navigate(R.id.action_nav_home_to_menu_newOrder2, bundle);
                                }*/
                            } else if (data.getType() == MenuEnums.EXPIRY_ENTRY.getOrder()) {
                                Bundle bundle = new Bundle();
                                ((BaseFragment) fragment).orderEntryClickHandling(v, Constant.EXPIRY_ENTRY, bundle);
                            }  else if (data.getType() == MenuEnums.EXPIRY_CART.getOrder()) {

                            } else if (data.getType() == MenuEnums.EXPIRY_BOOK.getOrder()) {

                            } else {
                                Toast.makeText(fragment.getActivity(), "work in progress", Toast.LENGTH_SHORT).show();
                            }
                        }
                    });
                } else if (type.equalsIgnoreCase(fragment.getResources().getString(R.string.testimonial))) {
                    TestimonialsListItem data = testimonials.get(position);
                    ((NewArrivalHolder) holder).Author_Name.setText(data.getName());
                    ((NewArrivalHolder) holder).Testimonial_Description.setText(data.getDescriptions());
                    ((NewArrivalHolder) holder).Testimonial_Description.setTextColor(Color.parseColor(data.getFontColor()));
                    ((NewArrivalHolder) holder).testimonialMainCard.setCardBackgroundColor(Color.parseColor(data.getBackgroundColorOfTestimonial()));
                    ((NewArrivalHolder) holder).Writing_Date.setText(data.getDate());
                    ((NewArrivalHolder) holder).Author_Rating.setText(data.getRating());
                    ((NewArrivalHolder) holder).Author_Organisation.setText(data.getBusinessName());
                } else if (type.equalsIgnoreCase(fragment.getResources().getString(R.string.new_arrival))) {
                    ProductModel data = productArrayList.get(position);
//                    if (position == productArrayList.size() - 1) {
//                        ConstraintLayout.LayoutParams params = new ConstraintLayout.LayoutParams(
//                                ConstraintLayout.LayoutParams.WRAP_CONTENT,
//                                ConstraintLayout.LayoutParams.WRAP_CONTENT
//                        );
//                        params.setMargins(0, 0, 0, 0);
//                        ((NewArrivalHolder) holder).constraintLayoutNewArrival.setLayoutParams(params);
//                    }
                    String currencySym = "₹";
                    if (fragment instanceof HomeFragment)
                        currencySym = ((HomeFragment) fragment).getLicDetails().getCurrency();
                    else if (fragment instanceof CartFragment)
                        currencySym = ((CartFragment) fragment).getLicDetails().getCurrency();
                    if (fragment instanceof NewArrivalFragment)
                        currencySym = ((NewArrivalFragment) fragment).getLicDetails().getCurrency();

                    ((NewArrivalHolder) holder).productDiscount.setText(data.getScheme());
                    if (data.getScheme().isEmpty())
                        ((NewArrivalHolder) holder).productDiscount.setVisibility(View.GONE);
                    ((NewArrivalHolder) holder).productName.setText(data.getProductName());
                    ((NewArrivalHolder) holder).Product_Real_Price.setText(currencySym + data.getProductMrp());
                    ((NewArrivalHolder) holder).productDiscount.setText(data.getScheme());
                    ((NewArrivalHolder) holder).productPrice.setText(currencySym + data.getProductRate());
                    if (data.getImageUrl() != null && !data.getImageUrl().isEmpty())
                        Glide.with(fragment).load(data.getImageUrl()).apply(RequestOptions.placeholderOf(R.drawable.photo_upload)).into(((NewArrivalHolder) holder).Product_Image);
                    else
                        ((NewArrivalHolder) holder).Product_Image.setImageDrawable(fragment.getResources().getDrawable(R.drawable.photo_upload));
                    ((NewArrivalHolder) holder).Product_Description.setText(data.getProductSalt());
                    ((NewArrivalHolder) holder).itemView.setOnClickListener(v -> {
                        if (isSalesMan) {
                            Bundle bundle = new Bundle();
                            bundle.putString("isNewArrival", "1");
                            if (fragment instanceof HomeFragment)
                                ((HomeFragment) fragment).orderEntryClickHandling(v, Constant.NEW_ARRIVAL, bundle);
                            else if (fragment instanceof CartFragment)
                                ((CartFragment) fragment).orderEntryClickHandling(v, Constant.NEW_ARRIVAL, bundle);
                            if (fragment instanceof NewArrivalFragment)
                                ((NewArrivalFragment) fragment).orderEntryClickHandling(v, Constant.NEW_ARRIVAL, bundle);
                        } else {
                            data.setProductId(productArrayList.get(position).getProductIdCol());
                            AddToCartModel cartModel = new AddToCartModel();
                            cartModel.setId(data.getProductIdCol());
                            cartModel.setProductName(data.getProductName());
                            cartModel.setItemCount(data.getProductCount());
                            setConstantBundle(data);
                            NavHostFragment.findNavController(fragment).navigate(R.id.nav_ProductDetailsFragment, Constant.bundle);
                        }
                    });
                } else {
                    BrandListItem data = brandListItems.get(position);
                    ((NewArrivalHolder) holder).brandName.setText(data.getTitle());
                    ((NewArrivalHolder) holder).brandCard.setCardBackgroundColor(Color.parseColor(data.getBgColor()));
                    ((NewArrivalHolder) holder).brand_discount.setText(data.getDescription());
                    Glide.with(fragment).load(data.getImage()).apply(RequestOptions.placeholderOf(R.drawable.photo_upload)).into(((NewArrivalHolder) holder).brandImg);
                    ((NewArrivalHolder) holder).itemView.setOnClickListener(v -> {
                        System.out.println("Brands Fragment CLicked item----------------");
                        Bundle bundle = new Bundle();
                        bundle.putString("BrandItemId", String.valueOf(data.getId()));
                        SharedPrefUtils.setString(fragment.getActivity(), Constant.AC_CODE, "");
//                        NavHostFragment.findNavController(fragment).navigate(R.id.nav_Order_Entry, bundle);
                        if (fragment instanceof BrandsFragment) {
                            System.out.println("Brands Fragment CLicked item-   1  ---------------");
                            ((BrandsFragment) fragment).orderEntryClickHandling(v, Constant.BRAND_LIST, bundle);
                        } else
                            ((HomeFragment) fragment).orderEntryClickHandling(v, Constant.BRAND, bundle);
                    });
                }
            } else {
                ProductModel data = productArrayList.get(position);
                ((NewArrivalHolder) holder).productName.setText(data.getProductName());
                int disc = (int) (100 - (Double.parseDouble(data.getProductRate()) / Double.parseDouble(data.getProductMrp()) * 100));
                //          ((NewArrivalHolder) holder).productDiscount.setText("save " + disc + "%");
                ((NewArrivalHolder) holder).productPrice.setText(((ProductDetailsFragment) fragment).getLicDetails().getCurrency() + data.getProductRate());
                ((NewArrivalHolder) holder).brandName.setText(data.getProductMfgComp());
                ((NewArrivalHolder) holder).productMrp.setText("MRP " + ((ProductDetailsFragment) fragment).getLicDetails().getCurrency() + data.getProductMrp());
                ((NewArrivalHolder) holder).productPacking.setText(data.getProductpacking());
                holder.itemView.setOnClickListener(v -> {
                    data.setProductId(data.getProductIdCol());
                    ((ProductDetailsFragment) fragment).setConstantModel();
                    //      data.setAmt(data.getProductRate());
                    ArrayList<AddToCartModel> productCountList = new ArrayList();
                    AddToCartModel cartModel = new AddToCartModel();
                    cartModel.setId(data.getProductIdCol());
                    cartModel.setItemCount(data.getProductCount());
                    productCountList.add(cartModel);
                    Constant.bundle = new Bundle();
                    Constant.bundle.putString("id", String.valueOf(data.getProductIdCol()));
                    Constant.bundle.putString("itemCount", String.valueOf(data.getProductCount()));
                    Constant.bundle.putString("ProductList", gson.toJson(productCountList));
                    Constant.bundle.putString("model", gson.toJson(data));
                    Constant.bundle.putString("id_col", String.valueOf(data.getProductIdCol()));
                    Constant.bundle.putString(Constant.SCREEN_NAME, Constant.PRODUCT_DETAILS);
                    Constant.bundle.putString("Lic_No", data.getFLicNo());
                    Constant.bundle.putString("Firm_Code", data.getFCode());
//                    Constant.bundle.putString("PARTYCODE", );
                    Navigation.findNavController(v).navigate(R.id.toProductDetails, Constant.bundle);
                });
            }
        } else if (holder instanceof FeedbackOptionHolder) {
            if (fragment instanceof Feedback) {
                ((FeedbackOptionHolder) holder).binding.cardPaymentHolder.setVisibility(View.GONE);
                ((FeedbackOptionHolder) holder).binding.tvFeedbackOption.setText(options.get(position));
                holder.itemView.setOnClickListener(v -> {
                    ((FeedbackOptionHolder) holder).binding.tvFeedbackOption.setTextColor(fragment.getResources().getColor(R.color.red));
                    ((FeedbackOptionHolder) holder).binding.cardHolder.setCardBackgroundColor(fragment.getResources().getColor(R.color.red));
                    i++;
                });
            } else {
                ((FeedbackOptionHolder) holder).binding.cardHolder.setVisibility(View.GONE);
                ((FeedbackOptionHolder) holder).binding.tvPaymentOption.setText(options.get(position));
                holder.itemView.setOnClickListener(v -> {

                });
            }
        }

    }


    @Override
    public int getItemCount() {
        if (fragment instanceof OrderHistory) {
            return orderList.size();
        }else if (fragment instanceof MyBillsFragment) {
            return billsList.size();
        } else if (fragment instanceof HomeFragment || fragment instanceof BrandsFragment || fragment instanceof NewArrivalFragment || fragment instanceof CartFragment) {
            if (type.equalsIgnoreCase(fragment.getString(R.string.testimonial))) {
                return testimonials.size();
            } else if (type.equalsIgnoreCase(fragment.getString(R.string.menu))) {
                return menus.size();
            } else if (type.equals(fragment.getString(R.string.new_arrival))) {
                return productArrayList.size();
            } else {
                if (brandListItems.size() < 10 || fragment instanceof BrandsFragment)
                    return brandListItems.size();
                else
                    return 10;
            }
        } else if (fragment instanceof ProductDetailsFragment) {
            return productArrayList.size();
        } else if (fragment instanceof DeliveryDetails) {
            return timeSlotList.size();
        } else {
            return options.size();

        }
    }

    private void setConstantBundle(ProductModel productModel) {
        Constant.bundle = new Bundle();
        Constant.bundle.putString("id", String.valueOf(productModel.getProductIdCol()));
        Constant.bundle.putString("itemCount", String.valueOf(productModel.getProductCount()));
        Constant.bundle.putString("ProductList", "");
        Constant.bundle.putString("model", gson.toJson(productModel));
        Constant.bundle.putString("id_col", String.valueOf(productModel.getProductIdCol()));
        Constant.bundle.putString(Constant.SCREEN_NAME, Constant.PRODUCT);
        Constant.bundle.putString("totalCalculatedPriceOfCartValue", "0.0");
        //   Constant.bundle.putString("qtyList",productModel.getQuantityList().toString());
    }

    public class DateBinderHolder extends RecyclerView.ViewHolder {
        DeliveryDateTagLayoutBinding binding;

        public DateBinderHolder(@NonNull DeliveryDateTagLayoutBinding deliveryDateTagLayoutBinding) {
            super(deliveryDateTagLayoutBinding.getRoot());
            this.binding = deliveryDateTagLayoutBinding;
        }
    }

    public class FeedbackOptionHolder extends RecyclerView.ViewHolder {
        //        CardView cardHolder;
//        TextView tvFeedbackOptions;
        FeedbackOptionsLayoutBinding binding;

        public FeedbackOptionHolder(@NonNull FeedbackOptionsLayoutBinding feedbackOptionsLayoutBinding) {
            super(feedbackOptionsLayoutBinding.getRoot());
            this.binding = feedbackOptionsLayoutBinding;

        }
    }

    public class OrderHistoryHolder extends RecyclerView.ViewHolder {
        //        CardView cardHolder;
//        TextView tvFeedbackOptions;
        OrderHistoryLayoutBinding binding;

        public OrderHistoryHolder(@NonNull OrderHistoryLayoutBinding orderHistoryLayoutBinding) {
            super(orderHistoryLayoutBinding.getRoot());
            this.binding = orderHistoryLayoutBinding;

        }
    }

    public class MyBillsHolder extends RecyclerView.ViewHolder {
        MyBillsRowLayoutBinding binding;

        public MyBillsHolder(@NonNull MyBillsRowLayoutBinding myBillsRowLayoutBinding) {
            super(myBillsRowLayoutBinding.getRoot());
            this.binding = myBillsRowLayoutBinding;

        }
    }
    public class NewArrivalHolder extends RecyclerView.ViewHolder {
        TextView productName, Product_Description, productPrice, Product_Real_Price, productDiscount, brandName, productMrp, productPacking, brand_discount,
                Testimonial_Description, Author_Name, Writing_Date, Author_Organisation, Author_Rating, menuName;
        ImageView Product_Image, brandImg, menuImage;
        CardView brandCard, menuCard, testimonialMainCard;
        LinearLayout menuLL;
        ConstraintLayout constraintLayoutBrands, constraintLayoutNewArrival;
        RelativeLayout rlMenuTile;

        public NewArrivalHolder(@NonNull View itemView) {
            super(itemView);
            if (fragment instanceof HomeFragment || fragment instanceof BrandsFragment || fragment instanceof NewArrivalFragment || fragment instanceof CartFragment) {
                if (type.equalsIgnoreCase(fragment.getString(R.string.menu))) {
                    menuImage = itemView.findViewById(R.id.menu_image);
                    menuName = itemView.findViewById(R.id.menu_name);
                    menuCard = itemView.findViewById(R.id.menuCard);
                    menuLL = itemView.findViewById(R.id.menuLL);
                    rlMenuTile = itemView.findViewById(R.id.rlMenuTile);
                } else if (type.equalsIgnoreCase(fragment.getString(R.string.testimonial))) {
                    testimonialMainCard = itemView.findViewById(R.id.testimonialMainCard);
                    Testimonial_Description = itemView.findViewById(R.id.testimonial_description);
                    Author_Name = itemView.findViewById(R.id.author_name);
                    Author_Organisation = itemView.findViewById(R.id.author_organisation);
                    Writing_Date = itemView.findViewById(R.id.writing_date);
                    Author_Rating = itemView.findViewById(R.id.author_rating);
                } else if (type.equalsIgnoreCase(fragment.getString(R.string.new_arrival))) {
                    productName = itemView.findViewById(R.id.product_name);
                    constraintLayoutNewArrival = itemView.findViewById(R.id.constraintLayoutNewArrival);
                    productDiscount = itemView.findViewById(R.id.product_discount);
                    Product_Image = itemView.findViewById(R.id.product_image);
                    productPrice = itemView.findViewById(R.id.product_price_after_discount);
                    Product_Description = itemView.findViewById(R.id.product_description);
                    Product_Real_Price = itemView.findViewById(R.id.product_real_price);
                    Product_Real_Price.setPaintFlags(Product_Real_Price.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
                } else {
                    brandCard = itemView.findViewById(R.id.brandCard);
                    brandImg = itemView.findViewById(R.id.brandImg);
                    brand_discount = itemView.findViewById(R.id.brand_discount);
                    brandName = itemView.findViewById(R.id.brand_name);
                }
            } else {
                productName = itemView.findViewById(R.id.productName);
//                productDiscount = itemView.findViewById(R.id.productDiscount);
                productPrice = itemView.findViewById(R.id.productPrice);
                brandName = itemView.findViewById(R.id.productBrandName);
                productMrp = itemView.findViewById(R.id.productMrp);
                productPacking = itemView.findViewById(R.id.productPacking);
                constraintLayoutBrands = itemView.findViewById(R.id.constraintLayoutBrands);

            }
        }
    }
}
