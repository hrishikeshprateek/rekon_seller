package com.reckon.reckonorders.Fragment.Home;
/**
 * Created by Manvendra Kumar Singh on 20/07/2019.
 */
import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;
import android.provider.Settings;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.reckon.reckonorders.Adapter.PhotosAdapter;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Base64;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import butterknife.Unbinder;
import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.RequestBody;

import static android.app.Activity.RESULT_OK;
import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;
import static com.reckon.reckonorders.Utils.ReckonUtils.hasPermissions;
import static com.reckon.reckonorders.Utils.ReckonUtils.hasRationalPermissions;


public class UploadPrescriptionFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private static final String ID = "id";
    private static final String NAME = "name";
    private Unbinder unbinder;
    public static final int REQUEST_CODE_ASK_PERMISSIONS = 30;
    private String requestPermission[] = {Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE};
    final int REQUEST_PERMISSIONS = 103;
    final int FROM_GALLERY = 101;
    final int FROM_CAMERA = 102;
    private Uri uri = null;
    private String filePath = "";
    final int WIDTH = 600;
    final int HEIGHT = 800;
    @BindView(R.id._rvPhoto)
    public RecyclerView _rvPhoto;
    @BindView(R.id.image_bg)
    public LinearLayout image_bg;
    private PhotosAdapter photoAdapter;
    private ArrayList<String> imageArrayList = new ArrayList<>();
    ArrayList<Bitmap> arrayList = new ArrayList<>();

    private JSONArray jsonArrayImages = new JSONArray();

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_upload_prescription, container, false);
        unbinder = ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        setupBackButton(view);
        setTitle(view, getString(R.string.uploadPrescription));
        setupUI();
        return view;
    }

    private void setupUI() {
        try {
            setContactImageAdapter();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setContactImageAdapter() {
        _rvPhoto.setLayoutManager(new LinearLayoutManager(getActivity(), LinearLayoutManager.HORIZONTAL, false));
    //    photoAdapter = new PhotosAdapter(imageArrayList, this, arrayList, (short) 0, (byte) 3,0);
        _rvPhoto.setNestedScrollingEnabled(false);
        _rvPhoto.setAdapter(photoAdapter);
        _rvPhoto.hasFixedSize();
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    @OnClick({R.id.imgFromGallery, R.id.imgFromCamera, R.id.uploadImage_fl})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.imgFromGallery:
                getImageFromGallery();
                break;
            case R.id.imgFromCamera:
                if (checkAndRequestPermissions(getActivity(), requestPermission, REQUEST_PERMISSIONS)) {
                    openCamera();
                }
                break;
            case R.id.uploadImage_fl:
                uploadImagesOnServer();
                break;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private void uploadImagesOnServer() {
        try {
            jsonArrayImages = new JSONArray();
            for (int i = 0; i < imageArrayList.size(); i++) {
                File file = new File(imageArrayList.get(i));
                int size = (int) file.length();
                byte[] imageBytes = new byte[size];
                try {
                    BufferedInputStream buf1 = new BufferedInputStream(new FileInputStream(file));
                    buf1.read(imageBytes, 0, imageBytes.length);
                    buf1.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                RequestBody body = RequestBody.create(MediaType.parse("application/octet-stream"), imageBytes);
                String b = Base64.getEncoder().encodeToString(imageBytes);
                jsonArrayImages.put(b);
            }
            UploadPrescriptions();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    protected void openCamera() {
        Intent cameraIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        ContentValues values = new ContentValues(3);
        values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
        uri = requireActivity().getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
        cameraIntent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
        startActivityForResult(cameraIntent, FROM_CAMERA);
    }

    private void getImageFromGallery() {
        try {
            if (!hasPermissions(getActivity(), new String[]{Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE})) {
                ActivityCompat.requestPermissions(requireActivity(), new String[]{Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE}, REQUEST_CODE_ASK_PERMISSIONS);
            } else {
                if (checkAndRequestPermissions(getActivity(), requestPermission, REQUEST_PERMISSIONS)) {
                    imageFromGallery();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void imageFromGallery() {
        Intent photoPickerIntent = new Intent(Intent.ACTION_PICK);
        photoPickerIntent.setType("image/*");
        startActivityForResult(photoPickerIntent, FROM_GALLERY);
    }

    public  boolean checkAndRequestPermissions(Activity activity, String[] permissions, int requestCode) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ArrayList<String> listPermissionsNeeded = new ArrayList<>();
            for (int i = 0; i < permissions.length; i++) {
                if (ContextCompat.checkSelfPermission(activity, permissions[i]) != PackageManager.PERMISSION_GRANTED) {
                    listPermissionsNeeded.add(permissions[i]);
                }
            }

            if (!listPermissionsNeeded.isEmpty()) {
                ActivityCompat.requestPermissions(activity, listPermissionsNeeded.toArray(new String[listPermissionsNeeded.size()]), requestCode);

                return false;
            } else {
                return true;
            }
        } else {
            return true;
        }

    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        switch (requestCode) {
            case REQUEST_PERMISSIONS:
                if (!hasPermissions(getActivity(), permissions)) {
                    if (hasRationalPermissions(getActivity(), permissions)) {
                        openDialog();
                    } else {
                        Toast.makeText(getActivity(), getResources().getString(R.string.enable_permission), Toast.LENGTH_LONG).show();
                    }
                }
                break;
            default:
                break;
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (FROM_CAMERA == requestCode && resultCode == RESULT_OK) {
            if (uri != null) {
                String[] filePathColumn = {MediaStore.Images.Media.DATA};
                Cursor imageCursor = requireActivity().getContentResolver().query(uri, filePathColumn, null, null, null);
                if (imageCursor != null && imageCursor.moveToFirst()) {
                    int columnIndex = imageCursor.getColumnIndex(filePathColumn[0]);
                    filePath = imageCursor.getString(columnIndex);
                    imageCursor.close();
                    filePath = RotateImage(filePath).getAbsolutePath();
                    imageArrayList.add(filePath);
                    image_bg.setVisibility(View.GONE);
                    _rvPhoto.setVisibility(View.VISIBLE);
                    photoAdapter.notifyDataSetChanged();
                }
            }
        } else if (data != null) {
            switch (requestCode) {
                case FROM_GALLERY:
                    if (resultCode == RESULT_OK && checkAndRequestPermissions(getActivity(), requestPermission, REQUEST_PERMISSIONS)) {
                        Uri selectedImage = data.getData();
                        String[] filePathColumn = {MediaStore.Images.Media.DATA};
                        filePath = getPath(getActivity(), selectedImage);
                        if (filePath != null && filePath.length() > 0) {
                            File f = RotateImageNew(filePath);
                            Uri fPath = getImageContentUri(getActivity(), f);
                            filePath = getPath(getActivity(), fPath);
                            imageArrayList.add(filePath);
                            image_bg.setVisibility(View.GONE);
                            _rvPhoto.setVisibility(View.VISIBLE);
                            photoAdapter.notifyDataSetChanged();
                        }
                    }
                    break;

                default:
                    break;
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        try {
            JSONObject jsonObject = new JSONObject(result);
            if (jsonObject.getString("Status").equalsIgnoreCase("true")) {
                Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
                if (imageArrayList != null && imageArrayList.size() > 0) {
                    imageArrayList.clear();
                    photoAdapter.notifyDataSetChanged();
                    image_bg.setVisibility(View.VISIBLE);
                    _rvPhoto.setVisibility(View.GONE);
                }
                String content = jsonObject.getString("Content") != null ? jsonObject.getString("Content") : "";
                JSONArray jsonArray = new JSONArray(content);
                for (int i = 0; i < jsonArray.length(); i++) {
                    try {
                        byte[] bd = Base64.getDecoder().decode(jsonArray.getString(i).getBytes());
                        new DefaultAsyncTaskRunner(bd, i).executeOnExecutor(DefaultAsyncTaskRunner.THREAD_POOL_EXECUTOR);
                        photoAdapter.notifyDataSetChanged();

                    } catch (Exception e) {
                        e.printStackTrace();
                    }


                }
                photoAdapter.notifyDataSetChanged();

                System.out.println("images========================"+arrayList.toString());


/*
                Bitmap bmp = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.length);
                ImageView image = (ImageView) findViewById(R.id.imageView1);

                image.setImageBitmap(Bitmap.createScaledBitmap(bmp, image.getWidth(), image.getHeight(), false));*/
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        unbinder.unbind();
    }

    private void openDialog() {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(getActivity());
        alertDialogBuilder.setMessage(getResources().getString(R.string.require_permission));

        alertDialogBuilder.setPositiveButton(getResources().getString(R.string.yes), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface arg0, int arg1) {
                Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", requireActivity().getPackageName(), null));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
            }
        });

        alertDialogBuilder.setNegativeButton(getResources().getString(R.string.no), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
            }
        });

        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.setCancelable(false);
        alertDialog.show();
    }

    private File RotateImage(String filestr) {
        File file = new File(filestr);
        try {
            if (file.exists()) {
                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inJustDecodeBounds = true;
                BitmapFactory.decodeStream(new FileInputStream(file), null, options);
                int scale = calculateInSampleSize(options, WIDTH, HEIGHT);
                BitmapFactory.Options option = new BitmapFactory.Options();
                option.inSampleSize = scale;
                Bitmap bitmap = BitmapFactory.decodeStream(new FileInputStream(file), null, option);
                bitmap = setRotation(bitmap, file.getAbsolutePath());
                file = SaveImage(bitmap);
         /*       Intent intent = new Intent();
                intent.putExtra("image_path", filePath);
                setResult(RESULT_OK, intent);
                finish();*/

            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        return file;
    }

    public static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;
        if (height > reqHeight || width > reqWidth) {
            final int halfHeight = height / 2;
            final int halfWidth = width / 2;
            while ((halfHeight / inSampleSize) > reqHeight && (halfWidth / inSampleSize) > reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    private File SaveImage(Bitmap finalBitmap) {
        File file = new File(filePath);
        if (file.exists()) {
            boolean isDel = file.delete();
        }
        try {
            FileOutputStream out = new FileOutputStream(file);
            finalBitmap.compress(Bitmap.CompressFormat.JPEG, 90, out);
            out.flush();
            out.close();
            Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
            Uri contentUri = Uri.fromFile(file);
            mediaScanIntent.setData(contentUri);
            requireActivity().sendBroadcast(mediaScanIntent);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return file;
    }

    public static Bitmap setRotation(Bitmap bmp, String imagePath) {
        Bitmap bmp1 = bmp;
        ExifInterface exifcam = null;
        Matrix matrix = new Matrix();
        try {
            exifcam = new ExifInterface(imagePath);
        } catch (Exception e) {
            e.printStackTrace();
        }
        if (exifcam != null) {
            int orientation = exifcam.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
            switch (orientation) {
                case ExifInterface.ORIENTATION_ROTATE_270:
                    matrix.postRotate(270);
                    break;
                case ExifInterface.ORIENTATION_ROTATE_180:
                    matrix.postRotate(180);
                    break;
                case ExifInterface.ORIENTATION_ROTATE_90:
                    matrix.postRotate(90);
                    break;

            }
            bmp1 = Bitmap.createBitmap(bmp, 0, 0, bmp.getWidth(), bmp.getHeight(), matrix, false);
        }
        return bmp1;
    }

    public static String getPath(final Context context, final Uri uri) {
        final boolean isKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;
        String result = uri + "";
        if (isKitKat && (result.contains("media.documents"))) {
            String[] ary = result.split("/");
            int length = ary.length;
            String imgary = ary[length - 1];
            final String[] dat = imgary.split("%3A");
            final String docId = dat[1];
            final String type = dat[0];

            Uri contentUri = null;
            if ("image".equals(type)) {
                contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
            } else if ("video".equals(type)) {

            } else if ("audio".equals(type)) {
            }

            final String selection = "_id=?";
            final String[] selectionArgs = new String[]{dat[1]
            };

            return getDataColumn(context, contentUri, selection, selectionArgs);
        } else if ("content".equalsIgnoreCase(uri.getScheme())) {
            return getDataColumn(context, uri, null, null);
        }
        // File
        else if ("file".equalsIgnoreCase(uri.getScheme())) {
            return uri.getPath();
        }

        return null;
    }


    public static Uri getImageContentUri(Context context, File imageFile) {
        String filePath = imageFile.getAbsolutePath();
        Cursor cursor = context.getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                new String[]{MediaStore.Images.Media._ID},
                MediaStore.Images.Media.DATA + "=? ",
                new String[]{filePath}, null);
        if (cursor != null && cursor.moveToFirst()) {
            int id = cursor.getInt(cursor.getColumnIndex(MediaStore.MediaColumns._ID));
            cursor.close();
            return Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "" + id);
        } else {
            if (imageFile.exists()) {
                ContentValues values = new ContentValues();
                values.put(MediaStore.Images.Media.DATA, filePath);
                return context.getContentResolver().insert(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            } else {
                return null;
            }
        }
    }


    public static String getDataColumn(Context context, Uri uri, String selection, String[] selectionArgs) {
        Cursor cursor = null;
        final String column = "_data";
        final String[] projection = {column};

        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs, null);
            if (cursor != null && cursor.moveToFirst()) {
                final int column_index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(column_index);
            }
        } finally {
            if (cursor != null)
                cursor.close();
        }
        return null;
    }

    private File RotateImageNew(String filestr) {
        File file = new File(filestr);
        try {
            if (file.exists()) {
                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inJustDecodeBounds = true;
                BitmapFactory.decodeStream(new FileInputStream(file), null, options);
                int scale = calculateInSampleSize(options, WIDTH, HEIGHT);
                BitmapFactory.Options option = new BitmapFactory.Options();
                option.inSampleSize = scale;
                Bitmap bitmap = BitmapFactory.decodeStream(new FileInputStream(file), null, option);
                bitmap = setRotation(bitmap, file.getAbsolutePath());
                file = SaveImage(bitmap);

            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return file;
    }

    private void UploadPrescriptions() {
        try {
            JSONArray jsonArray1 = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.USER_DATA_LIST));
            JSONObject jsonObject = jsonArray1.getJSONObject(0);
            RequestBody lLicNo = RequestBody.create(MediaType.parse("text/plain"), jsonObject.getString("CountryCode") + jsonObject.getString("LicNo"));
            RequestBody lApkName = RequestBody.create(MediaType.parse("text/plain"), requireActivity().getPackageName());
            MultipartBody.Part message_image = null;
            if (filePath != null && !filePath.isEmpty() && !filePath.contains("http")) {
                File file = new File(filePath);
                RequestBody reqFile = RequestBody.create(MediaType.parse("image/*"), file);
                message_image = MultipartBody.Part.createFormData("imageBytes", file.getName(), reqFile);
            }
            String LicNo = jsonObject.getString("CountryCode") + jsonObject.getString("LicNo");
            String apkName = requireActivity().getPackageName();//
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().uploadImage(LicNo, apkName, RequestBody.create(MediaType.parse("text/plain"), jsonArrayImages.toString())), "UploadImage", true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }




    @SuppressLint("StaticFieldLeak")
    private class DefaultAsyncTaskRunner extends AsyncTask<String, String, Bitmap> {
        int finalI;
        byte[] bytes;

        DefaultAsyncTaskRunner(byte[] bytes, int finalI) {
            this.bytes = bytes;
            this.finalI = finalI;
        }

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
        }

        @Override
        protected Bitmap doInBackground(String... params) {
            return  BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        }

        @Override
        protected void onPostExecute(Bitmap bmp) {
            try {
                arrayList.add(bmp);
                System.out.println(bmp);
        //        photoAdapter = new PhotosAdapter(imageArrayList, UploadPrescriptionFragment.this, arrayList, (short) 0, 3,0);
                _rvPhoto.setAdapter(photoAdapter);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
