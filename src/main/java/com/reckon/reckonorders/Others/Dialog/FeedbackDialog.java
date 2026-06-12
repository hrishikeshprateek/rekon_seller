package com.reckon.reckonorders.Others.Dialog;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.LayerDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.EditText;
import android.widget.RatingBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Base.BaseActivity;
import com.reckon.reckonorders.Interfaces.DialogListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.DialogAdapter;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.LocalStorage;

import java.util.ArrayList;

import butterknife.BindView;

public class FeedbackDialog extends Dialog {
    // @BindView(R.id.ratingBar)
    RatingBar ratingBar;
    //   @BindView(R.id.tvImprove)
    TextView tvImprove;
    String tabValue = "";
    @BindView(R.id.cardCommentSection)
    CardView cardCommentSection;
    @BindView(R.id.cardNotNow)
    CardView cardNotNow;
    @BindView(R.id.cardSubmit)
    CardView cardSubmit;
    @BindView(R.id.submit)
    TextView submit;
    //    @BindView(R.id.feedbackListRecycler)
    RecyclerView feedbackListRecycler;
    @BindView(R.id.clear)
    TextView clear;
    EditText commentSection;
    DialogAdapter dialogAdapter;
    Activity activity;
    DialogListener clickListener;
    ArrayList<String> options = new ArrayList<>();

    public FeedbackDialog(@NonNull Context context) {
        super(context, android.R.style.Widget_Holo);
        activity = (Activity) context;
    }

