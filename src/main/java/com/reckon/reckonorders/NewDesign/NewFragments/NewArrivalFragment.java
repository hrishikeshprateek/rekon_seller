package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.GridLayoutManager;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.NewArrivalAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentNewArrivalBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

public class NewArrivalFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    FragmentNewArrivalBinding arrivalBinding;
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    private String mParam1;
    private String mParam2;
    private ArrayList<ProductModel> arrivalListItems = null;

    public static NewArrivalFragment newInstance(String param1, String param2) {
        NewArrivalFragment fragment = new NewArrivalFragment();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mParam1 = getArguments().getString(ARG_PARAM1);
            mParam2 = getArguments().getString(ARG_PARAM2);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        arrivalBinding = FragmentNewArrivalBinding.inflate(inflater, container, false);
        return arrivalBinding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        retrofitCallBackListener = this;
        ((NewMainActivity) getActivity()).setUpTitle(NewArrivalFragment.this, getString(R.string.new_arrival));
        arrivalListItems = new ArrayList<>();
        arrivalBinding.newArrivalsRecycler.setLayoutManager(new GridLayoutManager(getActivity(), 2));
        getProductList();
    }

    public void getProductList() {
        try {
            String acCode = SharedPrefUtils.getString(getActivity(), Constant.AC_CODE);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lFirmCode", getLicDetails().getFirmcode());
            jsonObject.put("lPageNo", String.valueOf(1));
            jsonObject.put("lSize", String.valueOf(1000));
            jsonObject.put("lSearchFieldValue", "");
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lExcludeId", "-1");
            jsonObject.put("AcCode", acCode);
            jsonObject.put("NewArrival", "1");
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("app_role", getLicDetails().getRole());
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostProductList(String.valueOf(jsonObject)), Constant.PRODUCT, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.PRODUCT:
                    try {
                        if (jsonObject.has("Item"))
                            setProductListData(jsonObject.getJSONArray("Item"), action);
                    } catch (Exception e) {
                        e.printStackTrace();
                     /*   if (arrivalListItems.size() == 0)
                            noRecordTV.setVisibility(View.VISIBLE);
                        else noRecordTV.setVisibility(View.GONE);*/
                    }
                    break;
            }
        }
    }
    private void setProductListData(JSONArray jsonArray, String action) {
        try {
            if ( arrivalListItems != null && arrivalListItems.size() > 0) {
                arrivalListItems.clear();
            }
            Objects.requireNonNull(arrivalListItems).addAll(getParsedProductList(jsonArray, action));
        /*    if (arrivalListItems.size() == 0)
                noRecordTV.setVisibility(View.VISIBLE);
            else noRecordTV.setVisibility(View.GONE);*/
            arrivalBinding.newArrivalsRecycler.setAdapter(new NewArrivalAdapter(NewArrivalFragment.this, arrivalListItems, getString(R.string.new_arrival)));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}