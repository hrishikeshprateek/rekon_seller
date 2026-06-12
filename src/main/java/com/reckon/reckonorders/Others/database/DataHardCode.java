package com.reckon.reckonorders.Others.database;
/**
 * Created by Manvendra Kumar Singh on 20/01/2018.
 */


import com.reckon.reckonorders.Model.SelectionModel;

import java.util.ArrayList;
import java.util.List;

public class DataHardCode {
    public static List<SelectionModel> getListSortDistributors() {
        List<SelectionModel> rs = new ArrayList<>();
        rs.add(new SelectionModel(1, "All"));
        rs.add(new SelectionModel(2, "Selected City"));
        return rs;
    }
    public static List<SelectionModel> getStatusListSortDistributors() {
        List<SelectionModel> rs = new ArrayList<>();
        rs.add(new SelectionModel(1, "All"));
        rs.add(new SelectionModel(2, "Active"));
        rs.add(new SelectionModel(3, "Pending"));
        rs.add(new SelectionModel(4, "Locked"));
        return rs;
    }
    public static List<SelectionModel> getProductListSort() {
        List<SelectionModel> rs = new ArrayList<>();
        rs.add(new SelectionModel(1, "Name"));
        rs.add(new SelectionModel(2, "Barcode"));
        rs.add(new SelectionModel(3, "Reference No."));
        return rs;
    }
}


