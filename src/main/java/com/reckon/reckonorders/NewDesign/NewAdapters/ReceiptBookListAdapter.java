package com.reckon.reckonorders.NewDesign.NewAdapters;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.reckon.reckonorders.Model.ReceiptBookModel;
import com.reckon.reckonorders.NewDesign.NewFragments.ReceiptBook;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.databinding.ReceiptBookRowLayoutBinding;

import java.util.ArrayList;

public class ReceiptBookListAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private Fragment fragment;
    private ArrayList<ReceiptBookModel> dataList;
    private boolean isSalesMan = false;

    public ReceiptBookListAdapter(Fragment fragment, ArrayList<ReceiptBookModel> mList) {
        this.fragment = fragment;
        this.dataList = mList;
        isSalesMan = ((ReceiptBook) fragment).getLicDetails().getRole().equalsIgnoreCase("SalesMan");
    }


    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new ReceiptBookHolder(ReceiptBookRowLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        if (holder instanceof ReceiptBookHolder) {
            ReceiptBookModel model = dataList.get(position);
            ((ReceiptBookHolder) holder).binding.orderId.setTextColor(((ReceiptBook) fragment).getThirdHeaderColor());
            ((ReceiptBookHolder) holder).binding.orderId.setText("#00" + model.getId());
            ((ReceiptBookHolder) holder).binding.partyNameTxt.setText(model.getAccountName());
            ((ReceiptBookHolder) holder).binding.partyNameTxt.setVisibility(model.getAccountName().isEmpty() ? View.GONE : View.VISIBLE);
            ((ReceiptBookHolder) holder).binding.receiptCreatedDate.setText(model.getCreatedDate());
            ((ReceiptBookHolder) holder).binding.docDateTv.setText(model.getReceiptDate());
            ((ReceiptBookHolder) holder).binding.receiptValue.setText(((ReceiptBook) fragment).getLicDetails().getCurrency() + model.getAmount());
            ((ReceiptBookHolder) holder).binding.modeTv.setText(model.getPaymentMode());
            ((ReceiptBookHolder) holder).binding.docNoTv.setText(model.getDocumentNo());
            ((ReceiptBookHolder) holder).binding.docDateTv.setTextColor(((ReceiptBook) fragment).getThirdHeaderColor());
            if (position == dataList.size() - 1) {
                ReckonUtils.setLastVisibleItemMargin(((ReceiptBookHolder) holder).binding.itemLl, 5, 5, 5, 250);
            }
            ((ReceiptBookHolder) holder).binding.orderDetailsCard.setOnClickListener(v -> {
                Bundle bundle = new Bundle();
                if (((ReceiptBook) fragment).storeDetailObjectModel != null)
                    bundle.putString(Constant.PARTY, new Gson().toJson(((ReceiptBook) fragment).storeDetailObjectModel));
                bundle.putString(Constant.ID, model.getId());
                Navigation.findNavController(v).navigate(R.id.nav_receipt_details, bundle);
            });
        }

    }


    @Override
    public int getItemCount() {
        return dataList.size();
    }

    public static class ReceiptBookHolder extends RecyclerView.ViewHolder {
        ReceiptBookRowLayoutBinding binding;

        public ReceiptBookHolder(@NonNull ReceiptBookRowLayoutBinding receiptBookRowLayoutBinding) {
            super(receiptBookRowLayoutBinding.getRoot());
            this.binding = receiptBookRowLayoutBinding;
        }
    }

}
