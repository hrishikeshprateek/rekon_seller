package com.reckon.reckonorders.service;

import static androidx.core.app.NotificationCompat.PRIORITY_MAX;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.Others.NotificationHelper;
import com.reckon.reckonorders.Others.NotificationUtils;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Map;

public class MyFirebaseMessagingService extends FirebaseMessagingService {
    private static final String TAG = MyFirebaseMessagingService.class.getSimpleName();
    LocalStorage localStorage;
    Intent intent;
    private NotificationUtils notificationUtils;

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Log.e(TAG, "From: " + remoteMessage.getFrom());
        if (remoteMessage == null)
            return;
        if (remoteMessage.getData() != null && remoteMessage.getData().size() > 0) {
            showNotification(remoteMessage.getData().get("title"), remoteMessage.getData().get("message")!=null?remoteMessage.getData().get("message"):"", remoteMessage.getData().get("image"));
        }else if(remoteMessage.getNotification() != null){
            Log.e(TAG, "Notification Body: " + remoteMessage.getNotification().getBody());
            handleNotificationMessage(remoteMessage.getNotification());
        }
    }

    @Override
    public void onNewToken(@NonNull String token) {
        Log.d(TAG, "Refreshed token: " + token);
        localStorage = new LocalStorage(getApplicationContext());
        FirebaseMessaging.getInstance().subscribeToTopic("global");
        localStorage.setFirebaseToken(token);
        // If you want to send messages to this application instance or
        // manage this apps subscriptions on the server side, send the
        // FCM registration token to your app server.
//        sendFCMToServer(token);
    }


    @RequiresApi(api = Build.VERSION_CODES.Q)
    private void handleNotification(String message, String image) {
        if (!NotificationUtils.isAppIsInBackground(getApplicationContext())) {
            // app is in foreground, broadcast the push message
            Intent pushNotification = new Intent("");
            pushNotification.putExtra("message", message);
            pushNotification.putExtra("image", image);
            LocalBroadcastManager.getInstance(this).sendBroadcast(pushNotification);

            // play notification sound
            NotificationUtils notificationUtils = new NotificationUtils(getApplicationContext());
            notificationUtils.playNotificationSound();
        } else {
            // If the app is in background, firebase itself handles the notification
        }
    }


    private void handleDataMessage(Map<String, String> data) {
        Log.e(TAG, "push json: " + data.toString());

        try {
            String title = data.get("title");
            String message = data.get("message");
            String imageUrl = data.get("image");
            //            boolean isBackground = data.getBoolean("is_background");

//            String timestamp = data.getString("timestamp");
//            JSONObject payload = data.getJSONObject("payload");

            Log.e(TAG, "title: " + title);
            Log.e(TAG, "message: " + message);
//            Log.e(TAG, "isBackground: " + isBackground);
//            Log.e(TAG, "payload: " + payload.toString());
            Log.e(TAG, "imageUrl: " + imageUrl);
//            Log.e(TAG, "timestamp: " + timestamp);

            NotificationHelper notificationHelper = new NotificationHelper(getApplicationContext());
            intent = new Intent(getApplicationContext(), NewMainActivity.class);
            if (imageUrl != null) {
                notificationHelper.createNotification(title, message, R.drawable.logo, imageUrl, "", intent);
            } else {
                notificationHelper.createNotification(title, message, "", intent);
            }

        } catch (Exception e) {
            Log.e(TAG, "Json Exception: " + e.getMessage());
        }
    }
    private void handleNotificationMessage(RemoteMessage.Notification remoteMessage) {
        Log.e(TAG, "push notification remoteMessage: " + remoteMessage.toString());
        try {
            String title = remoteMessage.getTitle()!=null?remoteMessage.getTitle():"";
            String message = remoteMessage.getBody()!=null?remoteMessage.getBody():"";
            String imageUrl = remoteMessage.getLink()!=null?remoteMessage.getLink().toString()!=null? remoteMessage.getLink().toString():"":"";
            Log.e(TAG, "title: " + title);
            Log.e(TAG, "message: " + message);
            Log.e(TAG, "imageUrl: " + imageUrl);
            Intent intent = new Intent(this, NewMainActivity.class);
            String channel_id = "notification_channel";
            intent.addCategory(Intent. CATEGORY_LAUNCHER ) ;
            intent.setAction(Intent. ACTION_MAIN) ;
            intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_ONE_SHOT);

            Notification notification = new NotificationCompat.Builder(getApplicationContext(), channel_id)
                    .setSmallIcon(R.drawable.logo)
                    .setContentTitle(title)
                    .setContentText(message)
                    .setAutoCancel(true)
                    .setPriority(PRIORITY_MAX)
                    .setLargeIcon(getImageBitmap(imageUrl))
                    .setStyle(new NotificationCompat.BigPictureStyle().bigPicture(getImageBitmap(imageUrl)).bigLargeIcon(null))
                    .setContentIntent(pendingIntent)
                    .build();

            NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            // Check if the Android Version is greater than Oreo
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel notificationChannel = new NotificationChannel(channel_id, "web_app", NotificationManager.IMPORTANCE_HIGH);
                notificationManager.createNotificationChannel(notificationChannel);
            }
            notificationManager.notify(0, notification);

         /*   NotificationHelper notificationHelper = new NotificationHelper(getApplicationContext());
            intent = new Intent(getApplicationContext(), WelcomeActivity.class);
            if (imageUrl != null) {
                notificationHelper.createNotification(title, message, R.mipmap.ic_launcher, imageUrl, "", intent);
            } else {
                notificationHelper.createNotification(title, message, "", intent);
            }*/

        } catch (Exception e) {
            Log.e(TAG, "Json Exception: " + e.getMessage());
        }
    }
    /**
     * Showing notification with text only
     */
    private void showNotificationMessage(Context context, String title, String message, String timeStamp, Intent intent) {
        notificationUtils = new NotificationUtils(context);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        notificationUtils.showNotificationMessage(title, message, timeStamp, intent);
    }

    /**
     * Showing notification with text and image
     */
    private void showNotificationMessageWithBigImage(Context context, String title, String message, String timeStamp, Intent intent, String imageUrl) {
        notificationUtils = new NotificationUtils(context);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        notificationUtils.showNotificationMessage(title, message, timeStamp, intent, imageUrl);
    }

    private Bitmap getImageBitmap(String url) {
        Bitmap bm = null;
        try {
            URL aURL = new URL(url);
            URLConnection conn = aURL.openConnection();
            conn.connect();
            InputStream is = conn.getInputStream();
            BufferedInputStream bis = new BufferedInputStream(is);
            bm = BitmapFactory.decodeStream(bis);
            bis.close();
            is.close();
        } catch (IOException e) {
            Log.e("TAG", "Error getting bitmap", e);
        }
        return bm;
    }

    public void showNotification(String title, String message, String img) {
        String image =  Constant.IMAGE_UPLOAD_URL + img;
        // Pass the intent to switch to the MainActivity
        Intent intent = new Intent(this, NewMainActivity.class);
        // Assign channel ID
        String channel_id = "notification_channel";
        // Here FLAG_ACTIVITY_CLEAR_TOP flag is set to clear
        // the activities present in the activity stack,
        // on the top of the Activity that is to be launched
        intent.addCategory(Intent. CATEGORY_LAUNCHER ) ;
        intent.setAction(Intent. ACTION_MAIN) ;
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        // Pass the intent to PendingIntent to start the
        // next Activity.
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_ONE_SHOT);

        // Create a Builder object using NotificationCompat
        // class. This will allow control over all the flags
