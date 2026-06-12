package com.reckon.reckonorders.NewDesign;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.annotation.SuppressLint;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.cardview.widget.CardView;
import androidx.core.widget.NestedScrollView;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Adapter.SelectionSingleAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Interfaces.ItemListener;
import com.reckon.reckonorders.Model.ProductFilterItemModel;
import com.reckon.reckonorders.Model.ProductFilterModel;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;


@SuppressLint("NonConstantResourceId")
public class ProductFilterScreen extends BaseFragment implements RetrofitCallBackListener {
    private static final String ID = "id";
    private static final String NAME = "name";
    private List<SelectionModel> categoryList = new ArrayList<>();
    private RetrofitCallBackListener retrofitCallBackListener;

    @BindView(R.id.cvClearBtn)
    CardView cvClearBtn;

    @BindView(R.id.cvApplyBtn)
    CardView cvApplyBtn;

    @BindView(R.id.sv_filter_category)
    NestedScrollView svFilterCategory;

    @BindView(R.id.rv_category)
    RecyclerView rvCategory;

    @BindView(R.id.search_loc_et)
    EditText edtSearch;


 /*   @BindView(R.id.sv_category_item)
    NestedScrollView svCategoryItem;*/

    @BindView(R.id.rv_category_item_list)
    RecyclerView rvCategoryItemList;

    String id = "", name = "";
    boolean isSalesMan = false;

    private LinearLayoutManager mCategoryLayoutManager;
    private LinearLayoutManager mCatItemLayoutManager;
    private ItemListener listener;
    private boolean loading = true;
    int visibleItemCount, totalItemCount;
    private ArrayList<ProductFilterItemModel> mSubFilterList = new ArrayList<>();

    public void setOnItemListener(ItemListener listener) {
        this.listener = listener;
    }

    private SelectionSingleAdapter subFilterItemAdapter;
    private SelectionSingleAdapter filterAdapter;
    private ArrayList<ProductFilterModel> filterList = new ArrayList<>();
    private ArrayList<ProductFilterItemModel> mainItemList = new ArrayList<>();
    final ArrayList<ProductFilterItemModel> mList = new ArrayList<>();
    private final int pageLimit = 50;
    private String selectedFilters = "", filterType = "Item", screen ="", source;
    final ArrayList<ProductFilterItemModel> savedList = new ArrayList<>();

