package com.example.legacyapp.flutter;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

/**
 * Flutter画面を表示する唯一のActivity。
 *
 * <p>画面ごとにActivityを作らないのが要点。どの画面を表示するかは
 * {@link FlutterHost} が渡した初期ルートで決まるため、画面をFlutter化しても
 * このクラスには手を入れない。
 *
 * <p>チャネルの登録場所としても機能する。ハンドラがActivityを必要とする
 * （画面遷移など）ため、エンジン生成時ではなくここで登録する。
 */
public class FlutterScreenActivity extends FlutterActivity {

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        // プラグインの登録はここで行われる。独自のチャネルはその後に登録する。
        super.configureFlutterEngine(flutterEngine);
        NativeServices.attach(this, flutterEngine);
    }
}
