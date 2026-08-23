import Flutter
import UIKit

/// Flutter側のServiceに対応するネイティブ側のハンドラ。
///
/// チャネルは画面単位ではなく機能単位で切る。画面ごとに用意すると画面数だけ
/// ハンドラが増えるが、機能単位なら画面が増えても増えず、機能がFlutterへ移る
/// たびに減っていく。
enum NativeServices {

    private static let channelLegacyStore = "com.example.legacyapp/legacy_store"
    private static let channelNavigation = "com.example.legacyapp/navigation"

    static func attach(to engine: FlutterEngine, host: UIViewController) {
        attachLegacyStore(engine: engine)
        attachNavigation(engine: engine, host: host)
    }

    /// 移行前のネイティブコードが保持しているデータを読ませる。
    ///
    /// このデータの所有者はネイティブのままで、Flutterからは読むだけ。
    /// 項目ごとにメソッドを分けず、まとめて返す。
    private static func attachLegacyStore(engine: FlutterEngine) {
        let channel = FlutterMethodChannel(
            name: channelLegacyStore,
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "readFormData":
                let data = BaseViewController.sharedFormData
                result([
                    "name": data.name,
                    "email": data.email,
                    "message": data.message,
                ])
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// Flutterの領域から出る遷移をネイティブが引き受ける。
    private static func attachNavigation(engine: FlutterEngine, host: UIViewController) {
        let channel = FlutterMethodChannel(
            name: channelNavigation,
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { [weak host] call, result in
            guard let host else {
                result(FlutterError(code: "no_host", message: "Host was released", details: nil))
                return
            }
            switch call.method {
            case "openNative":
                guard let arguments = call.arguments as? [String: Any],
                      let screen = arguments["screen"] as? String else {
                    result(FlutterError(code: "invalid_argument",
                                        message: "screen is required", details: nil))
                    return
                }
                guard let next = NativeRouter.viewController(for: screen) else {
                    result(FlutterError(code: "unknown_screen",
                                        message: "No native screen for \(screen)", details: nil))
                    return
                }
                // Flutter画面をスタックに残さず置き換える。ネイティブ⇔Flutterを
                // 往復したときに戻る先が二重にならないようにする。
                if let navigation = host.navigationController {
                    var stack = navigation.viewControllers
                    if let index = stack.firstIndex(of: host) {
                        stack.replaceSubrange(index..<stack.count, with: [next])
                        navigation.setViewControllers(stack, animated: true)
                    } else {
                        navigation.pushViewController(next, animated: true)
                    }
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
