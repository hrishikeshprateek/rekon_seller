package com.reckon.reckonorders.Others.Dialog;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.hbb20.CountryCodePicker;
import com.reckon.reckonorders.Interfaces.DialogListener;
import com.reckon.reckonorders.R;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class ConfirmDialog extends Dialog {

    @BindView(R.id.dialogConfirm_tvTitle)
    TextView tvTitle;
    @BindView(R.id.dialogConfirm_imgIcon)
    ImageView imgIcon;
    @BindView(R.id.dialogConfirm_tvContent)
    TextView tvContent;
    @BindView(R.id.dialogConfirm_tvConfirm)
    public TextView tvConfirm;
    @BindView(R.id.ccp)
    CountryCodePicker ccp;
    @BindView(R.id.country_code_txt)
    TextView country_code_txt;
    @BindView(R.id.mobile_number_ll)
    LinearLayout mobile_number_ll;
    @BindView(R.id.ResendOtpLayout)
    LinearLayout ResendOtpLayout;
    @BindView(R.id.resendbtn)
    public TextView resendbtn;
    @BindView(R.id.timer)
    public TextView timer;
    String textMobile = "";
    @BindView(R.id.otp_ll)
    LinearLayout otp_ll;
    @BindView(R.id.fragmentRegister_edtMobileNumber)
    public EditText tvmobileNumber;
    @BindView(R.id.resetPassword_ll)
    LinearLayout resetPassword_ll;
    @BindView(R.id.cancel_btn_ll)
    LinearLayout cancel_btn_ll;
    @BindView(R.id.fragmentRegister_edtPassword)
    public EditText _edtPassword;
    @BindView(R.id.fragmentRegister_edtConfirmPass)
    public EditText _edtConfirmPass;
    @BindView(R.id.imgBack)
    public ImageView imgBack;
    @BindView(R.id.ed_OTP)
    public EditText ed_OTP;
    private String content, title, mConfirm;
    private boolean isCall;
    Context context1;
    private DialogListener clickListener;

    public String countryCodeAndroid = "91";

    public void setOnItemClickListener(DialogListener listener) {
        this.clickListener = listener;
    }

    public ConfirmDialog(Context context, String title, String content) {
        super(context, R.style.MainActivity);
        this.content = content;
        context1 = context;
        this.isCall = false;
        this.title = title;
        mConfirm = "Delete";


    }

    public ConfirmDialog(Context context, String title, String content, String confirmName) {
        super(context, R.style.AppTheme);
        this.content = content;
        this.isCall = false;
        this.title = title;
        mConfirm = confirmName;
    }

    public ConfirmDialog(Context context, String content) {
        super(context, R.style.AppTheme);
        this.content = content;
        this.isCall = true;
        mConfirm = "Call";
    }

    public void setTextConfirm(String mConfirm) {
        this.mConfirm = mConfirm;
    }

    public void setTextOfMobile(String textOfMobile) {
        textMobile = textOfMobile;
    }

    public void setTextMobile(String mConfirm) {
        this.mConfirm = mConfirm;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setCancelable(false);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        if (getWindow() != null) {
            getWindow().setDimAmount(0.3f);
            getWindow().setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            getWindow().setStatusBarColor(context1.getResources().getColor(R.color.new_blue));
        }
        setContentView(R.layout.dialog_confirm);
        ButterKnife.bind(this);
        tvTitle.setVisibility(isCall ? View.GONE : View.VISIBLE);
//        imgIcon.setVisibility(isCall ? View.VISIBLE : View.GONE);
        tvTitle.setText(title);
        if (mConfirm.equals("Call") && (TextUtils.isEmpty(content) || content.equals("Call "))) {
            content = "No phone number";
            tvConfirm.setVisibility(View.GONE);
        }
        tvContent.setText(content);
        tvConfirm.setText(mConfirm);
        tvmobileNumber.setText(textMobile);
        if (title.equalsIgnoreCase(getContext().getResources().getString(R.string.create_new_account)) || title.equalsIgnoreCase(getContext().getResources().getString(R.string.forgot_your_password))||title.equals(getContext().getResources().getString(R.string.update_mobile))) {
            mobile_number_ll.setVisibility(View.VISIBLE);
            otp_ll.setVisibility(View.GONE);
            imgBack.setVisibility(View.GONE);
            resetPassword_ll.setVisibility(View.GONE);
            cancel_btn_ll.setVisibility(View.VISIBLE);
        } else if (title.equalsIgnoreCase(getContext().getResources().getString(R.string.create_password))) {
            mobile_number_ll.setVisibility(View.GONE);
            otp_ll.setVisibility(View.GONE);
            imgBack.setVisibility(View.VISIBLE);
            resetPassword_ll.setVisibility(View.VISIBLE);
            cancel_btn_ll.setVisibility(View.GONE);
        } else {
            mobile_number_ll.setVisibility(View.GONE);
            otp_ll.setVisibility(View.VISIBLE);
            resetPassword_ll.setVisibility(View.GONE);
            imgBack.setVisibility(View.GONE);
            cancel_btn_ll.setVisibility(View.VISIBLE);
            ResendOtpLayout.setVisibility(View.VISIBLE);

        }
        ccp.setOnCountryChangeListener(new CountryCodePicker.OnCountryChangeListener() {
            @Override
            public void onCountrySelected() {
                countryCodeAndroid = ccp.getSelectedCountryCode();
                country_code_txt.setText("+" + countryCodeAndroid);
            }
        });
    }

    public void StartTimer() {
        try {
            resendbtn.setVisibility(View.GONE);
            new CountDownTimer(60000, 1000) {

                public void onTick(long millisUntilFinished) {
                    timer.setText("seconds remaining: " + millisUntilFinished / 1000);
                    //here you can have your logic to set text to edittext
                }

                public void onFinish() {
                    timer.setText(context1.getResources().getString(R.string.did_not_Rcv_otp));
                    resendbtn.setEnabled(true);
                    resendbtn.setTextColor(context1.getResources().getColor(R.color.red_wine));
                    resendbtn.setVisibility(View.VISIBLE);
                }

            }.start();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @OnClick({R.id.dialogConfirm_tvCancel, R.id.dialogConfirm_tvConfirm, R.id.resendbtn, R.id.imgBack})
    void onViewClicked(View view) {
        switch (view.getId()) {
            case R.id.dialogConfirm_tvCancel:
                if (title.equalsIgnoreCase(getContext().getResources().getString(R.string.mobile_verification)))
                    cancelOTPScreenAlert();
                else
                    dismiss();
                break;
            case R.id.dialogConfirm_tvConfirm:
            case R.id.resendbtn:
                if (clickListener != null)
                    clickListener.onConfirmClicked();
                StartTimer();
                break;
            case R.id.imgBack:
                dismiss();
                break;
        }
    }

    private void cancelOTPScreenAlert() {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(getContext());
        alertDialogBuilder.setMessage("Are you sure want to cancel Mobile Verification?");
        alertDialogBuilder.setPositiveButton("YES",
                new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface arg0, int arg1) {
                        dismiss();
                    }
                });

        alertDialogBuilder.setNegativeButton("NO", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
            }
        });

        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(getContext().getResources().getColor(R.color.black));
        alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(getContext().getResources().getColor(R.color.black));
    }
}
