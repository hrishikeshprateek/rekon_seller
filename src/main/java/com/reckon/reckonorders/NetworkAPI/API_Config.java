package com.reckon.reckonorders.NetworkAPI;


import com.reckon.reckonorders.BuildConfig;
import com.reckon.reckonorders.Utils.ReckonUtils;

import java.util.Arrays;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import retrofit2.Retrofit;
import retrofit2.adapter.rxjava3.RxJava3CallAdapterFactory;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.converter.scalars.ScalarsConverterFactory;

/**
 * Project SquareupRetrofit
 * Created by Manvendra Kumar Singh on 29/12/18.
 */

public class API_Config {
    private static String URL = ReckonUtils.BASE_URL;
    public static ApiService getApiClientByPost(String... imageBaseUrl) {
        OkHttpClient okHttpClient = new OkHttpClient.Builder()
                .readTimeout(120, TimeUnit.SECONDS)
                .writeTimeout(120, TimeUnit.SECONDS)
                .connectTimeout(120, TimeUnit.SECONDS)
                .addInterceptor(new HeaderInterceptor())
                .build();
        String _baseUrl = BuildConfig.BaseUrl/*.replace("ReckonPwsOrderWSApp", "ReckonPwsOrderWSApp_"+BuildConfig.VERSION_CODE)*/;
        Retrofit.Builder builder = new Retrofit.Builder()
                .baseUrl(imageBaseUrl!=null && !Arrays.toString(imageBaseUrl).contains("[]") &&!Arrays.toString(imageBaseUrl).isEmpty()? BuildConfig.ImageBaseUrl : _baseUrl/*BuildConfig.BaseUrl*/)
                .addConverterFactory(ScalarsConverterFactory.create())
                .addConverterFactory(GsonConverterFactory.create())
                .addCallAdapterFactory(RxJava3CallAdapterFactory.create())
                .client(okHttpClient);
        Retrofit retrofit = builder.build();
        return retrofit.create(ApiService.class);
    }
    public static ApiService getApiClientByPostInBackground() {
        OkHttpClient okHttpClient = new OkHttpClient.Builder()
                .readTimeout(120, TimeUnit.SECONDS)
                .writeTimeout(120, TimeUnit.SECONDS)
                .connectTimeout(120, TimeUnit.SECONDS)
                .build();

        Retrofit.Builder builder = new Retrofit.Builder()
                .baseUrl(BuildConfig.BaseUrl)
                .addConverterFactory(ScalarsConverterFactory.create())
                .addConverterFactory(GsonConverterFactory.create())
                .callbackExecutor(Executors.newSingleThreadExecutor())
                .client(okHttpClient);
        Retrofit retrofit = builder.build();
        return retrofit.create(ApiService.class);
    }


    public static ApiService getApiClient_ByGet() {
        Retrofit.Builder builder = new Retrofit.Builder().baseUrl(URL).addConverterFactory(GsonConverterFactory.create());
        Retrofit retrofit = builder.build();
        return retrofit.create(ApiService.class);
    }
}