    public void showEditText(String items) {
        if (items.equalsIgnoreCase("others"))
            commentSection.setVisibility(View.VISIBLE);
        else
            commentSection.setVisibility(View.GONE);
        tabValue = items;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        if (getWindow() != null) {
            getWindow().setDimAmount(0.3f);
            getWindow().setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            Drawable drawable = getContext().getDrawable(R.drawable.blur_bg_dialog);
            drawable.setAlpha(100);
            getWindow().setBackgroundDrawable(drawable);
        }
        setContentView(R.layout.feedback_popup_dialog);
//        Bitmap map=takeScreenShot();
//        Bitmap fast=fastblur(map, 10);
//        final Drawable draw=new BitmapDrawable(getContext().getResources(),fast);
//        getWindow().setBackgroundDrawable(draw);

//        getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
//        getWindow().addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND);
        Gson gson = new Gson();
        options = gson.fromJson(LocalStorage.getInstance(getContext()).getTags(), new TypeToken<ArrayList<String>>() {
        }.getType());
        dialogAdapter = new DialogAdapter(FeedbackDialog.this, options);
        clear = findViewById(R.id.clear);
        clear.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });
        GridLayoutManager gridLayoutManager = new GridLayoutManager(getContext(), 2);
        feedbackListRecycler = findViewById(R.id.feedbackListRecycler);
        feedbackListRecycler.setLayoutManager(gridLayoutManager);
        feedbackListRecycler.setAdapter(dialogAdapter);
        submit = findViewById(R.id.submit);
        cardNotNow = findViewById(R.id.cardNotNow);
        cardCommentSection = findViewById(R.id.cardCommentSection);
        cardSubmit = findViewById(R.id.cardSubmit);
        commentSection = findViewById(R.id.commentSection);
        tvImprove = findViewById(R.id.tvImprove);
        ratingBar = findViewById(R.id.ratingBar);
        try{
            cardCommentSection.setCardBackgroundColor(((BaseActivity) getContext()).getSecondHeaderTextColor());
            LayerDrawable stars = (LayerDrawable) ratingBar.getProgressDrawable();
            //  stars.getDrawable(2).setColorFilter(Color.parseColor("#DA1D2F"), PorterDuff.Mode.SRC_ATOP);
//        Drawable drawable = ratingBar.getProgressDrawable();
            stars.getDrawable(2).setColorFilter(Color.parseColor("#DA1D2F"), PorterDuff.Mode.SRC_ATOP);
            submit.setText(((BaseActivity) getContext()).getHeaderTextColor());
            clear.setText(((BaseActivity) getContext()).getHeaderTextColor());
            cardSubmit.setCardBackgroundColor(((BaseActivity) getContext()).getSecondHeaderTextColor());
            cardNotNow.setCardBackgroundColor(((BaseActivity) getContext()).getSecondHeaderTextColor());
        }catch (Exception e){
            e.printStackTrace();
        }
        ratingBar.setOnRatingBarChangeListener((ratingBar, rating, fromUser) -> {
            if (rating > 3) {
                feedbackListRecycler.setVisibility(View.GONE);
                tvImprove.setVisibility(View.GONE);
            } else {
                feedbackListRecycler.setVisibility(View.VISIBLE);
                tvImprove.setVisibility(View.VISIBLE);
            }
        });
        submit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                float rating = ratingBar.getRating();
                if (rating > 3) {
                    final String appPackageName = getContext().getPackageName(); // getPackageName() from Context or Activity object
                    try {
                        getContext().startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + appPackageName)));
                    } catch (android.content.ActivityNotFoundException anfe) {
                        getContext().startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=" + appPackageName)));
                    }
                } else {
                    if (!tabValue.isEmpty()) {
                        if (tabValue.equalsIgnoreCase("others")) {
                            if (commentSection.getText().toString().isEmpty()) {
                                Toast.makeText(getContext(), getContext().getResources().getString(R.string.write_a_suggestion), Toast.LENGTH_SHORT).show();
                            } else {
                                dismiss();
                            }
                        } else {
                            dismiss();
                        }
                    } else {
                        Toast.makeText(getContext(), getContext().getResources().getString(R.string.reason_error), Toast.LENGTH_SHORT).show();
                    }
                }
            }
        });

    }

    private Bitmap takeScreenShot() {
        View view = getWindow().getDecorView();
        view.setDrawingCacheEnabled(true);
        view.buildDrawingCache();
        Bitmap b1 = view.getDrawingCache();
        Rect frame = new Rect();
        getWindow().getDecorView().getWindowVisibleDisplayFrame(frame);
        int statusBarHeight = frame.top;
        int width = activity.getWindowManager().getDefaultDisplay().getWidth();
        int height = activity.getWindowManager().getDefaultDisplay().getHeight();

        Bitmap b = Bitmap.createBitmap(b1, 0, statusBarHeight, width, height - statusBarHeight);
        view.destroyDrawingCache();
        return b;
    }

    public Bitmap fastblur(Bitmap sentBitmap, int radius) {
        Bitmap bitmap = sentBitmap.copy(sentBitmap.getConfig(), true);

        if (radius < 1) {
            return (null);
        }

        int w = bitmap.getWidth();
        int h = bitmap.getHeight();

        int[] pix = new int[w * h];
        Log.e("pix", w + " " + h + " " + pix.length);
        bitmap.getPixels(pix, 0, w, 0, 0, w, h);

        int wm = w - 1;
        int hm = h - 1;
        int wh = w * h;
        int div = radius + radius + 1;

        int r[] = new int[wh];
        int g[] = new int[wh];
        int b[] = new int[wh];
        int rsum, gsum, bsum, x, y, i, p, yp, yi, yw;
        int vmin[] = new int[Math.max(w, h)];

        int divsum = (div + 1) >> 1;
        divsum *= divsum;
        int dv[] = new int[256 * divsum];
        for (i = 0; i < 256 * divsum; i++) {
            dv[i] = (i / divsum);
        }

        yw = yi = 0;

        int[][] stack = new int[div][3];
        int stackpointer;
        int stackstart;
        int[] sir;
        int rbs;
        int r1 = radius + 1;
        int routsum, goutsum, boutsum;
        int rinsum, ginsum, binsum;

        for (y = 0; y < h; y++) {
            rinsum = ginsum = binsum = routsum = goutsum = boutsum = rsum = gsum = bsum = 0;
            for (i = -radius; i <= radius; i++) {
                p = pix[yi + Math.min(wm, Math.max(i, 0))];
                sir = stack[i + radius];
                sir[0] = (p & 0xff0000) >> 16;
                sir[1] = (p & 0x00ff00) >> 8;
                sir[2] = (p & 0x0000ff);
                rbs = r1 - Math.abs(i);
                rsum += sir[0] * rbs;
                gsum += sir[1] * rbs;
                bsum += sir[2] * rbs;
                if (i > 0) {
                    rinsum += sir[0];
                    ginsum += sir[1];
                    binsum += sir[2];
                } else {
                    routsum += sir[0];
                    goutsum += sir[1];
                    boutsum += sir[2];
                }
            }
            stackpointer = radius;

            for (x = 0; x < w; x++) {

                r[yi] = dv[rsum];
                g[yi] = dv[gsum];
                b[yi] = dv[bsum];

                rsum -= routsum;
                gsum -= goutsum;
                bsum -= boutsum;

                stackstart = stackpointer - radius + div;
                sir = stack[stackstart % div];

                routsum -= sir[0];
                goutsum -= sir[1];
                boutsum -= sir[2];

                if (y == 0) {
                    vmin[x] = Math.min(x + radius + 1, wm);
                }
                p = pix[yw + vmin[x]];

                sir[0] = (p & 0xff0000) >> 16;
                sir[1] = (p & 0x00ff00) >> 8;
                sir[2] = (p & 0x0000ff);

                rinsum += sir[0];
                ginsum += sir[1];
                binsum += sir[2];

                rsum += rinsum;
                gsum += ginsum;
                bsum += binsum;

                stackpointer = (stackpointer + 1) % div;
                sir = stack[(stackpointer) % div];

                routsum += sir[0];
                goutsum += sir[1];
                boutsum += sir[2];

                rinsum -= sir[0];
                ginsum -= sir[1];
                binsum -= sir[2];

                yi++;
            }
            yw += w;
        }
        for (x = 0; x < w; x++) {
            rinsum = ginsum = binsum = routsum = goutsum = boutsum = rsum = gsum = bsum = 0;
            yp = -radius * w;
            for (i = -radius; i <= radius; i++) {
                yi = Math.max(0, yp) + x;

                sir = stack[i + radius];

                sir[0] = r[yi];
                sir[1] = g[yi];
                sir[2] = b[yi];

                rbs = r1 - Math.abs(i);

                rsum += r[yi] * rbs;
                gsum += g[yi] * rbs;
                bsum += b[yi] * rbs;

                if (i > 0) {
                    rinsum += sir[0];
                    ginsum += sir[1];
                    binsum += sir[2];
                } else {
                    routsum += sir[0];
                    goutsum += sir[1];
                    boutsum += sir[2];
                }

                if (i < hm) {
                    yp += w;
                }
            }
            yi = x;
            stackpointer = radius;
            for (y = 0; y < h; y++) {
                // Preserve alpha channel: ( 0xff000000 & pix[yi] )
                pix[yi] = (0xff000000 & pix[yi]) | (dv[rsum] << 16) | (dv[gsum] << 8) | dv[bsum];

                rsum -= routsum;
                gsum -= goutsum;
                bsum -= boutsum;

                stackstart = stackpointer - radius + div;
                sir = stack[stackstart % div];

                routsum -= sir[0];
                goutsum -= sir[1];
                boutsum -= sir[2];

                if (x == 0) {
                    vmin[y] = Math.min(y + r1, hm) * w;
                }
                p = x + vmin[y];

                sir[0] = r[p];
                sir[1] = g[p];
                sir[2] = b[p];

                rinsum += sir[0];
                ginsum += sir[1];
                binsum += sir[2];

                rsum += rinsum;
                gsum += ginsum;
                bsum += binsum;

                stackpointer = (stackpointer + 1) % div;
                sir = stack[stackpointer];

                routsum += sir[0];
                goutsum += sir[1];
                boutsum += sir[2];

                rinsum -= sir[0];
                ginsum -= sir[1];
                binsum -= sir[2];

                yi += w;
            }
        }

        Log.e("pix", w + " " + h + " " + pix.length);
        bitmap.setPixels(pix, 0, w, 0, 0, w, h);

        return (bitmap);
    }
//    @OnClick({R.id.submit, R.id.clear})
//    void onViewClicked(View view) {
//        switch (view.getId()) {
//            case R.id.submit:
//                if (clickListener != null)
//                    clickListener.onConfirmClicked();
//                break;
//            case R.id.clear:
//                dismiss();
//                break;
//
//        }
//    }

    public void setOnItemClickListener(DialogListener listener) {
        this.clickListener = listener;
    }
}
