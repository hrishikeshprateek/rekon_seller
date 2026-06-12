package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Fragment.Home.SettingFragment;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;

public class SettingAdapter extends RecyclerView.Adapter<SettingAdapter.SelectionSingleViewHolder> {

    private List<SelectionModel> data;
    private SettingFragment settingFragment;
    private String pos = "", pos1 = "";
    private String FROM;

    public SettingAdapter(SettingFragment settingFragment, List<SelectionModel> data, String FROM) {
        this.data = data;
        this.settingFragment = settingFragment;
        this.FROM = FROM;
    }

    @Override
    public SelectionSingleViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.setting_row_layout, parent, false);
        return new SelectionSingleViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final SelectionSingleViewHolder holder, int position) {
        SelectionModel item = data.get(position);
        holder.tvTitle.setText(item.getName());

        //  position == 0 && ((FROM.equalsIgnoreCase("") && pos.equalsIgnoreCase("")) || (FROM.equalsIgnoreCase("HINT") && pos1.equalsIgnoreCase("")))
        if ((FROM.equalsIgnoreCase("") && SharedPrefUtils.getString(settingFragment.getActivity(), Constant.SearchTypeID).equalsIgnoreCase(item.getItemId())) || (FROM.equalsIgnoreCase("HINT") && SharedPrefUtils.getString(settingFragment.getActivity(), Constant.ItemHelpIndex).equalsIgnoreCase(item.getItemId()))) {
            holder.tvTitle.setBackgroundColor(settingFragment.getResources().getColor(R.color.grey));
            holder.tvTitle.setTextColor(settingFragment.getResources().getColor(R.color.white));
        } else {
            if (pos.equalsIgnoreCase(item.getItemId()) || pos1.equalsIgnoreCase(item.getItemId())) {
                holder.tvTitle.setBackgroundColor(settingFragment.getResources().getColor(R.color.grey));
                holder.tvTitle.setTextColor(settingFragment.getResources().getColor(R.color.white));
            } else {
                holder.tvTitle.setBackgroundColor(settingFragment.getResources().getColor(R.color.white));
                holder.tvTitle.setTextColor(settingFragment.getResources().getColor(R.color.grey));
            }
        }


        holder.selection_img_ll.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (FROM.equalsIgnoreCase("HINT")) {
                    pos1 = item.getItemId();
                    settingFragment.getSelectedData(holder.getAdapterPosition(), "HINT");
                } else {
                    pos = item.getItemId();
                    settingFragment.getSelectedData(holder.getAdapterPosition(), "");
                }
                notifyDataSetChanged();
            }
        });

    }

    @Override
    public int getItemCount() {
        return data != null ? data.size() : 0;
    }

    static class SelectionSingleViewHolder extends RecyclerView.ViewHolder {
        @BindView(R.id.setting_txt)
        TextView tvTitle;
        @BindView(R.id.selected_img)
        ImageView selected_img;
        @BindView(R.id.selection_img_ll)
        LinearLayout selection_img_ll;

        SelectionSingleViewHolder(View itemView) {
            super(itemView);
            ButterKnife.bind(this, itemView);
        }
    }
}

