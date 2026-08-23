package com.example.legacyapp.flutter;

import android.content.Context;
import android.content.Intent;

import com.example.legacyapp.CompleteActivity;
import com.example.legacyapp.ConfirmActivity;

/**
 * 論理的な画面名から、実際に開くネイティブ画面を決める。
 *
 * <p>Flutter側は「完了画面へ行きたい」としか言わず、それがどのActivityかは
 * 知らない。
 */
public final class NativeRouter {

    public static final String SCREEN_CONFIRM = "confirm";
    public static final String SCREEN_COMPLETE = "complete";

    private NativeRouter() {
    }

    public static Intent intentFor(Context context, String screen) {
        switch (screen) {
            case SCREEN_CONFIRM:
                return new Intent(context, ConfirmActivity.class);
            case SCREEN_COMPLETE:
                return new Intent(context, CompleteActivity.class);
            default:
                return null;
        }
    }
}
