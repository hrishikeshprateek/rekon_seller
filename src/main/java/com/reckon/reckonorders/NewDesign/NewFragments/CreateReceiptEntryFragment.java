package com.reckon.reckonorders.NewDesign.NewFragments;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.os.Handler;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ListPopupWindow;
import android.widget.TextView;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.NewDesign.NewAdapters.AreaOutletAdapter;
import com.reckon.reckonorders.NewDesign.NewModals.OutletModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.databinding.FragmentCreateReceiptEntryBinding;

import java.util.ArrayList;
import java.util.regex.Pattern;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link CreateReceiptEntryFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class CreateReceiptEntryFragment extends BaseFragment {

    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    FragmentCreateReceiptEntryBinding binding;
    int i = 0;
    ArrayList<String> paymentOption=new ArrayList<>();
    ArrayList<String> outletNames = new ArrayList<>();
    ArrayList<OutletModel> outletDetails;
    ListPopupWindow listPopupWindow;

    // TODO: Rename and change types of parameters
    private String mParam1;
    private String mParam2;

    public CreateReceiptEntryFragment() {
        // Required empty public constructor
    }

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param param1 Parameter 1.
     * @param param2 Parameter 2.
     * @return A new instance of fragment CreateReceiptEntryFragment.
     */
    // TODO: Rename and change types and number of parameters
    public static CreateReceiptEntryFragment newInstance(String param1, String param2) {
        CreateReceiptEntryFragment fragment = new CreateReceiptEntryFragment();
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
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        binding = FragmentCreateReceiptEntryBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setUpUi();
        paymentOption.add("IMPS");
        paymentOption.add("CASH");
        paymentOption.add("CHEQUE");
        paymentOption.add("UPI");
        paymentOption.add("NEFT");
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
                binding.listOfData.setAdapter(new AreaOutletAdapter(CreateReceiptEntryFragment.this, outletDetails, getString(R.string.search), outletNames));
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
        binding.listOfData.setLayoutManager(new LinearLayoutManager(requireActivity()));
        //   binding.listOfData.setAdapter(new AreaOutletAdapter(CreateReceiptEntryFragment.this, outletDetails, getString(R.string.outlet_listing), new ArrayList<String>()));
        postDataPrepare();
    }

    private void setUpUi() {
        allClickListeners();
        binding.saveAndShareInnerCard.setCardBackgroundColor(getButtonColor());
        binding.tagBillsCard.setCardBackgroundColor(getButtonColor());
        binding.searchBox.setHintTextColor(getSecondHeaderTextColor());
        binding.searchButton.setColorFilter(getSecondHeaderTextColor());

    }

    private void setUpListPopUpWindow() {
        try {

            listPopupWindow = new ListPopupWindow(requireActivity());
            listPopupWindow.setAdapter(new ArrayAdapter(requireActivity(), R.layout.cc_row_layout, R.id.tv_country, this.paymentOption));
            listPopupWindow.setAnchorView(binding.cardPaymentOption);
            listPopupWindow.setWidth(200);
            listPopupWindow.setHeight(androidx.appcompat.widget.ListPopupWindow.WRAP_CONTENT);
            listPopupWindow.setModal(true);
            listPopupWindow.setOnItemClickListener((adapterView, view, i, l) -> {
                listPopupWindow.dismiss();
                binding.tvPaymentOption.setText(paymentOption.get(i).toUpperCase());
            });
            //    if (!isTextEnterOn)
            listPopupWindow.show();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    private void allClickListeners() {
        binding.tvPaymentOption.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                setUpListPopUpWindow();
            }
        });
    }

    public void setSearchText(String s) {
        binding.searchBox.setText(s);
        binding.listOfData.setVisibility(View.GONE);
        i = 1;
    }

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