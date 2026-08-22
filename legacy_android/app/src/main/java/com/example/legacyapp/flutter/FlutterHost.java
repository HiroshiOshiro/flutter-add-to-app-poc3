package com.example.legacyapp.flutter;

import android.content.Context;
import android.content.Intent;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterEngineGroup;
import io.flutter.embedding.engine.dart.DartExecutor;

/**
 * Flutterのエンジンを一元管理する唯一の場所。
 *
 * <p>画面ごとにFlutterEngineを個別に生成すると1つあたり数十MBを消費する。
 * FlutterEngineGroupから生成したエンジンはスナップショット・GPUコンテキスト・
 * フォントを共有するため、2つ目以降の増分はごくわずかで済む。
 *
 * <p>ネイティブ側が知っているのはルート名だけで、その名前に対応する画面が
 * Flutter側のどのWidgetかは知らない。画面をFlutter化するときにネイティブ側へ
 * コードを足さずに済むのはこのため。
 */
public final class FlutterHost {

    private static FlutterEngineGroup engineGroup;

    private FlutterHost() {
    }

    public static Intent intentFor(Context context, String route) {
        Context appContext = context.getApplicationContext();
        if (engineGroup == null) {
            engineGroup = new FlutterEngineGroup(appContext);
        }
        FlutterEngine engine = engineGroup.createAndRunEngine(
                appContext,
                DartExecutor.DartEntrypoint.createDefault(),
                route);

        String engineId = "flutter_engine_" + route;
        FlutterEngineCache.getInstance().put(engineId, engine);
        return FlutterActivity.withCachedEngine(engineId).build(context);
    }
}
