package com.reckon.reckonorders.NewDesign;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.telephony.SmsMessage;
import android.util.Log;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.common.api.Status;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class IncomingSms extends BroadcastReceiver {
    private OTPReceiveListener otpReceiveListener;

    public IncomingSms() {

    }

    public void init(OTPReceiveListener otpReceiveListener) {
        this.otpReceiveListener = otpReceiveListener;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        if (SmsRetriever.SMS_RETRIEVED_ACTION.equals(intent.getAction())) {
            Bundle extras = intent.getExtras();
            if (extras != null) {
                Status status = (Status) extras.get(SmsRetriever.EXTRA_STATUS);
                if (status != null)
                    switch (status.getStatusCode()) {
                        case CommonStatusCodes.SUCCESS:
                            Intent messageIntent=extras.getParcelable(SmsRetriever.EXTRA_CONSENT_INTENT);
                            if (this.otpReceiveListener != null)
                            {
                            otpReceiveListener.onOTPReceived(messageIntent);}
                            break;
                        case CommonStatusCodes.TIMEOUT:
                            if (this.otpReceiveListener != null)
                                this.otpReceiveListener.onOTPTimeOut();
                            break;
                    }
            }
        }
    }

    public  interface OTPReceiveListener {
       public void onOTPReceived(Intent intent);

        public void onOTPTimeOut();
    }
}
