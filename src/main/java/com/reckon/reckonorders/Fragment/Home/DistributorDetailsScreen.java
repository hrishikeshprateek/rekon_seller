package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.cardview.widget.CardView;
import androidx.core.content.res.ResourcesCompat;
import androidx.core.widget.NestedScrollView;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager.widget.ViewPager;

import com.reckon.reckonorders.Adapter.BannerPagerAdapter;
import com.reckon.reckonorders.Adapter.DealsInAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BannerListItem;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.view.AutoScrollViewPager;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class DistributorDetailsScreen extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private static final String ID = "id";
    private static final String NAME = "name";

    @BindView(R.id.viewPagerCountDots)
    LinearLayout viewPagerCountDots;

    @BindView(R.id.imageSlides)
    AutoScrollViewPager imageSlides;

    @BindView(R.id.imageSlidesFl)
    FrameLayout imageSlidesFl;


    @BindView(R.id.gradientLL)
    LinearLayout gradientLL;

    @BindView(R.id.tvTitle)
    TextView tvTitle;

    @BindView(R.id.address1Tv)
    TextView address1Tv;

    @BindView(R.id.address2Tv)
    TextView address2Tv;

    @BindView(R.id.address3Tv)
    TextView address3Tv;

    @BindView(R.id.distributorNameTv)
    TextView distributorNameTv;

    @BindView(R.id.distributorNameLL)
    LinearLayout distributorNameLL;

    @BindView(R.id.phoneTv)
    TextView phoneTv;

    @BindView(R.id.phone_row_ll)
    LinearLayout phone_row_ll;

    @BindView(R.id.emailLl)
    LinearLayout emailLl;
    @BindView(R.id.emailTv)
    TextView emailTv;

    @BindView(R.id.gstLl)
    LinearLayout gstLl;
    @BindView(R.id.gstNoTv)
    TextView gstNoTv;

    @BindView(R.id.DLLl)
    LinearLayout DLLl;
    @BindView(R.id.drugLTv)
    TextView drugLTv;
    @BindView(R.id.drugL2Tv)
    TextView drugL2Tv;

    @BindView(R.id.foodLLl)
    LinearLayout foodLLl;
    @BindView(R.id.foodTv)
    TextView foodTv;

    @BindView(R.id.businessTypeLl)
    LinearLayout businessTypeLl;
    @BindView(R.id.businessTv)
    TextView businessTv;

    @BindView(R.id.dealsInLl)
    LinearLayout dealsInLl;

    @BindView(R.id.cartRecycler)
    RecyclerView cartRecycler;

    @BindView(R.id.scrollView)
    NestedScrollView scrollView;

    @BindView(R.id.detailsCv)
    CardView detailsCv;

    private String _Id = "";
    private boolean isSalesMan;
    private String appMobile = "";

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_distributor_details, container, false);
        ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        ((NewMainActivity) getActivity()).setUpTitle(DistributorDetailsScreen.this, getString(R.string.distributor_details));
        getBundle();
        setupUI();
        setTitle(view, getString(R.string.distributor_details).toUpperCase());
        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        cartRecycler.setLayoutManager(new LinearLayoutManager(getContext(), LinearLayoutManager.VERTICAL, false));
        cartRecycler.setNestedScrollingEnabled(false);

        getDistributorDetail();

    }


    @OnClick({R.id.callCV})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.callCV:
                ReckonUtils.performCall(requireActivity(), appMobile);
                break;
        }
    }

    private void displayImageSlides(ArrayList<BannerListItem> bannerList) {
        if (bannerList != null && bannerList.size() > 0) {
            imageSlidesFl.setVisibility(View.VISIBLE);
            gradientLL.setVisibility(View.VISIBLE);
            BannerPagerAdapter bannerPagerAdapter = new BannerPagerAdapter(DistributorDetailsScreen.this, bannerList, getActivity(), imageSlides);
            imageSlides.setAdapter(bannerPagerAdapter);
            int dotsCount = bannerPagerAdapter.getCount();
            ImageView[] dots = new ImageView[dotsCount];
            viewPagerCountDots.removeAllViews();//
            for (int i = 0; i < dotsCount; i++) {
                dots[i] = new ImageView(getActivity());
                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem_black_dot, null));
                } else {
                    dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_dot, null));
                }
                LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
                params.setMargins(4, 0, 4, 0);
                viewPagerCountDots.addView(dots[i], params);
            }
            if (dots.length > 0) {
                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    dots[0].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem__red_dot, null));
                } else {
                    dots[0].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem_dot, null));
                }
            }
            imageSlides.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
                @Override
                public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
                }

                @Override
                public void onPageSelected(int position) {
                    for (int i = 0; i < dotsCount; i++) {
                        if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                            dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem_black_dot, null));
                        } else {
                            dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_dot, null));
                        }
                    }
                    if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                        dots[position].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem__red_dot, null));
                    } else {
                        dots[position].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem_dot, null));
                    }

                }

                @Override
                public void onPageScrollStateChanged(int state) {

                }
            });
            bannerPagerAdapter.notifyDataSetChanged();
        } else {
            gradientLL.setVisibility(View.GONE);
            imageSlidesFl.setVisibility(View.GONE);
        }

    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            _Id = bundle.containsKey(Constant.ID) ? bundle.getString(Constant.ID) : "";
        }
    }

    private void getDistributorDetail() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lId", _Id);
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().GetDistributorDetail(String.valueOf(jsonObject)), Constant.DISTRIBUTOR_DETAILS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null) {
            JSONObject jsonObject = new JSONObject(result);
            setDistributorDetailsData(jsonObject, action);
        }
    }

    private void setDistributorDetailsData(JSONObject jsonObject, String action) {
        try {

            String emailId = ReckonUtils.getJsonCheckedString(jsonObject, "Email", "");
            String gstNumber = ReckonUtils.getJsonCheckedString(jsonObject, "GstNumber", "");
            String licNo = ReckonUtils.getJsonCheckedString(jsonObject, "LicNo", "");
            String mobile = ReckonUtils.getJsonCheckedString(jsonObject, "Mobile", "");
            String name = ReckonUtils.getJsonCheckedString(jsonObject, "Name", "");
            String pinCode = ReckonUtils.getJsonCheckedString(jsonObject, "PinCode", "");
            String foolLicence = ReckonUtils.getJsonCheckedString(jsonObject, "FL", "");
            String address1 = ReckonUtils.getJsonCheckedString(jsonObject, "Address1", "");
            String address2 = ReckonUtils.getJsonCheckedString(jsonObject, "Address2", "");
            String address3 = ReckonUtils.getJsonCheckedString(jsonObject, "Address3", "");
            appMobile = ReckonUtils.getJsonCheckedString(jsonObject, "AppMobile", "");
            String businessType = ReckonUtils.getJsonCheckedString(jsonObject, "BussinessType", "");
            String code = ReckonUtils.getJsonCheckedString(jsonObject, "Code", "");
            String CPerson = ReckonUtils.getJsonCheckedString(jsonObject, "CPerson", "");
            String DL1 = ReckonUtils.getJsonCheckedString(jsonObject, "DL1", "");
            String DL2 = ReckonUtils.getJsonCheckedString(jsonObject, "DL2", "");

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
                displayImageSlides(bannerList);

            }
            detailsCv.setVisibility(View.VISIBLE);
            tvTitle.setText(name);
            address1Tv.setText(address1);
            address2Tv.setText(address2);
            address3Tv.setText(!address3.isEmpty() ? (address3 + ", " + pinCode) : pinCode);

            distributorNameTv.setText(name);
            distributorNameLL.setVisibility(appMobile.isEmpty() ? View.GONE : View.VISIBLE);

            phoneTv.setText(appMobile);
            phone_row_ll.setVisibility(appMobile.isEmpty() ? View.GONE : View.VISIBLE);

            emailTv.setText(emailId);
            emailLl.setVisibility(emailId.isEmpty() ? View.GONE : View.VISIBLE);

            gstNoTv.setText(gstNumber);
            gstLl.setVisibility(gstNumber.isEmpty() ? View.GONE : View.VISIBLE);

            drugLTv.setText(DL1);
            drugL2Tv.setText(DL2);
            DLLl.setVisibility(DL1.isEmpty() && DL2.isEmpty() ? View.GONE : View.VISIBLE);

            foodTv.setText(foolLicence);
            foodLLl.setVisibility(foolLicence.isEmpty() ? View.GONE : View.VISIBLE);

            businessTv.setText(businessType);
            businessTypeLl.setVisibility(businessType.isEmpty() ? View.GONE : View.VISIBLE);


            if (jsonObject.has("CompanyDetail")) {
                JSONObject jsonObj = jsonObject.getJSONObject("CompanyDetail");
                JSONArray items = jsonObj.getJSONArray("items");
                ArrayList<BannerListItem> imageList = new ArrayList<>();
                for (int k = 0; k < items.length(); k++) {
                    try {
                        JSONObject obj = items.getJSONObject(k);
                        BannerListItem model = new BannerListItem();
                        String image = ReckonUtils.getJsonCheckedString(obj, "image", "");
                        model.setImageUrl(image.contains("https") || image.contains("http") ? image : getUserImageBaseUrl() + image);
                        model.setType(ReckonUtils.getJsonCheckedString(obj, "type", ""));
                        model.setTitle(ReckonUtils.getJsonCheckedString(obj, "title", ""));
                        model.setDealsInId(ReckonUtils.getJsonCheckedString(obj, "id", ""));
                        if (imageList.size() < 11 && !model.getTitle().isEmpty() && !model.getTitle().equalsIgnoreCase(".") && !model.getTitle().equalsIgnoreCase("..") && !model.getTitle().equalsIgnoreCase("...")) {
                            imageList.add(model);
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                if (imageList.size() > 0) {
                    cartRecycler.setAdapter(new DealsInAdapter(imageList, DistributorDetailsScreen.this));
                }
                dealsInLl.setVisibility(imageList.size() == 0 ? View.GONE : View.VISIBLE);
            } else {
                dealsInLl.setVisibility(View.GONE);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
