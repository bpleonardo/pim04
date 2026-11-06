// Horário atual de São Paulo usado pela agenda da barbearia.
const shopUtcOffset = Duration(hours: -3);

DateTime shopTime(DateTime instant) => instant.toUtc().add(shopUtcOffset);

DateTime shopSlotToUtc(DateTime day, int hour, int minute) =>
    DateTime.utc(day.year, day.month, day.day, hour, minute)
        .subtract(shopUtcOffset);
