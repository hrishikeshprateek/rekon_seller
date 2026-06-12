package com.reckon.reckonorders.Others.enums;
/**
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */


import com.reckon.reckonorders.R;

public enum TabsEnum {
    HOME(0, "HOME", R.drawable.selector_home),
    NOTIFICATION(1, "NOTIFICATION", R.drawable.selector_notification),
    SETTING(2, "SETTING", R.drawable.selector_setting),
    PROFILE(3, "PROFILE", R.drawable.selector_profile),
    REQUEST(4, "REQUEST",  R.color.white),
    STATUS(5, "STATUS",  R.color.white),
    ADD(6, "ADD",  R.color.white);


    private String title;
    private int idIcon;
    private int order;

    TabsEnum(int order, String title, int idIcon) {
        this.title = title;
        this.idIcon = idIcon;
        this.order = order;
    }

    public String getTitle() {
        return title;
    }

    @Override
    public String toString() {
        return this.title;
    }

    public int getIdIcon() {
        return idIcon;
    }

    public int getOrder() {
        return order;
    }
}
