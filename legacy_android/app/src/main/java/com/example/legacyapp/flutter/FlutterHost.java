package com.example.legacyapp.flutter;

import android.content.Context;
import android.content.Intent;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterActivityLaunchConfigs;
import io.flutter.embedding.engine.FlutterEngineGroup;
import io.flutter.embedding.engine.FlutterEngineGroupCache;

/**
 * Flutterのエンジンを一元管理する唯一の場所。
 *
 * <p>画面ごとにFlutterEngineを個別に生成すると1つあたり数十MBを消費する。
 * FlutterEngineGroupから生成したエンジンはスナップショット・GPUコンテキスト・
 * フォントを共有するため、2つ目以降の増分はごくわずかで済む。
 *
 * <p><b>NewEngineInGroupIntentBuilder を使う理由</b>: グループから
 * {@code createAndRunEngine} でエンジンを作る方式だと、その時点でDartが
 * 走り出す。Activityがチャネルを登録するのはその後になるため、Dart側が
 * 起動直後にチャネルを呼ぶと MissingPluginException になる。この方式なら
 * FlutterActivityがエンジン生成・チャネル登録・Dart実行の順序を保証する。
 */
public final class FlutterHost {

    private static final String ENGINE_GROUP_ID = "legacyapp_engine_group";

    private FlutterHost() {
    }

    public static Intent intentFor(Context context, String route) {
        FlutterEngineGroupCache cache = FlutterEngineGroupCache.getInstance();
        if (cache.get(ENGINE_GROUP_ID) == null) {
            cache.put(ENGINE_GROUP_ID, new FlutterEngineGroup(context.getApplicationContext()));
        }
        return new FlutterActivity.NewEngineInGroupIntentBuilder(
                FlutterScreenActivity.class, ENGINE_GROUP_ID)
                .initialRoute(route)
                .backgroundMode(FlutterActivityLaunchConfigs.BackgroundMode.opaque)
                .build(context);
    }
}
