package com.example.legacyapp.flutter;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.example.legacyapp.BaseActivity;
import com.example.legacyapp.FormData;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * Flutter側のServiceに対応するネイティブ側のハンドラ。
 *
 * <p>チャネルは画面単位ではなく機能単位で切る。画面ごとに用意すると画面数だけ
 * ハンドラが増えるが、機能単位なら画面が増えても増えず、機能がFlutterへ移る
 * たびに減っていく。
 */
public final class NativeServices {

    private static final String CHANNEL_LEGACY_STORE = "com.example.legacyapp/legacy_store";
    private static final String CHANNEL_NAVIGATION = "com.example.legacyapp/navigation";

    private NativeServices() {
    }

    public static void attach(@NonNull Activity activity, @NonNull FlutterEngine engine) {
        attachLegacyStore(engine);
        attachNavigation(activity, engine);
    }

    /**
     * 移行前のネイティブコードが保持しているデータを読ませる。
     *
     * <p>このデータの所有者はネイティブのままで、Flutterからは読むだけ。
     * 項目ごとにメソッドを分けず、まとめて返す。
     */
    private static void attachLegacyStore(@NonNull FlutterEngine engine) {
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), CHANNEL_LEGACY_STORE)
                .setMethodCallHandler((call, result) -> {
                    if ("readFormData".equals(call.method)) {
                        FormData data = BaseActivity.sFormData;
                        Map<String, String> values = new HashMap<>();
                        values.put("name", data.name == null ? "" : data.name);
                        values.put("email", data.email == null ? "" : data.email);
                        values.put("message", data.message == null ? "" : data.message);
                        result.success(values);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    /** Flutterの領域から出る遷移をネイティブが引き受ける。 */
    private static void attachNavigation(@NonNull Activity activity, @NonNull FlutterEngine engine) {
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAVIGATION)
                .setMethodCallHandler((call, result) -> {
                    if ("openNative".equals(call.method)) {
                        String screen = call.argument("screen");
                        if (screen == null) {
                            result.error("invalid_argument", "screen is required", null);
                            return;
                        }
                        android.content.Intent intent = NativeRouter.intentFor(activity, screen);
                        if (intent == null) {
                            result.error("unknown_screen", "No native screen for " + screen, null);
                            return;
                        }
                        activity.startActivity(intent);
                        activity.finish();
                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
