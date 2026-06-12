package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

import android.content.res.TypedArray;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.appcompat.content.res.AppCompatResources;
import androidx.core.graphics.drawable.DrawableCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.StorePartyPickerDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.databinding.PartyPickerItemLayoutBinding;

import java.util.ArrayList;
import java.util.List;

import butterknife.ButterKnife;

public class PartyPickerAdapter extends RecyclerView.Adapter<PartyPickerAdapter.SelectionSingleViewHolder>  {
    private final List<StoreDetailObjectModel> data;
    private final StorePartyPickerDialog context;
    private final StoreDetailObjectModel selectedStoreDetailsFromPicker;
    private final String screen;

    public PartyPickerAdapter(StorePartyPickerDialog context, ArrayList<StoreDetailObjectModel> data, StoreDetailObjectModel selectedStoreDetailsFromPicker, String screen) {
        this.data = data;
        this.context = context;
        this.selectedStoreDetailsFromPicker = selectedStoreDetailsFromPicker;
        this.screen= screen;
    }

    @Override
    public SelectionSingleViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        return new SelectionSingleViewHolder(PartyPickerItemLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
    }

    @Override
    public void onBindViewHolder(final SelectionSingleViewHolder holder, int position) {
        StoreDetailObjectModel dataPos = data.get(position);
        if(!screen.equalsIgnoreCase(Constant.PARTY)){
            holder.binding.parentCv.setCardBackgroundColor(context.getContext().getResources().getColor((selectedStoreDetailsFromPicker != null && selectedStoreDetailsFromPicker.getFirmCode().equalsIgnoreCase(dataPos.getFirmCode())) ? R.color.green : R.color.white));
        }
        if (dataPos.getName() != null && !dataPos.getName().isEmpty()) {
            holder.binding.tvAccountName.setText(dataPos.getName());
            holder.binding.iconText.setText(dataPos.getFirstChar());
        } else
            holder.binding.tvAccountName.setVisibility(View.GONE);

        if (dataPos.getAdd1() != null && !dataPos.getAdd1().isEmpty())
            holder.binding.tvAddress.setText(dataPos.getAdd1() + dataPos.getAdd2() + dataPos.getAdd3());
        else
            holder.binding.tvAddress.setVisibility(View.GONE);

        holder.itemView.setOnClickListener(v -> {
            context.getSelectedData(dataPos);
        });
        DrawableCompat.setTint(DrawableCompat.wrap(AppCompatResources.getDrawable(context.getContext(), R.drawable.bg_circle)), getRandomMaterialColor());
    }

    @Override
    public int getItemCount() {
        return data != null ? data.size() : 0;
    }

    static class SelectionSingleViewHolder extends RecyclerView.ViewHolder {
        PartyPickerItemLayoutBinding binding;

        SelectionSingleViewHolder(PartyPickerItemLayoutBinding binding) {
            super(binding.getRoot());
            this.binding = binding;
            ButterKnife.bind(this, itemView);
        }
    }

    private int getRandomMaterialColor() {
        int returnColor;
        int arrayId = context.getContext().getResources().getIdentifier("mdcolor_" + "400", "array", context.getContext().getPackageName());
        TypedArray colors = context.getContext().getResources().obtainTypedArray(arrayId);
        int index = (int) (Math.random() * colors.length());
        returnColor = colors.getColor(index, Color.GREEN);
        colors.recycle();
        return returnColor;
    }


}

