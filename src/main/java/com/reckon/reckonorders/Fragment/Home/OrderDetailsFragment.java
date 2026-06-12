package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.cardview.widget.CardView;
import androidx.core.graphics.drawable.DrawableCompat;
import androidx.core.widget.NestedScrollView;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Adapter.CommonRowAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class OrderDetailsFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private static final String ID = "id";
    private static final String NAME = "name";
    @BindView(R.id.shippingHeading)
    TextView shippingHeading;
    @BindView(R.id.tvOrderDetails)
    TextView tvOrderDetails;
    @BindView(R.id.deliveryCharges)
    TextView deliveryCharges;
    @BindView(R.id.orderSummaryHeaderText)
    TextView orderSummaryHeaderText;
    @BindView(R.id.placedToPackedLine)
    View placedToPackedLine;
    @BindView(R.id.packedToShippedLine)
    View packedToShippedLine;
    @BindView(R.id.shippedToDeliverLine)
    View shippedToDeliverLine;
    @BindView(R.id.tvPlaced)
    TextView tvPlaced;
    @BindView(R.id.tvPacked)
    TextView tvPacked;
    @BindView(R.id.tvShipped)
    TextView tvShipped;
    @BindView(R.id.tvDelivered)
    TextView tvDelivered;
    @BindView(R.id.orderPlacedCard)
    CardView orderPlacedCard;
    @BindView(R.id.orderInvoicedCv)
    CardView orderInvoicedCv;


    @BindView(R.id.orderPackedCard)
    CardView orderPackedCard;
    @BindView(R.id.orderShippedCard)
    CardView orderShippedCard;
    @BindView(R.id.orderDeliveredCard)
    CardView orderDeliveredCard;
    @BindView(R.id.tvFeedback)
    TextView tvFeedback;
    @BindView(R.id.cartRecycler)
    RecyclerView cartRecycler;
    private String orderId = "";
    @BindView(R.id.scrollView)
    NestedScrollView scrollView;
    @BindView(R.id.tvItemPurchase)
    TextView tvItemPurchase;
    @BindView(R.id.orderId)
    TextView tvOrderId;
    @BindView(R.id.orderPlacingDate)
    TextView orderPlacingDate;
    @BindView(R.id.paymentMode)
    TextView paymentMode;
    @BindView(R.id.tvItemNumber)
    TextView tvItemNumber;
    @BindView(R.id.tvInvoiceNumber)
    TextView tvInvoiceNumber;
    @BindView(R.id.tvInvoiceDate)
    TextView tvInvoiceDate;
    @BindView(R.id.tvInvoiceAmt)
    TextView tvInvoiceAmt;

    @BindView(R.id.deliveryDate)
    TextView deliveryDate;
    @BindView(R.id.delivery_mode)
    TextView delivery_mode;
    @BindView(R.id.order_status)
    TextView order_status;
    @BindView(R.id.totalValueAmount)
    TextView totalValueAmount;
    @BindView(R.id.tvTotalValue)
    TextView tvTotalValue;
    @BindView(R.id.tvShipAddress)
    TextView tvShipAddress;

    @BindView(R.id.tvContactNumber)
    TextView tvContactNumber;

    @BindView(R.id.tvCustomerName)
    TextView tvCustomerName;

    @BindView(R.id.cvItemPurchased)
    CardView cvItemPurchased;

    @BindView(R.id.orderDetailsLl)
    LinearLayout orderDetailsLl;

    @BindView(R.id.noRecordTV)
    TextView noRecordTV;
    @BindView(R.id.gstAmount)
    TextView gstAmount;

    @BindView(R.id.discountAmount)
    TextView discountAmount;

    @BindView(R.id.tvDiscountCharges)
    TextView tvDiscountCharges;

    @BindView(R.id.paymentModeRl)
    RelativeLayout paymentModeRl;

    @BindView(R.id.rlInvoiceNo)
    RelativeLayout rlInvoiceNo;
    @BindView(R.id.rlInvoiceDate)
    RelativeLayout rlInvoiceDate;
    @BindView(R.id.rlInvoiceAmt)
    RelativeLayout rlInvoiceAmt;

    @BindView(R.id.paymentDetailCard)
    CardView paymentDetailCard;

    @BindView(R.id.invoiceFileView)
    TextView invoiceFileView;

    @BindView(R.id.deliveredIv)
    ImageView deliveredIv;

    @BindView(R.id.shippedIv)
    ImageView shippedIv;

    @BindView(R.id.placedIv)
    ImageView placedIv;

    @BindView(R.id.invoicedIv)
    ImageView invoicedIv;
    @BindView(R.id.partyNameTxt)
    TextView partyNameTxt;


    private boolean isSalesMan;

    private boolean isItemPurchasedClicked = false;
    private StoreDetailObjectModel selectedPartyDataModel;
    private final Gson gson = new Gson();
    private Animation animation;
    private String lKeyEntryNo;

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_order_details2, container, false);
        ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        ((NewMainActivity) getActivity()).setUpTitle(OrderDetailsFragment.this, getString(R.string.order_details));
        getBundle();
        setupUI();
        setTitle(view, getString(R.string.order_details).toUpperCase());
        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        try {
            animation = AnimationUtils.loadAnimation(requireActivity(), R.anim.blink_animation);
//            0:Placed,1:Packed,2:Shipped,3:Deliverd,4:Cancel'

            orderSummaryHeaderText.setTextColor(getSecondHeaderTextColor());
            orderSummaryHeaderText.setText(orderSummaryHeaderText.getText().toString().toUpperCase());
//            if (isSalesMan)
            paymentModeRl.setVisibility(View.GONE);
            getMyOrderDetails();
            //drawable code

//TODO:Place Code For Drawable Tint
            Drawable unwrappedDrawable = AppCompatResources.getDrawable(getActivity(), R.drawable.ic_baseline_arrow_drop_down_24);
            Drawable wrappedDrawable = DrawableCompat.wrap(unwrappedDrawable);
            DrawableCompat.setTint(wrappedDrawable, getSecondHeaderTextColor());
            unwrappedDrawable = AppCompatResources.getDrawable(getActivity(), R.drawable.ic_baseline_arrow_drop_up_24);
            wrappedDrawable = DrawableCompat.wrap(unwrappedDrawable);
            DrawableCompat.setTint(wrappedDrawable, getSecondHeaderTextColor());
            tvOrderDetails.setTextColor(getSecondHeaderTextColor());
            deliveryCharges.setTextColor(getSecondHeaderTextColor());
            tvOrderId.setTextColor(getSecondHeaderTextColor());
            orderPlacingDate.setTextColor(getSecondHeaderTextColor());
            paymentMode.setTextColor(getSecondHeaderTextColor());
            tvItemNumber.setTextColor(getSecondHeaderTextColor());
            tvInvoiceNumber.setTextColor(getSecondHeaderTextColor());
            tvInvoiceDate.setTextColor(getSecondHeaderTextColor());
            tvInvoiceAmt.setTextColor(getThirdHeaderColor());
            deliveryDate.setTextColor(getSecondHeaderTextColor());
            delivery_mode.setTextColor(getSecondHeaderTextColor());
            order_status.setTextColor(getSecondHeaderTextColor());
            totalValueAmount.setTextColor(getSecondHeaderTextColor());
            gstAmount.setTextColor(getSecondHeaderTextColor());
            tvTotalValue.setTextColor(getThirdHeaderColor());

            tvCustomerName.setTextColor(getSecondHeaderTextColor());
            discountAmount.setTextColor(getSecondHeaderTextColor());
            shippingHeading.setTextColor(getSecondHeaderTextColor());
            tvDiscountCharges.setTextColor(getSecondHeaderTextColor());
            isItemPurchasedClicked = true;
            tvItemPurchase.setCompoundDrawablesWithIntrinsicBounds(0, 0, R.drawable.ic_baseline_arrow_drop_up_24, 0);
            scrollView.setVisibility(View.VISIBLE);
            cvItemPurchased.setOnClickListener(v -> {
                if (isItemPurchasedClicked) {
                    isItemPurchasedClicked = false;
                    tvItemPurchase.setCompoundDrawablesWithIntrinsicBounds(0, 0, R.drawable.ic_baseline_arrow_drop_down_24, 0);
                    scrollView.setVisibility(View.GONE);
                } else {
                    isItemPurchasedClicked = true;
                    tvItemPurchase.setCompoundDrawablesWithIntrinsicBounds(0, 0, R.drawable.ic_baseline_arrow_drop_up_24, 0);
                    scrollView.setVisibility(View.VISIBLE);
                }

            });

            orderPlacedCard.setOnClickListener(view -> {

            });
            //   rv_my_order_listing.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
            //order_agency_txt.setText(FirmName);
   /*         if (orderListData.size() > 0)
                orderListData.clear();
            JSONArray jsonArray = new JSONArray(OrderList);
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                MyOrderModel myOrderModel = new MyOrderModel();
                myOrderModel.setORDERDATE(jsonObject.getString("ORDERDATE"));
                myOrderModel.setORDERNUMBER(jsonObject.getString("ORDERNO"));
                myOrderModel.setORDERSTATUS(jsonObject.getString("OSTATUS"));
                myOrderModel.setOrderList(jsonObject.getJSONArray("OrderItems"));
                orderListData.add(myOrderModel);
            }*/
            //   rv_my_order_listing.setAdapter(new MyOrderAdapter(OrderDetailsFragment.this, orderListData, Constant.ORDER_LIST));

        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            if (isSalesMan) {
                selectedPartyDataModel = gson.fromJson(getArguments().getString(Constant.PARTY), new TypeToken<StoreDetailObjectModel>() {
                }.getType());
                if (selectedPartyDataModel != null) {
                    tvCustomerName.setText(selectedPartyDataModel.getName());
                }
            }
            orderId = bundle.containsKey(Constant.ORDER_ID) ? bundle.getString(Constant.ORDER_ID) : "";

        }
    }

    @OnClick({R.id.tvFeedback})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.tvFeedback:
