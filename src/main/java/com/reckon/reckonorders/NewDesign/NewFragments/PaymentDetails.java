package com.reckon.reckonorders.NewDesign.NewFragments;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.navigation.fragment.NavHostFragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.reckon.reckonorders.NewDesign.NewAdapters.NewArrivalAdapter;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.databinding.FragmentPaymentDetailsBinding;

import java.util.ArrayList;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link PaymentDetails#newInstance} factory method to
 * create an instance of this fragment.
 */
public class PaymentDetails extends Fragment {

    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";

    // TODO: Rename and change types of parameters
    private String mParam1;
    private String mParam2;
    FragmentPaymentDetailsBinding binding;
    ArrayList<String> paymentOptions;
    NewArrivalAdapter adapter;


    public static PaymentDetails newInstance(String param1, String param2) {
        PaymentDetails fragment = new PaymentDetails();
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
        binding = FragmentPaymentDetailsBinding.inflate(getLayoutInflater());
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        paymentOptions=new ArrayList<>();
        paymentOptions.add(getResources().getString(R.string.cash_or_card_payment_options));
        paymentOptions.add(getResources().getString(R.string.debit_credit_card_options));
        paymentOptions.add(getResources().getString(R.string.net_banking));
        paymentOptions.add(getResources().getString(R.string.e_wallet));
        adapter=new NewArrivalAdapter(PaymentDetails.this,paymentOptions);
        binding.paymentOptionsRecycler.setAdapter(adapter);
        binding.placeYourOrderLl.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                NavHostFragment.findNavController(PaymentDetails.this).navigate(R.id.nav_order_confirmation);
            }
        });

    }
}