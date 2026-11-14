import 'package:barbearia_frontend/features/appointments/data/offline_booking_repository.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/core/storage/app_database.dart'
    show AppDatabase;

class ServiceRepository {
  final BarbershopApi api = BarbershopApi();
  final _offlineBookings = OfflineBookingRepository();
  bool offline = false;
  Future<void> save(Service service, {required bool creating}) =>
      api.saveService(service, creating: creating);

  Future<void> setEnabled(Service service, bool enabled) =>
      api.setServiceEnabled(service.id, enabled);
  Future<void> delete(String id) => api.deleteService(id);

  Future<List<Service>> list() async {
    if (AppDatabase.available) {
      try {
        return await _offlineBookings.services();
      } finally {
        offline = _offlineBookings.offline;
      }
    }
    return api.services();
  }
}
