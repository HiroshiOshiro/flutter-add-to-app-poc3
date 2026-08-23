import Flutter
import UIKit

/// Flutter画面を表示する唯一のViewController。
///
/// 画面ごとにViewControllerを作らないのが要点。どの画面を表示するかは
/// `FlutterHost.viewController(route:)` が渡した初期ルートで決まる。
///
/// チャネルの登録場所としても機能する。ハンドラがViewControllerを必要とする
/// （画面遷移など）ため。
final class FlutterScreenViewController: FlutterViewController {

    init(engine: FlutterEngine) {
        super.init(engine: engine, nibName: nil, bundle: nil)
        NativeServices.attach(to: engine, host: self)
    }

    // UIViewControllerの init(coder:) は非failableなので、failableとして
    // オーバーライドするとコンパイルエラーになる。
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }
}
