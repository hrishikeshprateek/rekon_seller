package com.reckon.reckonorders.NewDesign.ViewModel;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.reckon.reckonorders.Model.ProductModel;

import java.util.ArrayList;
import java.util.List;

public class MyViewModel extends ViewModel {
    private MutableLiveData<ArrayList<ProductModel>> modelList;
    public LiveData<ArrayList<ProductModel>> getProducts() {
        if (modelList == null) {
            modelList = new MutableLiveData<ArrayList<ProductModel>>();
         //   loadProducts();
        }
        return modelList;
    }

    public void addProducts(ProductModel model) {
        ArrayList<ProductModel> modelItems = new ArrayList<>();
        modelItems.add(model);
        modelList.setValue(modelItems);
        // Do an asynchronous operation to fetch users.
    }
    public void removeProducts()
    {

    }
    public void loadProducts()
    {

    }
}