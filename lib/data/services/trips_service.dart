import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigo_frontend/core/constants/api_constants.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';

class TripsService {
  final StorageService _storageService = StorageService();

  // Obtener historial de viajes
  Future<List<Map<String, dynamic>>> getTripHistory({
    DateTime? startDate,
    DateTime? endDate,
    double? minCost,
    double? maxCost,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Construir la URL para la API
      String url = '${ApiConstants.baseUrl}${ApiConstants.tripHistory}';

      // Realizar la petición HTTP
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          // Convertir la respuesta en una lista
          List<dynamic> tripsList = jsonResponse['data'];

          // Mapear la respuesta al formato que necesitamos
          List<Map<String, dynamic>> trips = tripsList.map((trip) {
            // Parsear la fecha y hora
            String fechaStr = trip['fecha'];
            String horaInicioStr = trip['hora_inicio'] ?? '00:00';

            // Crear un objeto DateTime
            List<String> fechaParts = fechaStr.split('/');
            List<String> horaParts = horaInicioStr.split(':');

            DateTime tripDate = DateTime(
              int.parse(fechaParts[2]),
              int.parse(fechaParts[1]),
              int.parse(fechaParts[0]),
              int.parse(horaParts[0]),
              int.parse(horaParts[1]),
            );

            // Convertir el costo a double
            double cost = 0.0;
            if (trip['costo'] != null) {
              cost = double.tryParse(trip['costo'].toString()) ?? 0.0;
            }

            // Construir el objeto de viaje en el formato que espera la UI
            return {
              'id': trip['id'] ?? 'ID-${DateTime.now().millisecondsSinceEpoch}',
              'origin': trip['origen'] ?? 'Origen desconocido',
              'destination': trip['destino'] ?? 'Destino desconocido',
              'date': tripDate,
              'driverName': trip['conductor'] ?? 'Conductor desconocido',
              'vehicleInfo': trip['vehiculo'] ??
                  'Información no disponible', // Este es el campo clave
              'cost': cost,
              'hora_inicio': trip['hora_inicio'],
              'hora_fin': trip['hora_fin'],
            };
          }).toList();

          // Aplicar filtros en el lado del cliente si es necesario
          // (ideal sería hacerlo en el backend, pero por ahora lo hacemos aquí)
          return _applyFilters(trips, startDate, endDate, minCost, maxCost);
        } else {
          throw Exception('Error en la respuesta del servidor');
        }
      } else {
        throw Exception('Error al cargar historial: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getTripHistory: $e');
      throw Exception('Error al cargar el historial de viajes');
    }
  }

  // Método auxiliar para aplicar filtros en el lado del cliente
  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> trips,
    DateTime? startDate,
    DateTime? endDate,
    double? minCost,
    double? maxCost,
  ) {
    return trips.where((trip) {
      // Filtrar por fecha
      bool dateFilter = true;
      final tripDate = trip['date'] as DateTime;

      if (startDate != null) {
        dateFilter = dateFilter &&
            tripDate.isAfter(startDate.subtract(const Duration(days: 1)));
      }

      if (endDate != null) {
        dateFilter = dateFilter &&
            tripDate.isBefore(endDate.add(const Duration(days: 1)));
      }

      // Filtrar por costo
      bool costFilter = true;
      final cost = trip['cost'] as double;

      if (minCost != null) {
        costFilter = costFilter && cost >= minCost;
      }

      if (maxCost != null) {
        costFilter = costFilter && cost <= maxCost;
      }

      return dateFilter && costFilter;
    }).toList();
  }
}
