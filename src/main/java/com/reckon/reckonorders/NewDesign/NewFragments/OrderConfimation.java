package com.reckon.reckonorders.NewDesign.NewFragments;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.bluetooth.BluetoothSocket;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.res.ResourcesCompat;
import androidx.fragment.app.Fragment;
import androidx.navigation.fragment.NavHostFragment;
import androidx.viewpager.widget.ViewPager;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Adapter.SubmitedOrderViewPagerAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.OrderDetailsModel;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.FeedbackDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.BTDeviceList;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.FragmentOrderConfimationBinding;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.OutputStream;
import java.util.ArrayList;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link OrderConfimation#newInstance} factory method to
 * create an instance of this fragment.
 */
public class OrderConfimation extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;

    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    FeedbackDialog feedbackDialog;
    FragmentOrderConfimationBinding binding;
    // TODO: Rename and change types of parameters
    private String mParam1;
    private String mParam2;
    private StoreDetailObjectModel selectedPartyDataModel;
    private boolean isSalesMan;
    private int dotsCount;
    private ImageView[] dots;
    private SubmitedOrderViewPagerAdapter bannerPagerAdapter;

    byte FONT_TYPE;
    private static BluetoothSocket btsocket;
    private static OutputStream btoutputstream;
    private  OrderDetailsModel orderDetailsModel;
    public static OrderConfimation newInstance(String param1, String param2) {
        OrderConfimation fragment = new OrderConfimation();
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
        // Inflate the layout for this fragment
        binding = FragmentOrderConfimationBinding.inflate(getLayoutInflater());
        retrofitCallBackListener = this;
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setUpUiTheme();
        binding.addMoreItemCard.setBackgroundColor(getButtonColor());
        feedbackDialog = new FeedbackDialog(getActivity());
        Constant.bundle = new Bundle();
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
  /*      if (!isSalesMan)
            feedbackDialog.show();*/
        Gson gson = new Gson();
        if (getArguments() != null) {
            Bundle bundle = getArguments();
            selectedPartyDataModel = gson.fromJson(getArguments().getString(Constant.PARTY), new TypeToken<StoreDetailObjectModel>() {
            }.getType());
            ArrayList<OrderDetailsModel> arrayList = gson.fromJson(bundle.getString("orderModel"), new TypeToken<ArrayList<OrderDetailsModel>>() {
            }.getType());
            if (arrayList != null && !arrayList.isEmpty()) {
                OrderDetailsModel model = arrayList.get(0);
                if (model.getOrderId() == null && model.getOrderId().isEmpty()) {
                    binding.orderIdRl.setVisibility(View.GONE);
                }
                if (model.getPlacedOn() == null && model.getPlacedOn().isEmpty()) {
                    binding.placedOnRl.setVisibility(View.GONE);
                }

                if (model.getOrderValue() == null && model.getOrderValue().isEmpty()) {
                    binding.orderValueRl.setVisibility(View.GONE);
                }
                if (model.getPaymentMode() == null && model.getPaymentMode().isEmpty()) {
                    binding.paymentModeRl.setVisibility(View.GONE);
                }
                if (model.getDeliveryDate() == null && model.getDeliveryDate().isEmpty()) {
                    binding.deliveryDateLayoutRl.setVisibility(View.GONE);
                }
                if (model.getDeliveryMode() == null && model.getDeliveryMode().isEmpty()) {
                    binding.deliveryModeLayoutRl.setVisibility(View.GONE);
                }

                if (model.getOrderStatus() == null && model.getOrderStatus().isEmpty()) {
                    binding.orderIdRl.setVisibility(View.GONE);
                }
                binding.orderId.setText("#"+model.getOrderId());
                binding.orderPlacingDate.setText(model.getPlacedOn());
                binding.orderValue.setText(getLicDetails().getCurrency() + model.getOrderValue());
                binding.paymentMode.setText(model.getPaymentMode());
                binding.deliveryDate.setText(model.getDeliveryDate());
                binding.deliveryMode.setText(model.getDeliveryMode());
                binding.orderStatus.setText(model.getOrderStatus());
                if (isSalesMan) {
                    binding.tvCustomerName.setText(selectedPartyDataModel.getName());
                    binding.tvContactNumber.setText(selectedPartyDataModel.getMobile());
                    binding.tvDeliveryAddress.setText(selectedPartyDataModel.getAdd1() + selectedPartyDataModel.getAdd2() + selectedPartyDataModel.getAdd3() + selectedPartyDataModel.getPinCode());
                } else {
                    binding.tvCustomerName.setText(bundle.getString("nameAddress"));
                    binding.tvContactNumber.setText(bundle.getString("mobileNumber"));
                    binding.tvDeliveryAddress.setText(model.getDeliveryAddress());
                }
                if (bundle.getString("nameAddress").isEmpty())
                    binding.tvCustomerName.setVisibility(View.GONE);
                else
                    binding.tvCustomerName.setVisibility(View.VISIBLE);
                if (bundle.getString("mobileNumber").isEmpty())
                    binding.tvContactNumber.setVisibility(View.GONE);
                else
                    binding.tvContactNumber.setVisibility(View.VISIBLE);
            }
            if (isSalesMan){
                binding.bannerLl.setVisibility(View.VISIBLE);
                binding.orderDetailsCard.setVisibility(View.GONE);
            }else{
                binding.orderDetailsCard.setVisibility(View.VISIBLE);
                binding.bannerLl.setVisibility(View.GONE);
            }
            prepareBannerData(arrayList);
        }

        binding.goToHome.setOnClickListener(v -> NavHostFragment.findNavController(OrderConfimation.this).navigate(R.id.nav_home));
        OnBackPressedCallback callback = new OnBackPressedCallback(true /* enabled by default */) {
            @Override
            public void handleOnBackPressed() {
                NavHostFragment.findNavController(OrderConfimation.this).navigate(R.id.nav_to_home);
            }
        };
        ((NewMainActivity) requireActivity()).setUpTitle(OrderConfimation.this, getString(R.string.order_confirmation));
        requireActivity().getOnBackPressedDispatcher().addCallback(getViewLifecycleOwner(), callback);
//        binding.nestedScrollView.setFillViewport(true);
       /* binding.pagerOrderConfirmed.startAutoScroll();
        binding.pagerOrderConfirmed.setInterval(5000);
        binding.pagerOrderConfirmed.setCycle(true);*/

//        binding.pagerOrderConfirmed.setNestedScrollingEnabled(false);
/*        Animation animation = AnimationUtils.loadAnimation(getActivity(), android.R.anim.fade_out);
        animation.setDuration(500);*/
        binding.pagerOrderConfirmed.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
            }

            @Override
            public void onPageSelected(int position) {
                if (getContext() != null) {
                    for (int i = 0; i < dotsCount; i++) {
                        if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                            dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_peach_dot, null));
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
            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });


    }

    public void shareOrderReceipt(OrderDetailsModel model) {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lId", model.getOrderId());
            jsonObject.put("lSharePdf", String.valueOf(true));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().GetOrderDetails(String.valueOf(jsonObject)), Constant.ORDER_DETAILS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void prepareBannerData(ArrayList<OrderDetailsModel> arrayList) {
        if (!arrayList.isEmpty()) {
            bannerPagerAdapter = new SubmitedOrderViewPagerAdapter(requireActivity(), arrayList, OrderConfimation.this);
            binding.pagerOrderConfirmed.setAdapter(bannerPagerAdapter);
            binding.pagerOrderConfirmed.setStopScrollWhenTouch(true);
            binding.pagerOrderConfirmed.setDrawingCacheEnabled(false);
            binding.nestedScrollView.setNestedScrollingEnabled(false);
            dotsCount = bannerPagerAdapter.getCount();
            dots = new ImageView[dotsCount];
            binding.viewPagerCountDots.removeAllViews();
            for (int i = 0; i < dotsCount; i++) {
                dots[i] = new ImageView(getActivity());
                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_peach_dot, null));
                } else {
                    dots[i].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.nonselecteditem_dot, null));
                }
                LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
                params.setMargins(4, 0, 4, 0);
                binding.viewPagerCountDots.addView(dots[i], params);
            }
            if (dots.length > 0) {
                if (requireActivity().getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
                    dots[0].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem__red_dot, null));
                } else {
                    dots[0].setImageDrawable(ResourcesCompat.getDrawable(getResources(), R.drawable.selecteditem_dot, null));
                }
            }
            bannerPagerAdapter.notifyDataSetChanged();
        }
    }


    private void setUpUiTheme() {
        binding.tvThankYou.setTextColor(getSecondHeaderTextColor());
        binding.tvOrderPlaced.setTextColor(getSecondHeaderTextColor());
        binding.orderValue.setTextColor(getSecondHeaderTextColor());
        binding.addMoreItemCard.setCardBackgroundColor(getThirdHeaderColor());
    }


    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 1) {
            try {
                JSONObject jsonObject = new JSONObject(result);
                boolean sharePDF = jsonObject.has("share_pdf") && jsonObject.getBoolean("share_pdf");
                if (sharePDF && jsonObject.has("data")) {
                    JSONObject obj = jsonObject.getJSONObject("data");
                    String pdfLink = ReckonUtils.getJsonCheckedString(obj, "link", "");
                    String docName = ReckonUtils.getJsonCheckedString(obj, "doc_name", "order_receipt");
                    if (ReckonUtils.isPDFValid(pdfLink)) {
                        ReckonUtils.downloadAndSharePdf(pdfLink, requireActivity(), false, docName);
                    } else {
                        Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                    }
                } else {
                    Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public void printOrderDetails(OrderDetailsModel model){
        orderDetailsModel  = model;
//        connect(model);
        Toast.makeText(requireActivity(), requireActivity().getString(R.string.workOnProgress), Toast.LENGTH_SHORT).show();

    }
    protected void connect(OrderDetailsModel model) {
        if (btsocket == null) {
            Intent BTIntent = new Intent(requireActivity(), BTDeviceList.class);
            this.startActivityForResult(BTIntent, BTDeviceList.REQUEST_CONNECT_BT);
        } else {

            OutputStream opstream = null;
            try {
                opstream = btsocket.getOutputStream();
            } catch (Exception e) {
                e.printStackTrace();
            }
            btoutputstream = opstream;
            print(model.getOrderId());

        }

    }
    public void print(String model) {
        try {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            btoutputstream = btsocket.getOutputStream();
            byte[] printformat = {0x1B, 0x21, FONT_TYPE};
            btoutputstream.write(printformat);
            String msg = model;
            btoutputstream.write(msg.getBytes());
            btoutputstream.write(0x0D);
            btoutputstream.write(0x0D);
            btoutputstream.write(0x0D);
            btoutputstream.flush();
        } catch (Exception e) {
            e.printStackTrace();
        }

    }
    @Override
    public void onDestroy() {
        super.onDestroy();
        try {
            if (btsocket != null) {
                btoutputstream.close();
                btsocket.close();
                btsocket = null;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        try {
            btsocket = BTDeviceList.getSocket();
            if (btsocket != null) {
                print(orderDetailsModel.getOrderId());
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}