package com.reckon.reckonorders.NewDesign.NewAdapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Base.BaseActivity;
import com.reckon.reckonorders.Others.Dialog.FeedbackDialog;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.databinding.FeedbackOptionsLayoutBinding;

import java.util.ArrayList;

public class DialogAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    FeedbackDialog feedbackDialog;
    int selectedTimeSlotPos = -1;
    ArrayList<String> options;

    public DialogAdapter(FeedbackDialog feedbackDialog, ArrayList<String> options) {
        this.feedbackDialog=feedbackDialog;
        this.options=options;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new FeedbackOptionHolder(FeedbackOptionsLayoutBinding.inflate(LayoutInflater.from(parent.getContext()), parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        if(feedbackDialog!=null) {
            ((FeedbackOptionHolder) holder).binding.cardPaymentHolder.setVisibility(View.GONE);
            ((FeedbackOptionHolder) holder).binding.tvFeedbackOption.setText(options.get(position));
            ((FeedbackOptionHolder)holder).binding.cardPaymentHolder.setCardBackgroundColor(((BaseActivity)feedbackDialog.getContext()).getSecondHeaderTextColor());
            if (selectedTimeSlotPos != position) {
                ((FeedbackOptionHolder) holder).binding.tvFeedbackOption.setTextColor(feedbackDialog.getContext().getResources().getColor(R.color.grey));
                ((FeedbackOptionHolder) holder).binding.cardHolder.setCardBackgroundColor(feedbackDialog.getContext().getResources().getColor(R.color.grey));
            }
            holder.itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if(selectedTimeSlotPos!=position) {
                        selectedTimeSlotPos = position;
                        ((FeedbackOptionHolder) holder).binding.tvFeedbackOption.setTextColor(feedbackDialog.getContext().getResources().getColor(R.color.red));
                        ((FeedbackOptionHolder) holder).binding.cardHolder.setCardBackgroundColor(feedbackDialog.getContext().getResources().getColor(R.color.red));
                        feedbackDialog.showEditText(options.get(position));
                    }else{
                        selectedTimeSlotPos = -1;
                        feedbackDialog.showEditText("");
                        ((FeedbackOptionHolder) holder).binding.tvFeedbackOption.setTextColor(feedbackDialog.getContext().getResources().getColor(R.color.grey));
                        ((FeedbackOptionHolder) holder).binding.cardHolder.setCardBackgroundColor(feedbackDialog.getContext().getResources().getColor(R.color.grey));
                    }
                    notifyDataSetChanged();
                }
            });
        }
    }

    @Override
    public int getItemCount() {
        return options.size();
    }

    public class FeedbackOptionHolder extends RecyclerView.ViewHolder {
        //        CardView cardHolder;
//        TextView tvFeedbackOptions;
        FeedbackOptionsLayoutBinding binding;

        public FeedbackOptionHolder(@NonNull FeedbackOptionsLayoutBinding feedbackOptionsLayoutBinding) {
            super(feedbackOptionsLayoutBinding.getRoot());
            this.binding = feedbackOptionsLayoutBinding;

        }
    }
}
