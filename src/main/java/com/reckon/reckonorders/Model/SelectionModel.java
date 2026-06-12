package com.reckon.reckonorders.Model;

/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

public class SelectionModel {
    private int id;
    private String name, itemid, isSelected;

    public SelectionModel(int id, String name) {
        this.id = id;
        this.name = name;
    }
    public SelectionModel(String itemid, String name, String isSelected) {
        this.itemid = itemid;
        this.name = name;
        this.isSelected = isSelected;
    }
    public String getName() {
        return name != null ? name : "";
    }
    public String getItemId() {
        return itemid != null ? itemid : "";
    }
    public String getIsSelected() {
        return isSelected != null ? isSelected : "";
    }

    public int getId() {
        return id;
    }


}
