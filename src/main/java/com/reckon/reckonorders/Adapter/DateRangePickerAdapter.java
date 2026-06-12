package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Model.DateRangeModel;
import com.reckon.reckonorders.NewDesign.NewFragments.AccountStatementFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.OrderHistory;
import com.reckon.reckonorders.NewDesign.NewFragments.ReceiptBook;
import com.reckon.reckonorders.R;

import java.util.ArrayList;

public class DateRangePickerAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private final ArrayList<DateRangeModel> list;
    private final Fragment fragment;
    private final DateRangeModel dateRangeModel;

    public DateRangePickerAdapter(ArrayList<DateRangeModel> arrayList, Fragment context, DateRangeModel mModel) {
        this.fragment = context;
        this.dateRangeModel = mModel;
        this.list = arrayList;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new ViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.cc_row_layout, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, final int position) {
        if (holder instanceof ViewHolder) {
            onBindViewDataRendering(holder, position);
        }
    }

    private void onBindViewDataRendering(RecyclerView.ViewHolder holder, int position) {
        try {
            ViewHolder row = (ViewHolder) holder;
            row.cName.setText(list.get(position).getTitle());
            if(fragment instanceof OrderHistory){
                row.cName.setTextColor(dateRangeModel!=null && dateRangeModel==list.get(position)?((OrderHistory)fragment).getThirdHeaderColor(): fragment.getResources().getColor(R.color.black));
            }else if(fragment instanceof AccountStatementFragment){
                row.cName.setTextColor(dateRangeModel!=null && dateRangeModel==list.get(position)?((AccountStatementFragment)fragment).getThirdHeaderColor(): fragment.getResources().getColor(R.color.black));
            }
            row.rowLayout.setOnClickListener(v -> {
                if(fragment instanceof OrderHistory){
                    ((OrderHistory) fragment).executeClick(list.get(position));
                }else if(fragment instanceof AccountStatementFragment){
                    ((AccountStatementFragment) fragment).executeClick(list.get(position));
                }else if(fragment instanceof ReceiptBook){
                    ((ReceiptBook) fragment).executeClick(list.get(position));
                }
                notifyItemChanged(position);
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public int getItemCount() {
        return list != null ? list.size() : 0;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView cName;
        LinearLayout rowLayout;

        ViewHolder(View v) {
            super(v);
            cName = v.findViewById(R.id.tv_country);
            rowLayout = v.findViewById(R.id.row_layout);
            cName.setGravity(Gravity.CENTER);

        }
    }


}

