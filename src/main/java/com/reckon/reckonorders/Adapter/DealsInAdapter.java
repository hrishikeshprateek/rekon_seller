package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BannerListItem;
import com.reckon.reckonorders.R;

import java.util.ArrayList;

import butterknife.BindView;
import butterknife.ButterKnife;

public class DealsInAdapter extends RecyclerView.Adapter<DealsInAdapter.SelectionSingleViewHolder> {

    private ArrayList<BannerListItem> dataList;
    private Fragment fragment;


    public DealsInAdapter(ArrayList<BannerListItem> data, Fragment _fragment) {
        this.dataList = data;
        this.fragment = _fragment;
    }


    @Override
    public SelectionSingleViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.deals_in_row, parent, false);
        return new SelectionSingleViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final SelectionSingleViewHolder holder, int position) {
        BannerListItem item = dataList.get(position);
        holder.titleTv.setText(item.getTitle());
        holder.subTitleTv.setText(item.getType());
        holder.subTitleTv.setVisibility(item.getType().length() == 0 ? View.GONE : View.VISIBLE);
        Glide.with(fragment).load(item.getLink()).apply(RequestOptions.placeholderOf(R.drawable.photo_upload)).into(holder.imageDeals);
    }

    @Override
    public int getItemCount() {
        return dataList != null ? dataList.size() : 0;
    }

    static class SelectionSingleViewHolder extends RecyclerView.ViewHolder {

        @BindView(R.id.titleTv)
        TextView titleTv;
        @BindView(R.id.subTitleTv)
        TextView subTitleTv;
        @BindView(R.id.imageDeals)
        ImageView imageDeals;
        @BindView(R.id.dealsInCV)
        CardView dealsInCV;

        SelectionSingleViewHolder(View itemView) {
            super(itemView);
            ButterKnife.bind(this, itemView);
        }
    }
}

