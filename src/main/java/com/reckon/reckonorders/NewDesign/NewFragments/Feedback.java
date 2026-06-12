package com.reckon.reckonorders.NewDesign.NewFragments;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NewDesign.NewAdapters.NewArrivalAdapter;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.databinding.FragmentFeedbackBinding;

import java.util.ArrayList;

public class Feedback extends BaseFragment {
    FragmentFeedbackBinding binding;
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    NewArrivalAdapter arrivalAdapter;
    ArrayList<String> options;
    LinearLayoutManager layoutManager;

    public static Feedback newInstance(String param1, String param2) {
        Feedback fragment = new Feedback();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        binding = FragmentFeedbackBinding.inflate(getLayoutInflater());
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        binding.tvRateYourexperience.setText(getResources().getString(R.string.rate_your_experience).toUpperCase());
        options=new ArrayList<>();
        options.add(getResources().getString(R.string.delivery_time));
        options.add(getResources().getString(R.string.professionalism));
        options.add(getResources().getString(R.string.others));
        options.add(getResources().getString(R.string.product_quality));
        arrivalAdapter = new NewArrivalAdapter(Feedback.this, options);
        GridLayoutManager gridLayoutManager = new GridLayoutManager(getActivity(), 2);
        binding.feedbackListRecycler.setLayoutManager(gridLayoutManager);
        binding.feedbackListRecycler.setAdapter(arrivalAdapter);

    }
}