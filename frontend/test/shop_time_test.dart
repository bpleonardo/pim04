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
  test('Horários UTC, com GMT-3 e locais exibem a mesma hora', () {
    for (final value in [
      '2026-11-06T21:00:00Z',
      '2026-11-06T18:00:00-03:00',
      '2026-11-06T18:00:00',
    ]) {
      expect(shopClockLabel(appointmentShopTime(value)!), '18:00');
    }
    expect(appointmentShopTime('inválido'), isNull);
  });
}
