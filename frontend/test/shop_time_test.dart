import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Converte o horário da barbearia para UTC, inclusive na virada do dia',
      () {
    final day = DateTime(2026, 11, 6);
    expect(
        shopSlotToUtc(day, 9, 0).toIso8601String(), '2026-11-06T12:00:00.000Z');
    final lateSlot = shopSlotToUtc(day, 22, 30);
    expect(lateSlot, DateTime.utc(2026, 11, 7, 1, 30));
    expect(shopTime(lateSlot), DateTime.utc(2026, 11, 6, 22, 30));
  });
}
