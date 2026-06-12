package com.reckon.reckonorders.NetworkAPI;

import org.json.JSONException;

/**
 * Created by Manvendra Kumar Singh on 06/01/19.
 */

public interface RetrofitCallBackListener {
    void RetrofitCallBackListener(int code, String result, String action) throws JSONException;
}


