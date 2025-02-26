import 'package:shared_preferences/shared_preferences.dart';

class ConductorService {
  // Actualizar disponibilidad del conductor
  static Future<bool> updateAvailability(bool isAvailable) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driverAvailable', isAvailable);
      return true;
    } catch (e) {
      print('Error en updateAvailability: $e');
      throw Exception('Error al actualizar disponibilidad');
    }
  }

  // Obtener estado de disponibilidad actual
  static Future<bool> getAvailabilityStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('driverAvailable') ?? false;
    } catch (e) {
      print('Error en getAvailabilityStatus: $e');
      return false;
    }
  }
}
