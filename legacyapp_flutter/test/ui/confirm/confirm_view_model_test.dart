import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legacyapp_flutter/data/repositories/confirm_repository.dart';
import 'package:legacyapp_flutter/domain/models/form_data.dart';
import 'package:legacyapp_flutter/ui/confirm/view_models/confirm_view_model.dart';

class _ThrowingRepository implements ConfirmRepository {
  @override
  Future<FormDataModel> load() async => throw Exception('channel missing');

  @override
  Future<bool> submit(FormDataModel data) async => throw Exception('offline');
}

void main() {
  test('load stores the fetched data', () async {
    final ConfirmViewModel viewModel =
        ConfirmViewModel(FakeConfirmRepository());

    expect(viewModel.status, ConfirmStatus.loading);
    await viewModel.load();

    expect(viewModel.status, ConfirmStatus.ready);
    expect(viewModel.formData?.name, 'Taro');
  });

  test('load surfaces a failure instead of throwing', () async {
    final ConfirmViewModel viewModel = ConfirmViewModel(_ThrowingRepository());

    await viewModel.load();

    expect(viewModel.status, ConfirmStatus.loadFailed);
    expect(viewModel.formData, isNull);
  });

  test('submit sends the loaded data', () async {
    final FakeConfirmRepository repository = FakeConfirmRepository();
    final ConfirmViewModel viewModel = ConfirmViewModel(repository);
    await viewModel.load();

    expect(await viewModel.submit(), isTrue);
    expect(repository.submitted.single.name, 'Taro');
    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.submitFailed, isFalse);
  });

  test('submit reports a failed response', () async {
    final ConfirmViewModel viewModel =
        ConfirmViewModel(FakeConfirmRepository(submitResult: false));
    await viewModel.load();

    expect(await viewModel.submit(), isFalse);
    expect(viewModel.submitFailed, isTrue);

    viewModel.clearSubmitFailure();
    expect(viewModel.submitFailed, isFalse);
  });

  test('submit reports a thrown error as a failure', () async {
    final ConfirmViewModel viewModel = ConfirmViewModel(_ThrowingRepository());
    // load は失敗するため、送信対象が無い状態になる
    await viewModel.load();

    expect(await viewModel.submit(), isFalse);
  });

  test('submit is ignored while a submission is in flight', () async {
    final _SlowRepository repository = _SlowRepository();
    final ConfirmViewModel viewModel = ConfirmViewModel(repository);
    await viewModel.load();

    final Future<bool> first = viewModel.submit();
    final bool second = await viewModel.submit();

    repository.completeSubmit(true);
    expect(await first, isTrue);
    expect(second, isFalse);
    expect(repository.calls, 1);
  });
}

class _SlowRepository implements ConfirmRepository {
  final List<void Function(bool)> _pending = <void Function(bool)>[];
  int calls = 0;

  @override
  Future<FormDataModel> load() async =>
      const FormDataModel(name: 'a', email: 'b', message: 'c');

  @override
  Future<bool> submit(FormDataModel data) {
    calls++;
    final Completer<bool> completer = Completer<bool>();
    _pending.add(completer.complete);
    return completer.future;
  }

  void completeSubmit(bool value) {
    for (final void Function(bool) complete in _pending) {
      complete(value);
    }
    _pending.clear();
  }
}