//                NavHostFragment.findNavController(OrderDetailsFragment.this).navigate(R.id.nav_feedback);
                break;
        }
    }

    private void getMyOrderDetails() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lId", orderId);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().GetOrderDetails(String.valueOf(jsonObject)), Constant.ORDER_DETAILS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            switch (action) {
                case Constant.ORDER_DETAILS:
                    JSONObject jsonObject = new JSONObject(result);
                    if (jsonObject.getBoolean("Status")) {
                        setMyOrderListData(jsonObject, action);
                    }
                    break;
                case Constant.GET_FILE:
                    String pdfLink = result;
                    if (ReckonUtils.isPDFValid(pdfLink)) {
                        ReckonUtils.viewPdf(requireActivity(), pdfLink);
                    } else {
                        Toast.makeText(requireActivity(), getResources().getString(R.string.fill_not_found), Toast.LENGTH_LONG).show();
                    }
                    break;
            }

        }
    }

    private void setTextDecorations(View view) {
        if (view instanceof TextView) {
            ((TextView) view).setTextColor(getThirdHeaderColor());
        } else if (view instanceof CardView) {
            ((CardView) view).setCardBackgroundColor(getThirdHeaderColor());
//            ((CardView) view).setBackgroundColor(getThirdHeaderColor());
        } else {
            view.setBackgroundColor(getThirdHeaderColor());
        }
    }

    private void setMyOrderListData(JSONObject jsonObject, String action) {
        try {
            if (ReckonUtils.getJsonCheckedString(jsonObject, "OrderId", "").isEmpty()) {
                orderDetailsLl.setVisibility(View.GONE);
                noRecordTV.setVisibility(View.VISIBLE);
            } else {
                orderDetailsLl.setVisibility(View.VISIBLE);
                noRecordTV.setVisibility(View.GONE);
            }
            int deliverId = Integer.parseInt(ReckonUtils.nonNullNotEmptyString(ReckonUtils.getJsonCheckedString(jsonObject, "StatusId", "")) ? ReckonUtils.getJsonCheckedString(jsonObject, "StatusId", "") : "0");
            if (deliverId == 0) {
//                setTextDecorations(orderPlacedCard);
//                setTextDecorations(tvPlaced);
                placedIv.startAnimation(animation);

            } else if (deliverId == 1) {
                setTextDecorations(orderPlacedCard);
                setTextDecorations(tvPlaced);
                invoicedIv.startAnimation(animation);

            } else if (deliverId == 2) {
                setTextDecorations(orderPlacedCard);
                setTextDecorations(tvPlaced);
                setTextDecorations(placedToPackedLine);
                setTextDecorations(orderPackedCard);
                setTextDecorations(orderInvoicedCv);
                setTextDecorations(tvPacked);
                shippedIv.startAnimation(animation);

            } else if (deliverId == 3) {
                setTextDecorations(tvPlaced);
                setTextDecorations(tvShipped);
                setTextDecorations(tvPacked);
                setTextDecorations(orderPlacedCard);
                setTextDecorations(orderPackedCard);
                setTextDecorations(orderInvoicedCv);
                setTextDecorations(orderShippedCard);
                setTextDecorations(placedToPackedLine);
                setTextDecorations(packedToShippedLine);
                deliveredIv.startAnimation(animation);
            } else {
                setTextDecorations(tvPlaced);
                setTextDecorations(tvShipped);
                setTextDecorations(tvPacked);
                setTextDecorations(tvDelivered);
                setTextDecorations(orderPlacedCard);
                setTextDecorations(orderInvoicedCv);
                setTextDecorations(orderPackedCard);
                setTextDecorations(orderShippedCard);
                setTextDecorations(orderDeliveredCard);
                setTextDecorations(placedToPackedLine);
                setTextDecorations(packedToShippedLine);
                setTextDecorations(shippedToDeliverLine);
                deliveredIv.clearAnimation();

            }
            String currency = getLicDetails().getCurrency();

            tvOrderId.setText("#" + ReckonUtils.getJsonCheckedString(jsonObject, "OrderId", "0"));
            orderPlacingDate.setText(ReckonUtils.getJsonCheckedString(jsonObject, "PlacedOn", ""));
            paymentMode.setText(ReckonUtils.getJsonCheckedString(jsonObject, "PaymentMode", ""));
            tvItemNumber.setText(ReckonUtils.getJsonCheckedString(jsonObject, "NoOfItem", "0"));
            String invoiceNumber = ReckonUtils.getJsonCheckedString(jsonObject, "InvNo", "");
            String invoiceDate = ReckonUtils.getJsonCheckedString(jsonObject, "InvDt", "");
            String invoiceAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "InvAmt", "0"));

            tvInvoiceNumber.setText(invoiceNumber);
            tvInvoiceDate.setText(invoiceDate);
            tvInvoiceAmt.setText(currency + invoiceAmt);

            rlInvoiceNo.setVisibility(invoiceNumber.isEmpty() ? View.GONE : View.VISIBLE);
            rlInvoiceDate.setVisibility(invoiceDate.isEmpty() ? View.GONE : View.VISIBLE);
            rlInvoiceAmt.setVisibility(invoiceAmt.isEmpty() ? View.GONE : View.VISIBLE);
            paymentDetailCard.setVisibility(invoiceNumber.isEmpty() ? View.GONE : View.VISIBLE);


            deliveryDate.setText(ReckonUtils.getJsonCheckedString(jsonObject, "DeliveryDate", ""));
            delivery_mode.setText(ReckonUtils.getJsonCheckedString(jsonObject, "DeliveryMode", ""));
            order_status.setText(ReckonUtils.getJsonCheckedString(jsonObject, "OrderStatus", ""));
            totalValueAmount.setText(currency + ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "ItemAmt", "0.0")));
            gstAmount.setText(currency + ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "TaxAmt", "0.0")));
            tvTotalValue.setText(currency + ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "OrderValue", "0.0")));
            tvShipAddress.setText(ReckonUtils.getJsonCheckedString(jsonObject, "ShippingInformation", ""));
            lKeyEntryNo = ReckonUtils.getJsonCheckedString(jsonObject, "lKeyEntryNo", "");
            discountAmount.setText(currency + ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "SchAmt", "0.0")));
            deliveryCharges.setText(currency + "0");

            invoiceFileView.setVisibility(ReckonUtils.nonNullNotEmptyString(lKeyEntryNo) ? View.VISIBLE : View.GONE);

            String Disc1Amt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "Disc1Amt", "0.0"));
            String DiscAmt = ReckonUtils.roundTwoDecimals(ReckonUtils.getJsonCheckedString(jsonObject, "DiscAmt", "0.0"));
            Double discount = 0.0;
            try {
                discount = Double.parseDouble(Disc1Amt) + Double.parseDouble(DiscAmt);
            } catch (Exception e) {
                e.printStackTrace();
            }
            tvDiscountCharges.setText(getLicDetails().getCurrency() + ReckonUtils.roundTwoDecimals(String.valueOf(discount)));

            ArrayList<ProductModel> orderItemsList = new ArrayList<>();
            Objects.requireNonNull(orderItemsList).addAll(getParsedProductList(jsonObject.getJSONArray("Item"), action));
            cartRecycler.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
            cartRecycler.setAdapter(new CommonRowAdapter(OrderDetailsFragment.this, orderItemsList, Constant.ORDER_DETAILS));
            if (tvCustomerName.getText().toString().isEmpty())
                tvCustomerName.setVisibility(View.GONE);
            else
                tvCustomerName.setVisibility(View.VISIBLE);
            if (tvContactNumber.getText().toString().isEmpty())
                tvContactNumber.setVisibility(View.GONE);
            else
                tvContactNumber.setVisibility(View.VISIBLE);
            if (tvShipAddress.getText().toString().isEmpty())
                tvShipAddress.setVisibility(View.GONE);
            else
                tvShipAddress.setVisibility(View.VISIBLE);

            invoiceFileView.setOnClickListener(view -> {
                getInvoiceFile(ReckonUtils.getJsonCheckedString(jsonObject, "LicNo", ""));
            });
            partyNameTxt.setText(ReckonUtils.getJsonCheckedString(jsonObject, "AcName", ""));
            partyNameTxt.setVisibility(ReckonUtils.nonNullNotEmptyString(ReckonUtils.getJsonCheckedString(jsonObject, "AcName", "")) ? View.VISIBLE : View.GONE);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void getInvoiceFile(String licNo) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", isSalesMan ? getLicDetails().getLicno() : ReckonUtils.nonNullNotEmptyString(getLicDetails().getLicno()) ? getLicDetails().getLicno() : licNo);
            jsonObject.put("lKeyEntryNo", lKeyEntryNo);
            jsonObject.put("order_id", orderId);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().GetFile(String.valueOf(jsonObject)), Constant.GET_FILE, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onDestroy() {
        if (placedIv.getAnimation() != null) {
            placedIv.clearAnimation();
        }
        if (invoicedIv.getAnimation() != null) {
            invoicedIv.clearAnimation();
        }
        if (shippedIv.getAnimation() != null) {
            shippedIv.clearAnimation();
        }
        if (deliveredIv.getAnimation() != null) {
            deliveredIv.clearAnimation();
        }
        super.onDestroy();
    }
}
