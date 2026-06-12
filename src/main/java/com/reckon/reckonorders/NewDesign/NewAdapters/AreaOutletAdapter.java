package com.reckon.reckonorders.NewDesign.NewAdapters;

import android.graphics.Color;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.navigation.fragment.NavHostFragment;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Fragment.Home.ReceiptDetailsFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.AccountStatementFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.AddBillsFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.CreateReceiptEntryFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.OutstandingBillWiseFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.OutstandingFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.ReceiptFragment;
import com.reckon.reckonorders.NewDesign.NewModals.InvoiceModel;
import com.reckon.reckonorders.NewDesign.NewModals.OutletModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.databinding.AddBillsRowLayoutBinding;
import com.reckon.reckonorders.databinding.AddedBillsRowLayoutBinding;
import com.reckon.reckonorders.databinding.InvoiceLayoutBinding;
import com.reckon.reckonorders.databinding.OutletInvoiceLayoutBinding;
import com.reckon.reckonorders.databinding.OutletLayoutBinding;
import com.reckon.reckonorders.databinding.SearchListLayoutBinding;

import java.util.ArrayList;

public class AreaOutletAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    Fragment fragment;
    ArrayList<OutletModel> outletDetails;
    ArrayList<String> outletSearchedList;
    ArrayList<InvoiceModel> invoiceDetails;
    ArrayList<String> id = new ArrayList<>();
    public ArrayList<InvoiceModel> taggedDataList = new ArrayList<>();


    String type;

    public AreaOutletAdapter(OutstandingFragment fragment, ArrayList<OutletModel> outletDetails, String type, ArrayList<String> outletSearchedList) {
        this.fragment = fragment;
        this.outletDetails = outletDetails;
        this.outletSearchedList = outletSearchedList;
        this.type = type;
    }

    public AreaOutletAdapter(AccountStatementFragment fragment, ArrayList<InvoiceModel> invoiceDetails, String type, ArrayList<String> outletSearchedList) {
        this.fragment = fragment;
        this.invoiceDetails = invoiceDetails;
        this.outletSearchedList = outletSearchedList;
        this.type = type;
    }

    public AreaOutletAdapter(CreateReceiptEntryFragment fragment, ArrayList<OutletModel> outletDetails, String type, ArrayList<String> outletSearchedList) {
        this.fragment = fragment;
        this.outletDetails = outletDetails;
        this.outletSearchedList = outletSearchedList;
        this.type = type;
    }

    public AreaOutletAdapter(OutstandingBillWiseFragment fragment, ArrayList<InvoiceModel> invoiceDetails, ArrayList<InvoiceModel> selectedTaggedDataList) {
        this.invoiceDetails = invoiceDetails;
        this.fragment = fragment;
        this.taggedDataList = selectedTaggedDataList;
    }

    public AreaOutletAdapter(AddBillsFragment fragment, ArrayList<InvoiceModel> invoiceDetails) {
        this.invoiceDetails = invoiceDetails;
        this.fragment = fragment;
    }
    public AreaOutletAdapter(ReceiptFragment fragment, ArrayList<InvoiceModel> invoiceDetails) {
        this.invoiceDetails = invoiceDetails;
        this.fragment = fragment;
    }
    public AreaOutletAdapter(ReceiptDetailsFragment fragment, ArrayList<InvoiceModel> invoiceDetails) {
        this.invoiceDetails = invoiceDetails;
        this.fragment = fragment;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        if (fragment instanceof CreateReceiptEntryFragment) {
            return new OutletHolder(SearchListLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        } else if (fragment instanceof AccountStatementFragment) {
            if (type.equalsIgnoreCase("main"))
                return new AccountStatementHolder(InvoiceLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
            else
                return new AccountStatementHolder(SearchListLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        } else if (fragment instanceof OutstandingFragment)
            if (type.equalsIgnoreCase(fragment.getString(R.string.outlet_listing)))
                return new OutletHolder(OutletLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
            else
                //if (type.equalsIgnoreCase(fragment.getString(R.string.search)))
                return new OutletHolder(SearchListLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        else if (fragment instanceof AddBillsFragment) {
            return new AddBillsHolder(AddBillsRowLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        } else if (fragment instanceof ReceiptFragment || fragment instanceof ReceiptDetailsFragment) {
            return new AddedBillsHolder(AddedBillsRowLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
        } else
            return new OutletDetailsHolder(OutletInvoiceLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));

    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        if (fragment instanceof CreateReceiptEntryFragment) {
            ((OutletHolder) holder).layoutBinding.searchItem.setText(outletSearchedList.get(position));
            ((OutletHolder) holder).itemView.setOnClickListener(v ->
                    ((CreateReceiptEntryFragment) fragment).setSearchText(outletSearchedList.get(position))
            );
        } else if (fragment instanceof AccountStatementFragment) {

            if (type.equalsIgnoreCase("main")) {
                InvoiceModel model = invoiceDetails.get(position);
                ((AccountStatementHolder) holder).binding.tvInvoiceNumber.setTextColor(((AccountStatementFragment) fragment).getSecondHeaderTextColor());
                ((AccountStatementHolder) holder).binding.voucherType.setText(model.getTranType());
                ((AccountStatementHolder) holder).binding.tvDate.setText(model.getDate());
                ((AccountStatementHolder) holder).binding.tvInvoiceNumber.setText(model.getEntryNo());
                ((AccountStatementHolder) holder).binding.tvAmountValue.setText(((AccountStatementFragment) fragment).getLicDetails().getCurrency() + (Double.parseDouble(ReckonUtils.nonNullNotEmptyString(model.getDrAmt())?model.getDrAmt():"0") + Double.parseDouble(ReckonUtils.nonNullNotEmptyString(model.getCrAmt())?model.getCrAmt():"0")));
                ((AccountStatementHolder) holder).binding.tvBalanceValue.setText(((AccountStatementFragment) fragment).getLicDetails().getCurrency() + model.getRunningAmt());
              /*  if (model.getTranType().equalsIgnoreCase("CN")) {
                    ((AccountStatementHolder) holder).binding.tvAmountValue.setTextColor(fragment.getResources().getColor(R.color.red));
                } else {
                    ((AccountStatementHolder) holder).binding.tvAmountValue.setTextColor(((AccountStatementFragment) fragment).getThirdHeaderColor());
                }*/
                ((AccountStatementHolder) holder).binding.tvAmountValue.setTextColor(Color.parseColor(model.getAmountColor()));

                if (position == invoiceDetails.size() - 1) {
                    ReckonUtils.setLastVisibleItemMargin(((AccountStatementHolder) holder).binding.invoiceLayout, 5, 5, 5, 250);
                }
//                if (position == invoiceDetails.size() - 1)
//                    setLastItemVisible(((AccountStatementHolder) holder).binding.invoiceLayout, 50);
                holder.itemView.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        Bundle bundle = new Bundle();
                        bundle.putString(Constant.STATEMENT_ID, model.getKeyEntryNo());
                        bundle.putString(Constant.KEY_ENTRY_SR_NO, model.getKeyEntrySrNo());
                        bundle.putString(Constant.IS_ENTRY_RECORD, model.getIsEntryRecord());
                        NavHostFragment.findNavController(fragment).navigate(R.id.nav_sale_voucher, bundle);
                    }
                });
            } else {
                if (outletSearchedList != null && outletSearchedList.size() > 0) {
                    ((AccountStatementHolder) holder).searchListLayoutBinding.searchItem.setText(outletSearchedList.get(position));
                }
                ((AccountStatementHolder) holder).itemView.setOnClickListener(v ->
                        ((AccountStatementFragment) fragment).setSearchText(outletSearchedList.get(position))
                );
            }
        } else if (fragment instanceof OutstandingFragment) {
            if (type.equalsIgnoreCase(fragment.getString(R.string.outlet_listing))) {
                ((OutletHolder) holder).binding.tvLastPayment.setText(outletDetails.get(position).getLastPaymentDate());
                ((OutletHolder) holder).binding.tvAddress.setText(outletDetails.get(position).getOutletAddress());
                ((OutletHolder) holder).binding.firmName.setTextColor(((OutstandingFragment) fragment).getSecondHeaderTextColor());
                ((OutletHolder) holder).binding.outstandingBalance.setTextColor(((OutstandingFragment) fragment).getSecondHeaderTextColor());
                ((OutletHolder) holder).binding.outstandingBalance.setText(fragment.getString(R.string.inr) + outletDetails.get(position).getOutstanding() + fragment.getString(R.string.slash));
                ((OutletHolder) holder).binding.firmName.setText(outletDetails.get(position).getOutletName());
                ((OutletHolder) holder).binding.customerType.setText(outletDetails.get(position).getCustomerType());
                ((OutletHolder) holder).itemView.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
//                        if (((BaseFragment) fragment).getLicDetails().getRole().equalsIgnoreCase("SalesMan"))
//                            NavHostFragment.findNavController(fragment).navigate(R.id.nav_account_statement);
//                        else
                        NavHostFragment.findNavController(fragment).navigate(R.id.nav_outlet_details);
                    }
                });
            } else {
                ((OutletHolder) holder).layoutBinding.searchItem.setText(outletSearchedList.get(position));
                ((OutletHolder) holder).itemView.setOnClickListener(v ->
                        ((OutstandingFragment) fragment).setSearchText(outletSearchedList.get(position))
                );
            }
        } else if (fragment instanceof OutstandingBillWiseFragment) {


            if (((OutstandingBillWiseFragment) fragment).getLicDetails().getRole().equalsIgnoreCase("SalesMan")) {
                ((OutletDetailsHolder) holder).layoutBinding.payNowCv.setVisibility(View.GONE);//will be visible for Retailers only
            } else {

            }
            ((OutletDetailsHolder) holder).layoutBinding.invoiceAmount.setTextColor(((OutstandingBillWiseFragment) fragment).getSecondHeaderTextColor());
//            ((OutletDetailsHolder) holder).layoutBinding.tvPayTheBill.setTextColor(((OutstandingBillWiseFragment) fragment).getSecondHeaderTextColor());
            ((OutletDetailsHolder) holder).layoutBinding.invoiceNumber.setTextColor(((OutstandingBillWiseFragment) fragment).getSecondHeaderTextColor());
            ((OutletDetailsHolder) holder).layoutBinding.tvPayTheBill.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    Toast.makeText(fragment.requireActivity(), "Work In progress", Toast.LENGTH_SHORT).show();
                }
            });
            ((OutletDetailsHolder) holder).layoutBinding.invoiceType.setText(invoiceDetails.get(position).getTranType());
            ((OutletDetailsHolder) holder).layoutBinding.invoiceDate.setText(invoiceDetails.get(position).getDate());
            ((OutletDetailsHolder) holder).layoutBinding.invoiceNumber.setText(invoiceDetails.get(position).getEntryNo());
            ((OutletDetailsHolder) holder).layoutBinding.invoiceAmount.setText(((OutstandingBillWiseFragment) fragment).getLicDetails().getCurrency() + invoiceDetails.get(position).getAmount());
            ((OutletDetailsHolder) holder).layoutBinding.dueDate.setText(invoiceDetails.get(position).getDueDate());
            ((OutletDetailsHolder) holder).layoutBinding.overDueDate.setText(invoiceDetails.get(position).getOverDue());


            if (position == invoiceDetails.size() - 1) {
                ReckonUtils.setLastVisibleItemMargin(((OutletDetailsHolder) holder).layoutBinding.cardViewInvoice, 5, 5, 5, 150);
            }

            ((OutletDetailsHolder) holder).layoutBinding.imgCheck.setImageResource(taggedDataList.contains(invoiceDetails.get(position)) ? R.drawable.check_box : R.drawable.uncheck_box);
            ((OutletDetailsHolder) holder).layoutBinding.tagForPaymentChkBox.setOnClickListener(v -> {
                if(((OutstandingBillWiseFragment) fragment).getStoreListData()!=null && ((OutstandingBillWiseFragment) fragment).getStoreListData().size()>1 &&
                        !ReckonUtils.nonNullNotEmptyString(((OutstandingBillWiseFragment) fragment).firmCode)) {
                    Toast.makeText( ((OutstandingBillWiseFragment) fragment).requireActivity(),  ((OutstandingBillWiseFragment) fragment).getResources().getString(R.string.first_select_your_firm), Toast.LENGTH_LONG).show();
                }else{
                    if (taggedDataList.contains(invoiceDetails.get(position)))
                        taggedDataList.remove(invoiceDetails.get(position));
                    else {
                        taggedDataList.add(invoiceDetails.get(position));
                    }
                    ((OutstandingBillWiseFragment) fragment).setVisibilityOfActionCard(taggedDataList);
                    notifyItemChanged(position);
                }

            });
        } else if (fragment instanceof AddBillsFragment) {
            ((AddBillsHolder) holder).layoutBinding.invoiceAmount.setTextColor(((AddBillsFragment) fragment).getSecondHeaderTextColor());
            ((AddBillsHolder) holder).layoutBinding.invoiceDate.setText(invoiceDetails.get(position).getDate());
            ((AddBillsHolder) holder).layoutBinding.invoiceNumber.setText(invoiceDetails.get(position).getEntryNo());
            ((AddBillsHolder) holder).layoutBinding.invoiceType.setText(invoiceDetails.get(position).getTranType());
            ((AddBillsHolder) holder).layoutBinding.invoiceAmount.setText(((AddBillsFragment) fragment).getLicDetails().getCurrency() + invoiceDetails.get(position).getAmount());
            ((AddBillsHolder) holder).layoutBinding.dueDate.setText(invoiceDetails.get(position).getDueDate());
            ((AddBillsHolder) holder).layoutBinding.overDueDate.setText(invoiceDetails.get(position).getOverDue());

            ((AddBillsHolder) holder).layoutBinding.adjustAmount.setText(invoiceDetails.get(position).getAdjustmentAmount().isEmpty() ? "" : ((AddBillsFragment) fragment).getLicDetails().getCurrency() + invoiceDetails.get(position).getAdjustmentAmount());
           if(!invoiceDetails.get(position).getAdjustmentAmount().isEmpty() && Double.parseDouble(invoiceDetails.get(position).getAdjustmentAmount())>0 && Double.parseDouble(invoiceDetails.get(position).getAmount())!=Double.parseDouble(invoiceDetails.get(position).getAdjustmentAmount())){
               ((AddBillsHolder) holder).layoutBinding.imgCheck.setImageResource(taggedDataList.contains(invoiceDetails.get(position)) ? R.drawable.check_box_orange : R.drawable.uncheck_box);
               ((AddBillsHolder) holder).layoutBinding.imgCheck.getLayoutParams().height = 50;
               ((AddBillsHolder) holder).layoutBinding.imgCheck.getLayoutParams().width = 50;
               ((AddBillsHolder) holder).layoutBinding.imgCheck.requestLayout();
           }else{
               ((AddBillsHolder) holder).layoutBinding.imgCheck.setImageResource(taggedDataList.contains(invoiceDetails.get(position)) ? R.drawable.check_box : R.drawable.uncheck_box);
           }

            ((AddBillsHolder) holder).layoutBinding.tagForPaymentChkBox.setOnClickListener(v -> {

                if (taggedDataList.contains(invoiceDetails.get(position))) {
                    taggedDataList.remove(invoiceDetails.get(position));
                    invoiceDetails.get(position).setAdjustmentAmount("");
                } else {
                    taggedDataList.add(invoiceDetails.get(position));
                    invoiceDetails.get(position).setAdjustmentAmount(invoiceDetails.get(position).getAmount());
                }
                if (((AddBillsFragment) fragment).getAdjustmentAmount() <= ((AddBillsFragment) fragment).getReceiptAmount()) {
                    double checkAmt = getSelectedAmounts();
                    double adjustedAmt = 0.0;
                    if (checkAmt > ((AddBillsFragment) fragment).getReceiptAmount()) {
                        adjustedAmt = getSelectedAmounts() - (checkAmt - ((AddBillsFragment) fragment).getReceiptAmount());
                        if (Double.parseDouble(invoiceDetails.get(position).getAmount()) > (checkAmt - ((AddBillsFragment) fragment).getReceiptAmount())) {
                            invoiceDetails.get(position).setAdjustmentAmount("" + (Double.parseDouble(invoiceDetails.get(position).getAmount()) - (checkAmt - ((AddBillsFragment) fragment).getReceiptAmount())));
                        } else {
                            taggedDataList.remove(invoiceDetails.get(position));
                            invoiceDetails.get(position).setAdjustmentAmount("");
                            Toast.makeText(fragment.getContext(), fragment.requireActivity().getString(R.string.add_bill_selection_msg), Toast.LENGTH_SHORT).show();
                        }
                    } else if (checkAmt <=((AddBillsFragment) fragment).getReceiptAmount()) {
                        adjustedAmt = getSelectedAmounts();
                    }

                    ((AddBillsFragment) fragment).setVisibilityOfActionCard(taggedDataList, adjustedAmt);
                    notifyItemChanged(position);
                } else {
                    taggedDataList.remove(invoiceDetails.get(position));
                    invoiceDetails.get(position).setAdjustmentAmount("");
                    Toast.makeText(fragment.getContext(), fragment.requireActivity().getString(R.string.add_bill_selection_msg), Toast.LENGTH_SHORT).show();
                }
            });
        }else if (fragment instanceof ReceiptFragment || fragment instanceof ReceiptDetailsFragment) {
            ((AddedBillsHolder) holder).layoutBinding.entryDateTv.setText(invoiceDetails.get(position).getDate());
            ((AddedBillsHolder) holder).layoutBinding.entryNo.setText(invoiceDetails.get(position).getEntryNo());
            if(invoiceDetails.get(position).getAdjustmentAmount()==null){
                ((AddedBillsHolder) holder).layoutBinding.amount.setText(((BaseFragment) fragment).getLicDetails().getCurrency() + invoiceDetails.get(position).getAmount());
            }else{
                ((AddedBillsHolder) holder).layoutBinding.amount.setText(((BaseFragment) fragment).getLicDetails().getCurrency() + invoiceDetails.get(position).getAdjustmentAmount());
            }
        }
    }

    private double getSelectedAmounts() {
        double totalSelectedAmt = 0.0;
        for (InvoiceModel item : taggedDataList) {
            totalSelectedAmt = totalSelectedAmt + Double.parseDouble(item.getAmount());
        }
        return totalSelectedAmt;
    }

    @Override
    public int getItemCount() {
        if (fragment instanceof CreateReceiptEntryFragment) {
            return outletSearchedList.size();
        } else if (fragment instanceof AccountStatementFragment)
            return invoiceDetails.size();
        else if (fragment instanceof OutstandingFragment)
            if (type.equalsIgnoreCase(fragment.getString(R.string.outlet_listing)))
                return outletDetails.size();
            else
                return outletSearchedList.size();
        else
            return invoiceDetails.size();
    }

    public void executeAutoAdjust() {
        for(InvoiceModel item : invoiceDetails){
            if (taggedDataList.contains(item)) {
                taggedDataList.remove(item);
                item.setAdjustmentAmount("");
            } else {
                taggedDataList.add(item);
                item.setAdjustmentAmount(item.getAmount());
            }
            if (((AddBillsFragment) fragment).getAdjustmentAmount() <= ((AddBillsFragment) fragment).getReceiptAmount()) {
                double checkAmt = getSelectedAmounts();
                double adjustedAmt = 0.0;
                if (checkAmt > ((AddBillsFragment) fragment).getReceiptAmount()) {
                    adjustedAmt = getSelectedAmounts() - (checkAmt - ((AddBillsFragment) fragment).getReceiptAmount());
                    if (Double.parseDouble(item.getAmount()) > (checkAmt - ((AddBillsFragment) fragment).getReceiptAmount())) {
                        item.setAdjustmentAmount("" + (Double.parseDouble(item.getAmount()) - (checkAmt - ((AddBillsFragment) fragment).getReceiptAmount())));
                    } else {
                        taggedDataList.remove(item);
                        item.setAdjustmentAmount("");
                        Toast.makeText(fragment.getContext(), fragment.requireActivity().getString(R.string.add_bill_selection_msg), Toast.LENGTH_SHORT).show();
                   break;
                    }
                } else if (checkAmt <= ((AddBillsFragment) fragment).getReceiptAmount()) {
                    adjustedAmt = getSelectedAmounts();
                }
                ((AddBillsFragment) fragment).setVisibilityOfActionCard(taggedDataList, adjustedAmt);
//                notifyItemChanged(position);
                notifyDataSetChanged();
            } else {
                taggedDataList.remove(item);
                item.setAdjustmentAmount("");
                Toast.makeText(fragment.getContext(), fragment.requireActivity().getString(R.string.add_bill_selection_msg), Toast.LENGTH_SHORT).show();
            }
        }
    }

    public class OutletHolder extends RecyclerView.ViewHolder {
        OutletLayoutBinding binding;
        SearchListLayoutBinding layoutBinding;

        public OutletHolder(@NonNull OutletLayoutBinding layoutBinding) {
            super(layoutBinding.getRoot());
            this.binding = layoutBinding;
        }

        public OutletHolder(@NonNull SearchListLayoutBinding listLayoutBinding) {
            super(listLayoutBinding.getRoot());
            this.layoutBinding = listLayoutBinding;
        }
    }

    public class AccountStatementHolder extends RecyclerView.ViewHolder {
        InvoiceLayoutBinding binding;
        SearchListLayoutBinding searchListLayoutBinding;

        public AccountStatementHolder(@NonNull InvoiceLayoutBinding binding) {
            super(binding.getRoot());
            this.binding = binding;
        }

        public AccountStatementHolder(@NonNull SearchListLayoutBinding searchBinding) {
            super(searchBinding.getRoot());
            this.searchListLayoutBinding = searchBinding;
        }
    }

    public class OutletDetailsHolder extends RecyclerView.ViewHolder {
        OutletInvoiceLayoutBinding layoutBinding;

        public OutletDetailsHolder(@NonNull OutletInvoiceLayoutBinding layoutBinding) {
            super(layoutBinding.getRoot());
            this.layoutBinding = layoutBinding;
        }
    }

    public class AddBillsHolder extends RecyclerView.ViewHolder {
        AddBillsRowLayoutBinding layoutBinding;

        public AddBillsHolder(@NonNull AddBillsRowLayoutBinding layoutBinding) {
            super(layoutBinding.getRoot());
            this.layoutBinding = layoutBinding;
        }
    }
    public class AddedBillsHolder extends RecyclerView.ViewHolder {
        AddedBillsRowLayoutBinding layoutBinding;
        public AddedBillsHolder(@NonNull AddedBillsRowLayoutBinding layoutBinding) {
            super(layoutBinding.getRoot());
            this.layoutBinding = layoutBinding;
        }
    }


}
