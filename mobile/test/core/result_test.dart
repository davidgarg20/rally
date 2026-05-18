import 'package:flutter_test/flutter_test.dart';
import 'package:rally/core/result.dart';
import 'package:rally/core/errors.dart';

void main() {
  test('Ok holds value', () {
    final r = Result<int, AppError>.ok(42);
    expect(r.isOk, true);
    expect(r.valueOrNull, 42);
    expect(r.errorOrNull, null);
  });

  test('Err holds error', () {
    final e = AppError(code: 'x', message: 'm', httpStatus: 400);
    final r = Result<int, AppError>.err(e);
    expect(r.isOk, false);
    expect(r.valueOrNull, null);
    expect(r.errorOrNull, e);
  });

  test('fold dispatches', () {
    final ok = Result<int, AppError>.ok(7);
    expect(ok.fold(onOk: (v) => 'v=$v', onErr: (e) => 'e=${e.code}'), 'v=7');
  });
}
