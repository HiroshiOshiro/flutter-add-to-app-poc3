import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_data.freezed.dart';
part 'form_data.g.dart';

/// 確認画面が表示する入力内容。
///
/// ネイティブ側が所有しているデータをFlutterへ渡すための型（手順6.2節）。
/// チャネルを渡ってくる `FormDataDto` からの変換はServiceが行う。
///
/// `copyWith` / `==` / `toString` / `toJson` はFreezedが生成する。生成物は
/// コミットしてあるため、このファイルを変更したときだけ再生成すればよい。
///
/// ```bash
/// dart run build_runner build
/// ```
@freezed
abstract class FormDataModel with _$FormDataModel {
  const factory FormDataModel({
    required String name,
    required String email,
    required String message,
  }) = _FormDataModel;

  factory FormDataModel.fromJson(Map<String, dynamic> json) =>
      _$FormDataModelFromJson(json);
}
