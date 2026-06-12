package com.reckon.reckonorders.Model;
/*
 * Created by Manvendra Kumar Singh on 26/01/2019.
 */

import androidx.lifecycle.ViewModel;

public class ProductFilterItemModel extends ViewModel {
    private String title;
    private boolean isSelected = false;

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

    private String id;


    public boolean isSelected() {
        return isSelected;
    }

    public void setSelected(boolean selected) {
        isSelected = selected;
    }
}
