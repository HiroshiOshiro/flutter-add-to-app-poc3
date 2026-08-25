import 'package:flutter_test/flutter_test.dart';
import 'package:legacyapp_flutter/domain/models/form_data.dart';

void main() {
  const FormDataModel base = FormDataModel(
    name: 'Taro',
    email: 'taro@example.com',
    message: 'hi',
  );

  test('値が同じなら等しい', () {
    expect(
      base,
      const FormDataModel(
        name: 'Taro',
        email: 'taro@example.com',
        message: 'hi',
      ),
    );
    expect(base.hashCode, base.copyWith().hashCode);
  });

  test('copyWith は指定した項目だけ差し替える', () {
    final FormDataModel changed = base.copyWith(name: 'Jiro');

    expect(changed.name, 'Jiro');
    expect(changed.email, base.email);
    expect(changed, isNot(base));
  });

  test('toJson は送信に使う形を返す', () {
    expect(base.toJson(), <String, dynamic>{
      'name': 'Taro',
      'email': 'taro@example.com',
      'message': 'hi',
    });
  });
}
