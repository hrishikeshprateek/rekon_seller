package com.reckon.reckonorders.Adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.R;

import java.util.ArrayList;

public class CountryPickerAdapter extends RecyclerView.Adapter<CountryPickerAdapter.FruitViewHolder>  {
    private ArrayList<LoginModel> mDataset;
    RecyclerViewItemClickListener recyclerViewItemClickListener;

    public CountryPickerAdapter(ArrayList<LoginModel> myDataset, RecyclerViewItemClickListener listener) {
        mDataset = myDataset;
        this.recyclerViewItemClickListener = listener;
    }

    @NonNull
    @Override
    public FruitViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int i) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.country_picker_row_layout, parent, false);
        FruitViewHolder vh = new FruitViewHolder(v);
        return vh;

    }

    @Override
    public void onBindViewHolder(@NonNull FruitViewHolder holder, int i) {
        LoginModel model = mDataset.get(i);
        holder.title.setText(model.getTitle());
        holder.code.setText("(+"+model.getMobilePrefix()+")");
    }

    @Override
    public int getItemCount() {
        return mDataset.size();
    }



    public  class FruitViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener {
        public TextView title, code;
        public FruitViewHolder(View v) {
            super(v);
            title = v.findViewById(R.id.itemSelection_tvTitle);
            code = v.findViewById(R.id.code);
            v.setOnClickListener(this);
        }

        @Override
        public void onClick(View v) {
            recyclerViewItemClickListener.clickOnItem(mDataset.get(this.getAdapterPosition()));

        }
    }

    public interface RecyclerViewItemClickListener {
        void clickOnItem(LoginModel data);
    }
}
