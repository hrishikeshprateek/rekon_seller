package com.reckon.reckonorders.Utils;

import android.app.Activity;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;

import java.io.File;
import java.io.IOException;

public class DownloadSharePDF extends AsyncTask<String, Void, Void> {

    private final Activity mContext;
    private final boolean shareViaWhatsapp;

    public DownloadSharePDF(Activity context, boolean mShareViaWhatsapp) {
        mContext = context;
        shareViaWhatsapp = mShareViaWhatsapp;
    }

    @Override
    protected Void doInBackground(String... strings) {
        String fileUrl = strings[0];
        String fileName = strings[1];
        File pdfFolder = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            pdfFolder = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
        } else {
            pdfFolder = Environment.getExternalStorageDirectory();
        }
        File folder = new File(pdfFolder.toString());
        folder.mkdir();
        File pdfFile = new File(folder, fileName);
        try {
            pdfFile.createNewFile();
        } catch (IOException e) {
            e.printStackTrace();
        }
        FileDownloader.downloadFile(fileUrl, pdfFile);
        ReckonUtils.sharePDF(mContext, pdfFile, shareViaWhatsapp);
        return null;
    }
}
