package com.reckon.reckonorders.NetworkAPI;

import android.accounts.NetworkErrorException;
import android.app.Activity;
import android.util.Log;
import android.widget.Toast;

import com.reckon.reckonorders.Others.Dialog.LoadingDialog;
import com.reckon.reckonorders.Utils.ReckonUtils;

import org.json.JSONException;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ConnectToRetrofit {
    private String action = "";
    private Activity context;
    private RetrofitCallBackListener callbacklistner;
    private boolean showDialogue = true;
    private long beginTime;
    private Call<String> call;
    private LoadingDialog mDialogView;

    public ConnectToRetrofit(RetrofitCallBackListener listener, Activity context,
                             Call<String> _call, String action, boolean showDialogue) {
        this.callbacklistner = listener;
        this.context = context;
        this.action = action;
        this.showDialogue = showDialogue;
        this.call = _call;
        beginTime = System.currentTimeMillis();
        geData();
    }

    private void geData() {
        if (showDialogue && context != null) {
            showLoading();
        }

        call.enqueue(new Callback<String>() {

            @Override
            public void onResponse(Call<String> call, Response<String> response) {
                try {
                    dismissLoading();
                    String errorMsg = "Something Went Wrong!!!";
                    if(response.errorBody()!=null&& ReckonUtils.nonNullNotEmptyString(response.errorBody().source().toString())){
                         if(response.errorBody().source().toString().length()>6){
                             errorMsg = response.errorBody().source().toString().substring(6, response.errorBody().source().toString().length()-1);
                         }
                    }
                    if(response.body()!=null){
                        System.out.println("API Response: ======================== " + response.body());
                    }
                    if (response.raw().code() == 504) {
                        Toast.makeText(context, errorMsg, Toast.LENGTH_LONG).show();
                    } else if (response.raw().code() == 500) {
                        Toast.makeText(context, errorMsg, Toast.LENGTH_LONG).show();
                    } else if (response.raw().code() == 503) {
                        Toast.makeText(context, errorMsg, Toast.LENGTH_LONG).show();
//                        ReckonUtils.logout(context);
                    }else if (response.raw().code() == 403 || response.raw().code() == 404 || response.raw().code() == 412) {
                        Toast.makeText(context, errorMsg, Toast.LENGTH_LONG).show();
                        ReckonUtils.logout(context);
                    }
                    if (callbacklistner != null) {
                        callbacklistner.RetrofitCallBackListener(response.raw().code(), response.body(), action);
                    }


                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onFailure(Call<String> call, Throwable t) {
                if (callbacklistner != null) {
                    dismissLoading();
                }
                Log.d("DEBUG", "    onFailure" + t.fillInStackTrace() + "MESSAGE : " + t.getMessage());
                if (t.getMessage() != null && t.getMessage().equalsIgnoreCase("Canceled")) {
                    Log.d("DEBUG", "onFailure request forcefully Canceled ");
                } else {
                    Toast.makeText(context, getError(t), Toast.LENGTH_LONG).show();
                }
                if (callbacklistner != null) {
                    try {
                        callbacklistner.RetrofitCallBackListener(-1, "", action);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            }

        });
    }


    private static String getError(Throwable throwable) {
        String errMsg;
        if (throwable instanceof NetworkErrorException) {
            // Server error
            errMsg = "Unknown server error.";

        } else {
            // NumberFormatException, ParseError, IllegalArgumentException, NullPointerException...
            errMsg = "Network problem occurred.";
        }
        return errMsg;
    }


    private void showLoading() {
        if (ReckonUtils.isNetworkAvailable(context))
            if (!context.isFinishing() && mDialogView != null) {
                mDialogView.show();
            } else {
                mDialogView = new LoadingDialog(context);
                mDialogView.setCanceledOnTouchOutside(false);
                mDialogView.show();
            }
    }

    private void dismissLoading() {
        if (!context.isFinishing() && mDialogView != null) {
            mDialogView.dismiss();
        }
    }

}


