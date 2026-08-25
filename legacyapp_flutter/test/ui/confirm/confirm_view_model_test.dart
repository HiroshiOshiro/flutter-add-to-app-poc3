import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacyapp_flutter/data/repositories/confirm_repository.dart';
import 'package:legacyapp_flutter/domain/models/form_data.dart';
import 'package:legacyapp_flutter/ui/confirm/view_models/confirm_view_model.dart';

/// 取得に失敗する。ネイティブ側のハンドラが無い状況に相当する。
class _LoadFailsRepository implements ConfirmRepository {
  @override
  Future<FormDataModel> load() async => throw Exception('channel missing');

  @override
  Future<bool> submit(FormDataModel data) async => false;
}

/// 取得はできるが送信で例外になる。通信断に相当する。
class _SubmitThrowsRepository implements ConfirmRepository {
  @override
  Future<FormDataModel> load() async =>
      const FormDataModel(name: 'a', email: 'b', message: 'c');

  @override
  Future<bool> submit(FormDataModel data) async => throw Exception('offline');
}

class _SlowRepository implements ConfirmRepository {
  final List<Completer<bool>> _pending = <Completer<bool>>[];
  int calls = 0;

  @override
  Future<FormDataModel> load() async =>
      const FormDataModel(name: 'a', email: 'b', message: 'c');

  @override
  Future<bool> submit(FormDataModel data) {
    calls++;
    final Completer<bool> completer = Completer<bool>();
    _pending.add(completer);
    return completer.future;
  }

  void completeSubmit(bool value) {
    for (final Completer<bool> completer in _pending) {
      completer.complete(value);
    }
    _pending.clear();
  }
}

/// Repositoryを差し替えたコンテナを作る。
ProviderContainer _container(ConfirmRepository repository) {
  final ProviderContainer container = ProviderContainer(
    overrides: [confirmRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('formDataProvider は取得した値を返す', () async {
    final ProviderContainer container = _container(FakeConfirmRepository());

    expect(
      container.read(formDataProvider),
      isA<AsyncLoading<FormDataModel>>(),
    );

    final FormDataModel data = await container.read(formDataProvider.future);
    expect(data.name, 'Taro');
  });

  test('formDataProvider は失敗をAsyncErrorとして持つ', () async {
    final ProviderContainer container = _container(_LoadFailsRepository());

    // 失敗した .future は待てないため、購読して状態が確定するまで進める。
    container.listen(formDataProvider, (_, _) {});
    await pumpEventQueue();

    expect(container.read(formDataProvider).hasError, isTrue);
  });

  test('submit は取得済みの値を送る', () async {
    final FakeConfirmRepository repository = FakeConfirmRepository();
    final ProviderContainer container = _container(repository);
    await container.read(formDataProvider.future);

    expect(
      await container.read(submitControllerProvider.notifier).submit(),
      isTrue,
    );
    expect(repository.submitted.single.name, 'Taro');
    expect(container.read(submitControllerProvider), isFalse);
  });

  test('submit は失敗レスポンスをfalseで返す', () async {
    final ProviderContainer container = _container(
      FakeConfirmRepository(submitResult: false),
    );
    await container.read(formDataProvider.future);

    expect(
      await container.read(submitControllerProvider.notifier).submit(),
      isFalse,
    );
  });

  test('submit は例外もfalseとして返す', () async {
    final ProviderContainer container = _container(_SubmitThrowsRepository());
    await container.read(formDataProvider.future);

    expect(
      await container.read(submitControllerProvider.notifier).submit(),
      isFalse,
    );
    expect(container.read(submitControllerProvider), isFalse);
  });

  test('取得できていなければ submit は何も送らない', () async {
    final ProviderContainer container = _container(_LoadFailsRepository());
    container.listen(formDataProvider, (_, _) {});
    await pumpEventQueue();

    expect(
      await container.read(submitControllerProvider.notifier).submit(),
      isFalse,
    );
  });

  test('送信中の呼び出しは無視される', () async {
    final _SlowRepository repository = _SlowRepository();
    final ProviderContainer container = _container(repository);
    await container.read(formDataProvider.future);

    final SubmitController controller = container.read(
      submitControllerProvider.notifier,
    );
    final Future<bool> first = controller.submit();
    final bool second = await controller.submit();

    repository.completeSubmit(true);
    expect(await first, isTrue);
    expect(second, isFalse);
    expect(repository.calls, 1);
  });
}
