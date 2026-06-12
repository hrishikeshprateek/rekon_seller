package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.navigation.Navigation;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Fragment.Home.MyOrderFragment;
import com.reckon.reckonorders.Fragment.Home.OrderDetailsFragment;
import com.reckon.reckonorders.Model.MyOrderModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;

public class MyOrderAdapter extends RecyclerView.Adapter<MyOrderAdapter.SelectionSingleViewHolder> {

    private List<MyOrderModel> data;
    private MyOrderFragment settingFragment;
    private String pos = "", pos1 = "";
    private String FROM;
    private OrderDetailsFragment morderDetailsFragment;
    private ArrayList<MyOrderModel> orderListData = new ArrayList<>();

    public MyOrderAdapter(MyOrderFragment settingFragment, ArrayList<MyOrderModel> data, String FROM) {
        this.data = data;
        this.settingFragment = settingFragment;
        this.FROM = FROM;
    }

    public MyOrderAdapter(OrderDetailsFragment orderDetailsFragment, ArrayList<MyOrderModel> orderListData, String mFROM) {
        FROM = mFROM;
        this.data = orderListData;
        this.morderDetailsFragment = orderDetailsFragment;

    }

    @Override
    public SelectionSingleViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.my_order_row_layout, parent, false);
        return new SelectionSingleViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final SelectionSingleViewHolder holder, int position) {
        MyOrderModel dataPos = data.get(position);

        if (FROM.equalsIgnoreCase(Constant.ORDER_LIST)) {
            holder.order_agency_txt.setText(dataPos.getFIRM_NAME());
            holder.status_txt.setText(dataPos.getORDERSTATUS());
            holder.product_date_txt.setVisibility(View.VISIBLE);
            holder.product_date_txt.setText(String.valueOf("Date: " + dataPos.getORDERDATE()));
            holder.Order_no_ll.setVisibility(View.VISIBLE);
            holder.Order_status_ll.setVisibility(View.VISIBLE);
            holder.order_number_txt.setText(dataPos.getORDERNUMBER());
            holder.rv_my_order_listing.setVisibility(View.VISIBLE);

            try {
                holder.rv_my_order_listing.setLayoutManager(new LinearLayoutManager(morderDetailsFragment.getActivity(), LinearLayoutManager.VERTICAL, false));
                if (orderListData.size() > 0)
                    orderListData.clear();
                JSONArray jsonArray = new JSONArray(dataPos.getOrderList().toString());
                for (int i = 0; i < jsonArray.length(); i++) {
                    JSONObject jsonObject = jsonArray.getJSONObject(i);
                    MyOrderModel myOrderModel = new MyOrderModel();
                     myOrderModel.setOrderIName("Name:               " + jsonObject.getString("IName"));
                    myOrderModel.setOrderBalQty("Delivered QTY:  " + jsonObject.getString("BalQty"));
                      myOrderModel.setOrderOQty("Order QTY:        " + jsonObject.getString("OQty"));
                      myOrderModel.setOrderPack("Pack:                 " + jsonObject.getString("Pack"));
                    orderListData.add(myOrderModel);
                }
                holder.rv_my_order_listing.setAdapter(new MyOrderAdapter(morderDetailsFragment, orderListData, "ADAPTER"));
            } catch (Exception e) {
                e.printStackTrace();
            }

        } else if (FROM.equalsIgnoreCase("ADAPTER")) {
            holder.orderItem_ll.setVisibility(View.VISIBLE);
            holder.product_name_txt.setText(dataPos.getOrderIName());
            holder.order_qty_txt.setText(dataPos.getOrderOQty());
            holder.product_Del_txt.setText(dataPos.getOrderBalQty());
            holder.product_Pack_txt.setText(dataPos.getOrderPack());
        } else {
            holder.order_agency_txt.setVisibility(View.VISIBLE);
            holder.order_details_ll.setVisibility(View.VISIBLE);
            holder.order_agency_txt.setText(dataPos.getFIRM_NAME());
            holder.status_txt.setText(dataPos.getFIRM_CODE());
            holder.order_details_ll.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    Navigation.findNavController(v).navigate(R.id.nav_order_details);
                    //GoToItemDetailsFragment(dataPos);
                }
            });
        }


    }

    @Override
    public int getItemCount() {
        return data != null ? data.size() : 0;

    }

    static class SelectionSingleViewHolder extends RecyclerView.ViewHolder {
        @BindView(R.id.order_number_txt)
        TextView order_number_txt;
        @BindView(R.id.order_agency_txt)
        TextView order_agency_txt;
        @BindView(R.id.order_details_ll)
        LinearLayout order_details_ll;
        @BindView(R.id.product_date_txt)
        TextView product_date_txt;
        @BindView(R.id.status_txt)
        TextView status_txt;
        @BindView(R.id.Order_no_ll)
        LinearLayout Order_no_ll;
        @BindView(R.id.Order_status_ll)
        LinearLayout Order_status_ll;
        @BindView(R.id.rv_my_order_listing)
        RecyclerView rv_my_order_listing;
        @BindView(R.id.orderItem_ll)
        LinearLayout orderItem_ll;
        @BindView(R.id.product_name_txt)
        TextView product_name_txt;
        @BindView(R.id.order_qty_txt)
        TextView order_qty_txt;
        @BindView(R.id.product_Del_txt)
        TextView product_Del_txt;
        @BindView(R.id.product_Pack_txt)
        TextView product_Pack_txt;


        SelectionSingleViewHolder(View itemView) {
            super(itemView);
            ButterKnife.bind(this, itemView);

        }
    }

    private void GoToItemDetailsFragment(MyOrderModel orderModel) {
        OrderDetailsFragment fragment = new OrderDetailsFragment();
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, "MY_ORDER_ITEM");
        bundle.putString(Constant.ORDER_LIST, orderModel.getOrderList().toString());
        bundle.putString(Constant.FIRM_NAME, orderModel.getFIRM_NAME());
        fragment.setArguments(bundle);
        settingFragment.addFragment(fragment, true);
    }
}

