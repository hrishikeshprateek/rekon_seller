package com.reckon.reckonorders.NewDesign;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import android.annotation.SuppressLint;
import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.cardview.widget.CardView;
import androidx.navigation.Navigation;
import androidx.navigation.fragment.NavHostFragment;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.KeyboardUtils;

import org.json.JSONException;
import org.json.JSONObject;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;


@SuppressLint("NonConstantResourceId")
public class AccountFilterScreen extends BaseFragment implements RetrofitCallBackListener {
    private static final String ID = "id";
    private static final String NAME = "name";
    private String selectedStationId, selectedStationName, selectedAreaId, selectedAreaName, source;

    @BindView(R.id.stationTv)
    TextView stationTv;

    @BindView(R.id.areaTv)
    TextView areaTv;

    @BindView(R.id.cvClearBtn)
    CardView cvClearBtn;

    @BindView(R.id.cvApplyBtn)
    CardView cvApplyBtn;


    @BindView(R.id.select_station_rl)
    RelativeLayout selectStationRl;

    @BindView(R.id.select_area_rl)
    RelativeLayout selectAreaRl;

    String id = "", name="";
    public static AccountFilterScreen newInstance(String id, String name) {
        Bundle args = new Bundle();
        args.putString(ID, id);
        args.putString(NAME, name);
        AccountFilterScreen fragment = new AccountFilterScreen();
        fragment.setArguments(args);
        return fragment;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_account_filter_screen, container, false);
        ButterKnife.bind(this, view);
        ((NewMainActivity) requireActivity()).setUpTitle(AccountFilterScreen.this, getString(R.string.account_filters));
        KeyboardUtils.setupUI(view, getActivity());
        setupBackButton(view);
        getBundle();
        setupUI();
        return view;
    }


    @OnClick({R.id.cvApplyBtn, R.id.select_area_rl,R.id.select_station_rl, R.id.cvClearBtn})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.cvApplyBtn:
                applyFilter();
                break;
            case R.id.select_station_rl:
                GoToCommonListingFragment(Constant.SELECT_STATION, selectStationRl);
                break;
            case R.id.select_area_rl:
//                    stateTV.clearComposingText();
                GoToCommonListingFragment(Constant.SELECT_AREA, selectAreaRl);
                break;
            case R.id.cvClearBtn:
                clearFilter();
                break;
        }
    }

    private void clearFilter() {
        selectedStationId = "";
        selectedStationName = "";
        selectedAreaId = "";
        selectedAreaName = "";
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.ACCOUNT_FILTER);
        bundle.putString("selected_station_id", selectedStationId);
        bundle.putString("selected_station_name", selectedStationName);
        bundle.putString("selected_area_id", selectedAreaId);
        bundle.putString("selected_area_name", selectedAreaName);
        bundle.putString("source", source);
        NavHostFragment.findNavController(this).navigate(R.id.action_back_to_Party_screen, bundle);
    }
    private void applyFilter() {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.ACCOUNT_FILTER);
        bundle.putString("selected_station_id", selectedStationId);
        bundle.putString("selected_station_name", selectedStationName);
        bundle.putString("selected_area_id", selectedAreaId);
        bundle.putString("selected_area_name", selectedAreaName);
        bundle.putString("source", source);
        NavHostFragment.findNavController(this).navigate(R.id.action_back_to_Party_screen, bundle);
    }


    private void GoToCommonListingFragment(String from, View view) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, from);
        bundle.putString("selected_station_id", selectedStationId);
        bundle.putString("selected_station_name", selectedStationName);
        bundle.putString("selected_area_id", selectedAreaId);
        bundle.putString("selected_area_name", selectedAreaName);
        bundle.putString("source", source);
        Navigation.findNavController(view).navigate(R.id.nav_common_listing, bundle);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        stationTv.setTextColor(getSecondHeaderTextColor());
        areaTv.setTextColor(getSecondHeaderTextColor());
    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            selectedStationId = bundle.containsKey("selected_station_id") ? bundle.getString("selected_station_id") : "";
            selectedStationName = bundle.containsKey("selected_station_name") ? bundle.getString("selected_station_name") : "";
            selectedAreaId = bundle.containsKey("selected_area_id") ? bundle.getString("selected_area_id") : "";
            selectedAreaName = bundle.containsKey("selected_area_name") ? bundle.getString("selected_area_name") : "";
            source = bundle.containsKey("source") ? bundle.getString("source") : "";
            stationTv.setText(selectedStationName);
            areaTv.setText(selectedAreaName);
            if(!selectedStationId.isEmpty() || !selectedAreaId.isEmpty()){
                cvApplyBtn.setCardBackgroundColor(getThirdHeaderColor());
                cvClearBtn.setCardBackgroundColor(getThirdHeaderColor());
            }else{
                cvApplyBtn.setCardBackgroundColor(getResources().getColor(R.color.btn_dark_grey));
                cvClearBtn.setCardBackgroundColor(getResources().getColor(R.color.btn_dark_grey));
            }

        }
    }


    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && !result.isEmpty()) {
            JSONObject jsonObject = new JSONObject(result);
            if (jsonObject.has("Status") && jsonObject.getBoolean("Status")) {
                switch (action) {
                    case Constant.SIGNUP:
                        break;
                }
            }
        }
    }


}
