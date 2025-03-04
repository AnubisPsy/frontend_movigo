// lib/data/services/passenger_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movigo_frontend/core/constants/api_constants.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';

class PassengerService {
  // Solicitar un viaje
  Future<Map<String, dynamic>> requestTrip(
      String origin, String destination) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // URL para solicitar viaje
      String url = '${ApiConstants.baseUrl}/viajes';

      // Petición HTTP
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'origen': origin,
          'destino': destination,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          final tripData = jsonResponse['data'];

          // Guardar el viaje como activo localmente
          await _saveActiveTrip(tripData);

          return tripData;
        } else {
          throw Exception(
              'Error en la respuesta del servidor: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Error al solicitar viaje: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en requestTrip: $e');
      throw Exception('Error al solicitar viaje');
    }
  }

  // Cancelar un viaje
// En PassengerService
  Future<bool> cancelTrip(String tripId) async {
    try {
      print("DEBUG cancelTrip: Iniciando cancelación con ID: $tripId");
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Importante: Comprobar que la URL es correcta
      String url = '${ApiConstants.baseUrl}/viajes/$tripId/cancelar';
      print("DEBUG cancelTrip: URL: $url");

      // Probemos con PUT ya que es lo que vimos en las rutas
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
          "DEBUG cancelTrip: Respuesta - Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          await _removeActiveTrip();
          return true;
        }
        return false;
      } else {
        throw Exception('Error al cancelar viaje: ${response.statusCode}');
      }
    } catch (e) {
      print("DEBUG cancelTrip: Error: $e");
      throw Exception('Error al cancelar viaje');
    }
  }

  // Obtener historial de viajes
  Future<List<Map<String, dynamic>>> getTripHistory() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return [];
      }

      String url = '${ApiConstants.baseUrl}/viajes/historial';

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
          List<dynamic> tripsList = jsonResponse['data'];
          List<Map<String, dynamic>> trips = [];

          for (var trip in tripsList) {
            // Crear un objeto simplificado con solo los campos esenciales
            Map<String, dynamic> tripMap = {
              'id': trip['id'] ?? 'ID desconocido',
              'origin': trip['origen'] ?? 'Origen desconocido',
              'destination': trip['destino'] ?? 'Destino desconocido',
              'date': DateTime.now(), // Fecha por defecto
              'driverName': trip['conductor'] ?? 'Sin conductor',
              'vehicleInfo': trip['vehiculo'] ?? 'Sin vehículo',
              'cost': trip['costo'] != null
                  ? double.tryParse(trip['costo'].toString()) ?? 0.0
                  : 0.0,
              'status': trip['estado_id'] ?? 0,
              'statusName': trip['estado'] ?? 'Desconocido'
            };

            trips.add(tripMap);
          }

          return trips;
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error en getTripHistory: $e');
      return [];
    }
  }

  // Verificar si hay un viaje activo
  Future<Map<String, dynamic>?> getActiveTrip() async {
    try {
      // Verificar primero en el almacenamiento local
      final prefs = await SharedPreferences.getInstance();
      final tripJson = prefs.getString('active_trip');

      // También intentar obtener directamente del servidor
      final token = await StorageService.getToken();
      if (token == null) {
        return null;
      }

      // Obtener historial de viajes del usuario
      String historyUrl = '${ApiConstants.baseUrl}${ApiConstants.tripHistory}';

      final historyResponse = await http.get(
        Uri.parse(historyUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (historyResponse.statusCode == 200) {
        final historyData = jsonDecode(historyResponse.body);
        if (historyData['success'] == true && historyData['data'] != null) {
          List<dynamic> tripsList = historyData['data'];

          // Buscar viajes activos (estados 1, 2 o 3)
          final activeTrips = tripsList.where((trip) {
            final status = trip['estado_id'] ?? 0;
            return status == 1 ||
                status == 2 ||
                status == 3; // Pendiente, Aceptado o En Curso
          }).toList();

          if (activeTrips.isNotEmpty) {
            // Encontramos un viaje activo en el servidor
            final serverTrip = activeTrips.first;

            // Actualizar almacenamiento local
            await _saveActiveTrip(serverTrip);
            return serverTrip;
          }
        }
      }

      // Si no encontramos nada en el servidor pero tenemos local, devolver local
      if (tripJson != null) {
        try {
          final localTrip = jsonDecode(tripJson);
          return localTrip;
        } catch (e) {
          print("Error al decodificar trip JSON: $e");
        }
      }

      return null;
    } catch (e) {
      print('Error completo en getActiveTrip: $e');
      return null;
    }
  }

  // Método auxiliar para verificar estado de un viaje
  Future<Map<String, dynamic>?> _checkTripStatus(String tripId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return null;

      String url = '${ApiConstants.baseUrl}/viajes/$tripId';

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
          return jsonResponse['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error al verificar estado: $e');
      return null;
    }
  }

  // Métodos para manejar el almacenamiento local de viajes activos
  Future<void> _saveActiveTrip(Map<String, dynamic> trip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_trip', jsonEncode(trip));
  }

  Future<void> _removeActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_trip');
  }

  Future<Map<String, dynamic>?> getTripById(String tripId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/viajes/$tripId';

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
          // Actualizar almacenamiento local
          await _saveActiveTrip(jsonResponse['data']);
          return jsonResponse['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error en getTripById: $e');
      return null;
    }
  }
}
