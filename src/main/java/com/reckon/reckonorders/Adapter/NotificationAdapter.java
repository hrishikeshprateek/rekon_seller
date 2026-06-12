package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/07/2019.
 */

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Fragment.Home.NotificationFragment;
import com.reckon.reckonorders.R;

import java.util.ArrayList;

import butterknife.BindView;
import butterknife.ButterKnife;

public class NotificationAdapter extends RecyclerView.Adapter<NotificationAdapter.SelectionSingleViewHolder> {

    private ArrayList<String> data;
    private NotificationFragment notificationFragment;
    private String pos = "", pos1 = "";
    private String FROM;

    public NotificationAdapter(NotificationFragment notificationFragment, ArrayList<String> data, String FROM) {
        this.data = data;
        this.notificationFragment = notificationFragment;
        this.FROM = FROM;
    }

    @Override
    public SelectionSingleViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.notification_row_layout, parent, false);
        return new SelectionSingleViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final SelectionSingleViewHolder holder, int position) {
        holder.tvTitle.setText(data.get(position));
    }

    @Override
    public int getItemCount() {
        return data != null ? data.size() : 0;
    }

    static class SelectionSingleViewHolder extends RecyclerView.ViewHolder {
        @BindView(R.id.setting_txt)
        TextView tvTitle;

        SelectionSingleViewHolder(View itemView) {
            super(itemView);
            ButterKnife.bind(this, itemView);
        }
    }
}