    public static ProductFilterScreen newInstance(String id, String name) {
        Bundle args = new Bundle();
        args.putString(ID, id);
        args.putString(NAME, name);
        ProductFilterScreen fragment = new ProductFilterScreen();
        fragment.setArguments(args);
        return fragment;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_product_filter_screen, container, false);
        ButterKnife.bind(this, view);
        ((NewMainActivity) requireActivity()).setUpTitle(ProductFilterScreen.this, getString(R.string.filters));
        retrofitCallBackListener = this;
        KeyboardUtils.setupUI(view, getActivity());
        setupBackButton(view);
        getBundle();
        setupUI();
        return view;
    }


    @OnClick({R.id.cvApplyBtn, R.id.cvClearBtn})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.cvApplyBtn:
                applyFilter();
                break;
            case R.id.cvClearBtn:
                clearFilter();
                break;
        }
    }

    private void clearFilter() {
        for (int i = 0; i < filterList.size(); i++) {
            filterList.get(i).setSelected(false);
            for (int j = 0; j < filterList.get(i).getMlist().size(); j++) {
                filterList.get(i).getMlist().get(j).setSelected(false);
            }
        }
        filterAdapter.notifyDataSetChanged();
        subFilterItemAdapter.notifyDataSetChanged();
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.PRODUCT_FILTER);
        if(screen.equalsIgnoreCase(Constant.NEW_ORDER)){
            if(getLicDetails().getFirmcode().isEmpty()){
                bundle.putString(Constant.OPEN_PRODUCT_LIST_DIRECT, Constant.YES);
            }
            NavHostFragment.findNavController(this).navigate(R.id.action_back_to_product_screen, bundle);
        }else  if(screen.equalsIgnoreCase(Constant.PARTY_LIST)){
            bundle.putString("source", source);
            NavHostFragment.findNavController(this).navigate(R.id.action_back_to_party_screen, bundle);
        }else  if(screen.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)){
            bundle.putString(Constant.OPEN_PRODUCT_LIST_DIRECT, Constant.YES);
            NavHostFragment.findNavController(this).navigate(R.id.action_back_to_recent_product_screen, bundle);
        }
    }

    private void applyFilter() {
        try {
            JSONArray jsonArray = new JSONArray();
            for (int i = 0; i < filterList.size(); i++) {
                JSONObject jsonObject = new JSONObject();
                JSONArray jsonArray1 = new JSONArray();
                for (int j = 0; j < filterList.get(i).getMlist().size(); j++) {
                    if (filterList.get(i).getMlist().get(j).isSelected()) {
                        jsonArray1.put(filterList.get(i).getMlist().get(j).getId());
                    }
                }
                if (jsonArray1.length() > 0) {
                    jsonObject.put("id", filterList.get(i).getId());
                    jsonObject.put("items", jsonArray1);
                }
                if (jsonObject.length() > 0) {
                    jsonArray.put(jsonObject);
                }
            }
            System.out.println(jsonArray);
            Bundle bundle = new Bundle();
            bundle.putString(Constant.FROM, Constant.PRODUCT_FILTER);
            bundle.putString(Constant.APPLIED_FILTERS, jsonArray.toString());
            if(screen.equalsIgnoreCase(Constant.NEW_ORDER)){
                if(getLicDetails().getFirmcode().isEmpty()){
                    bundle.putString(Constant.OPEN_PRODUCT_LIST_DIRECT, Constant.YES);
                }
                NavHostFragment.findNavController(this).navigate(R.id.action_back_to_product_screen, bundle);
            }else  if(screen.equalsIgnoreCase(Constant.PARTY_LIST)){
                bundle.putString("source", source);
                NavHostFragment.findNavController(this).navigate(R.id.action_back_to_party_screen, bundle);
            }else  if(screen.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)){
                bundle.putString(Constant.OPEN_PRODUCT_LIST_DIRECT, Constant.YES);
                NavHostFragment.findNavController(this).navigate(R.id.action_back_to_recent_product_screen, bundle);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        cvApplyBtn.setCardBackgroundColor(getThirdHeaderColor());
        new Handler().postDelayed(this::getFilterList, 500);

        mCategoryLayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
        rvCategory.setLayoutManager(mCategoryLayoutManager);
        rvCategory.setNestedScrollingEnabled(false);

        mCatItemLayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
        rvCategoryItemList.setLayoutManager(mCatItemLayoutManager);
        rvCategoryItemList.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                if (dy > 0) {
                    visibleItemCount = mCatItemLayoutManager.getChildCount() + mCatItemLayoutManager.findFirstVisibleItemPosition();
                    if (loading) {
                        if (visibleItemCount >= mCatItemLayoutManager.getItemCount() && mCatItemLayoutManager.getItemCount() < totalItemCount) {
                            showLoading();
                            loading = false;
                            doApiCall();
                        }
                    }
                }
            }
        });
        searchWatcherListener();

    }

    private void searchWatcherListener() {
        edtSearch.setHint(R.string.search_hint);
        edtSearch.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if(s.toString().isEmpty()){
                    mList.clear();
                    mList.addAll(savedList);
                }else{
                    mList.clear();
                    for (ProductFilterItemModel d : mSubFilterList) {
                        if (d.getTitle().toLowerCase().contains(s.toString().toLowerCase())) {
                            mList.add(d);
                        }
                    }
                }

                subFilterItemAdapter.notifyDataSetChanged();
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
    }


    private void getFilterList() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("app_role", getLicDetails().getRole());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lFirmCode", isSalesMan ? getSelectedStoreDetailsFromPicker().getFirmCode() : getLicDetails().getFirmcode());
            jsonObject.put("lFlag", filterType);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("lRole", getLicDetails().getRole());
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getFiltersFromServer(String.valueOf(jsonObject)), Constant.FILTERS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private final ItemListener categoryListener = new ItemListener() {
        @Override
        public void onItemClicked(int position) {
            showLoading();
            if (listener != null)
                listener.onItemClicked(position);
            mList.clear();
            totalItemCount = 0;
            visibleItemCount = 0;
            ProductFilterModel selectedData = filterList.get(position);
            totalItemCount = Integer.parseInt(selectedData.getTotalCount());
            filterList.get(position).setSelected(true);
            mSubFilterList = selectedData.getMlist();
            mList.addAll(mSubFilterList.size() >= pageLimit ? mSubFilterList.subList(visibleItemCount, visibleItemCount + pageLimit) : mSubFilterList.subList(visibleItemCount, mSubFilterList.size()));
            mCatItemLayoutManager.scrollToPositionWithOffset(0, 0);
            subFilterItemAdapter.notifyDataSetChanged();
            dismissLoading();
            mainItemList.addAll(mSubFilterList.size() >= pageLimit ? mSubFilterList.subList(visibleItemCount, visibleItemCount + pageLimit) : mSubFilterList.subList(visibleItemCount, mSubFilterList.size()));
            savedList.clear();
            savedList.addAll(mList);
        }
    };

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            filterType = bundle.containsKey(Constant.FILTER_TYPE) ? bundle.getString(Constant.FILTER_TYPE) : "Item";
            selectedFilters = bundle.containsKey(Constant.APPLIED_FILTERS) ? bundle.getString(Constant.APPLIED_FILTERS) : "";
            screen = bundle.containsKey(Constant.FROM) ? bundle.getString(Constant.FROM) : "";
            source = bundle.containsKey("source") ? bundle.getString("source") : "";
            //            selectedAreaName = bundle.containsKey("selected_area_name") ? bundle.getString("selected_area_name") : "";
      /*      if (!selectedStationId.isEmpty() || !selectedAreaId.isEmpty()) {
                cvApplyBtn.setCardBackgroundColor(getThirdHeaderColor());
                cvClearBtn.setCardBackgroundColor(getThirdHeaderColor());
            } else {
                cvApplyBtn.setCardBackgroundColor(getResources().getColor(R.color.btn_dark_grey));
                cvClearBtn.setCardBackgroundColor(getResources().getColor(R.color.btn_dark_grey));
            }*/

        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && !result.isEmpty()) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.FILTERS:
                    parseFiltersData(jsonObject);
                    break;
            }
        }
    }

    private void parseFiltersData(JSONObject jsonObject) {
        try {
            JSONArray data = jsonObject.getJSONArray("data");
            for (int i = 0; i < data.length(); i++) {
                JSONObject item = data.getJSONObject(i);
                ProductFilterModel model = new ProductFilterModel();
                String catId = ReckonUtils.getJsonCheckedString(item, "id", "0");
                model.setId(catId);
                model.setTitle(ReckonUtils.getJsonCheckedString(item, "title", ""));
                model.setTitleColor(ReckonUtils.getJsonCheckedString(item, "title_color", "#000000"));
                model.setTotalCount(ReckonUtils.getJsonCheckedString(item, "total_count", "0"));
                model.setSelected(false);
                if (item.has("items")) {
                    ArrayList<ProductFilterItemModel> m2List = new ArrayList<>();
                    JSONArray items = item.getJSONArray("items");
                    for (int j = 0; j < items.length(); j++) {
                        JSONObject jsonObject1 = items.getJSONObject(j);
                        ProductFilterItemModel itemModel = new ProductFilterItemModel();
                        itemModel.setId(ReckonUtils.getJsonCheckedString(jsonObject1, "id", "0"));
                        itemModel.setTitle(ReckonUtils.getJsonCheckedString(jsonObject1, "title", ""));
                        itemModel.setSelected(false);
                        m2List.add(itemModel);
                    }
                    model.setMlist(m2List);
                }
                filterList.add(model);
            }
            for (ProductFilterModel model : filterList) {
                for (ProductFilterItemModel items : model.getMlist()) {
                    try {
                        if (!selectedFilters.isEmpty()) {
                            JSONArray jsonArray = new JSONArray(selectedFilters);
                            for (int k = 0; k < jsonArray.length(); k++) {
                                JSONObject jsonObject2 = jsonArray.getJSONObject(k);
                                JSONArray items2 = jsonObject2.getJSONArray("items");
                                for (int l = 0; l < items2.length(); l++) {
                                    if (model.getId().equalsIgnoreCase(jsonObject2.getString("id")) && items.getId().equalsIgnoreCase(items2.getString(l))) {
                                        items.setSelected(true);
                                    }
                                }
                            }
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }


            }


            filterAdapter = new SelectionSingleAdapter(filterList, Constant.PRODUCT_FILTER, this);
            rvCategory.setAdapter(filterAdapter);
            filterAdapter.setOnItemListener(categoryListener);
            setAdaptersData(0);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void setAdaptersData(int pos) {
        if (filterList != null && filterList.size() > 0) {
            mSubFilterList.clear();
            mList.clear();
            totalItemCount = Integer.parseInt(filterList.get(pos).getTotalCount());
            filterList.get(pos).setSelected(true);
            mSubFilterList = filterList.get(pos).getMlist();
            mList.addAll(mSubFilterList.size() >= pageLimit ? mSubFilterList.subList(visibleItemCount, visibleItemCount + pageLimit) : mSubFilterList.subList(visibleItemCount, mSubFilterList.size()));
            subFilterItemAdapter = new SelectionSingleAdapter(mList, ProductFilterScreen.this);
            rvCategoryItemList.setAdapter(subFilterItemAdapter);
            mainItemList.addAll(mSubFilterList.size() >= pageLimit ? mSubFilterList.subList(visibleItemCount, visibleItemCount + pageLimit) : mSubFilterList.subList(visibleItemCount, mSubFilterList.size()));
            savedList.clear();
            savedList.addAll(mList);
        }
    }

    private void doApiCall() {
        new Handler().postDelayed(() -> {
            mList.addAll(mSubFilterList.size() > visibleItemCount + pageLimit ? mSubFilterList.subList(visibleItemCount, visibleItemCount + pageLimit) : mSubFilterList.subList(visibleItemCount, mSubFilterList.size()));
            subFilterItemAdapter.notifyItemInserted(mList.size() - 1);
            loading = true;
            mainItemList.addAll(mSubFilterList.size() > visibleItemCount + pageLimit ? mSubFilterList.subList(visibleItemCount, visibleItemCount + pageLimit) : mSubFilterList.subList(visibleItemCount, mSubFilterList.size()));
        }, 1);
        dismissLoading();
    }
}
