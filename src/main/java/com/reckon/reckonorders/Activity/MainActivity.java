package com.reckon.reckonorders.Activity;

import static com.reckon.reckonorders.Others.enums.TabsEnum.HOME;
import static com.reckon.reckonorders.Others.enums.TabsEnum.NOTIFICATION;
import static com.reckon.reckonorders.Others.enums.TabsEnum.PROFILE;
import static com.reckon.reckonorders.Others.enums.TabsEnum.SETTING;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TabHost;
import android.widget.TabWidget;
import android.widget.TextView;

import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTabHost;

import com.reckon.reckonorders.Base.BaseActivity;
import com.reckon.reckonorders.Fragment.Account.ProfileFragment;
import com.reckon.reckonorders.Fragment.Home.HomeFragment;
import com.reckon.reckonorders.Fragment.Home.NotificationFragment;
import com.reckon.reckonorders.Fragment.Home.SettingFragment;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.enums.TabsEnum;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import butterknife.BindView;
import butterknife.ButterKnife;

public class MainActivity extends BaseActivity {
    @BindView(android.R.id.tabhost)
    public FragmentTabHost tabHost;
    @BindView(android.R.id.tabs)
    public TabWidget tabWidget;
    @BindView(R.id.activityMain_llTabBottom)
    public LinearLayout llTabBottom;
    public boolean isPush;
    private ImageView notiIcon;
    private AnimatorSet mAnimationSet;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if(SharedPrefUtils.getEnableScreenshot(this)){
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
        }
        setContentView(R.layout.activity_main);
        ButterKnife.bind(this);
        initiateTabHost();
        getBundle(getIntent().getExtras());

    }


    private void getBundle(Bundle bundle) {
        if (bundle != null && bundle.containsKey(Constant.TYPE_LOGIN)) {
            final String type = bundle.getString(Constant.TYPE_LOGIN);
            assert type != null;
            isPush = true;

            if (type.equals("review")) {
                final Handler handler = new Handler();
                handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        setCurrentTab(4);
                    }
                }, 400);
            } else
                setCurrentTab(3);
            llTabBottom.setVisibility(View.VISIBLE);
        }
    }

    @Override
    protected void onNewIntent(final Intent intent) {
        super.onNewIntent(intent);
        getBundle(intent.getExtras());
    }

    private void initiateTabHost() {
        tabHost.setup(this, getSupportFragmentManager(), android.R.id.tabcontent);
        tabHost.addTab(createTabSpec(HOME), HomeFragment.class, getIntent().getExtras());
        tabHost.addTab(createTabSpec(NOTIFICATION), NotificationFragment.class, null);
        tabHost.addTab(createTabSpec(SETTING), SettingFragment.class, null);
        tabHost.addTab(createTabSpec(PROFILE), ProfileFragment.class, null);
        setTabsColor();
        tabHost.setOnTabChangedListener(new TabHost.OnTabChangeListener() {
            @Override
            public void onTabChanged(String s) {
                clearAllBackStack();
                setTabsColor();
            }
        });
    }

    public TabHost.TabSpec createTabSpec(TabsEnum tab) {
        TabHost.TabSpec tabSpec = tabHost.newTabSpec(tab.toString());
        View view = LayoutInflater.from(this).inflate(R.layout.view_tab_main, null, false);
        ((ImageView) view.findViewById(R.id.viewTab_imgIcon)).setImageResource(tab.getIdIcon());
        ((TextView) view.findViewById(R.id.viewTab_tvTitle)).setText(tab.getTitle());
        notiIcon = view.findViewById(R.id.notiIcon);
        if (tab.getTitle().equalsIgnoreCase("NOTIFICATION"))
            notiIcon.setVisibility(View.VISIBLE);
        RelativeLayout relativelayout = view.findViewById(R.id.relativelayout);
        ObjectAnimator fadeOut = ObjectAnimator.ofFloat(relativelayout, "alpha", .5f, .1f);
        fadeOut.setDuration(300);
        ObjectAnimator fadeIn = ObjectAnimator.ofFloat(relativelayout, "alpha", .1f, .5f);
        fadeIn.setDuration(300);
        mAnimationSet = new AnimatorSet();
        mAnimationSet.play(fadeIn).after(fadeOut);
        mAnimationSet.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                super.onAnimationEnd(animation);
                mAnimationSet.start();
            }
        });
        mAnimationSet.start();

        tabSpec.setIndicator(view);
        return tabSpec;
    }

    public void setCurrentTab(final int index) {
        if (tabHost.isEnabled()) {
            tabHost.postDelayed(new Runnable() {
                @Override
                public void run() {
                    tabHost.setCurrentTab(index);
                }
            }, 10);
        }
    }

    @Override
    protected void onPause() {
        tabHost.getTabWidget().setEnabled(false);
        super.onPause();

    }

    @Override
    protected void onResume() {
        tabHost.getTabWidget().setEnabled(true);
        super.onResume();
    }

    private void setTabsColor() {
        for (int i = 0; i < tabHost.getTabWidget().getChildCount(); i++) {
            setColorForView(i, false);
        }
        setColorForView(tabHost.getCurrentTab(), true);

    }

    private void setColorForView(int i, boolean select) {
        View view = tabHost.getTabWidget().getChildAt(i);
        TextView tvTitle = view.findViewById(R.id.viewTab_tvTitle);
        ImageView imgIcon = view.findViewById(R.id.viewTab_imgIcon);
        ImageView notiIcon = view.findViewById(R.id.notiIcon);
        imgIcon.setSelected(select);
        tvTitle.setTextColor(ContextCompat.getColor(this, R.color.slate_grey));
        if (tabHost.getCurrentTab() == 1)
            notiIcon.setVisibility(View.GONE);
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        FragmentManager fragmentManager = getSupportFragmentManager();
        int stackCount = fragmentManager.getBackStackEntryCount();
        fragmentManager.getFragments();
        if (stackCount <= 0) {
            llTabBottom.setVisibility(View.VISIBLE);
        }
    }

}
