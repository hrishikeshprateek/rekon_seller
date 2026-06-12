package com.reckon.reckonorders.Adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Fragment.Account.CommonListingFragment;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BrandListItem;
import com.reckon.reckonorders.R;

import java.util.ArrayList;

public class StationFilterRowAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private final CommonListingFragment context;
    private final ArrayList<BrandListItem> mArrayList;
    private String screen;
    private boolean isSalesMan = false;

    public StationFilterRowAdapter(CommonListingFragment context, ArrayList<BrandListItem> arrayList, String _from) {
        this.mArrayList = arrayList;
        this.context = context;
        this.screen = _from;
        isSalesMan = ((BaseFragment) context).getLicDetails().getRole().equalsIgnoreCase("SalesMan");
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
        ViewHolder row = (ViewHolder) holder;
        try {
            row.cName.setText(mArrayList.get(position).getTitle());
            row.rowLayout.setOnClickListener(v -> context.executeAccountFilerClick(mArrayList.get(position).getId(), mArrayList.get(position).getTitle()));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public int getItemCount() {
        return mArrayList.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView cName;
        LinearLayout rowLayout;

        ViewHolder(View v) {
            super(v);
            cName = v.findViewById(R.id.tv_country);
            rowLayout = v.findViewById(R.id.row_layout);
        }
    }

}
