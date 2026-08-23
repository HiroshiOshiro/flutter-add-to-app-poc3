import Flutter
import FlutterPluginRegistrant
import UIKit

/// Flutterのエンジンを一元管理する唯一の場所。
///
/// FlutterEngineGroup から生成したエンジンはスナップショット・GPUコンテキスト・
/// フォントを共有するため、2つ目以降の増分はごくわずかで済む。
///
/// ネイティブ側が知っているのはルート名だけで、その名前に対応する画面が
/// Flutter側のどのWidgetかは知らない。
@objc final class FlutterHost: NSObject {

    private static let engineGroup = FlutterEngineGroup(
        name: "legacyapp_engine_group",
        project: nil
    )

    @objc static func viewController(route: String) -> UIViewController {
        // entrypoint に nil を渡すと main() が使われる
        let engine = engineGroup.makeEngine(
            withEntrypoint: nil,
            libraryURI: nil,
            initialRoute: route
        )
        GeneratedPluginRegistrant.register(with: engine)
        return FlutterScreenViewController(engine: engine)
    }
}
