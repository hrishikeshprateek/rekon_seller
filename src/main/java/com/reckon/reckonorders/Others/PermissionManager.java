package com.reckon.reckonorders.Others;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;

import java.util.ArrayList;
import java.util.List;

public class PermissionManager {
    public static void requestAllPermissions(AppCompatActivity activity) {
        List<String> permissionsToRequest = new ArrayList<>();

        // Add common permissions
        permissionsToRequest.add(Manifest.permission.CAMERA);
        permissionsToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION);
        permissionsToRequest.add(Manifest.permission.ACCESS_COARSE_LOCATION);

        // === CRITICAL LOGIC FOR STORAGE AND MEDIA PERMISSIONS ===
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { // Android 13+
            permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES);
            permissionsToRequest.add(Manifest.permission.READ_MEDIA_VIDEO);
            // permissionsToRequest.add(Manifest.permission.READ_MEDIA_AUDIO);
        } else { // Android 12 and below
            permissionsToRequest.add(Manifest.permission.READ_EXTERNAL_STORAGE);
            // WRITE_EXTERNAL_STORAGE is only needed for Android 9 and below for this use case
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                permissionsToRequest.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
            }
        }

        // === CRITICAL LOGIC FOR BLUETOOTH PERMISSIONS ===
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { // Android 12+
            permissionsToRequest.add(Manifest.permission.BLUETOOTH_SCAN);
            permissionsToRequest.add(Manifest.permission.BLUETOOTH_CONNECT);
        } else { // Android 11 and below
            permissionsToRequest.add(Manifest.permission.BLUETOOTH);
            permissionsToRequest.add(Manifest.permission.BLUETOOTH_ADMIN);
        }


        Dexter.withActivity(activity)
                .withPermissions(permissionsToRequest)
                .withListener(new MultiplePermissionsListener() {
                    @Override
                    public void onPermissionsChecked(MultiplePermissionsReport report) {
                        if (report.areAllPermissionsGranted()) {
                            // All permissions granted!
                            // Proceed with your logic.
                        }

                        if (report.isAnyPermissionPermanentlyDenied()) {
                            // A permission was permanently denied. Show a dialog.
                            showSettingsDialog(activity);
                        }
                    }

                    @Override
                    public void onPermissionRationaleShouldBeShown(List<PermissionRequest> permissions, PermissionToken token) {
                        // This is good practice: show a rationale before requesting again.
                        token.continuePermissionRequest();
                    }
                }).check();
    }

    private static void showSettingsDialog(Context context) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("Permissions Required");
        builder.setMessage("This app needs certain permissions to function correctly. Please grant them in the app settings.");
        builder.setPositiveButton("Go to Settings", (dialog, which) -> {
            dialog.cancel();
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            Uri uri = Uri.fromParts("package", context.getPackageName(), null);
            intent.setData(uri);
            context.startActivity(intent);
        });
        builder.setNegativeButton("Cancel", (dialog, which) -> dialog.cancel());
        builder.show();
    }
}
