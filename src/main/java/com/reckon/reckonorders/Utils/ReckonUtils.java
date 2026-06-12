package com.reckon.reckonorders.Utils;
/*
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import static java.util.Calendar.getInstance;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.DatePickerDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.drawable.Drawable;
import android.location.LocationManager;
import android.media.ExifInterface;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.preference.PreferenceManager;
import android.provider.MediaStore;
import android.text.Html;
import android.text.InputFilter;
import android.text.InputType;
import android.text.Spanned;
import android.text.TextUtils;
import android.util.Base64;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.Patterns;
import android.util.SparseArray;
import android.util.TypedValue;
import android.view.View;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.core.app.ActivityCompat;
import androidx.core.content.FileProvider;
import androidx.fragment.app.Fragment;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.reckon.reckonorders.Interfaces.DialogListener;
import com.reckon.reckonorders.Interfaces.ItemListener;
import com.reckon.reckonorders.Model.ImageModel;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.Profile;
import com.reckon.reckonorders.NewDesign.NewModals.Registration.ResponseFromRegistration;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.Dialog.ConfirmDialog;
import com.reckon.reckonorders.R;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.SimpleDateFormat;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.StringTokenizer;

public class ReckonUtils {
    public static String BASE_URL = "";
    public static String PLAY_STORE_APP_URL = "https://play.google.com/store/apps/details?id=com.reckon.reckonorders";


    public static boolean isURL(String url) {
        return Patterns.WEB_URL.matcher(url).matches();
    }

    public static int getScreenHalfWidth() {
        return Resources.getSystem().getDisplayMetrics().widthPixels / 2;
    }

    public static int getScreenWidth() {
        return Resources.getSystem().getDisplayMetrics().widthPixels;
    }

    public static void redirectStore(Context context, String updateUrl) {
        final Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(updateUrl));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }

    public static String getNameSelection(SparseArray<String> selection) {
        StringBuilder buffer = new StringBuilder();
        for (int i = 0; i < selection.size(); i++) {
            int key = selection.keyAt(i);
            buffer.append(selection.get(key));
            if (i != selection.size() - 1) {
                buffer.append(", ");
            }
        }
        if (buffer.length() > 100) {
            return buffer.toString().substring(0, buffer.length());
        } else
            return buffer.toString();
    }

    public static List<Integer> getListId(SparseArray<String> selection) {
        List<Integer> rs = new ArrayList<>();
        for (int i = 0; i < selection.size(); i++) {

            int key = selection.keyAt(i);
            if (key != 0)
                rs.add(key);
        }
        return rs;
    }

    public static SparseArray<String> convertStringToSparseArray(String str) {
        SparseArray<String> rs = new SparseArray<>();
        if (str.startsWith("{") && str.endsWith("}")) {
            str = str.replace("{", "").replace("}", "");
            String[] arrayItem = str.split(",");
            for (String anArrayItem : arrayItem) {
                String[] keyValue = anArrayItem.split("=");
                if (keyValue.length == 2) {
                    rs.put(Integer.valueOf(keyValue[0].replace(" ", "")), keyValue[1]);
                }
            }
        }
        return rs;

    }

    public static String convertTimeStampToDate(long timeStamp) {
        return new SimpleDateFormat("dd MMMM yyyy", Locale.US).format(new Date(timeStamp * 1000L));
    }

    public static String convertTimeStampChildToDate(long timeStamp) {
        return new SimpleDateFormat("dd/MM/yyyy", Locale.US).format(new Date(timeStamp * 1000L));
    }

    private static String convertTimeStampToTime(long timeStamp) {
        return new SimpleDateFormat("hh:mm aa", Locale.US).format(new Date(timeStamp * 1000L));
    }

    private static String convertTimeStampToDate2(long timeStamp) {
        return new SimpleDateFormat("dd/MM/yyyy", Locale.US).format(new Date(timeStamp * 1000L));
    }

    private static long compareTimeByHour(long timeStamp) {
        Date userDob = new Date(timeStamp * 1000L);
        Date today = new Date();
        long diff = today.getTime() - userDob.getTime();
        return (diff / (24 * 60 * 60 * 1000));
    }

    public static String showDateTime(long timeStamp) {
        String dateTime = "";
        if (compareTimeByHour(timeStamp) == 0)
            dateTime = convertTimeStampToTime(timeStamp);
        else if (compareTimeByHour(timeStamp) == 1)
            dateTime = "YESTERDAY";
        else
            dateTime = convertTimeStampToDate2(timeStamp);
        return dateTime;
    }

    public static int getAge(Calendar birthDate) {
        Calendar today = getInstance();
        if (birthDate.after(today)) {
            throw new IllegalArgumentException("You don't exist yet");
        }
        int todayYear = today.get(Calendar.YEAR);
        int birthDateYear = birthDate.get(Calendar.YEAR);
        int todayDayOfYear = today.get(Calendar.DAY_OF_YEAR);
        int birthDateDayOfYear = birthDate.get(Calendar.DAY_OF_YEAR);
        int todayMonth = today.get(Calendar.MONTH);
        int birthDateMonth = birthDate.get(Calendar.MONTH);
        int todayDayOfMonth = today.get(Calendar.DAY_OF_MONTH);
        int birthDateDayOfMonth = birthDate.get(Calendar.DAY_OF_MONTH);
        int age = todayYear - birthDateYear;

        if ((birthDateDayOfYear - todayDayOfYear > 3) || (birthDateMonth > todayMonth)) {
            age--;
        } else if ((birthDateMonth == todayMonth) && (birthDateDayOfMonth > todayDayOfMonth)) {
            age--;
        }
        return age;
    }

    public static String getAuthorization(String token) {
        return "Bearer " + token;
    }

    public static boolean isNetworkAvailable(Context context) {
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo netInfo = cm.getActiveNetworkInfo();
        return netInfo != null && netInfo.isConnectedOrConnecting();
    }


    public static void showAlert(final Context context, String title, String errorMessage, @Nullable final DialogListener listener) {
        final AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(title);
        builder.setMessage(errorMessage);
        builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                if (listener != null) {
                    listener.onConfirmClicked();
                }
            }
        });
        builder.create().show();
    }

    public static boolean isGPSEnable(Context context) {
        boolean gps_enabled = false;
        boolean network_enabled = false;
        LocationManager locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
        try {
            gps_enabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER);
        } catch (Exception ignored) {
        }

        try {
            network_enabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
        } catch (Exception ignored) {
        }
        return gps_enabled || network_enabled;
    }

    public static JsonObject convertToJsonObject(String json) {

        return (new JsonParser()).parse(json).getAsJsonObject();
    }

    public static void showConfirmDialog(Context context, String message, final AlertDialog.OnClickListener yesClickListener) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setMessage(message)
                .setCancelable(false)
                .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        yesClickListener.onClick(dialog, id);
                    }
                })
                .setNegativeButton("No", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        dialog.cancel();
                    }
                });
        AlertDialog alert = builder.create();
        alert.show();
    }

    public static void showConfirmUpdateDialog(Context context, String message, final AlertDialog.OnClickListener yesClickListener) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setMessage(message)
                .setTitle("Update Available")
                .setCancelable(false)
                .setPositiveButton("Update", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        yesClickListener.onClick(dialog, id);
                    }
                })
                .setNegativeButton("Next time", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        dialog.cancel();
                    }
                });
        AlertDialog alert = builder.create();
        alert.show();
    }

    public static float convertDpToPx(final Context context, final float dp) {
        return dp * context.getResources().getDisplayMetrics().density;
    }

    private static String convertToHex(byte[] data) {
        StringBuilder buf = new StringBuilder();
        for (byte b : data) {
            int halfbyte = (b >>> 4) & 0x0F;
            int two_halfs = 0;
            do {
                buf.append((0 <= halfbyte) && (halfbyte <= 9) ? (char) ('0' + halfbyte) : (char) ('a' + (halfbyte - 10)));
                halfbyte = b & 0x0F;
            } while (two_halfs++ < 1);
        }
        return buf.toString();
    }

    public static boolean isValidEmail(String email) {
        return !TextUtils.isEmpty(email) && android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches();
    }

    public static boolean nonNullNotEmptyString(String value) {
        if (value != null) {
//            if (value is List || value is Map) return value.length > 0;
            /* if (value is String) */
            return !value.isEmpty() && !value.equalsIgnoreCase("0") && !value.equalsIgnoreCase("0.0");
