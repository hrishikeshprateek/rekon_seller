package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.Others.Constant.Constant.CODE_REQUEST_DISTRIBUTOR_FILTER;
import static com.reckon.reckonorders.Others.enums.TabsEnum.ADD;
import static com.reckon.reckonorders.Others.enums.TabsEnum.REQUEST;
import static com.reckon.reckonorders.Others.enums.TabsEnum.STATUS;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TabHost;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTabHost;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.enums.TabsEnum;
import com.reckon.reckonorders.R;

import java.util.Objects;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.Unbinder;

public class AddDistributorFragment extends BaseFragment {

    @BindView(android.R.id.tabhost)
    public FragmentTabHost tabHost;
    private Unbinder unbinder;
    private boolean isCreated = false;

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_add_distributor, container, false);
        unbinder = ButterKnife.bind(this, view);
        setupBackButton(view);
        initiateTabHost();
        setTitle(view, getString(R.string.add_distributor).toUpperCase());
        ((NewMainActivity) requireActivity()).setUpTitle(AddDistributorFragment.this, getString(R.string.add_distributor));
    /*    if (!isCreated) {
            tabHost.setVisibility(View.GONE);
        }*/
        return view;
    }


    private void initiateTabHost() {
        tabHost.setup(requireActivity(), getChildFragmentManager(), android.R.id.tabcontent);
        tabHost.addTab(createTabSpec(REQUEST), RequestDistributorFragment.class, null);
        tabHost.addTab(createTabSpec(STATUS), StatusDistributorFragment.class, null);
        tabHost.addTab(createTabSpec(ADD), AddDistFragment.class, null);
        tabHost.setOnTabChangedListener(s -> {
            Fragment fragmentVendor = getChildFragmentManager().findFragmentByTag(STATUS.getTitle());
            Fragment fragmentReview = getChildFragmentManager().findFragmentByTag(ADD.getTitle());
            if (fragmentVendor != null && fragmentVendor.getView() != null) {
                fragmentVendor.getView().setVisibility(View.GONE);
            }
            if (fragmentReview != null && fragmentReview.getView() != null) {
                fragmentReview.getView().setVisibility(View.GONE);
            }
//                clearAllBackStack();
            setTabsColor();
        });
        setColorForView(tabHost.getCurrentTab(), true);

    }


    public TabHost.TabSpec createTabSpec(TabsEnum tab) {
        TabHost.TabSpec tabSpec = tabHost.newTabSpec(tab.toString());
        View view = LayoutInflater.from(getActivity()).inflate(R.layout.view_tab_distributor, null, false);
        FrameLayout viewTab_imgIcon = view.findViewById(R.id.viewTab_imgIcon1);
        viewTab_imgIcon.setBackgroundResource(tab.getIdIcon());
        ((TextView) view.findViewById(R.id.viewTab_tvTitle)).setText(tab.getTitle());
        tabSpec.setIndicator(view);
        return tabSpec;
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
        FrameLayout imgIcon = view.findViewById(R.id.viewTab_imgIcon1);
        imgIcon.setSelected(select);
        tvTitle.setTextColor(ContextCompat.getColor(getActivity(), select ? R.color.black : R.color.warm_grey));
        imgIcon.setBackgroundResource(select ? R.color.new_blue : R.color.white);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        switch (requestCode) {
            case CODE_REQUEST_DISTRIBUTOR_FILTER:
                String Distributor = Objects.requireNonNull(data.getExtras()).containsKey("data") ? data.getStringExtra("data") : "";
//                Country_id = data.getExtras().containsKey(Constant.SELECTED_ID) ? data.getStringExtra(Constant.SELECTED_ID) : "";
//                search_dis_tv.setText(Distributor);
                break;

        }
    }
    @Override
    public void onDestroyView() {
        super.onDestroyView();
        unbinder.unbind();
    }
}
