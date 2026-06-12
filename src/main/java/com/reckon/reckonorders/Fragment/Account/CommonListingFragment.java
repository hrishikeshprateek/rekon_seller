package com.reckon.reckonorders.Fragment.Account;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.cardview.widget.CardView;
import androidx.core.widget.NestedScrollView;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.reckon.reckonorders.Adapter.CommonRowAdapter;
import com.reckon.reckonorders.Adapter.StationFilterRowAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Fragment.Home.RequestDistributorFragment;
import com.reckon.reckonorders.Interfaces.ItemListener;
import com.reckon.reckonorders.Model.LicDetailObjectModel;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BannerListItem;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BrandListItem;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.SelectSinglePopup;
import com.reckon.reckonorders.Others.database.DataHardCode;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.ActivityNewMainBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;


public class CommonListingFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private ArrayList<LoginModel> country_list = new ArrayList();
    private ArrayList<LoginModel> comun_list = new ArrayList();
    private ArrayList<LoginModel> distributor_list = new ArrayList();
    @BindView(R.id.common_listing_ll)
    LinearLayout commonListingLayout;
    @BindView(R.id.rv_common_listing)
    RecyclerView rv_common_listing;
    @BindView(R.id.rv_distributor_listing)
    RecyclerView rv_distributor_listing;
    @BindView(R.id.noRecordTV)
    LinearLayout noRecordTV;
    @BindView(R.id.search_bar)
    CardView searchBar;
    @BindView(R.id.header)
    View header;
    @BindView(R.id.search_loc_et)
    EditText search_loc_et;
    @BindView(R.id.fragmentProfile_llContainerSort)
    LinearLayout _llContainerSort;
    @BindView(R.id.fragmentMyVendor_imgSortVendors)
    ImageView imgSortVendors;

    @BindView(R.id.scrollView)
    NestedScrollView scrollView;
    @BindView(R.id.rvAccountFilterList)
    RecyclerView rvAccountFilterList;

    ActivityNewMainBinding mainBinding;
    private String Title, pin_code, selectedStationId, selectedStationName, selectedAreaId, selectedAreaName, source = "";
    private String brandNameSearchId = "", isNewArrival = "", withScheme = "", previousTitle = "";
    private static String _Country_ID, _State_ID, _City_ID, code = "";
    private SelectSinglePopup popupSortVendors;
    private List<SelectionModel> dataSortDistributors = new ArrayList<>();
    private final ArrayList<BrandListItem> accountFilterList = new ArrayList<>();
    public boolean isSearched = false;
    private boolean acceptClick = true;

    private Gson gson = new Gson();
    LocalStorage localStorage;
    private int PAGE_NUM = 1;
    private int _totalCount = 0;


    private SelectionModel selectedSortVendors;
    @BindView(R.id.fragmentMyVendor_tvCount)
    TextView tvCount;
    private int page, maxPage, sortBy = 2;
    private boolean loading;
    private int currentRemove = -1;
    private String searchType;
    private LinearLayoutManager mlayoutManager;
    private boolean isSalesMan;
    private View view;

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        view = inflater.inflate(R.layout.fragment_listing, container, false);
        ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        if (NewMainActivity.binding != null) {
            previousTitle = NewMainActivity.binding.appBarNewMain.pageName.getText().toString();
        }
        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        setupBackButton(view);
        getBundle();
        setupUI();
        setTitle(view, Title.equalsIgnoreCase(Constant.NEW_ORDER) ||Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL)
                || Title.equalsIgnoreCase(Constant.BRAND) || Title.equalsIgnoreCase(Constant.BRAND_LIST) || Title.equalsIgnoreCase(Constant.MYORDERLIST) ? Constant.DISTRIBUTOR.toUpperCase() : Title.toUpperCase());
        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        localStorage = new LocalStorage(requireActivity());
        if (getActivity() instanceof NewMainActivity) {
            header.setVisibility(View.GONE);
        }
        selectedSortVendors = new SelectionModel(2, "Selected City");
        if (Title.equalsIgnoreCase(Constant.SELECT_STATION) || Title.equalsIgnoreCase(Constant.SELECT_AREA)) {
            setUpAccountFilterData();
        } else {
            setUpCommonListingData();
        }

    }

    private void setUpCommonListingData() {
        final ArrayList<LoginModel> new_country_list = new ArrayList();
        final ArrayList<LoginModel> new_distributor_list = new ArrayList();

        rv_common_listing.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));
        rv_distributor_listing.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false));

        if (Title == null || Title.equalsIgnoreCase(Constant.COUNTRY)) {
            String string = SharedPrefUtils.getList(getActivity(), Constant.COUNTRY_LIST);
            try {
                JSONArray jsonArray = new JSONArray(string);
                setListingAdapter(jsonArray);
            } catch (Exception e) {
                e.printStackTrace();
            }
        } else if (Title.equalsIgnoreCase(Constant.STATE)) {
            searchType = "common";
            getList();
        } else if (Title.equalsIgnoreCase(Constant.DISTRIBUTOR)) {
            searchType = "common";
            _llContainerSort.setVisibility(View.GONE);
            rv_common_listing.setVisibility(View.GONE);
            rv_distributor_listing.setVisibility(View.VISIBLE);
            search_loc_et.setHint(getResources().getString(R.string.search_distributor));
            getDistributorList("UNMAP", "", "");
        } else if (Title.equalsIgnoreCase(Constant.NEW_ORDER) ||Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)|| Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL)
                || Title.equalsIgnoreCase(Constant.BRAND) || Title.equalsIgnoreCase(Constant.BRAND_LIST) || Title.equalsIgnoreCase(Constant.MYORDERLIST)) {
            searchType = "common";
            _llContainerSort.setVisibility(View.GONE);
            search_loc_et.setHint(getResources().getString(R.string.search_distributor));
            ((NewMainActivity) getActivity()).setHeader(Constant.DISTRIBUTOR.toUpperCase(), false);
            rv_common_listing.setVisibility(View.GONE);
            rv_distributor_listing.setVisibility(View.VISIBLE);
            getDistributorList("MAP", "1", "0");
        } else if (Title.equalsIgnoreCase(Constant.AREA)) {
            searchType = getString(R.string.area);
            getAreaList();
        } else {
            searchType = "common";
            getCityList();
        }
        if (searchType.equalsIgnoreCase(getString(R.string.area))) {
            searchBar.setVisibility(View.GONE);
        } else {
            searchBar.setVisibility(View.VISIBLE);
            search_loc_et.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {
                }

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                    if (s.length() == 0) {
                        noRecordTV.setVisibility(country_list.size() == 0 && distributor_list.size() == 0 ? View.VISIBLE : View.GONE);
                        if (Title.equalsIgnoreCase(Constant.DISTRIBUTOR) || (!isSalesMan && Title.equalsIgnoreCase(Constant.NEW_ORDER)||Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS))) {
                            rv_distributor_listing.setAdapter(new CommonRowAdapter(CommonListingFragment.this, distributor_list, Constant.DISTRIBUTOR));
                        } else {//|| FROM.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)
                            rv_common_listing.setAdapter(new CommonRowAdapter(CommonListingFragment.this, Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT)
                                    || Title.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL) || Title.equalsIgnoreCase(Constant.BRAND)
                                    || Title.equalsIgnoreCase(Constant.BRAND_LIST) || Title.equalsIgnoreCase(Constant.MYORDERLIST) ? distributor_list : country_list, "CSC"));
                        }

                    } else {
                        if (new_country_list.size() > 0)
                            new_country_list.clear();
                        if (new_distributor_list.size() > 0)
                            new_distributor_list.clear();

                        if (country_list.size() > 0 || distributor_list.size() > 0) {
                            if (comun_list.size() > 0)
                                comun_list.clear();
                            if (country_list.size() > 0)
                                comun_list.addAll(country_list);
                            else comun_list.addAll(distributor_list);

                            for (int i = 0; i < comun_list.size(); i++) {
                                if (comun_list.get(i).getCountry_name().toLowerCase().contains(s.toString().toLowerCase())) {
                                    LoginModel loginModel = new LoginModel();
                                    loginModel.setCountry_name(comun_list.get(i).getCountry_name());
                                    loginModel.setCountry_id(comun_list.get(i).getCountry_id());
                                    if (Title.equalsIgnoreCase(Constant.DISTRIBUTOR)) {
                                        loginModel.setAdd1(comun_list.get(i).getAdd1());
                                        loginModel.setMobile(comun_list.get(i).getMobile());
                                        String emailId = comun_list.get(i).getEmail();
                                        loginModel.setEmail(ReckonUtils.isValidEmail(emailId) ? emailId : "");
                                        loginModel.setLicNo(comun_list.get(i).getLicNo());
                                    }
                                    if (country_list.size() > 0)
                                        new_country_list.add(loginModel);
                                    else new_distributor_list.add(comun_list.get(i));
                                }
                                if (new_country_list.size() == 0 && new_distributor_list.size() == 0)
                                    noRecordTV.setVisibility(View.VISIBLE);
                                else noRecordTV.setVisibility(View.GONE);

                                if (Title.equalsIgnoreCase(Constant.DISTRIBUTOR) || (!isSalesMan && Title.equalsIgnoreCase(Constant.NEW_ORDER)||Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)))
                                    rv_distributor_listing.setAdapter(new CommonRowAdapter(CommonListingFragment.this, new_distributor_list, Constant.DISTRIBUTOR));
                                else
                                    rv_common_listing.setAdapter(new CommonRowAdapter(CommonListingFragment.this, Title.equalsIgnoreCase(Constant.NEW_ORDER) ||Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)|| Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT)
                                            || Title.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL) || Title.equalsIgnoreCase(Constant.BRAND)
                                            || Title.equalsIgnoreCase(Constant.BRAND_LIST) || Title.equalsIgnoreCase(Constant.MYORDERLIST) ? new_distributor_list : new_country_list, "CSC"));
                            }
                        }
                    }
                }

                @Override
                public void afterTextChanged(Editable s) {

                }
            });
        }
    }

    private void getDistributorList(String MapType, String status, String lock) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lCityCode", "");
            jsonObject.put("lMapType", MapType);
            jsonObject.put("lStatus", status);
            jsonObject.put("lLock", lock);
            jsonObject.put("lBussinessType", "");
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostDistributorList(String.valueOf(jsonObject)), Constant.DISTRIBUTOR, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void getCityList() {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostCity(requireActivity().getPackageName(), _State_ID), Constant.POST_CITY, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void getList() {
        try {
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().PostState(requireActivity().getPackageName(), _Country_ID), Constant.GET_STATE, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void getAreaList() {
        try {
//            ReckonUtils.BASE_URL = " ";
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getAreaFromPostOffice(pin_code), Constant.AREA, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setListingAdapter(JSONArray jsonArray) {
        try {
            if (country_list != null && country_list.size() > 0)
                country_list.clear();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                LoginModel loginModel = new LoginModel();
                loginModel.setCountry_name(jsonObject.getString("Name") != null ? jsonObject.getString("Name") : "");
                loginModel.setCity(jsonObject.getString("District") != null ? jsonObject.getString("District") : "");
                loginModel.setState(jsonObject.getString("State") != null ? jsonObject.getString("State") : "");
                loginModel.setCountry_id(jsonObject.has("Code") ? jsonObject.getString("Code") != null ? jsonObject.getString("Code") : "" : "");
                country_list.add(loginModel);
            }
            if (country_list.size() == 0)
                noRecordTV.setVisibility(View.VISIBLE);
            else noRecordTV.setVisibility(View.GONE);

            rv_common_listing.setAdapter(new CommonRowAdapter(CommonListingFragment.this, country_list, "CSC"));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            Title = bundle.containsKey(Constant.FROM) ? bundle.getString(Constant.FROM) : "";
            pin_code = bundle.containsKey(Constant.PIN_CODE) ? bundle.getString(Constant.PIN_CODE) != null ? bundle.getString(Constant.PIN_CODE) : "" : "";
            if (bundle.getString("Update") == "UPDATE") {
                header.setVisibility(View.GONE);
            }
            selectedStationId = bundle.containsKey("selected_station_id") ? bundle.getString("selected_station_id") : "";
            selectedStationName = bundle.containsKey("selected_station_name") ? bundle.getString("selected_station_name") : "";
            selectedAreaId = bundle.containsKey("selected_area_id") ? bundle.getString("selected_area_id") : "";
            selectedAreaName = bundle.containsKey("selected_area_name") ? bundle.getString("selected_area_name") : "";
            source = bundle.containsKey("source") ? bundle.getString("source") : "";
            brandNameSearchId = bundle.containsKey("BrandItemId") ? bundle.getString("BrandItemId") : "";
            isNewArrival = bundle.containsKey("isNewArrival") ? bundle.getString("isNewArrival") : "";
            withScheme = bundle.containsKey("withScheme") ? bundle.getString("withScheme") : "";
        }
    }


    private void setDistributorListingAdapter(JSONArray jsonArray) {
        try {
            if (distributor_list != null && distributor_list.size() > 0)
                distributor_list.clear();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                LoginModel loginModel = new LoginModel();
                loginModel.setCountry_name(jsonObject.getString("Name"));
                loginModel.setCountry_id(jsonObject.getString("Code"));
                String emailId = ReckonUtils.getJsonCheckedString(jsonObject, "Email", "");
                loginModel.setEmail(ReckonUtils.isValidEmail(emailId) ? emailId : "");
                loginModel.setLicNo(jsonObject.getString("LicNo"));
                loginModel.setMobile(!jsonObject.getString("Mobile").equalsIgnoreCase("") ? jsonObject.getString("Mobile") : "");
                loginModel.setAdd1(!jsonObject.getString("Add1").equalsIgnoreCase("") ? jsonObject.getString("Add1") : "N/A");
                loginModel.setAdd2(ReckonUtils.getJsonCheckedString(jsonObject, "Add2", ""));
                loginModel.setAdd3(ReckonUtils.getJsonCheckedString(jsonObject, "Add3", ""));
                loginModel.setShowStock(jsonObject.has("ShowStock") ? jsonObject.getString("ShowStock") : "0");
                loginModel.setRateType(jsonObject.has("RateType") ? jsonObject.getString("RateType") : "");
                loginModel.setCity(jsonObject.has("City") ? jsonObject.getString("City") : "");
                loginModel.setId(jsonObject.has("id") ? jsonObject.getString("id") : "");
                loginModel.setAcCode(jsonObject.has("AcCode") ? jsonObject.getString("AcCode") : "");
                String rating = ReckonUtils.getJsonCheckedString(jsonObject, "Rating", "");
                loginModel.setRating(!rating.equalsIgnoreCase("0") ? rating : "");
                loginModel.setBusiness(ReckonUtils.getJsonCheckedString(jsonObject, "Bussiness", ""));
                if (jsonObject.has("Images") && jsonObject.getJSONArray("Images").length() > 0) {
                    JSONArray bannerArray = jsonObject.getJSONArray("Images");
                    ArrayList<BannerListItem> bannerList = new ArrayList<>();
                    for (int j = 0; j < bannerArray.length(); j++) {
                        try {
                            BannerListItem bannerListItem = new BannerListItem();
                            String image = bannerArray.getString(j);
                            bannerListItem.setImageUrl(image.contains("https") || image.contains("http") ? image : getUserImageBaseUrl() + image);
                            bannerList.add(bannerListItem);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                    loginModel.setBannerList(bannerList);
                }
                distributor_list.add(loginModel);
            }
            if (distributor_list.size() == 0)
                noRecordTV.setVisibility(View.VISIBLE);
            else noRecordTV.setVisibility(View.GONE);
            tvCount.setText(selectedSortVendors.getName() + " (" + distributor_list.size() + ")");
//            if (Title.equalsIgnoreCase(Constant.DISTRIBUTOR)) {
            rv_distributor_listing.setVisibility(View.VISIBLE);
            rv_distributor_listing.setAdapter(new CommonRowAdapter(CommonListingFragment.this, distributor_list, Constant.DISTRIBUTOR));
     /*       } else
                rv_common_listing.setAdapter(new CommonRowAdapter(CommonListingFragment.this, distributor_list, "CSC"));*/

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void getID(String country_id, String country_name, String State, String City, String LicNo, String showStock, String rateType) {
        if (Title == null || Title.equalsIgnoreCase(Constant.COUNTRY)) {
            _Country_ID = country_id;
            sendData(_Country_ID, country_name, State, City, "", "", "", "", "");
        } else if (Title.equalsIgnoreCase(Constant.STATE)) {
            _State_ID = country_id;
            sendData(_State_ID, country_name, State, City, "", "", "", "", "");
        } else if (Title.equalsIgnoreCase(Constant.NEW_ORDER)||Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL)
                || Title.equalsIgnoreCase(Constant.BRAND) || Title.equalsIgnoreCase(Constant.BRAND_LIST) || Title.equalsIgnoreCase(Constant.MYORDERLIST)) {
            sendData(country_id, country_name, State, City, LicNo, showStock, rateType, Title, code);
        } else {
            _City_ID = country_id;
            sendData(_City_ID, country_name, State, City, "", "", "", "", "");
        }
    }

    public void getDisstributorData(LoginModel loginModel) {
        if (Title.equalsIgnoreCase(Constant.NEW_ORDER) ||Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)|| Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL)
                || Title.equalsIgnoreCase(Constant.BRAND) || Title.equalsIgnoreCase(Constant.BRAND_LIST) || Title.equalsIgnoreCase(Constant.MYORDERLIST)) {
            Bundle bundle = new Bundle();
            bundle.putString(isSalesMan ? "data" : "name", loginModel.getCountry_name());
            bundle.putString(Constant.SELECTED_ID, loginModel.getCountry_id());
            bundle.putString(Constant.ID, loginModel.getId() == null ? loginModel.getCountry_id() : loginModel.getId());
            bundle.putString("LicNo", loginModel.getLicNo());
            bundle.putString("Mobile", loginModel.getMobile());
            bundle.putString("address", loginModel.getAdd1());
//            if(!getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)){
            LicDetailObjectModel model = getLicDetails();
            model.setLicno(loginModel.getLicNo());///TODO: remove for multi case
            model.setFirmcode(loginModel.getCountry_id());
            model.setFirmName(loginModel.getCountry_name());
            model.setFirmAdd(loginModel.getAdd1());
            localStorage.setLicDetails(gson.toJson(model));
//            }
            SharedPrefUtils.setString(getActivity(), Constant.AC_CODE, loginModel.getAcCode());
            localStorage.setDelStoreInfo(gson.toJson(parseStoreObjFromDistributorList(loginModel)));
            if (Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS) || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL) || Title.equalsIgnoreCase(Constant.BRAND) || Title.equalsIgnoreCase(Constant.BRAND_LIST)) {
                bundle.putString("BrandItemId", brandNameSearchId);
                bundle.putString("isNewArrival", isNewArrival);
                bundle.putString("withScheme", withScheme);
                if(Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS) ){
                    NavHostFragment.findNavController(CommonListingFragment.this).navigate(R.id.action_back_to_recent_ordered, bundle);
                }else{
                    NavHostFragment.findNavController(CommonListingFragment.this).navigate(R.id.action_back_to_order_entry, bundle);
                }
            } else if (Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT)) {
                bundle.putString(Constant.PARTY_LIST, new Gson().toJson(loginModel));
                NavHostFragment.findNavController(this).navigate(R.id.nav_account_statement, bundle);
            } else if (source.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.OUTSTANDING)) {
                bundle.putString("from", Constant.PARTY);
                NavHostFragment.findNavController(this).navigate(R.id.nav_outlet_details, bundle);
            } else if (source.equalsIgnoreCase(Constant.MYORDERLIST) || Title.equalsIgnoreCase(Constant.MYORDERLIST)) {
                requireActivity().onBackPressed();
            }
        } else {
            Intent intent = new Intent();
            intent.putExtra("data", loginModel.getCountry_name());
            intent.putExtra(Constant.SELECTED_ID, loginModel.getCountry_id());
            intent.putExtra(Constant.ID, loginModel.getId());
            intent.putExtra("LicNo", loginModel.getLicNo());
            intent.putExtra("Mobile", loginModel.getMobile());
            new RequestDistributorFragment().getSearchedData(intent);
            getActivity().onBackPressed();
        }

    }

    private void sendData(String _ID, String _name, String State, String City, String LicNo, String ShowStock, String RateType, String from, String _code) {

        Intent intent = new Intent();
        intent.putExtra("data", _name);
        intent.putExtra(Constant.SELECTED_ID, _ID);
        intent.putExtra("State", State);
        intent.putExtra("City", City);
        intent.putExtra("LicNo", LicNo);
        intent.putExtra("ShowStock", ShowStock);
        intent.putExtra("RateType", RateType);
        if (getTargetFragment() != null) {
            getTargetFragment().onActivityResult(getTargetRequestCode(), 0, intent);
            getActivity().onBackPressed();
        } else {
            Bundle bundle = new Bundle();
            bundle.putString("data", _name);
            bundle.putString(Constant.PIN_CODE, getArguments().getString(Constant.PIN_CODE));
            bundle.putString(Constant.SELECTED_ID, _ID);
            bundle.putString("State", State);
            bundle.putString("City", City);
            bundle.putString("Code", _code);
            bundle.putString("LicNo", LicNo);
            bundle.putString("ShowStock", ShowStock);
            bundle.putString("RateType", RateType);
            if (from.equalsIgnoreCase(Constant.NEW_ORDER))//Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT)
                NavHostFragment.findNavController(CommonListingFragment.this).navigate(R.id.nav_Order_Entry, bundle);
            else if(Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS))
                NavHostFragment.findNavController(CommonListingFragment.this).navigate(R.id.nav_Recent_Ordered_Products, bundle);
            else if (from.equalsIgnoreCase(Constant.ACCOUNT_FILTER))
                NavHostFragment.findNavController(CommonListingFragment.this).navigate(R.id.action_back_to_account_filter, bundle);
            else if (source.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT)) {
                bundle.putString("from", Constant.PARTY);
             /*   bundle.putString("address", address);
                if (!FirmCode.isEmpty()) {
                    bundle.putString(Constant.FIRM_NAME, FirmName);
                    bundle.putString(Constant.FIRM_CODE, FirmCode);
                }*/
                NavHostFragment.findNavController(this).navigate(R.id.nav_account_statement, bundle);
            } else if (Title.equalsIgnoreCase(Constant.OUTSTANDING)) {
                NavHostFragment.findNavController(this).navigate(R.id.nav_outlet_details, bundle);
            } else
                NavHostFragment.findNavController(CommonListingFragment.this).navigate(R.id.cation_back_to_profile, bundle);
        }
    }

    private void createPopupSortVendors() {
        if (popupSortVendors == null) {
            dataSortDistributors = DataHardCode.getListSortDistributors();
            popupSortVendors = new SelectSinglePopup(getActivity(), dataSortDistributors, false);
            popupSortVendors.setOnItemListener(new ItemListener() {
                @Override
                public void onItemClicked(int position) {
                    if (position < dataSortDistributors.size()) {
                        selectedSortVendors = dataSortDistributors.get(position);
                        tvCount.setText(position != 0 ? selectedSortVendors.getName() : "All (" + distributor_list.size() + ")");//data.size()
                        sortBy = dataSortDistributors.get(position).getId();
                        if (Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.OUTSTANDING)) {
                            getDistributorList("MAP", "1", "0");
                        } else
                            getDistributorList("UNMAP", "", "");
                    }
                }
            });
            popupSortVendors.setOnDismissListener(() -> imgSortVendors.setImageResource(R.drawable.ic_select_down));
        }
    }

    @OnClick(R.id.fragmentMyVendor_frmSortVendor)
    public void onViewClicked(View view) {
        imgSortVendors.setImageResource(R.drawable.ic_select_up);
        createPopupSortVendors();
        popupSortVendors.showAsDropDown(view, 0, 1);
    }

    private void setUpAccountFilterData() {
        mlayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
        rvAccountFilterList.setLayoutManager(mlayoutManager);
        rv_common_listing.setVisibility(View.GONE);
        rv_distributor_listing.setVisibility(View.GONE);
        scrollView.setVisibility(View.VISIBLE);
        search_loc_et.setHint(Title.equalsIgnoreCase(Constant.SELECT_STATION) ? getResources().getString(R.string.search_station) : getResources().getString(R.string.search_area));
        new Handler().postDelayed(() -> getAccountFilterList("", PAGE_NUM, true), 10);
        scrollView.setOnScrollChangeListener((NestedScrollView.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
            if (v.getChildAt(v.getChildCount() - 1) != null) {
                if ((scrollY >= (v.getChildAt(v.getChildCount() - 1).getMeasuredHeight() - v.getMeasuredHeight())) &&
                        scrollY > oldScrollY) {
                    int visibleItemCount = mlayoutManager.getChildCount();
                    int totalItemCount = mlayoutManager.getItemCount();
                    int pastVisiblesItems = mlayoutManager.findFirstVisibleItemPosition();
                    if ((visibleItemCount + pastVisiblesItems) >= totalItemCount) {
                        if (_totalCount > accountFilterList.size()) {
                            isSearched = false;
                            getAccountFilterList("", ++PAGE_NUM, true);
                        }
                    }
                }
            }
        });
        searchBar.setVisibility(View.VISIBLE);
        search_loc_et.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
//                clear_text_ll.setVisibility(!search_loc_et.getText().toString().isEmpty() ? View.VISIBLE : View.INVISIBLE);
                isSearched = true;
                PAGE_NUM = 1;
                if (s.toString().isEmpty()) {
                    getAccountFilterList(s.toString(), PAGE_NUM, false);
                } else if (acceptClick) {
                    acceptClick = false;
                    getAccountFilterList(s.toString(), PAGE_NUM, false);
                    new Handler().postDelayed(() -> acceptClick = true, 1500);
                }
                scrollView.scrollTo(0, 0);
            }

            @Override
            public void afterTextChanged(Editable s) {
                isSearched = true;
            }
        });
    }

    private void getAccountFilterList(String s, int PAGE_NUM, boolean isLoader) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lPageNo", String.valueOf(PAGE_NUM));
            jsonObject.put("lSize", String.valueOf(200));
            jsonObject.put("lSearchFieldValue", s);
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lCUID", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            if (Title.equalsIgnoreCase(Constant.SELECT_STATION)) {
                new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getStationList(String.valueOf(jsonObject)), Constant.FILTER_STATION, isLoader);
            } else if (Title.equalsIgnoreCase(Constant.SELECT_AREA)) {
                new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getFilterAreaList(String.valueOf(jsonObject)), Constant.FILTER_AREA, isLoader);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 0)
            switch (action) {
                case Constant.GET_STATE:
                    JSONObject jsonObject = new JSONObject(result);
                    setListingAdapter(jsonObject.getJSONArray("State"));
                    break;
                case Constant.POST_CITY:
                    JSONObject jsonObject1 = new JSONObject(result);
                    setListingAdapter(jsonObject1.getJSONArray("City"));
                    break;
                case Constant.DISTRIBUTOR:
                    try {
                        JSONObject jsonObject2 = new JSONObject(result);
                        if (jsonObject2.has("Distributor")) {
                            setDistributorListingAdapter(jsonObject2.getJSONArray("Distributor"));
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        if (distributor_list.size() == 0)
                            noRecordTV.setVisibility(View.VISIBLE);
                        else noRecordTV.setVisibility(View.GONE);
                    }
                    break;
                case Constant.AREA:
                    JSONArray jsonArrayArea = new JSONArray(result);
                    if (jsonArrayArea.length() > 0) {
                        JSONObject jsonObj = jsonArrayArea.getJSONObject(0);
                        if (jsonObj != null && jsonObj.has("PostOffice") && jsonObj.get("Status").equals("Success") && jsonObj.getJSONArray("PostOffice") != null) {
                            JSONArray jsonArrayPostOffice = jsonObj.getJSONArray("PostOffice");
                            setListingAdapter(jsonArrayPostOffice);
                        } else
                            noRecordTV.setVisibility(View.VISIBLE);
                    }
                    break;
                case Constant.FILTER_STATION:
                    try {
                        JSONObject jsonStation = new JSONObject(result);
                        _totalCount = Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonStation, "total_count", "0"));
                        if (jsonStation.has("Station"))
                            parseAccountFilterData(jsonStation.getJSONArray("Station"));
                    } catch (Exception e) {
                        e.printStackTrace();
                        noRecordTV.setVisibility(accountFilterList.isEmpty() ? View.VISIBLE : View.GONE);
                    }
                    break;
                case Constant.FILTER_AREA:
                    try {
                        JSONObject jsonFilterArea = new JSONObject(result);
                        _totalCount = Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonFilterArea, "total_count", "0"));
                        if (jsonFilterArea.has("Area"))
                            parseAccountFilterData(jsonFilterArea.getJSONArray("Area"));
                    } catch (Exception e) {
                        e.printStackTrace();
                        noRecordTV.setVisibility(accountFilterList.isEmpty() ? View.VISIBLE : View.GONE);
                    }
                    break;
            }

    }

    private void parseAccountFilterData(JSONArray jsonArray) {
        try {
            if (isSearched && accountFilterList.size() > 0) {
                isSearched = false;
                accountFilterList.clear();
            }
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                BrandListItem stationsItem = new BrandListItem();
                stationsItem.setTitle(ReckonUtils.getJsonCheckedString(jsonObject, "title", ""));
                stationsItem.setImage(getUserImageBaseUrl() + ReckonUtils.getJsonCheckedString(jsonObject, "image", ""));
                stationsItem.setBgColor("#ffffff");
                stationsItem.setDescription("");
                stationsItem.setId(Integer.parseInt(ReckonUtils.getJsonCheckedString(jsonObject, "id", "0")));
                accountFilterList.add(stationsItem);
            }
            noRecordTV.setVisibility(accountFilterList.isEmpty() ? View.VISIBLE : View.GONE);
            rvAccountFilterList.setAdapter(new StationFilterRowAdapter(CommonListingFragment.this, accountFilterList, "CSC"));
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public void executeAccountFilerClick(int id, String name) {
        if (Title.equalsIgnoreCase(Constant.SELECT_STATION)) {
            selectedStationId = String.valueOf(id);
            selectedStationName = name;
        } else if (Title.equalsIgnoreCase(Constant.SELECT_AREA)) {
            selectedAreaId = String.valueOf(id);
            selectedAreaName = name;
        }
        Bundle bundle = new Bundle();
        bundle.putString("selected_station_id", selectedStationId);
        bundle.putString("selected_station_name", selectedStationName);
        bundle.putString("selected_area_id", selectedAreaId);
        bundle.putString("selected_area_name", selectedAreaName);
        bundle.putString("source", source);
        NavHostFragment.findNavController(this).navigate(R.id.action_back_to_account_filter, bundle);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (requireActivity() instanceof NewMainActivity) {
            ((NewMainActivity) requireActivity()).setUpTitle(this, previousTitle);
        }

//        requireActivity().getSupportFragmentManager().popBackStack();

    }
}
