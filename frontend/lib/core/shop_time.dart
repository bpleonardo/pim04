// Horário atual de São Paulo usado pela agenda da barbearia.
const shopUtcOffset = Duration(hours: -3);

DateTime shopTime(DateTime instant) => instant.toUtc().add(shopUtcOffset);

DateTime shopSlotToUtc(DateTime day, int hour, int minute) =>
    DateTime.utc(day.year, day.month, day.day, hour, minute)
        .subtract(shopUtcOffset);

// Datas sem fuso explícito representam a hora de parede da barbearia.
DateTime? appointmentShopTime(String value) {
  final text = value.trim();
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  if (parsed.isUtc) return shopTime(parsed);
  return DateTime.tryParse('${text}Z') ?? parsed;
}

String shopClockLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String shopDateLabel(DateTime day) {
  const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return '${weekdays[day.weekday - 1]}, ${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
}
