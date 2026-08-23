/// 確認画面が表示する入力内容。
///
/// ネイティブ側が所有しているデータをFlutterへ渡すための型（ガイド6.2節）。
class FormDataModel {
  const FormDataModel({
    required this.name,
    required this.email,
    required this.message,
  });

  factory FormDataModel.fromMap(Map<String, String> map) {
    return FormDataModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      message: map['message'] ?? '',
    );
  }

  final String name;
  final String email;
  final String message;

  Map<String, String> toMap() => <String, String>{
        'name': name,
        'email': email,
        'message': message,
      };

  @override
  String toString() => 'FormDataModel(name: $name, email: $email, message: $message)';
}
