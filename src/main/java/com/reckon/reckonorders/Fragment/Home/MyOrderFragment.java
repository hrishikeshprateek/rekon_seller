package com.reckon.reckonorders.Fragment.Home;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.widget.NestedScrollView;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;

import com.reckon.reckonorders.Adapter.MyOrderAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Fragment.Account.CommonListingFragment;
import com.reckon.reckonorders.Model.MyOrderModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import butterknife.Unbinder;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

public class MyOrderFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private static final String ID = "id";
    private static final String NAME = "name";
    @BindView(R.id.rv_my_order_listing)
    RecyclerView rv_my_order_listing;
    @BindView(R.id.noRecordTV)
    LinearLayout noRecordTV;
    @BindView(R.id.search_loc_et)
    public EditText search_loc_et;
    @BindView(R.id.scroll_view)
    NestedScrollView scroll_view;
    private Unbinder unbinder;
    private ArrayList<MyOrderModel> product_list = new ArrayList();
    public String FirmCode, LicNo, SortByValue = "";
    @BindView(R.id.actionbar_imgLogout)
    LinearLayout _imgMyCart;
    @BindView(R.id.imgView)
    ImageView imgView;


    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_my_order, container, false);
        unbinder = ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        setupBackButton(view);
        setTitle(view, getString(R.string.my_order).toUpperCase());
        setupUI();
        return view;
    }

    private void setupUI() {
        try {
            getMyOrderList();
            ( (NewMainActivity)getActivity()).setUpTitle(MyOrderFragment.this,getString(R.string.Order_History));
            search_loc_et.setInputType(search_loc_et.getInputType() | EditorInfo.TYPE_TEXT_FLAG_NO_SUGGESTIONS | EditorInfo.TYPE_TEXT_VARIATION_FILTER);
            search_loc_et.setHint(getResources().getString(R.string.search_product_name));
            rv_my_order_listing.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @OnClick({R.id.clear_text_ll, R.id.actionbar_imgLogout})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.actionbar_imgLogout:
                GoToCartFragment();
                break;
            case R.id.clear_text_ll:
                if (!search_loc_et.getText().toString().equalsIgnoreCase("")) {
                    search_loc_et.getText().clear();
                }
                break;
        }
    }

    private void GoToCommonListingFragment(int codeRequest, String from) {
        CommonListingFragment fragment = new CommonListingFragment();
        fragment.setTargetFragment(this, codeRequest);
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, from);
        fragment.setArguments(bundle);
        addFragment(fragment, true);
    }

    private void GoToCartFragment() {
        CartFragment fragment = new CartFragment();
        fragment.setTargetFragment(this, Constant.CODE_REQUEST_CART);
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.CART);
        bundle.putString(ID, LicNo);
        bundle.putString(NAME, FirmCode);
        fragment.setArguments(bundle);
        addFragment(fragment, true);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        switch (requestCode) {
        }
    }

    public void getMyOrderList() {
        try {
/*            JSONArray jsonArray1 = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.USER_DATA_LIST));
            JSONObject jsonObject = jsonArray1.getJSONObject(0);
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().MyOrderList(requireActivity().getPackageName(), jsonObject.getString("CountryCode") + jsonObject.getString("LicNo")), Constant.MYORDERLIST, false);
      */  } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        JSONObject jsonObject = new JSONObject(result);
        JSONArray jsonArray = jsonObject.getJSONArray("UserOrderList");
        setMyOrderListData(jsonArray);
    }

    private void setMyOrderListData(JSONArray jsonArray) {
        try {
            product_list.clear();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                MyOrderModel myOrderModel = new MyOrderModel();
                myOrderModel.setFIRM_NAME(jsonObject.has("FIRMNAME") ? jsonObject.getString("FIRMNAME") : "");
                myOrderModel.setFIRM_LICNO(jsonObject.has("LICNO") ? jsonObject.getString("LICNO") : "");
                myOrderModel.setFIRM_CODE(jsonObject.has("FIRM") ? jsonObject.getString("FIRM") : "");
                myOrderModel.setOrderList(jsonObject.has("Order") ? jsonObject.getJSONArray("Order") : new JSONArray());
                product_list.add(myOrderModel);
            }
            rv_my_order_listing.setAdapter(new MyOrderAdapter(MyOrderFragment.this, product_list, Constant.My_ORDER));
            if (product_list.size() == 0)
                noRecordTV.setVisibility(View.VISIBLE);
            else noRecordTV.setVisibility(View.GONE);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        unbinder.unbind();
    }
}
