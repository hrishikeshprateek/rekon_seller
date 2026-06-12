package com.reckon.reckonorders.Model;
/*
 * Created by Manvendra Kumar Singh on 26/01/2019.
 */

import androidx.lifecycle.ViewModel;

import java.util.ArrayList;

public class ProductFilterModel extends ViewModel {
    private String totalCount;
    private String title;
    private String id;
    private String titleColor;
    private boolean isSelected;
    private ArrayList<ProductFilterItemModel> mlist;
    private ArrayList<String> selectedItemPos;

    public String getTotalCount() {
        return totalCount;
    }

    public void setTotalCount(String totalCount) {
        this.totalCount = totalCount;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTitleColor() {
        return titleColor;
    }

    public void setTitleColor(String titleColor) {
        this.titleColor = titleColor;
    }

    public ArrayList<ProductFilterItemModel> getMlist() {
        return mlist;
    }

    public void setMlist(ArrayList<ProductFilterItemModel> mlist) {
        this.mlist = mlist;
    }

    public boolean isSelected() {
        return isSelected;
    }

    public void setSelected(boolean selected) {
        isSelected = selected;
    }

    public ArrayList<String> getSelectedItemPos() {
        return selectedItemPos;
    }

    public void setSelectedItemPos(ArrayList<String> selectedItemPos) {
        this.selectedItemPos = selectedItemPos;
    }
}
