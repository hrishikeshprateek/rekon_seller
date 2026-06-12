package com.reckon.reckonorders.Others.Dialog;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.R;

public class CountryPickerDialog extends Dialog implements View.OnClickListener {
    public Activity activity;
    public Dialog dialog;
    TextView title;
    RecyclerView recyclerView;
    private RecyclerView.LayoutManager mLayoutManager;
    RecyclerView.Adapter adapter;

    public CountryPickerDialog(Context context, int themeResId) {
        super(context, themeResId);
    }

    public CountryPickerDialog(Context context, boolean cancelable, OnCancelListener cancelListener) {
        super(context, cancelable, cancelListener);
    }

    public CountryPickerDialog(Activity a, RecyclerView.Adapter adapter) {
        super(a);
        this.activity = a;
        this.adapter = adapter;
        setupLayout();
    }

    private void setupLayout() {

    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.country_picker_popup);
        title = findViewById(R.id.title);
        recyclerView = findViewById(R.id.popupSelect_recyclerView);
        mLayoutManager = new LinearLayoutManager(activity);
        recyclerView.setLayoutManager(mLayoutManager);
        recyclerView.setAdapter(adapter);
//        no.setOnClickListener(this);

    }


    @Override
    public void onClick(View v) {
        switch (v.getId()) {
        /*    case R.id.yes:
                //Do Something
                break;*/
        /*    case R.id.no:
                dismiss();
                break;*/
            default:
                break;
        }
        dismiss();
    }
}
