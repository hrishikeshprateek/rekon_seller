package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Interfaces.ItemListener;
import com.reckon.reckonorders.Model.ProductFilterItemModel;
import com.reckon.reckonorders.Model.ProductFilterModel;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.NewDesign.ProductFilterScreen;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;

import java.util.ArrayList;
import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;

public class SelectionSingleAdapter extends RecyclerView.Adapter<SelectionSingleAdapter.SelectionSingleViewHolder> {

    private List<SelectionModel> data;
    private String screen;
    private ArrayList<ProductFilterModel> filterList;
    private ArrayList<ProductFilterItemModel> selectedFilterList;
    private Fragment fragment;
    private ItemListener listener;
    private int selectedPos = 0;
    private Context mContext;

    public SelectionSingleAdapter(List<SelectionModel> data, Context context) {
        mContext = context;
        selectedPos  = -1;
        this.data = data;
    }

    public SelectionSingleAdapter(ArrayList<ProductFilterItemModel> data, ProductFilterScreen productFilterScreen) {
        this.selectedFilterList = data;
        this.fragment = productFilterScreen;
    }

    public SelectionSingleAdapter(ArrayList<ProductFilterModel> data, String screen, ProductFilterScreen productFilterScreen) {
        this.filterList = data;
        this.screen = screen;
        this.fragment = productFilterScreen;
    }

    public void setOnItemListener(ItemListener listener) {
        this.listener = listener;
    }

    @Override
    public SelectionSingleViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.filter_row_layout, parent, false);
        return new SelectionSingleViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final SelectionSingleViewHolder holder, int position) {
        if (filterList != null && screen != null && screen.equalsIgnoreCase(Constant.PRODUCT_FILTER)) {
            ProductFilterModel item = filterList.get(position);
            holder.tvSubTitle.setVisibility(View.VISIBLE);
            holder.tvTitle.setText(item.getTitle());
            holder.tvSubTitle.setText("(" + item.getTotalCount() + ")");
            if (fragment instanceof ProductFilterScreen) {
                filterList.get(position).setSelected(selectedPos == position);
                holder.flRow.setBackgroundColor(item.isSelected() ? fragment.getResources().getColor(R.color.white) : fragment.getResources().getColor(R.color.selected_filter_color_blue));
            }
        } else if (selectedFilterList != null) {
            holder.llCheck.setVisibility(View.VISIBLE);
            ProductFilterItemModel item = selectedFilterList.get(position);
            holder.tvTitle.setText(item.getTitle());
            holder.imgCheck.setImageResource(item.isSelected() ? R.drawable.check_box : R.drawable.uncheck_box);
//            holder.imgCheck.setImageResource(selectedItemPos.contains(selectedFilterList.get(holder.getAdapterPosition()).getId()) ? R.drawable.check_box : R.drawable.uncheck_box);
        } else {
            SelectionModel item = data.get(position);
            holder.tvTitle.setText(item.getName());
            holder.flRow.setBackgroundColor(selectedPos!=position? mContext.getResources().getColor(R.color.white) : mContext.getResources().getColor(R.color.selected_filter_color_blue));
        }

        holder.frmLine.setVisibility(position == getItemCount() - 1 ? View.INVISIBLE : View.VISIBLE);
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (selectedFilterList != null) {
                    selectedFilterList.get(holder.getAdapterPosition()).setSelected(!selectedFilterList.get(holder.getAdapterPosition()).isSelected());
                    notifyDataSetChanged();
                } else {
                    selectedPos = holder.getAdapterPosition();
                    if (listener != null) {
                        listener.onItemClicked(holder.getAdapterPosition());
                        notifyDataSetChanged();
                    }
                }

            }
        });
    }

    @Override
    public int getItemCount() {
        return screen != null && screen.equalsIgnoreCase(Constant.PRODUCT_FILTER) ? filterList != null ? filterList.size() : 0 : selectedFilterList != null ? selectedFilterList.size() : data != null ? data.size() : 0;
    }

    static class SelectionSingleViewHolder extends RecyclerView.ViewHolder {
        @BindView(R.id.itemSelection_tvTitle)
        TextView tvTitle;
        @BindView(R.id.itemSelection_frmLine)
        FrameLayout frmLine;
        @BindView(R.id.fl_row)
        FrameLayout flRow;
        @BindView(R.id.ll_check)
        LinearLayout llCheck;
        @BindView(R.id.img_check)
        ImageView imgCheck;
        @BindView(R.id.txt_sub_title)
        TextView tvSubTitle;

        SelectionSingleViewHolder(View itemView) {
            super(itemView);
            ButterKnife.bind(this, itemView);
        }
    }
}

