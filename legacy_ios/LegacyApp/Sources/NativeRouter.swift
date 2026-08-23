import UIKit

/// 論理的な画面名から、実際に開くネイティブ画面を決める。
///
/// Flutter側は「完了画面へ行きたい」としか言わず、それがどのViewControllerかは
/// 知らない。
enum NativeRouter {

    static let screenConfirm = "confirm"
    static let screenComplete = "complete"

    static func viewController(for screen: String) -> UIViewController? {
        switch screen {
        case screenConfirm:
            return ConfirmViewController()
        case screenComplete:
            return CompleteViewController()
        default:
            return nil
        }
    }
}
