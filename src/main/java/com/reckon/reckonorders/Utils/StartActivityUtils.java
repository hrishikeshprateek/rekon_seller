package com.reckon.reckonorders.Utils;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.reckon.reckonorders.Activity.AccountActivity;
import com.reckon.reckonorders.Activity.MainActivity;
import com.reckon.reckonorders.Activity.Splash;
import com.reckon.reckonorders.NewDesign.NewMainActivity;

@SuppressLint("WrongConstant")
public class StartActivityUtils {

    public static void toHome(Context context, String string) {
        Bundle bundle = new Bundle();
        bundle.putString("", string);
        Intent intent = new Intent().setClass(context, NewMainActivity.class);
        intent.putExtras(bundle);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        context.startActivity(intent);
    }

    public static void toAccount(Context context) {
        try {
            Intent intent = new Intent().setClass(context, AccountActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            context.startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void toSplash(Context context) {
        try {
            Intent intent = new Intent().setClass(context, Splash.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            context.startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