//        NotificationCompat.Builder builder
//                = new NotificationCompat
//                .Builder(getApplicationContext(),
//                channel_id)
//                .setSmallIcon(R.drawable.gfg)
////                .setStyle(new NotificationCompat.BigPictureStyle()
////                        .bigPicture(R.drawable.gfg))
//                .setAutoCancel(true)
//                .setVibrate(new long[]{1000, 1000, 1000,
//                        1000, 1000})
//                .setOnlyAlertOnce(true)
//                .setContentIntent(pendingIntent);
//        Uri uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        // A customized design for the notification can be
        // set only for Android versions 4.1 and above. Thus
        // condition for the same is checked here.
//        if (Build.VERSION.SDK_INT
//                >= Build.VERSION_CODES.JELLY_BEAN) {
//            builder = builder.setContent(
//                    getCustomDesign(title, message)).setCustomBigContentView(getCustomDesignExtended(title, message)).setContentTitle(title).setSmallIcon(getNotificationIcon())
//                    .setDefaults(Notification.DEFAULT_ALL).setSound(uri).setAutoCancel(true);
//
//        } // If Android Version is lower than Jelly Beans,
        // customized layout cannot be used and thus the
        // layout is set as follows
        Notification notification = new NotificationCompat.Builder(getApplicationContext(), channel_id)
                .setSmallIcon(R.drawable.logo)
                .setContentTitle(title)
                .setContentText(message)
                .setAutoCancel(true)
                .setPriority(PRIORITY_MAX)
                .setLargeIcon(getImageBitmap(image))
                .setStyle(new NotificationCompat.BigPictureStyle().bigPicture(getImageBitmap(image)).bigLargeIcon(null))
                .setContentIntent(pendingIntent)
                .build();

//        else {
//            builder = builder.setContentTitle(title)
//                    .setContentText(message)
//                    .setSmallIcon(R.drawable.gfg).setContentTitle(title).setSmallIcon(getNotificationIcon()).setLargeIcon(getImageBitmap(image))
//                    .setDefaults(Notification.DEFAULT_ALL).setSound(uri).setAutoCancel(true);
//      //  }
        // Create an object of NotificationManager class to
        // notify the
        // user of events that happen in the background.
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        // Check if the Android Version is greater than Oreo
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel notificationChannel = new NotificationChannel(channel_id, "web_app", NotificationManager.IMPORTANCE_HIGH);
            notificationManager.createNotificationChannel(notificationChannel);
        }
        notificationManager.notify(0, notification);
        //  notificationManager.notify(0, builder.build());
    }


}
