import 'package:flutter/services.dart';

/// Flutterの領域**から出る**ときにネイティブへ依頼するService。
///
/// Flutter化済みの画面同士の遷移はFlutterの `Navigator` が担当するため、
/// このチャネルを使うのはネイティブ画面へ抜けるときだけ。全画面のFlutter化が
/// 完了した時点でこのチャネル自体が不要になる。
class NavigationService {
  const NavigationService([
    this._channel = const MethodChannel(channelName),
  ]);

  static const String channelName = 'com.example.legacyapp/navigation';

  final MethodChannel _channel;

  /// まだFlutter化されていないネイティブ画面へ遷移する。
  ///
  /// [screen] はネイティブ側が解釈する論理的な画面名。Flutter側は遷移方法
  /// （Activityの起動かpushViewControllerか）を知らない。
  Future<void> openNative(String screen) {
    return _channel.invokeMethod<void>(
      'openNative',
      <String, Object?>{'screen': screen},
    );
  }
}
