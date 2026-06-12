package com.reckon.reckonorders.Others.Dialog;
/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.PopupWindow;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Adapter.SelectionSingleAdapter;
import com.reckon.reckonorders.Interfaces.ItemListener;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.R;

import java.util.ArrayList;
import java.util.List;

public class SelectSinglePopup extends PopupWindow {

    private List<SelectionModel> data = new ArrayList<>();
    private ItemListener listener;
    private boolean fullBorder = false;
    private int selectedPos = -1;
    public void setOnItemListener(ItemListener listener) {
        this.listener = listener;
    }

    public SelectSinglePopup(Context context, List<SelectionModel> data, boolean fullBorder) {
        super(context);
        this.data = data;
        this.fullBorder = fullBorder;
        onCreateView(context);
    }


    private void onCreateView(Context context) {
        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        assert inflater != null;
        View view = inflater.inflate(R.layout.popup_select, null);
        setContentView(view);
        setWidth(LinearLayout.LayoutParams.WRAP_CONTENT);
        setHeight(LinearLayout.LayoutParams.WRAP_CONTENT);
        setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        setFocusable(true);
        RecyclerView recyclerView = view.findViewById(R.id.popupSelect_recyclerView);
        recyclerView.setBackgroundResource(fullBorder ? R.drawable.shape_all_border_radius_light_grey : R.drawable.shape_border_radius_light_grey);
        SelectionSingleAdapter adapter = new SelectionSingleAdapter(data, context);
        adapter.setOnItemListener(listenerSelection);
        LinearLayoutManager layoutManager = new LinearLayoutManager(context);
        recyclerView.setLayoutManager(layoutManager);
        recyclerView.setAdapter(adapter);
    }

    @Override
    public void showAsDropDown(View anchor, int xoff, int yoff) {
        setWidth(anchor.getWidth() != 0 ? anchor.getWidth() : LinearLayout.LayoutParams.WRAP_CONTENT);
        super.showAsDropDown(anchor, xoff, yoff);
    }


    private ItemListener listenerSelection = new ItemListener() {
        @Override
        public void onItemClicked(int position) {
            if (listener != null){
                selectedPos = position;
                listener.onItemClicked(position);
            }
            dismiss();
        }
    };


}
