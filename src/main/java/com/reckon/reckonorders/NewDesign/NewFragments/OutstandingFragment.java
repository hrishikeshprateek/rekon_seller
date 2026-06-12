package com.reckon.reckonorders.NewDesign.NewFragments;

import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.ListPopupWindow;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NewDesign.NewAdapters.AreaOutletAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.OutletModel;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.databinding.FragmentOutstandingBinding;

import java.util.ArrayList;
import java.util.regex.Pattern;

public class OutstandingFragment extends BaseFragment {
    FragmentOutstandingBinding binding;
    ArrayList<OutletModel> outletDetails;
    ArrayList<String> outletNames = new ArrayList<>();
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    private String mParam1;
    private String mParam2;
    int i = 0;
    private ListPopupWindow listPopupWindow;

    public static OutstandingFragment newInstance(String param1, String param2) {
        OutstandingFragment fragment = new OutstandingFragment();
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

    public void setSearchText(String text) {
        binding.searchBox.setText(text);
        binding.listOfData.setVisibility(View.GONE);
        i = 1;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentOutstandingBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        binding.accountNameList.setCardBackgroundColor(getSecondHeaderTextColor());
        binding.tvHeadingOutStanding.setTextColor(getSecondHeaderTextColor());
        binding.searchButton.setColorFilter(getSecondHeaderTextColor());
        if (getLicDetails().getRole().equalsIgnoreCase("SalesMan")) {
            binding.tvDate.setVisibility(View.GONE);
            binding.searchBox.setHint(getString(R.string.account_name_list));
            binding.tvHeadingOutStanding.setVisibility(View.GONE);
            binding.tvHeadingTotalAmount.setVisibility(View.GONE);
            binding.tvAllGroup.setVisibility(View.GONE);
            binding.customerTypeCard.setVisibility(View.GONE);
        }
        ((NewMainActivity) getActivity()).setUpTitle(OutstandingFragment.this, getString(R.string.outstanding));
        outletDetails = new ArrayList<>();
        binding.searchBox.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (outletNames.size() > 0) {
                    outletNames.clear();
                }
                for (int i = 0; i < outletDetails.size(); i++) {
                    if (Pattern.compile(Pattern.quote(binding.searchBox.getText().toString()), Pattern.CASE_INSENSITIVE).matcher(outletDetails.get(i).getOutletName()).find()) {
                        outletNames.add(outletDetails.get(i).getOutletName());
                    }
                }
                binding.listOfData.setAdapter(new AreaOutletAdapter(OutstandingFragment.this, outletDetails, getString(R.string.search), outletNames));
                if (binding.searchBox.getText().toString().isEmpty()) {
                    i = 0;
                    binding.listOfData.setVisibility(View.GONE);
                } else if (i == 0)
                    binding.listOfData.setVisibility(View.VISIBLE);

            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
        binding.outletRecycler.setLayoutManager(new LinearLayoutManager(requireActivity()));
        binding.outletRecycler.setAdapter(new AreaOutletAdapter(OutstandingFragment.this, outletDetails, getString(R.string.outlet_listing), new ArrayList<String>()));
        postDataPrepare();


    }

//    private void setUpListPopUpWindow() {
//        try {
//            for (int i = 0; i < outletDetails.size(); i++) {
//                if (Pattern.compile(Pattern.quote(binding.searchBox.getText().toString()), Pattern.CASE_INSENSITIVE).matcher(outletDetails.get(i).getOutletName()).find()) {
//                    outletNames.add(outletDetails.get(i).getOutletName());
//                }
//            }
//            listPopupWindow = new ListPopupWindow(getActivity());
//            listPopupWindow.setAdapter(new ArrayAdapter(getActivity(), android.R.layout.simple_spinner_dropdown_item, outletNames));
//            listPopupWindow.setAnchorView(binding.searchBox);
//            listPopupWindow.setWidth(ListPopupWindow.WRAP_CONTENT);
//            listPopupWindow.setHeight(ListPopupWindow.WRAP_CONTENT);
//            listPopupWindow.setModal(true);
//            listPopupWindow.setOnItemClickListener((adapterView, view, i, l) -> {
//                listPopupWindow.dismiss();
//                new Handler().postDelayed(new Runnable() {
//                    @Override
//                    public void run() {
//
//                    }
//                }, 50);
//            });
//            listPopupWindow.show();
//        } catch (Exception e) {
//            e.printStackTrace();
//        }
//    }

    private void postDataPrepare() {
        OutletModel outletModel = new OutletModel();
        outletModel.setCustomerType("Sundry Debtor");
        outletModel.setLastPaymentDate("27-08-2021");
        outletModel.setOutletAddress("NIT-1-2-5 FARIDABAD");
        outletModel.setOutletName("BHAVISHYA MEDICAL STORE PVT LTD");
        outletModel.setOutstanding(11000.00);
        outletDetails.add(outletModel);
        outletModel = new OutletModel();
        outletModel.setCustomerType("Sundry Debtor");
        outletModel.setLastPaymentDate("25-05-2021");
        outletModel.setOutletAddress("Sec 29 Faridabad");
        outletModel.setOutletName("DR. RAJAN KALRA");
        outletModel.setOutstanding(11000.00);
        outletDetails.add(outletModel);
        outletModel = new OutletModel();
        outletModel.setCustomerType("Sundry Debtor");
        outletModel.setLastPaymentDate("07-09-2021");
        outletModel.setOutletAddress("Sec 29 Faridabad");
        outletModel.setOutletName("MATESHWARI MEDICAL STORE");
        outletModel.setOutstanding(11000.00);
        outletDetails.add(outletModel);
        outletModel = new OutletModel();
        outletModel.setCustomerType("Sundry Debtor");
        outletModel.setLastPaymentDate("17-09-2021");
        outletModel.setOutletAddress("SEC 15 , FARIDABAD");
        outletModel.setOutletName("INDIRA MEDICAL STORE");
        outletModel.setOutstanding(11000.00);
        outletDetails.add(outletModel);
    }
}