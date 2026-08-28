package com.example.legacyapp.flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Flutter画面を表示する唯一のActivity。
 *
 * 画面ごとにActivityを作らないのが要点。どの画面を表示するかは [FlutterHost] が
 * 渡した初期ルートで決まるため、画面をFlutter化してもこのクラスには手を入れない。
 *
 * チャネルの登録場所としても機能する。ハンドラがActivityを必要とする
 * （画面遷移など）ため、エンジン生成時ではなくここで登録する。
 */
class FlutterScreenActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // プラグインの登録はここで行われる。独自のチャネルはその後に登録する。
        super.configureFlutterEngine(flutterEngine)
        NativeServices.attach(this, flutterEngine)
    }
}
