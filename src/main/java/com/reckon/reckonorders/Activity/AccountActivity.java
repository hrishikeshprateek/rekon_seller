package com.reckon.reckonorders.Activity;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.view.WindowManager;

import com.reckon.reckonorders.Base.BaseActivity;
import com.reckon.reckonorders.Fragment.Account.LoginFragment;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
/*
 * Created by Manvendra Kumar Singh on 15/12/2018.
 */

public class AccountActivity extends BaseActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if(SharedPrefUtils.getEnableScreenshot(this)){
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
        }
        setContentView(R.layout.activity_account);
        setPackageManagerInfo();
        replaceFragment(new LoginFragment(), R.id.activityAccount_fmContainer, false);
    }
    private void setPackageManagerInfo() {
        try {
            PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            String versionName = pInfo.versionName;
            int versionCode = pInfo.versionCode;
            SharedPrefUtils.setVersionCode(this, (int) getLongVersionCode(pInfo));
            SharedPrefUtils.setVersionName(this, versionName);
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
    }

    private long getLongVersionCode(PackageInfo pInfo) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return pInfo.getLongVersionCode();
        } else {
            return pInfo.versionCode;
        }
    }
}
