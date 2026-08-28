package com.example.legacyapp.flutter

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.FlutterEngineGroupCache

/**
 * Flutterのエンジンを一元管理する唯一の場所。
 *
 * 画面ごとにFlutterEngineを個別に生成すると1つあたり数十MBを消費する。
 * FlutterEngineGroupから生成したエンジンはスナップショット・GPUコンテキスト・
 * フォントを共有するため、2つ目以降の増分はごくわずかで済む。
 *
 * **NewEngineInGroupIntentBuilder を使う理由**: グループから
 * `createAndRunEngine` でエンジンを作る方式だと、その時点でDartが走り出す。
 * Activityがチャネルを登録するのはその後になるため、Dart側が起動直後に
 * チャネルを呼ぶと MissingPluginException になる。この方式なら
 * FlutterActivityがエンジン生成・チャネル登録・Dart実行の順序を保証する。
 */
object FlutterHost {

    private const val ENGINE_GROUP_ID = "legacyapp_engine_group"

    @JvmStatic
    fun intentFor(context: Context, route: String): Intent {
        val cache = FlutterEngineGroupCache.getInstance()
        if (cache.get(ENGINE_GROUP_ID) == null) {
            cache.put(ENGINE_GROUP_ID, FlutterEngineGroup(context.applicationContext))
        }
        return FlutterActivity.NewEngineInGroupIntentBuilder(
            FlutterScreenActivity::class.java,
            ENGINE_GROUP_ID,
        )
            .initialRoute(route)
            .backgroundMode(FlutterActivityLaunchConfigs.BackgroundMode.opaque)
            .build(context)
    }
}
