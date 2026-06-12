package com.reckon.reckonorders.NetworkAPI;

import com.reckon.reckonorders.BuildConfig;

import java.io.IOException;

import okhttp3.Interceptor;
import okhttp3.Request;
import okhttp3.Response;

public class HeaderInterceptor implements Interceptor {
    @Override
    public Response intercept(Chain chain) throws IOException {
        Request request = chain.request()
                .newBuilder()
                .addHeader("v_code", String.valueOf(BuildConfig.VERSION_CODE))
                .addHeader("version_name", BuildConfig.VERSION_NAME)
//                .removeHeader("User-Agent")
//                .addHeader("User-Agent", "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0")
                .build();
        Response response = chain.proceed(request);
        return response;
    }
}
