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
      // Obtener del almacenamiento local
      final prefs = await SharedPreferences.getInstance();
      final tripJson = prefs.getString('active_trip');

      if (tripJson != null) {
        try {
          final tripData = jsonDecode(tripJson);

          // Opcional: Verificar estado actual del viaje
          final tripId = tripData['id'];
          if (tripId != null) {
            try {
              final updatedTrip = await _checkTripStatus(tripId);
              if (updatedTrip != null) {
                // Si el viaje fue completado o cancelado, limpiar almacenamiento
                if (updatedTrip['estado'] == 4 || updatedTrip['estado'] == 5) {
                  await _removeActiveTrip();
                  return null;
                }

                // Solo devolver el viaje si está en estado activo (1, 2 o 3)
                if (updatedTrip['estado'] >= 1 && updatedTrip['estado'] <= 3) {
                  // Actualizar el almacenamiento con datos frescos
                  await _saveActiveTrip(updatedTrip);
                  return updatedTrip;
                }

                // Si el estado no es activo, limpiar y devolver null
                await _removeActiveTrip();
                return null;
              }
            } catch (e) {
              print("Error al verificar estado: $e");
              // Limpiar datos potencialmente obsoletos
              await _removeActiveTrip();
              return null;
            }
          }

          // Verificar estado del viaje antes de devolverlo
          if (tripData['estado'] >= 1 && tripData['estado'] <= 3) {
            return tripData;
          } else {
            // Si no es un estado activo, limpiar y devolver null
            await _removeActiveTrip();
            return null;
          }
        } catch (e) {
          print("Error al decodificar viaje: $e");
          await _removeActiveTrip();
          return null;
        }
      }

      return null;
    } catch (e) {
      print('Error en getActiveTrip: $e');
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

  Future<void> saveActiveTrip(Map<String, dynamic> trip) async {
    return _saveActiveTrip(trip);
  }

  // Métodos para manejar el almacenamiento local de viajes activos
  Future<void> _saveActiveTrip(Map<String, dynamic> trip) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Depurar los datos que se están guardando
      print("💾 Guardando datos de viaje en almacenamiento local");
      print("💾 Conductor presente: ${trip['Conductor'] != null}");
      print("💾 Vehículo presente: ${trip['Vehiculo'] != null}");

      await prefs.setString('active_trip', jsonEncode(trip));
    } catch (e) {
      print("Error al guardar viaje activo: $e");
    }
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

  // Añadir estos métodos a la clase PassengerService

  Future<Map<String, dynamic>> proponerPrecio(
      String tripId, double precio) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/viajes/$tripId/proponer-precio';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'precio_propuesto': precio,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('Error al proponer precio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en proponerPrecio: $e');
      throw Exception('Error al proponer precio');
    }
  }

  Future<Map<String, dynamic>> aceptarContrapropuesta(String tripId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/viajes/$tripId/aceptar-propuesta';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception(
            'Error al aceptar contraoferta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en aceptarContrapropuesta: $e');
      throw Exception('Error al aceptar contraoferta');
    }
  }

  Future<Map<String, dynamic>> rechazarPropuesta(String tripId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/viajes/$tripId/rechazar-propuesta';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('Error al rechazar propuesta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en rechazarPropuesta: $e');
      throw Exception('Error al rechazar propuesta');
    }
  }
}
