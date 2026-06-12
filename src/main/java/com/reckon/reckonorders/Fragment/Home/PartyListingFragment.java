package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Address;
import android.location.Geocoder;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.cardview.widget.CardView;
import androidx.core.app.ActivityCompat;
import androidx.core.widget.NestedScrollView;
import androidx.navigation.Navigation;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.reckon.reckonorders.Adapter.PartyAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.LoginModel;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.SelectSinglePopup;
import com.reckon.reckonorders.Others.database.DataHardCode;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.Debouncer;
import com.reckon.reckonorders.Utils.KeyboardUtils;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

///Firm, Store are same
///Party and Account are same
public class PartyListingFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private static final int MIN_TIME = 1000;
    private static final int MIN_DISTANCE = 1;
    private ArrayList<LoginModel> party_list = new ArrayList();
    private ArrayList<LoginModel> comun_list = new ArrayList();
    @BindView(R.id.clear_text_ll)
    LinearLayout searchCancelBtn;
    PartyAdapter partyAdapter;
    @BindView(R.id.searchLL)
    LinearLayout searchButton;
    @BindView(R.id.firmName)
    TextView firmName;
    @BindView(R.id.firmNameHolder)
    CardView firmNameHolder;
    @BindView(R.id.rv_party_listing)
    RecyclerView rv_party_listing;
    @BindView(R.id.noRecordTV)
    LinearLayout noRecordTV;
    @BindView(R.id.search_loc_et)
    EditText search_loc_et;
    @BindView(R.id.fragmentMyVendor_imgSortVendors)
    ImageView imgSortVendors;

    private int TotalItemCount = 0;
    private String brandId = "";
    LinearLayoutManager mlayoutManager;
    private String Title, FirmName = "", FirmCode = "", previousTitle = "", selectedFilters = "";
    private SelectSinglePopup popupSortVendors;
    private List<SelectionModel> dataSortDistributors = new ArrayList<>();
    private SelectionModel selectedSortVendors;
    @BindView(R.id.fragmentMyVendor_tvCount)
    TextView tvCount;
    @BindView(R.id.pullToRefresh)
    SwipeRefreshLayout pullToRefresh;
    private int page, maxPage, sortBy = 2;
    private int pageCount = 20;
    public boolean isSearched = false;
    private int PAGE_NUM = 1;
    @BindView(R.id.scroll_view)
    NestedScrollView scroll_view;
    private String brandNameSearchId = "", isNewArrival = "", withScheme = "";
    private boolean acceptClick = true;
    @BindView(R.id.cvApplyFilter)
    CardView cvApplyFilter;
    @BindView(R.id.llFilterCircle)
    LinearLayout llFilterCircle;
    private String source = "", selectedStationId = "", selectedStationName = "", selectedAreaId = "", selectedAreaName = "";
    private View view = null;
    private LocationManager locationManager;
    public static final int CODE_PERMISSION_REQUEST = 4;
    private LoginModel selectedPartyModelData;
    private int selectedPartyModelPosition = -1;
    private boolean updateLocation = false, updatePartyWithLatLang = true;
    private String latitude = "", longitude = "";
    final Debouncer debouncer = new Debouncer();

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        if (view == null) {
            view = inflater.inflate(R.layout.fragment_party_listing, container, false);
            ButterKnife.bind(this, view);
            retrofitCallBackListener = this;
            previousTitle = NewMainActivity.binding.appBarNewMain.pageName.getText().toString();
            locationManager = (LocationManager) requireActivity().getSystemService(Context.LOCATION_SERVICE);
            setupBackButton(view);
            getBundle();
            setupUI(view);
            view.setOnTouchListener((v, event) -> {
                InputMethodManager imm = (InputMethodManager) requireActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
                return false;
            });
            setTitle(view, Title.equalsIgnoreCase(Constant.FIRM) ? Constant.FIRM : getResources().getString(R.string.serach_party).toUpperCase());

//            ReckonUtils.calculateDistance(26.8461898, 80.9293555, 28.416018, 77.324231);
        }

        return view;
    }
    @Override
    public void onDestroy() {
        if (locationManager != null) {
            locationManager.removeUpdates(locationListener);
            locationManager = null;
        }
        super.onDestroy();
//        ((NewMainActivity) requireActivity()).setUpTitle(this, previousTitle);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI(View view) {
        cvApplyFilter.setCardBackgroundColor(getThirdHeaderColor());
        cvApplyFilter.setOnClickListener(v -> {
//            GoToAccountFilterFragment(Constant.PARTY, view);
            goToFilterScreen(view);
        });
        llFilterCircle.setVisibility((!selectedAreaId.isEmpty() || !selectedStationId.isEmpty()) ? View.VISIBLE : View.GONE);
        pullToRefresh.setOnRefreshListener(() -> {
            clearPartyListData();
            pullToRefresh.setRefreshing(false);
        });
        ((NewMainActivity) requireActivity()).setUpTitle(PartyListingFragment.this, getString(R.string.select_account));
        mlayoutManager = new LinearLayoutManager(getActivity(), LinearLayoutManager.VERTICAL, false);
        rv_party_listing.setLayoutManager(mlayoutManager);
        rv_party_listing.setNestedScrollingEnabled(false);

        scroll_view.setOnTouchListener((v, event) -> {
            InputMethodManager imm = (InputMethodManager) requireActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
            return false;
        });
        scroll_view.setOnScrollChangeListener((View.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
            InputMethodManager imm = (InputMethodManager) requireActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
        });
        if (Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.BRAND) || Title.equalsIgnoreCase(Constant.BRAND_LIST) ||
                Title.equalsIgnoreCase(Constant.NEW_ARRIVAL) || Title.equalsIgnoreCase(Constant.ACCOUNT_FILTER) || Title.equalsIgnoreCase(Constant.PRODUCT_FILTER) ||
                Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.CREATE_RECEIPT)) {
            search_loc_et.setHint(getResources().getString(R.string.serach_party));
            partyAdapter = new PartyAdapter(PartyListingFragment.this, party_list, Constant.PARTY, Title);
            rv_party_listing.setAdapter(partyAdapter);
            if(SharedPrefUtils.getShowLocation(requireActivity())){
                if (ActivityCompat.checkSelfPermission(requireActivity(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(requireActivity(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    showLoading();
                    setupLocation();
                } else {
                    requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, CODE_PERMISSION_REQUEST);
                }
            }else{
                new Handler().postDelayed(() -> getPartyList("", PAGE_NUM, true), 1000);
            }

        } else {
            search_loc_et.setHint(getResources().getString(R.string.search_firm));
            if (party_list.size() == 0)
                new Handler().postDelayed(() -> getFirmList("", true), 1000);

        }
        searchCancelBtn.setOnClickListener(v -> {
            search_loc_et.setText("");
            InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
        });

        search_loc_et.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.toString().isEmpty()) {
                    searchCancelBtn.setVisibility(View.INVISIBLE);
                } else {
                    searchCancelBtn.setVisibility(View.VISIBLE);
                }
                isSearched = true;
                PAGE_NUM = 1;
                if (s.toString().isEmpty()) {
                    new Handler().postDelayed(() -> {
                        if (Title.equalsIgnoreCase(Constant.CREATE_RECEIPT) || Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.ACCOUNT_FILTER) || Title.equalsIgnoreCase(Constant.PRODUCT_FILTER) || Title.equalsIgnoreCase(Constant.OUTSTANDING))
                            getPartyList("", 1, false);
                        else
                            getFirmList("", false);
                    }, 1500);
                } else if (acceptClick) {
                    acceptClick = false;
                    if (Title.equalsIgnoreCase(Constant.CREATE_RECEIPT) || Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.ACCOUNT_FILTER) || Title.equalsIgnoreCase(Constant.PRODUCT_FILTER) || Title.equalsIgnoreCase(Constant.OUTSTANDING))
                        getPartyList(s.toString(), PAGE_NUM, false);
                    else
                        getFirmList(s.toString(), false);
                    new Handler().postDelayed(() -> acceptClick = true, 1500);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {
                InputMethodManager mgr = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                mgr.showSoftInput(search_loc_et, InputMethodManager.SHOW_FORCED);
            }
        });

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            scroll_view.setOnScrollChangeListener((NestedScrollView.OnScrollChangeListener) (v, scrollX, scrollY, oldScrollX, oldScrollY) -> {
                if (v.getChildAt(v.getChildCount() - 1) != null) {
                    if ((scrollY >= (v.getChildAt(v.getChildCount() - 1).getMeasuredHeight() - v.getMeasuredHeight())) &&
                            scrollY > oldScrollY) {
                        int visibleItemCount = mlayoutManager.getChildCount();
                        int totalItemCount = mlayoutManager.getItemCount();
                        int pastVisiblesItems = mlayoutManager.findFirstVisibleItemPosition();
                        if ((visibleItemCount + pastVisiblesItems) >= totalItemCount) {
                            if (TotalItemCount > party_list.size()) {
                                isSearched = false;
                                getPartyList(search_loc_et.getText().toString(), ++PAGE_NUM, true);
                            }
                        }
                    }
                }
            });
        }
    }

    private void clearPartyListData() {
        if (party_list != null)
            party_list.clear();
        getPartyList(search_loc_et.getText().toString(), 1, true);
        partyAdapter.notifyDataSetChanged();
    }

    private void GoToAccountFilterFragment(String from, View view) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, from);
        bundle.putString("selected_station_id", selectedStationId);
        bundle.putString("selected_station_name", selectedStationName);
        bundle.putString("selected_area_id", selectedAreaId);
        bundle.putString("selected_area_name", selectedAreaName);
        bundle.putString("source", Title);
        Navigation.findNavController(view).navigate(R.id.navAccountFilterFragment, bundle);
    }

    private void getFirmList(String s, boolean isLoader) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lPageNo", String.valueOf(PAGE_NUM));
            jsonObject.put("lSize", String.valueOf(pageCount));
            jsonObject.put("lSearchFieldValue", s);
            jsonObject.put("lStartWithSearchFieldValue", "");
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getFirmList(String.valueOf(jsonObject)), Constant.FIRM, isLoader);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void getPartyList(String s, int PAGE_NUM, boolean isLoader) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("lPageNo", String.valueOf(PAGE_NUM));
            jsonObject.put("lSize", String.valueOf(pageCount));
            jsonObject.put("lSearchFieldValue", s);
            jsonObject.put("lExecuteTotalRows", "1");
            jsonObject.put("lMr", selectedStationId);
            jsonObject.put("lArea", selectedAreaId);
            jsonObject.put("lCUID", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("ltype", "0");
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("latitude", latitude);
            jsonObject.put("longitude", longitude);
            try {
                if (!selectedFilters.isEmpty()) {
                    JSONArray jsonArray = new JSONArray(selectedFilters);
                    jsonObject.put("filters", jsonArray);
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().getPartyList(String.valueOf(jsonObject)), Constant.PARTY, isLoader);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            brandNameSearchId = bundle.containsKey("BrandItemId") ? bundle.getString("BrandItemId") : "";
            isNewArrival = bundle.containsKey("isNewArrival") ? bundle.getString("isNewArrival") : "";
            withScheme = bundle.containsKey("withScheme") ? bundle.getString("withScheme") : "";
            Title = bundle.containsKey(Constant.FROM) ? bundle.getString(Constant.FROM) : "";
            if (Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.BRAND) || Title.equalsIgnoreCase(Constant.BRAND_LIST)
                    || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT)
                    || Title.equalsIgnoreCase(Constant.OUTSTANDING)) {
                FirmName = bundle.containsKey("name") ? bundle.getString("name") : "";
                FirmCode = bundle.containsKey("Code") ? bundle.getString("Code") : "";

            }
            if (getArguments().containsKey("name")) {
                firmName.setText(getArguments().getString("name"));
            }
            if (Title.equalsIgnoreCase(Constant.ACCOUNT_FILTER) || Title.equalsIgnoreCase(Constant.PRODUCT_FILTER)) {
                selectedStationId = bundle.containsKey("selected_station_id") ? bundle.getString("selected_station_id") : "";
                selectedStationName = bundle.containsKey("selected_station_name") ? bundle.getString("selected_station_name") : "";
                selectedAreaId = bundle.containsKey("selected_area_id") ? bundle.getString("selected_area_id") : "";
                selectedAreaName = bundle.containsKey("selected_area_name") ? bundle.getString("selected_area_name") : "";
                source = bundle.containsKey("source") ? bundle.getString("source") : "";
            }
            if (Title.equalsIgnoreCase(Constant.CREATE_RECEIPT)) {
                FirmName = bundle.containsKey(Constant.FIRM_NAME) ? bundle.getString(Constant.FIRM_NAME) : "";
                FirmCode = bundle.containsKey(Constant.FIRM_CODE) ? bundle.getString(Constant.FIRM_CODE) : "";
            }
            selectedFilters = bundle.containsKey(Constant.APPLIED_FILTERS) ? bundle.getString(Constant.APPLIED_FILTERS) : "";
            System.out.println("Screen Name================== " + Title + "===============++ " + previousTitle + "Source================= " + source);
        }
    }


    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 1) {
            JSONObject jsonObject = new JSONObject(result);
            switch (action) {
                case Constant.PARTY:
                    try {
                        JSONArray jsonArray2 = jsonObject.getJSONArray("Account");
                        setDistributorListingAdapter(jsonArray2, Constant.PARTY);
                    } catch (Exception e) {
                        e.printStackTrace();
                        if (party_list.size() == 0) {
                            noRecordTV.setVisibility(View.VISIBLE);
                            pullToRefresh.setVisibility(View.GONE);

                        } else {
                            noRecordTV.setVisibility(View.GONE);
                            pullToRefresh.setVisibility(View.VISIBLE);
                        }
                    }
                    break;
                case Constant.FIRM:
                    try {
                        party_list.clear();
                        JSONArray jsonArray2 = jsonObject.getJSONArray("Firm");
                        setDistributorListingAdapter(jsonArray2, Constant.FIRM);
                    } catch (Exception e) {
                        e.printStackTrace();
                        if (party_list.size() == 0) {
                            noRecordTV.setVisibility(View.VISIBLE);
                            pullToRefresh.setVisibility(View.GONE);

                        } else {
                            noRecordTV.setVisibility(View.GONE);
                            pullToRefresh.setVisibility(View.VISIBLE);
                        }
                    }
                    break;
                case Constant.UPDATE_LOCATION:
                    updatePartyListData(jsonObject);
                    break;

            }
        }
    }

    private void updatePartyListData(JSONObject jsonObject) {
        try {
            String msg = ReckonUtils.getJsonCheckedString(jsonObject, "message", "");
            if (jsonObject.has("status") && jsonObject.getBoolean("status")) {
                String accId = ReckonUtils.getJsonCheckedString(jsonObject, "ac_id_col", "");
                String latitude = ReckonUtils.getJsonCheckedString(jsonObject, "latitude", "");
                String longitude = ReckonUtils.getJsonCheckedString(jsonObject, "longitude", "");

                LoginModel model = party_list.get(selectedPartyModelPosition);
                if (accId.equalsIgnoreCase(model.getAcIdCol())) {
                    model.setLatitude(latitude);
                    model.setLongitude(longitude);
                    model.setShowUpdateLocation(false);
                }
                partyAdapter.notifyItemChanged(selectedPartyModelPosition, model);
                Toast.makeText(requireActivity(), msg, Toast.LENGTH_LONG).show();
            } else {
                Toast.makeText(requireActivity(), msg, Toast.LENGTH_LONG).show();
            }
            selectedPartyModelPosition = -1;
        } catch (Exception e) {
            e.printStackTrace();
        }

         /*       {"ac_id_col":4075204,"latitude":"26.8461738","google_address":"10/29, Nazirabad, Ghasyari Mandi, Aminabad, Lucknow, Uttar Pradesh 226001, India","message":"1 Location Update",
                        "status":true,"longitude":"80.9293813"}*/
    }

    private void setDistributorListingAdapter(JSONArray jsonArray, String type) {
        try {
            if (isSearched && party_list != null && party_list.size() > 0) {
                isSearched = false;
                party_list.clear();
            }
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                TotalItemCount = Integer.parseInt(jsonObject.has("RCount") ? (jsonObject.getString("RCount") != null ? jsonObject.getString("RCount") : "") : "");
                party_list.add(parsePartyJsonData(jsonObject));
            }
            if (party_list.size() == 0) {
                noRecordTV.setVisibility(View.VISIBLE);
                pullToRefresh.setVisibility(View.GONE);

            } else {
                noRecordTV.setVisibility(View.GONE);
                pullToRefresh.setVisibility(View.VISIBLE);
            }
//            tvCount.setText(selectedSortVendors.getName() + " (" + party_list.size() + ")");
            tvCount.setText("All" + "(" + party_list.size() + ")");
            partyAdapter = new PartyAdapter(PartyListingFragment.this, party_list, type, Title);
            rv_party_listing.setAdapter(partyAdapter);

            // for implementing the touch
//            rv_party_listing.setOnTouchListener(new View.OnTouchListener() {
//                @Override
//                public boolean onTouch(View v, MotionEvent event) {
//                    hideKeyboard(getActivity());
//                    return true;
//                }
//            });

        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public void fetchLocation(LoginModel model, int position) {
        updateLocation = true;
        showLoading();
        selectedPartyModelData = model;
        selectedPartyModelPosition = position;
        if (ActivityCompat.checkSelfPermission(requireActivity(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(requireActivity(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            setupLocation();
        } else {
            requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, CODE_PERMISSION_REQUEST);
        }
    }

    LocationListener locationListener = new LocationListener() {
        @Override
        public void onLocationChanged(@NonNull Location location) {
            try {
                if (location.getLatitude() != 0.0 && location.getLongitude() != 0.0) {
                    dismissLoading();
                    latitude = String.valueOf(location.getLatitude());
                    longitude = String.valueOf(location.getLongitude());
                    if (updatePartyWithLatLang) {
                        updatePartyWithLatLang = false;
                        clearPartyListData();
                    }
//                    Toast.makeText(requireActivity(), "Location Changed=====", Toast.LENGTH_SHORT).show();
                    if (selectedPartyModelPosition > -1 && updateLocation) {
                        updateLocation = false;
                        getCurrentGoogleAddress(location.getLatitude(), location.getLongitude());
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        @Override
        public void onStatusChanged(String s, int i, Bundle bundle) {
        }

        @Override
        public void onProviderEnabled(String s) {
        }

        @Override
        public void onProviderDisabled(String s) {
        }
    };

    private void setupLocation() {
        if (ActivityCompat.checkSelfPermission(requireActivity(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(requireActivity(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, MIN_TIME, MIN_DISTANCE, locationListener);
            locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, MIN_TIME, MIN_DISTANCE, locationListener);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == CODE_PERMISSION_REQUEST) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.checkSelfPermission(requireActivity(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(requireActivity(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    setupLocation();
                }
            } else {
                new Handler().postDelayed(() -> getPartyList("", PAGE_NUM, true), 1000);
                ReckonUtils.openGPSEnableDialog(requireActivity());
            }
        }

    }

    public void getCurrentGoogleAddress(double lat, double lng) {
        Geocoder geocoder = new Geocoder(requireActivity(), Locale.getDefault());
        try {
            if (geocoder.getFromLocation(lat, lng, 1) != null) {
                List<Address> addresses = geocoder.getFromLocation(lat, lng, 1);
                if (addresses != null && !addresses.isEmpty()) {
                    Address obj = addresses.get(0);
                    String address = ReckonUtils.nonNullNotEmptyString(obj.getAddressLine(0)) ? obj.getAddressLine(0) : "";
                    dismissLoading();
                    sendCurrentAddress(address, lat, lng);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void sendCurrentAddress(String add, double lat, double lang) {
        try {

            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lUserId", SharedPrefUtils.getString(getActivity(), Constant.USER_ID));
            jsonObject.put("ac_id_col", selectedPartyModelData.getAcIdCol());
            jsonObject.put("latitude", String.valueOf(lat));
            jsonObject.put("longitude", String.valueOf(lang));
            jsonObject.put("google_address", add);
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().updateLocation(String.valueOf(jsonObject)), Constant.UPDATE_LOCATION, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void createPopupSortVendors() {
        if (popupSortVendors == null) {
            dataSortDistributors = DataHardCode.getListSortDistributors();
            popupSortVendors = new SelectSinglePopup(getActivity(), dataSortDistributors, false);
            popupSortVendors.setOnItemListener(position -> {
                if (position < dataSortDistributors.size()) {
                    selectedSortVendors = dataSortDistributors.get(position);
                    tvCount.setText(position != 0 ? selectedSortVendors.getName() : "All (" + party_list.size() + ")");//data.size()
                    sortBy = dataSortDistributors.get(position).getId();
                    if (Title.equalsIgnoreCase(Constant.CREATE_RECEIPT) || Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.OUTSTANDING)) {
                        getPartyList(search_loc_et.getText().toString(), PAGE_NUM, true);
                    } /*else
                        getPartyList(search_loc_et.getText().toString().split(" ")[0], PAGE_NUM, "", "", "", "");*/
                }
            });
            popupSortVendors.setOnDismissListener(() -> imgSortVendors.setImageResource(R.drawable.checked));
        }
    }

    @OnClick(R.id.fragmentMyVendor_frmSortVendor)
    public void onViewClicked(View view) {
        imgSortVendors.setImageResource(R.drawable.checked);
        createPopupSortVendors();
        popupSortVendors.showAsDropDown(view, 0, 1);
    }

    public void getPartyData(String code, String name, String stock, String address, String data) {
        debouncer.debounce(Void.class, new Runnable() {
            @Override public void run() {
                KeyboardUtils.hideSoftKeyboard(getActivity());
            }
        }, 500, TimeUnit.MILLISECONDS);
        Bundle bundle = new Bundle();
        bundle.putString("name", name);
        bundle.putString("Code", code);
        bundle.putString("Stock", stock);
        bundle.putString("BrandItemId", brandNameSearchId);
        bundle.putString("isNewArrival", isNewArrival);
        bundle.putString("withScheme", withScheme);
        bundle.putString(Constant.PARTY_LIST, data);
        if ((!source.equalsIgnoreCase(Constant.CREATE_RECEIPT) && !source.equalsIgnoreCase(Constant.OUTSTANDING) && !source.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT))
                && (Title.equalsIgnoreCase(Constant.NEW_ORDER) || Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS) || Title.equalsIgnoreCase(Constant.NEW_ARRIVAL) || Title.equalsIgnoreCase(Constant.BRAND) || Title.equalsIgnoreCase(Constant.BRAND_LIST)
                || Title.equalsIgnoreCase(Constant.ACCOUNT_FILTER) || Title.equalsIgnoreCase(Constant.PRODUCT_FILTER))) {
            bundle.putString("from", Constant.PARTY);
            if (!FirmCode.isEmpty()) {
                bundle.putString(Constant.FIRM_NAME, FirmName);
                bundle.putString(Constant.FIRM_CODE, FirmCode);
            }
            if (Title.equalsIgnoreCase(Constant.RECENT_ORDERED_PRODUCTS)) {
                NavHostFragment.findNavController(this).navigate(R.id.action_back_to_recent_ordered, bundle);
            } else {
                NavHostFragment.findNavController(this).navigate(R.id.action_back_to_order_entry, bundle);
            }
        } else if (Title.equalsIgnoreCase(Constant.FIRM)) {
            bundle.putString("from", Constant.NEW_ORDER);
            NavHostFragment.findNavController(this).navigate(R.id.navPartyLisingFragment, bundle);
        } else if (source.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT) || Title.equalsIgnoreCase(Constant.ACCOUNT_STATEMENT)) {
            bundle.putString("from", Constant.PARTY);
            bundle.putString("address", address);
            bundle.putString("selected_station_id", selectedStationId);
            bundle.putString("selected_station_name", selectedStationName);
            bundle.putString("selected_area_id", selectedAreaId);
            bundle.putString("selected_area_name", selectedAreaName);
            if (!FirmCode.isEmpty()) {
                bundle.putString(Constant.FIRM_NAME, FirmName);
                bundle.putString(Constant.FIRM_CODE, FirmCode);
            }
            NavHostFragment.findNavController(this).navigate(R.id.nav_account_statement, bundle);
        } else if (source.equalsIgnoreCase(Constant.OUTSTANDING) || Title.equalsIgnoreCase(Constant.OUTSTANDING)) {
            bundle.putString("from", Constant.PARTY);
            bundle.putString("address", address);
            NavHostFragment.findNavController(this).navigate(R.id.nav_outlet_details, bundle);
        } else if (source.equalsIgnoreCase(Constant.CREATE_RECEIPT) || Title.equalsIgnoreCase(Constant.CREATE_RECEIPT)) {
            bundle.putString("from", Constant.PARTY);
            bundle.putString("address", address);
            bundle.putString(Constant.FIRM_NAME, FirmName);
            bundle.putString(Constant.FIRM_CODE, FirmCode);
            NavHostFragment.findNavController(this).navigate(R.id.action_back_to_receipt_entry, bundle);
        }
    }

    private void goToFilterScreen(View view) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, Constant.PARTY_LIST);
        bundle.putString(Constant.APPLIED_FILTERS, selectedFilters);
        bundle.putString(Constant.FILTER_TYPE, "Account");
        bundle.putString("source", Title);
        Navigation.findNavController(view).navigate(R.id.action_go_to_product_filter, bundle);
    }
}

