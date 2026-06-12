package com.reckon.reckonorders.NetworkAPI;


import java.util.Map;

import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.Headers;
import retrofit2.http.Multipart;
import retrofit2.http.POST;
import retrofit2.http.Part;
import retrofit2.http.PartMap;
import retrofit2.http.Query;

public interface ApiService {

    String TAG = "ApiService";

//    @POST("RegisterProfile")
//    Call<String> postUserRegister(@Body String body);

    @POST("GeneralSetting")
    Call<String> generalSetting(@Body String object);

    @POST("CreateDeviceId")
    Call<String> sendFCM(@Body String object);

    @POST("GetDashBoard")
    Call<String> getDashBoard(@Body String object);

    @POST("ValidateLicense")
    Call<String> postLogin(@Body String object);

    @GET("GenerateOTPForMobile")
    Call<String> sendOtp(@Header("lApkName") String lApkName, @Header("MobileNo") String key1, @Header("CountryCode") String key0, @Header("GenerateOtp") String key);

    @POST("ValidateMobileOTP")
    Call<String> verifyOtp(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("SaveWebPassword")
    Call<String> postCreatePassword(@Query("lApkName") String lApkName, @Query("LicNo") String key, @Query("CountryCode") String key1, @Query("Password") String key2, @Query("OldPassword") String key3, @Query("CallFromForgotPwd") String key4);

    @GET("GetPinCode")
    Call<String> getAreaFromPostOffice(@Header("lPinCode") String pinCode);

    @Headers("Content-Type: application/json")
    @POST("UpdateImage")
    Call<String> uploadDocs(@Header("lApkName") String lApkName, @Body String body);

    @POST("RegisterProfile")
    Call<String> postUserRegister(@Header("lApkName") String lApkName, @Body String body);

    @POST("DeleteImage")
    Call<String> deleteDocs(@Header("lApkName") String lApkName, @Body String body);

    @GET("GetProfile")
    Call<String> getUserProfile(@Header("lApkName") String lApkName, @Header("CUMOBILE") String key1);





    @POST("GetBrand")
    Call<String> postBrandList(@Body String object);

    @POST("GetFilterList")
    Call<String> getFiltersFromServer(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("RegisterProfile")
    Call<String> postRegistered(@Query("lApkName") String lApkName, @Query("BussinessType") String key1, @Query("LicNo") String key2, @Query("LicName") String key3, @Query("LicEmail") String key4,
                                @Query("LicPassword") String key5, @Query("LicCity") String key6, @Query("LicPinCode") String key7,
                                @Query("CountryCode") String key8, @Query("LicUserRole") String key9, @Query("LicFirmLicNo") String key10);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("UpdateProfile")
    Call<String> postUpdateProfile(@Query("lApkName") String lApkName, @Query("LicBussinessType") String key1,
                                   @Query("LicNo") String key2,
                                   @Query("CountryCode") String key3,
                                   @Query("LicName") String key4,
                                   @Query("LicAdd1") String key5,
                                   @Query("LicAdd2") String key6,
                                   @Query("LicAdd3") String key7,
                                   @Query("LicEmail") String key8,
                                   @Query("LicDLNo") String key9,
                                   @Query("LicGstNo") String key10,
                                   @Query("LicPinCode") String key11,
                                   @Query("LicCity") String key12,
                                   @Query("LicReqType") String key13,
                                   @Query("LicMobile") String key14,
                                   @Query("LicUserRole") String key15,
                                   @Query("LicFirmLicNo") String key16);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("UpdateSetting")
    Call<String> postUpdateSetting(@Query("lApkName") String lApkName,
                                   @Query("LicNo") String key2,
                                   @Query("CountryCode") String key3,
                                   @Query("ShowRefNo") String key4,
                                   @Query("ShowPack") String key5,
                                   @Query("ShowBrand") String key6,
                                   @Query("ShowBarcode") String key7,
                                   @Query("ShowSalt") String key8,
                                   @Query("ShowIGroup") String key9,
                                   @Query("SearchType") String key10,
                                   @Query("ItemHelpIndex") String key11,
                                   @Query("StartWithSearchFieldValue") String key12
    );

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("CreateMapMaster")
    Call<String> submitRequestForDistributor(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("Create_Distributor_Request")
    Call<String> addRequestForDistributor(@Body String object);


    @POST("GetUserOrderList")
    Call<String> MyOrderList(@Body String object);

    @POST("GetReceiptBook")
    Call<String> getReceiptBook(@Body String object);

    @GET("GetDateRange")
    Call<String> getDateRange();

    @POST("GetOrderDetail")
    Call<String> GetOrderDetails(@Body String object);

    @POST("GetDistributorDetail")
    Call<String> GetDistributorDetail(@Body String object);


    @POST("GetReceiptDetail")
    Call<String> GetReceiptDetails(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetState")
    Call<String> PostState(@Query("lApkName") String lApkName, @Query("lCountryCode") String key);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetCity")
    Call<String> PostCity(@Query("lApkName") String lApkName, @Query("lStateCode") String key);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetDistributor")
    Call<String> PostDistributorList(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetItem")//GetItem
    Call<String> PostProductList(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetTopItem")
    Call<String> PostGetTopItemProductList(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetItemDetail")
    Call<String> PostProductDetails(@Body String Object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetAccount")
    Call<String> getPartyList(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetAccountLedger")
    Call<String> getAccountLedger(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("SubmitReceipt")
    Call<String> saveReceiptEntry(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetTranDetail")
    Call<String> getAccountLedgerDetails(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetFile")
    Call<String> GetFile(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetOutstandingDetails")
    Call<String> getOutstanding(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetStation")
    Call<String> getStationList(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetArea")
    Call<String> getFilterAreaList(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetDoAccount")
    Call<String> getDraftPartyList(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetFirm")
    Call<String> getFirmList(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("ListDraftOrder")
    Call<String> PostCartItemList(@Body String object);


    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetDraftOrderValue")
    Call<String> PostDraftOrderDetails(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("AddDraftOrder")
    Call<String> AddProductInCart(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("RemoveDraftOrder")
    Call<String> RemoveItemFromCart(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("SubmitOrder")
    Call<String> SubmitItemFromCart(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("UpdateLocation")
    Call<String> updateLocation(@Body String object);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("GetAccountStatus")
    Call<String> getAccountStatus(@Body String object);

    @POST("LogOff")
    Call<String> LogOff(@Body String object);

    @POST("UploadImage")
    Call<String> uploadImage(@Header("lLicNo") String lLicNo, @Header("lApkName") String lApkName, @Body RequestBody b);

    @Headers("Content-Type: application/x-www-form-urlencoded")
    @POST("ShareReceipt")
    Call<String> shareReceipt(@Body String object);
    @POST("api/auth/edit-profile")
    @Multipart
    Call<String> editProfile(@PartMap Map<String, RequestBody> id_category,
                             @Part MultipartBody.Part frontimage,
                             @Part("firstname") RequestBody firstname,
                             @Part("lastname") RequestBody lastname,
                             @Part("mobile_number") RequestBody mobile_number,
                             @Part("email") RequestBody email,
                             @Part("country_id") RequestBody country_id,
                             @Part("token") RequestBody token,
                             @Query("token") String key);


    @POST("api/auth/contact-us")
    @Multipart
    Call<String> contactUS(@Part("name") RequestBody name,
                           @Part("email") RequestBody email,
                           @Part("contact_number") RequestBody contact_number,
                           @Part("message") RequestBody message,
                           @Part("id_country") RequestBody id_country,
                           @Part("reference_id") RequestBody reference_id,
                           @Part("message_type") RequestBody message_type,
                           @Part("token") RequestBody token,
                           @Part MultipartBody.Part message_image,
                           @Query("token") String key);

}
//https://order.reckonsales.com/API/UpdateImage