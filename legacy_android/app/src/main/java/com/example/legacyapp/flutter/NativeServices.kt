package com.example.legacyapp.flutter

import android.app.Activity
import com.example.legacyapp.BaseActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter側のServiceに対応するネイティブ側のハンドラ。
 *
 * チャネルは画面単位ではなく機能単位で切る。画面ごとに用意すると画面数だけ
 * ハンドラが増えるが、機能単位なら画面が増えても増えず、機能がFlutterへ移る
 * たびに減っていく。
 */
object NativeServices {

    private const val CHANNEL_NAVIGATION = "com.example.legacyapp/navigation"

    @JvmStatic
    fun attach(activity: Activity, engine: FlutterEngine) {
        attachLegacyStore(engine)
        attachNavigation(activity, engine)
    }

    /**
     * 移行前のネイティブコードが保持しているデータを読ませる。
     *
     * このデータの所有者はネイティブのままで、Flutterからは読むだけ。
     * 項目ごとにメソッドを分けず、まとめて返す。
     *
     * チャネル名とメソッド名は [LegacyStorePigeon] が持つ。Dart側の定義と
     * 食い違えばコンパイルエラーになるため、ここで文字列を書かない。
     */
    private fun attachLegacyStore(engine: FlutterEngine) {
        LegacyStoreApi.setUp(
            engine.dartExecutor.binaryMessenger,
            object : LegacyStoreApi {
                override fun readFormData(): FormDataDto {
                    val data = BaseActivity.sFormData
                    return FormDataDto(
                        name = data.name.orEmpty(),
                        email = data.email.orEmpty(),
                        message = data.message.orEmpty(),
                    )
                }
            },
        )
    }

    /** Flutterの領域から出る遷移をネイティブが引き受ける。 */
    private fun attachNavigation(activity: Activity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAVIGATION)
            .setMethodCallHandler { call, result ->
                if (call.method == "openNative") {
                    val screen = call.argument<String>("screen")
                    if (screen == null) {
                        result.error("invalid_argument", "screen is required", null)
                        return@setMethodCallHandler
                    }
                    val intent = NativeRouter.intentFor(activity, screen)
                    if (intent == null) {
                        result.error("unknown_screen", "No native screen for $screen", null)
                        return@setMethodCallHandler
                    }
                    activity.startActivity(intent)
                    activity.finish()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