//            if (value is int || value is double) return value != 0;
        }
        return false;
    }

    public static void shareTextUrl(Context context, String content) {
        Intent share = new Intent(android.content.Intent.ACTION_SEND);
        share.setType("text/plain");
        share.putExtra(Intent.EXTRA_SUBJECT, "Share....");
        share.putExtra(Intent.EXTRA_TEXT, content);
        context.startActivity(Intent.createChooser(share, "Share"));
    }

    public static void sharePDF(Activity context, File pdfurl, boolean shareViaWhatsapp) {
        Uri fileUri = FileProvider.getUriForFile(context, context.getPackageName() + ".provider", pdfurl.getAbsoluteFile());
        Intent share = new Intent(android.content.Intent.ACTION_SEND);
        share.setType("application/pdf");
        share.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        share.putExtra(Intent.EXTRA_STREAM, fileUri);
        if (shareViaWhatsapp) {
            try {
                share.setPackage("com.whatsapp");
                context.startActivity(share);
            } catch (Exception e) {
                e.printStackTrace();
                context.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("http://play.google.com/store/apps/details?id=com.whatsapp")));
            }
        } else {
            context.startActivity(Intent.createChooser(share, "Share"));
        }
    }

    public static String getCurrentTimeInMilli() {
        String time = "";
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            time = String.valueOf(Instant.now().toEpochMilli());
        } else {
            Calendar calendar = Calendar.getInstance();
            time = String.valueOf(calendar.getTimeInMillis());
        }
        return time;
    }

    public static String getCurrentDateTime() {
        return new SimpleDateFormat("dd/MM/yyyy_hh/mm/ss_a").format(new Date());
    }

    public static String getDownloadedStmtPDFName(Activity context, String docName) {
        return "/" + docName + "_" + getCurrentTimeInMilli() + ".pdf";
    }

    public static void downloadAndSharePdf(String url, Activity context, boolean shareViaWhatsapp, String docName) {
        DownloadSharePDF downloadFile = new DownloadSharePDF(context, shareViaWhatsapp);
        downloadFile.execute(url, getDownloadedStmtPDFName(context, docName));
    }

    public static boolean isPDFValid(String pdfLink) {
        return !pdfLink.isEmpty() && (pdfLink.contains(".pdf") || pdfLink.contains(".Pdf") || pdfLink.contains(".PDF"));
    }

    public static void viewPdf(Activity context, String url) {
        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        context.startActivity(browserIntent);
    /*    Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(Uri.parse( "http://docs.google.com/viewer?url=" + url), "text/html");
        context.startActivity(intent);*/
     /*   if (myFile.exist()) {
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setDataAndType(Uri.fromFile(myFile), "application/pdf");
            intent.setFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
            startActivity(intent);
        } else {
            // method is showing toast
            showToast("File does not exist")
        }*/
    }

    @SuppressWarnings("deprecation")
    public static Spanned fromHtml(String html) {
        Spanned result;
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            result = Html.fromHtml(html, Html.FROM_HTML_MODE_LEGACY);
        } else {
            result = Html.fromHtml(html);
        }
        return result;
    }

    public static String textEncryption(String text) throws NoSuchAlgorithmException, UnsupportedEncodingException {
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        md.update(text.getBytes("iso-8859-1"), 0, text.length());
        byte[] sha1hash = md.digest();
        return convertToHex(sha1hash);
    }

    public static void SendOTPDialog(final Context context, String title, String content, final String appPackage) {
        final ConfirmDialog confirmDialog = new ConfirmDialog(context, title, content);
        confirmDialog.setTextConfirm("Create");
        confirmDialog.setOnItemClickListener(new DialogListener() {
            @Override
            public void onConfirmClicked() {
                confirmDialog.dismiss();

            }

        });
        confirmDialog.show();
    }

    private static void confirmApp(final Context context, String title, String content, final String appPackage) {
        final ConfirmDialog confirmDialog = new ConfirmDialog(context, title, content);
        confirmDialog.setTextConfirm("DOWNLOAD");
        confirmDialog.setOnItemClickListener(new DialogListener() {
            @Override
            public void onConfirmClicked() {
                confirmDialog.dismiss();
                try {
                    context.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + appPackage)));
                } catch (android.content.ActivityNotFoundException anfe) {
                    context.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=" + appPackage)));
                }
            }
        });

        confirmDialog.show();
    }

    public static void setBaseUrl(Context context) {
        if (!SharedPrefUtils.getString(context, Constant.SERVER_BASE_URL).equalsIgnoreCase(""))
            BASE_URL = SharedPrefUtils.getString(context, Constant.SERVER_BASE_URL);
        else
//            BASE_URL = "http://103.76.212.38:8080/ReckonRetailOrderWSApp/webresources/reckonretailorder/";// Staging
            //   BASE_URL = "http://103.76.212.60:8080/ReckonRetailOrderWSApp/webresources/reckonretailorder/";//Development
            //   BASE_URL = "http://103.153.58.136:8080/ReckonRetailOrderWSApp/webresources/reckonretailorder/";

            BASE_URL = "http://103.153.58.136:8080/ReckonPwsOrderWSApp/webresources/reckonpwsorder/";
//        BASE_URL = "http://103.153.58.136:8080/ReckonPwsOrderSalesmanWSApp/webresources/reckonpwsorder/";
//        BASE_URL = "http://103.153.58.136:8080/ReckonPwsOrderRetailerWSApp/webresources/reckonpwsorder/";
//        BASE_URL = "http://103.153.58.136:8080/ReckonPwsOrderUnagRetailerWSApp/webresources/reckonpwsorder/";
//                BASE_URL = "http://103.153.58.136:8080/ReckonPwsOrderUnagSalesmanWSApp/webresources/reckonpwsorder/";
//        BASE_URL = "http://103.153.58.136:8080/ReckonPwsOrderSarvahithaWSApp/webresources/reckonpwsorder/";//STAGING
//        BASE_URL = "http://mobile.reckonerp.online:8080/ReckonPwsOrderSarvahithaWSApp/webresources/reckonpwsorder/";//PRODUCTION
//        BASE_URL = "http://103.153.58.136:8080/ReckonPwsOrderThokBazarWSApp/webresources/reckonpwsorder/"; //ThokBazar


    }


    public static void performCall(Context context, String phone) {
        Intent intent = new Intent(Intent.ACTION_DIAL, Uri.fromParts("tel", phone, null));
        context.startActivity(intent);
    }

    public static boolean hasPermissions(Activity context, String[] permissions) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            for (int i = 0; i < permissions.length; i++) {
                if (ActivityCompat.checkSelfPermission(context, permissions[i]) != PackageManager.PERMISSION_GRANTED) {
                    return false;
                }
            }
        }
        return true;
    }

    public static boolean hasRationalPermissions(Activity context, String[] permissions) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            for (int i = 0; i < permissions.length; i++) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(context, permissions[i])) {
                    return true;
                }
            }
        }
        return false;
    }

    public static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;
        if (height > reqHeight || width > reqWidth) {
            final int heightRatio = Math.round((float) height / (float) reqHeight);
            final int widthRatio = Math.round((float) width / (float) reqWidth);
            inSampleSize = heightRatio < widthRatio ? heightRatio : widthRatio;
        }
        final float totalPixels = width * height;
        final float totalReqPixelsCap = reqWidth * reqHeight * 2;
        while (totalPixels / (inSampleSize * inSampleSize) > totalReqPixelsCap) {
            inSampleSize++;
        }
        return inSampleSize;
    }

    private static String getRealPathFromURI(String contentURI, Activity activity) {
        Uri contentUri = Uri.parse(contentURI);
        Cursor cursor = activity.getContentResolver().query(contentUri, null, null, null, null);
        if (cursor == null) {
            return contentUri.getPath();
        } else {
            cursor.moveToFirst();
            int index = cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATA);
            return cursor.getString(index);
        }
    }

    public static String compressImage(String imageUri, Activity activity) {
        String filePath = getRealPathFromURI(imageUri, activity);
        Bitmap scaledBitmap = null;
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        Bitmap bmp = BitmapFactory.decodeFile(filePath, options);
        int actualHeight = options.outHeight;
        int actualWidth = options.outWidth;
        float maxHeight = 816.0f;
        float maxWidth = 612.0f;
        float imgRatio = actualWidth / actualHeight;
        float maxRatio = maxWidth / maxHeight;
        if (actualHeight > maxHeight || actualWidth > maxWidth) {
            if (imgRatio < maxRatio) {
                imgRatio = maxHeight / actualHeight;
                actualWidth = (int) (imgRatio * actualWidth);
                actualHeight = (int) maxHeight;
            } else if (imgRatio > maxRatio) {
                imgRatio = maxWidth / actualWidth;
                actualHeight = (int) (imgRatio * actualHeight);
                actualWidth = (int) maxWidth;
            } else {
                actualHeight = (int) maxHeight;
                actualWidth = (int) maxWidth;

            }
        }
        options.inSampleSize = calculateInSampleSize(options, actualWidth, actualHeight);
        options.inJustDecodeBounds = false;
        options.inPurgeable = true;
        options.inInputShareable = true;
        options.inTempStorage = new byte[16 * 1024];
        try {
            bmp = BitmapFactory.decodeFile(filePath, options);
        } catch (OutOfMemoryError exception) {
            exception.printStackTrace();

        }
        try {
            scaledBitmap = Bitmap.createBitmap(actualWidth, actualHeight, Bitmap.Config.ARGB_8888);
        } catch (OutOfMemoryError exception) {
            exception.printStackTrace();
        }

        float ratioX = actualWidth / (float) options.outWidth;
        float ratioY = actualHeight / (float) options.outHeight;
        float middleX = actualWidth / 2.0f;
        float middleY = actualHeight / 2.0f;
        Matrix scaleMatrix = new Matrix();
        scaleMatrix.setScale(ratioX, ratioY, middleX, middleY);
        Canvas canvas = new Canvas(scaledBitmap);
        canvas.setMatrix(scaleMatrix);
        canvas.drawBitmap(bmp, middleX - bmp.getWidth() / 2, middleY - bmp.getHeight() / 2, new Paint(Paint.FILTER_BITMAP_FLAG));
//      check the rotation of the image and display it properly
        ExifInterface exif;
        try {
            exif = new ExifInterface(filePath);
            int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 0);
            Log.d("EXIF", "Exif: " + orientation);
            Matrix matrix = new Matrix();
            if (orientation == 6) {
                matrix.postRotate(90);
                Log.d("EXIF", "Exif: " + orientation);
            } else if (orientation == 3) {
                matrix.postRotate(180);
                Log.d("EXIF", "Exif: " + orientation);
            } else if (orientation == 8) {
                matrix.postRotate(270);
                Log.d("EXIF", "Exif: " + orientation);
            }
            scaledBitmap = Bitmap.createBitmap(scaledBitmap, 0, 0, scaledBitmap.getWidth(), scaledBitmap.getHeight(), matrix, true);
        } catch (IOException e) {
            e.printStackTrace();
        }

        FileOutputStream out = null;
        String filename = getFilename();
        try {
            out = new FileOutputStream(filename);
            if (scaledBitmap != null) {
                scaledBitmap.compress(Bitmap.CompressFormat.JPEG, 80, out);
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        return filename;
    }

    public static String getFilename() {
        File file = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "ReckonOrders/Images");
        if (!file.exists()) {
            file.mkdirs();
        }
        return (file.getAbsolutePath() + "/" + System.currentTimeMillis() + ".jpg");
    }

    public static String printFileSize(String fileName) {
        File file = new File(fileName);
        long kilobytes = 0;
        if (file.exists()) {
            long bytes = file.length();
            kilobytes = (bytes / 1024);
            long megabytes = (kilobytes / 1024);
            long gigabytes = (megabytes / 1024);
            long terabytes = (gigabytes / 1024);
            long petabytes = (terabytes / 1024);
            long exabytes = (petabytes / 1024);
            long zettabytes = (exabytes / 1024);
            long yottabytes = (zettabytes / 1024);
        } else {
            System.out.println("File does not exist!");
        }
        return String.valueOf(kilobytes);
    }

    public static String encodedImage(Bitmap resource) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        resource.compress(Bitmap.CompressFormat.JPEG, 100, baos);
        return Base64.encodeToString(baos.toByteArray(), Base64.DEFAULT);
    }

    public static ArrayList<String> getImagePathList(JSONObject jsonObject, String baseUrl, String arrayName) {
        ArrayList<String> mlist = new ArrayList<>();
        try {
            JSONArray jsonArray = jsonObject.getJSONArray(arrayName);
            for (int i = 0; i < jsonArray.length(); i++) {
                mlist.add(baseUrl + jsonArray.getString(i));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return mlist;
    }

    public static Profile gettingProfile(Context context) {
        Profile savedProfile = null;
        String json = SharedPrefUtils.getString(context, "profileData");
        Gson gson = new Gson();
        ResponseFromRegistration response = gson.fromJson(json, ResponseFromRegistration.class);
        if (response != null) {
            savedProfile = response.getProfile();
        }
        return savedProfile;
    }

    public static JSONObject gettingProfileData(Context context, Profile savedProfile) {
        JSONObject userInfo = new JSONObject();
        try {
            JSONArray dlImageList = new JSONArray();
            for (ImageModel imageModel : savedProfile.getDLIMAGEPATH()) {
                JSONObject imagesObj = new JSONObject();
                imagesObj.put("ID", imageModel.getId());
                imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                dlImageList.put(imagesObj);
            }

            JSONArray gstImageList = new JSONArray();
            for (ImageModel imageModel : savedProfile.getGSTIMAGEPATH()) {
                JSONObject gstImagesObj = new JSONObject();
                gstImagesObj.put("ID", imageModel.getId());
                gstImagesObj.put("IMAGEURL", imageModel.getImageUrl());
                gstImageList.put(gstImagesObj);
            }

            JSONArray flImageList = new JSONArray();
            for (ImageModel imageModel : savedProfile.getFLIMAGEPATH()) {
                JSONObject imagesObj = new JSONObject();
                imagesObj.put("ID", imageModel.getId());
                imagesObj.put("IMAGEURL", imageModel.getImageUrl());
                flImageList.put(imagesObj);
            }
            userInfo.put("DLIMAGEPATH", dlImageList);
            userInfo.put("FLIMAGEPATH", flImageList);
            userInfo.put("GSTIMAGEPATH", gstImageList);
            userInfo.put("AREA", savedProfile.getAREA());
            userInfo.put("CITY", savedProfile.getCITY());
            userInfo.put("DLNO1", savedProfile.getDLNO1());
            userInfo.put("FOODLICNO", savedProfile.getFOODLICNO());
            userInfo.put("GSTNUMBER", savedProfile.getGSTNUMBER());
            userInfo.put("CUID", savedProfile.getCUID());
            userInfo.put("ADDRESS1", savedProfile.getADDRESS1());
            userInfo.put("ADDRESS2", savedProfile.getADDRESS2());
            userInfo.put("MOBILENO", savedProfile.getMOBILENO());
            userInfo.put("NAME", savedProfile.getNAME());
            userInfo.put("PINCODE", savedProfile.getPINCODE());
            userInfo.put("STATE", savedProfile.getSTATE());
        } catch (Exception e) {
            e.printStackTrace();
        }

        return userInfo;
    }

    public static String getJsonCheckedString(JSONObject obj, String key, String defaultValue) {
        String _key = "";
        try {
            if (obj != null && obj.has(key) && !obj.getString(key).equalsIgnoreCase("0") && !obj.getString(key).equalsIgnoreCase("0.0")) {
                _key = obj.getString(key);
            } else {
                _key = defaultValue;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return _key;
    }

    public static void enterNumbersOnly(EditText editText, int charLimit) {
        editText.setInputType(InputType.TYPE_CLASS_NUMBER);
        editText.setFilters(new InputFilter[]{
                new InputFilter.LengthFilter(charLimit), // Limit to 10 characters
                (source, start, end, dest, dstart, dend) -> {
                    for (int i = start; i < end; i++) {
                        if (!Character.isDigit(source.charAt(i))) {
                            return ""; // Reject non-digit characters
                        }
                    }
                    return null; // Accept the input
                }
        });
    }

    public static String roundTwoDecimals(String value) {
//        String _value = value.replace(".00", "");
        String _value = value.replaceAll("\\.00$|\\.0$", "");
        /*
        * Explanation
replaceAll() method: This method replaces all occurrences of a regex pattern with a specified replacement string.
"\\.00$|\\.0$" regex pattern:
\\.: Matches a literal dot (.). Since the dot has a special meaning in regex, it needs to be escaped with a backslash.
00: Matches two zeros.
0: Matches a single zero.
$: Matches the end of the string.
|: Acts as an "or" operator.
This pattern matches either ".00" or ".0" at the end of the string.
"": This is the replacement string, which is empty in this case, effectively removing the matched pattern. Example
*
* String value = "12.00";
String _value = value.replaceAll("\\.00$|\\.0$", "");
System.out.println(_value); // Output: 12

value = "12.0";
_value = value.replaceAll("\\.00$|\\.0$", "");
System.out.println(_value); // Output: 12

value = "12.50";
_value = value.replaceAll("\\.00$|\\.0$", "");
System.out.println(_value); // Output: 12.50
*
*
* Alternative Solution (using DecimalFormat) You can also achieve this using DecimalFormat if you're working with numeric values:
*
* double number = Double.parseDouble(value);
DecimalFormat decimalFormat = new DecimalFormat("#.#");
String _value = decimalFormat.format(number);
*
* */

    /*    long factor = (long) Math.pow(10, 2);
        value = value * factor;
        long tmp = Math.round(value);
        return *//*(double)*//* String.valueOf(tmp / factor);*/

        BigDecimal bd = BigDecimal.valueOf(Double.parseDouble(_value));
        bd = bd.setScale(2, RoundingMode.HALF_UP);
        return String.valueOf(bd).replaceAll("\\.00$|\\.0$", "");//bd.doubleValue()

//        DecimalFormat twoDForm = new DecimalFormat("##.##");
//        return Double.parseDouble(twoDForm.format(value));
    }

    /**
     * Get decimal formated string to include comma seperator to decimal number
     *
     * @param value
     * @return
     */
    public static String getDecimalFormattedString(String value) {
        if (value != null && !value.equalsIgnoreCase("")) {
            StringTokenizer lst = new StringTokenizer(value, ".");
            String str1 = value;
            String str2 = "";
            if (lst.countTokens() > 1) {
                str1 = lst.nextToken();
                str2 = lst.nextToken();
            }
            String str3 = "";
            int i = 0;
            int j = -1 + str1.length();
            if (str1.charAt(-1 + str1.length()) == '.') {
                j--;
                str3 = ".";
            }
            for (int k = j; ; k--) {
                if (k < 0) {
                    if (str2.length() > 0)
                        str3 = str3 + "." + str2;
                    return str3;
                }
                if (i == 3) {
                    str3 = "," + str3;
                    i = 0;
                }
                str3 = str1.charAt(k) + str3;
                i++;
            }
        }
        return "";
    }

    public static boolean getJsonCheckedBoolean(JSONObject obj, String key, boolean defaultValue) {
        boolean _key = false;
        try {
            _key = obj != null && obj.has(key) ? obj.getString(key) != null ? obj.getBoolean(key) : defaultValue : defaultValue;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return _key;
    }


    @RequiresApi(api = Build.VERSION_CODES.N)
    public static Calendar getMyCalender(Fragment fragment, TextView tvDisplayDate, ItemListener listener) {
        Calendar calender = getInstance();
        int mYear = calender.get(Calendar.YEAR);
        int mMonth = calender.get(Calendar.MONTH);
        int mDay = calender.get(Calendar.DAY_OF_MONTH);
        DatePickerDialog mDatePicker = new DatePickerDialog(fragment.requireActivity(), R.style.DialogTheme, (datepicker, selectedyear, selectedmonth, selectedday) -> {
            try {
                String date = selectedday + "/" + (selectedmonth + 1) + "/" + selectedyear;
                SimpleDateFormat spf = new SimpleDateFormat("dd/MM/yyyy");
                Date newDate = spf.parse(date);
                spf = new SimpleDateFormat("dd/MMM/yyyy");
                date = spf.format(newDate);
                tvDisplayDate.setText(date.toLowerCase(Locale.ROOT));
            } catch (Exception e) {
                e.printStackTrace();
            }
            // set selected date into lbl View
            if (listener != null) {
                listener.onItemClicked(1);
            }
        }, mYear, mMonth, mDay);
        mDatePicker.show();
        return calender;

    }

    public static void logout(Activity context) {
        LocalStorage localStorage = new LocalStorage(context);
        localStorage.logoutUser();
        PreferenceManager.getDefaultSharedPreferences(context).edit().clear().apply();
        StartActivityUtils.toSplash(context);
        context.overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
    }

    public static void logoutAndRestartApp(Activity context) {
        SharedPrefUtils.setString(context, Constant.ACTIVATE, "");
        StartActivityUtils.toSplash(context);
        context.overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
    }

    public static String getFirstCharFromString(String value) {
        String first = "";
        if (value.trim().split(" ").length > 1)
            first = String.valueOf(value.trim().split(" ")[0].charAt(0)) + String.valueOf(value.trim().split(" ")[1].charAt(0));
        else first = String.valueOf(value.trim().charAt(0));
        return first;
    }

    public static ConstraintLayout.LayoutParams setDynamicMargin(int left, int right, int top, int bottom) {
        ConstraintLayout.LayoutParams params = new ConstraintLayout.LayoutParams(ConstraintLayout.LayoutParams.MATCH_PARENT, ConstraintLayout.LayoutParams.WRAP_CONTENT);
        params.setMargins(left, top, right, bottom);
        return params;
    }

    public static float dpToPx(Context context, float valueInDp) {
        DisplayMetrics metrics = context.getResources().getDisplayMetrics();
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, valueInDp, metrics);
    }

    public static void setLastVisibleItemMargin(View view, int top, int left, int right, int bottom) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        params.setMargins(left, top, right, bottom);
        view.setLayoutParams(params);
    }

    public static String getCurrentDate() {
        SimpleDateFormat df = new SimpleDateFormat("dd/MMM/yyyy hh:mm aa", Locale.getDefault());
        return df.format(getInstance().getTime()).toLowerCase(Locale.ROOT);
    }

    public static String getCurrentDateWithoutTime() {
        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());
        return df.format(getInstance().getTime()).toLowerCase(Locale.ROOT);
    }

    public static Drawable getSplashImageDrawable(Activity context, String appId) {
        switch (appId) {
            case Constant.APP_ID_RECKON_ORDERS_SALESMAN:
                return context.getResources().getDrawable(R.drawable.splash_salesman);
            case Constant.APP_ID_RECKON_ORDERS_UNAG_RETAILERS:
                return context.getResources().getDrawable(R.drawable.splash_unag_connect);
            case Constant.APP_ID_RECKON_ORDERS_UNAG_SALESMAN:
                return context.getResources().getDrawable(R.drawable.splash_smart_unag);
            case Constant.APP_ID_RECKON_ORDERS_SARVAHITHA:
                return context.getResources().getDrawable(R.drawable.splash_abliss_img);
            case Constant.APP_ID_NEED_INSIGHT_RETAILER:
            case Constant.APP_ID_NEED_INSIGHT_SALESMAN:
                return context.getResources().getDrawable(R.drawable.splash_need);
            case Constant.APP_ID_AMAR_E_RETAIL:
                return context.getResources().getDrawable(R.drawable.splash_amareretail);
            case Constant.APP_ID_AMAR_E_ORDER:
                return context.getResources().getDrawable(R.drawable.splash_amareorder);
            default:
                return context.getResources().getDrawable(R.drawable.splash_img);// will be called for Constant.APP_ID_RECKON_ORDERS_RETAILERS and Constant.APP_ID_RECKON_ORDERS_MASTER:
        }
    }

    public static int getAppIcon(Activity context) {
        return context.getResources().getIdentifier("ic_launcher", "mipmap", context.getPackageName());
    }

    public static boolean isRetailer(Activity activity) {
        return activity.getPackageName().equalsIgnoreCase("com.reckon.reckonretailers");
    }

    public static int getBannerPlaceHolder(Activity context) {
        return context.getResources().getIdentifier("photo_upload", "drawable", context.getPackageName());
    }

    public static String getDeviceName() {
        return Build.MANUFACTURER.equalsIgnoreCase(Build.BRAND) ? (Build.MANUFACTURER + " " + Build.MODEL) : (Build.MANUFACTURER + " " + Build.BRAND + " " + Build.MODEL);
    }

    public static void openGPSEnableDialog(final Activity mActivity) {
        AlertDialog.Builder builder1 = new AlertDialog.Builder(mActivity);
        builder1.setTitle(mActivity.getResources().getString(R.string.location_permission_required));
        builder1.setMessage(mActivity.getResources().getString(R.string.enable_device_location));
        builder1.setCancelable(false);
        builder1.setPositiveButton(mActivity.getResources().getString(R.string.setting), (dialog, id) -> {
            try {
                Intent intent = new Intent();
                intent.setAction(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                Uri uri = Uri.fromParts("package", Objects.requireNonNull(mActivity).getPackageName(), null);
                intent.setData(uri);
                mActivity.startActivity(intent);
                dialog.dismiss();
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
        AlertDialog alert11 = builder1.create();
        alert11.show();
    }

    public static void openGoogleMapIntent(Activity mActivity, Double latitude, Double longitude, String accName) {
        String urlAddress = "http://maps.google.com/maps?q=" + latitude + "," + longitude + "(" + accName + ")&iwloc=A&hl=es";
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(urlAddress));
        mActivity.startActivity(intent);
    }

    public static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        double theta = lon1 - lon2;
        double dist = Math.sin(deg2rad(lat1))
                * Math.sin(deg2rad(lat2))
                + Math.cos(deg2rad(lat1))
                * Math.cos(deg2rad(lat2))
                * Math.cos(deg2rad(theta));
        dist = Math.acos(dist);
        dist = rad2deg(dist);
        dist = dist * 60 * 1.1515;
        return (dist) * 1.60934;/// KMs multiple with 1.60934
    }

    private static double deg2rad(double deg) {
        return (deg * Math.PI / 180.0);
    }

    private static double rad2deg(double rad) {
        return (rad * 180.0 / Math.PI);
    }

}
