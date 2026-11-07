import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';

String appointmentStatusLabel(String status) => switch (status) {
      'agendado' => 'Agendado',
      'concluido' => 'Concluído',
      'cancelado' => 'Cancelado',
      _ => status,
    };

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.status,
    this.showEmployee = false,
    this.action,
  });

  final Appointment appointment;
  final String status;
  final bool showEmployee;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final time = appointmentShopTime(appointment.scheduledAt);
    final price = appointment.total.toStringAsFixed(2).replaceAll('.', ',');
    final details = [
      if (showEmployee && appointment.employeeName.isNotEmpty)
        appointment.employeeName,
      ...appointment.services,
      'R\$ $price',
    ];
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF303030)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(appointment.clientName,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(width: 8),
                Text(time == null ? 'Sem horário' : shopClockLabel(time)),
              ],
            ),
            const SizedBox(height: 4),
            Text(details.join(' · ')),
            Row(
              children: [
                Expanded(
                  child: Text(status,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                if (action != null) action!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
