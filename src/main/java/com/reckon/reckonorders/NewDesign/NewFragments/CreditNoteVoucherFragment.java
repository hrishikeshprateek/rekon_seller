package com.reckon.reckonorders.NewDesign.NewFragments;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.databinding.FragmentCreditNoteVoucherBinding;

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link CreditNoteVoucherFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class CreditNoteVoucherFragment extends BaseFragment {

    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";
    FragmentCreditNoteVoucherBinding binding;

    // TODO: Rename and change types of parameters
    private String mParam1;
    private String mParam2;

    public CreditNoteVoucherFragment() {
        // Required empty public constructor
    }

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param param1 Parameter 1.
     * @param param2 Parameter 2.
     * @return A new instance of fragment CreditNoteVoucherFragment.
     */
    // TODO: Rename and change types and number of parameters
    public static CreditNoteVoucherFragment newInstance(String param1, String param2) {
        CreditNoteVoucherFragment fragment = new CreditNoteVoucherFragment();
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
        binding = FragmentCreditNoteVoucherBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        ((NewMainActivity)getActivity()).setUpTitle(CreditNoteVoucherFragment.this,getString(R.string.credit_note_voucher));
        setUpUi();
    }
    private void setUpUi() {
        binding.firmName.setTextColor(getSecondHeaderTextColor());
        binding.tvVoucherNumber.setTextColor(getSecondHeaderTextColor());
        binding.tvBillHeading.setTextColor(getSecondHeaderTextColor());
        binding.tvTotalHeading.setTextColor(getSecondHeaderTextColor());
        binding.tvTotalValueOfBill.setTextColor(getSecondHeaderTextColor());
        binding.tvAdjustmentDetailHeading.setTextColor(getSecondHeaderTextColor());
        binding.shareCreditNoteInvoiceInnerCard.setCardBackgroundColor(getButtonColor());
    }
}