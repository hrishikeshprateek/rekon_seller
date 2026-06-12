package com.reckon.reckonorders.Utils;
/*
 * Created by Manvendra Kumar Singh on 16/12/2018.
 */

import static android.content.Context.INPUT_METHOD_SERVICE;

import android.app.Activity;
import android.os.Handler;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;

import java.util.concurrent.atomic.AtomicBoolean;

public class KeyboardUtils {
    public static AtomicBoolean isKeyBoardOpen= new AtomicBoolean(false);

    public static void setupUI(View view, final Activity activity) {
        if (!(view instanceof EditText)) {
            view.setOnTouchListener(new View.OnTouchListener() {
                public boolean onTouch(View v, MotionEvent event) {
                    hideSoftKeyboard(activity);
                    return false;
                }
            });
        }
        if (view instanceof ViewGroup) {
            for (int i = 0; i < ((ViewGroup) view).getChildCount(); i++) {
                View innerView = ((ViewGroup) view).getChildAt(i);
                setupUI(innerView, activity);
            }
        }
    }

    public static void hideSoftKeyboard(Activity activity) {
        try {
            InputMethodManager inputMethodManager = (InputMethodManager) activity.getSystemService(Activity.INPUT_METHOD_SERVICE);
            View view = activity.getCurrentFocus();
            if (view != null) {
                inputMethodManager.hideSoftInputFromWindow(view.getWindowToken(), 0);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void openSoftKeyboard(Activity activity, EditText editText) {
        try {
            new Handler().post(
                    () -> {
                        InputMethodManager inputMethodManager = (InputMethodManager) activity.getSystemService(INPUT_METHOD_SERVICE);
                        inputMethodManager.toggleSoftInputFromWindow(editText.getApplicationWindowToken(), InputMethodManager.SHOW_FORCED, 0);
                        editText.requestFocus();
                    });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    public static boolean isSoftKeyboardOpen(Activity activity, View view) {
        view.getViewTreeObserver().addOnGlobalLayoutListener(() -> {
            int heightDiff = view.getRootView().getHeight() - view.getHeight();
            isKeyBoardOpen.set(heightDiff > ReckonUtils.dpToPx(activity, 200));
        });
        return isKeyBoardOpen.get();
    }
}
