package com.reckon.reckonorders.Adapter;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.fragment.app.Fragment;
import androidx.viewpager.widget.PagerAdapter;
import androidx.viewpager.widget.ViewPager;

import com.reckon.reckonorders.Fragment.Home.HomeFragment;
import com.reckon.reckonorders.Model.SelectionModel;
import com.reckon.reckonorders.NewDesign.NewFragments.ProductDetailsFragment;
import com.reckon.reckonorders.NewDesign.NewModals.Home.BannerListItem;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.squareup.picasso.MemoryPolicy;
import com.squareup.picasso.NetworkPolicy;
import com.squareup.picasso.Picasso;

import java.util.ArrayList;


public class BannerPagerAdapter extends PagerAdapter {

    private ArrayList<SelectionModel> bannersList;
    private ArrayList<BannerListItem> bannerListItems;
    private LayoutInflater inflater;
    private Fragment context;
    private ImageView myImage;
    private Activity activity;

    private ViewPager pager;
    private int dotsCount;
    private ImageView[] dots;
    private int position = 0;
    private LinearLayout viewPagerCountDots;

    public BannerPagerAdapter(HomeFragment context, ArrayList<BannerListItem> bannersList, Activity activity, ViewPager pager) {
        this.context = context;
        this.bannerListItems = bannersList;
        this.activity = activity;
        this.pager = pager;
        inflater = LayoutInflater.from(activity);
    }

    public BannerPagerAdapter(ProductDetailsFragment context, ArrayList<SelectionModel> bannersList, Activity activity, ViewPager pager) {
        this.context = context;
        this.bannersList = bannersList;
        this.activity = activity;
        this.pager = pager;
        inflater = LayoutInflater.from(activity);
    }
    public BannerPagerAdapter(Fragment context, ArrayList<BannerListItem> bannersList, Activity activity, ViewPager pager) {
        this.context = context;
        this.bannerListItems = bannersList;
        this.activity = activity;
        this.pager = pager;
        inflater = LayoutInflater.from(activity);
    }
    @Override
    public int getCount() {

//        if (context instanceof HomeFragment)
            return bannerListItems != null ? bannerListItems.size() : 0;
////        else
//            return bannersList != null ? bannersList.size() : 0;
    }

    @Override
    public boolean isViewFromObject(View view, Object object) {
        return view.equals(object);
    }

    @Override
    public Object instantiateItem(ViewGroup view, final int position) {
        View myImageLayout = inflater.inflate(R.layout.banner_pager_adapter_row, view, false);
        ImageView myImage = myImageLayout.findViewById(R.id.image);
        viewPagerCountDots = myImageLayout.findViewById(R.id.viewPagerCountDots);
        try {
//            Picasso.with(context.getContext()).invalidate(bannersList.get(position).getName());
//            if (context instanceof HomeFragment)
//            {
//            if (context.getContext() != null)
                Picasso.get()
                        .load(bannerListItems.get(position).getImageUrl()).memoryPolicy(MemoryPolicy.NO_CACHE)
                        .networkPolicy(NetworkPolicy.NO_CACHE)
                        .resize(2048, 1600)
                        .onlyScaleDown()
                        .placeholder(ReckonUtils.getBannerPlaceHolder(activity))
                        .error(ReckonUtils.getAppIcon(activity))
                        .into(myImage);
        //}
//            else{
//                Picasso.get()
//                        .load(bannersList.get(position).getName()).memoryPolicy(MemoryPolicy.NO_CACHE)
//                        .networkPolicy(NetworkPolicy.NO_CACHE)
//                        .placeholder(R.mipmap.splash_bg)
//                        .error(R.mipmap.splash_bg)
//                        .into(myImage);
            //}
        } catch (Exception e) {
            e.printStackTrace();
        }
        myImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
//                Toast.makeText(context.getContext(), "Banner Clicked", Toast.LENGTH_SHORT).show();
            }
        });
        view.addView(myImageLayout, 0);

        return myImageLayout;
    }

    @Override
    public void destroyItem(ViewGroup container, int position, Object object) {
        container.removeView((View) object);
    }
}