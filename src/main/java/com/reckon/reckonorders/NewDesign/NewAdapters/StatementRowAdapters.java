package com.reckon.reckonorders.NewDesign.NewAdapters;

import android.view.LayoutInflater;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Model.StatementsModel;
import com.reckon.reckonorders.NewDesign.NewFragments.SaleVoucherFragment;
import com.reckon.reckonorders.databinding.StatmentRowLayoutBinding;

import java.util.ArrayList;

public class StatementRowAdapters extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    Fragment fragment;
    ArrayList<StatementsModel> arrayList;

    public StatementRowAdapters(Fragment fragment, ArrayList<StatementsModel> arrayList) {
        this.arrayList = arrayList;
        this.fragment = fragment;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new AccountStatementHolder(StatmentRowLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        StatementsModel model = arrayList.get(position);
        ((AccountStatementHolder) holder).binding.tvTitle.setTextColor(((SaleVoucherFragment) fragment).getSecondHeaderTextColor());
        ((AccountStatementHolder) holder).binding.tvTitle.setText(model.getTitle());
        ((AccountStatementHolder) holder).binding.tvValue.setText(model.getValue());
    }

    @Override
    public int getItemCount() {
        return arrayList.size();
    }

    public static class AccountStatementHolder extends RecyclerView.ViewHolder {
        StatmentRowLayoutBinding binding;

        public AccountStatementHolder(@NonNull StatmentRowLayoutBinding binding) {
            super(binding.getRoot());
            this.binding = binding;
        }
    }
}
