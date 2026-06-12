package com.reckon.reckonorders.Adapter;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.cardview.widget.CardView;
import androidx.viewpager.widget.PagerAdapter;

import com.reckon.reckonorders.Model.OrderDetailsModel;
import com.reckon.reckonorders.NewDesign.NewFragments.OrderConfimation;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;

import java.util.ArrayList;


public class SubmitedOrderViewPagerAdapter extends PagerAdapter {

    private ArrayList<OrderDetailsModel> itemList;
    private LayoutInflater inflater;
    private Activity activity;
    private  OrderConfimation fragment;

    public SubmitedOrderViewPagerAdapter(Activity activity, ArrayList<OrderDetailsModel> bannersList, OrderConfimation _fragment) {
        this.itemList = bannersList;
        this.activity = activity;
        inflater = LayoutInflater.from(activity);
        fragment = _fragment;
    }

    @Override
    public int getCount() {
        return itemList != null ? itemList.size() : 0;
    }

    @Override
    public boolean isViewFromObject(View view, Object object) {
        return view.equals(object);
    }

    @Override
    public Object instantiateItem(ViewGroup view, final int position) {
        View inflateView = inflater.inflate(R.layout.submitted_order_pager_adapter_row, view, false);
        OrderDetailsModel model = itemList.get(position);
        TextView orderId = inflateView.findViewById(R.id.orderId);
        TextView orderPlacingDate = inflateView.findViewById(R.id.orderPlacingDate);
        TextView orderValue = inflateView.findViewById(R.id.orderValue);
        TextView deliveryDate = inflateView.findViewById(R.id.deliveryDate);
        TextView deliveryMode = inflateView.findViewById(R.id.deliveryMode);
        TextView orderStatus = inflateView.findViewById(R.id.orderStatus);
        TextView paymentMode = inflateView.findViewById(R.id.paymentMode);
        TextView firmNameTv = inflateView.findViewById(R.id.firmNameTv);
        CardView shareCv = inflateView.findViewById(R.id.shareCv);
        CardView printCv = inflateView.findViewById(R.id.printCv);
        shareCv.setBackgroundColor(fragment.getButtonColor());
        printCv.setBackgroundColor(fragment.getButtonColor());

        String currencySign = ((NewMainActivity) activity).getLicDetails().getCurrency();
        if(ReckonUtils.nonNullNotEmptyString(model.getFirmName())){
            firmNameTv.setText(model.getFirmName());
            firmNameTv.setVisibility(View.VISIBLE);
        }else{
            firmNameTv.setVisibility(View.GONE);
        }
        if(ReckonUtils.nonNullNotEmptyString(model.getOrderId())){
            orderId.setText("#" + model.getOrderId());
            orderId.setVisibility(View.VISIBLE);
        }else{
            orderId.setVisibility(View.GONE);
        }
        if(ReckonUtils.nonNullNotEmptyString(model.getPlacedOn())){
            orderPlacingDate.setText(model.getPlacedOn());
            orderPlacingDate.setVisibility(View.VISIBLE);
        }else{
            orderPlacingDate.setVisibility(View.GONE);
        }
        if(ReckonUtils.nonNullNotEmptyString(model.getOrderValue())){
            orderValue.setText(currencySign + model.getOrderValue());
            orderValue.setVisibility(View.VISIBLE);
        }else{
            orderValue.setVisibility(View.GONE);
        }
        if(ReckonUtils.nonNullNotEmptyString(model.getPaymentMode())){
            paymentMode.setText(model.getPaymentMode());
            paymentMode.setVisibility(View.VISIBLE);
        }else{
            paymentMode.setVisibility(View.GONE);
        }

        if(ReckonUtils.nonNullNotEmptyString(model.getDeliveryDate())){
            deliveryDate.setText(model.getDeliveryDate());
            deliveryDate.setVisibility(View.VISIBLE);
        }else{
            deliveryDate.setVisibility(View.GONE);
        }
        if(ReckonUtils.nonNullNotEmptyString(model.getDeliveryMode())){
            deliveryMode.setText(model.getDeliveryMode());
            deliveryMode.setVisibility(View.VISIBLE);
        }else{
            deliveryMode.setVisibility(View.GONE);
        }
        if(ReckonUtils.nonNullNotEmptyString(model.getOrderStatus())){
            orderStatus.setText(model.getOrderStatus());
            orderStatus.setVisibility(View.VISIBLE);
        }else{
            orderStatus.setVisibility(View.GONE);
        }

        shareCv.setOnClickListener(v -> {
            fragment.shareOrderReceipt(model);
        });
        printCv.setOnClickListener(v -> {
            fragment.printOrderDetails(model);

        });
        view.addView(inflateView, 0);
        return inflateView;
    }
    @Override
    public void destroyItem(ViewGroup container, int position, Object object) {
        container.removeView((View) object);
    }
}