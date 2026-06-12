package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.widget.NestedScrollView;
import androidx.recyclerview.widget.GridLayoutManager;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.NewArrivalAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BrandListItem;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentBrandsBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

public class BrandsFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    FragmentBrandsBinding brandsBinding;
    // TODO: Rename parameter arguments, choose names that match
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    private String mParam1;
    private String mParam2;
    private ArrayList<BrandListItem> brandListItems = null;
    private int PAGE_NUM = 1;
    private int _totalCount = 0;
    private GridLayoutManager mlayoutManager;

    public static BrandsFragment newInstance(String param1, String param2) {
        BrandsFragment fragment = new BrandsFragment();
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
        brandsBinding = FragmentBrandsBinding.inflate(getLayoutInflater());
        retrofitCallBackListener = this;
        return brandsBinding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        ((NewMainActivity) getActivity()).setUpTitle(BrandsFragment.this, getString(R.string.Brands));
        brandListItems = new ArrayList<>();
        mlayoutManager = new GridLayoutManager(getActivity(), 3);
        brandsBinding.brandsRecycler.setLayoutManager(mlayoutManager);
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                getBrandList("", PAGE_NUM, false);
            }
        }, 10);

        brandsBinding.scrollView.setOnScrollChangeListener((NestedScrollView.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
            if (v.getChildAt(v.getChildCount() - 1) != null) {
                if ((scrollY >= (v.getChildAt(v.getChildCount() - 1).getMeasuredHeight() - v.getMeasuredHeight())) &&
                        scrollY > oldScrollY) {
                    int visibleItemCount = mlayoutManager.getChildCount();
                    int totalItemCount = mlayoutManager.getItemCount();
                    int pastVisiblesItems = mlayoutManager.findFirstVisibleItemPosition();
                    if ((visibleItemCount + pastVisiblesItems) >= totalItemCount) {
                        if (_totalCount > brandListItems.size()) {
                            getBrandList("", ++PAGE_NUM, true);
                        }
                    }
                }
            }
        });

    }

    public void getBrandList(String searchCharacter, int page, boolean showLoader) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lPageNo", String.valueOf(page));
            jsonObject.put("lSize", String.valueOf(30));
            jsonObject.put("lSearchFieldValue", searchCharacter);
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lFirmCode", getLicDetails().getFirmcode());
            jsonObject.put("lDashBoard", "0");
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postBrandList(String.valueOf(jsonObject)), Constant.BRAND, showLoader);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.BRAND:
                    try {
                        _totalCount = Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "total_count", "0"));
                        if (jsonObject.has("Brand"))
                            brandDataPrepare(jsonObject.getJSONArray("Brand"));
                    } catch (Exception e) {
                        e.printStackTrace();
                        if(brandListItems.size()>0){
                            brandsBinding.brandShimmer.setVisibility(View.GONE);
                            brandsBinding.brandsRecycler.setVisibility(View.VISIBLE);
                            brandsBinding.noRecordTV.setVisibility(View.GONE);
                        }else {
                            brandsBinding.noRecordTV.setVisibility(View.VISIBLE);
                        }
                    }
                    break;
            }
        }
    }


    private void brandDataPrepare(JSONArray jsonArray) {
        try {
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                BrandListItem brandListItem = new BrandListItem();
                brandListItem.setTitle(ReckonUtils.getJsonCheckedString(jsonObject, "title", ""));
                brandListItem.setImage(getUserImageBaseUrl() + ReckonUtils.getJsonCheckedString(jsonObject, "image", ""));
                brandListItem.setBgColor("#ffffff");
                brandListItem.setDescription("");
                brandListItem.setId(Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "id", "0")));
                brandListItems.add(brandListItem);
            }
            if(brandListItems.size()>0){
                brandsBinding.brandShimmer.setVisibility(View.GONE);
                brandsBinding.brandsRecycler.setVisibility(View.VISIBLE);
                brandsBinding.noRecordTV.setVisibility(View.GONE);
            }else {
                brandsBinding.noRecordTV.setVisibility(View.VISIBLE);
            }
            brandsBinding.brandsRecycler.setAdapter(new NewArrivalAdapter(BrandsFragment.this, brandListItems, getString(R.string.Brands)));
        } catch (Exception e) {
            e.printStackTrace();
        }

    }
}