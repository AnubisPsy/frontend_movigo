// lib/data/services/driver_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigo_frontend/core/constants/api_constants.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';

class DriverService {
  // Obtener viajes disponibles (en estado PENDIENTE)
  Future<List<Map<String, dynamic>>> getAvailableTrips() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/viajes';

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

          // El backend ya está filtrando por estado=1 para conductores,
          // así que no necesitamos filtrar de nuevo aquí
          return tripsList
              .map((trip) => Map<String, dynamic>.from(trip))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al cargar viajes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getAvailableTrips: $e');
      throw Exception('Error al cargar viajes disponibles');
    }
  }

  // Añade este método a la clase DriverService
  Future<Map<String, dynamic>?> getTripById(String tripId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return null;
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
          return Map<String, dynamic>.from(jsonResponse['data']);
        }
      } else {
        print("Error al obtener viaje: ${response.statusCode}");
        print("Respuesta: ${response.body}");
      }
      return null;
    } catch (e) {
      print('Error en getTripById: $e');
      return null;
    }
  }

  // Aceptar un viaje
  Future<Map<String, dynamic>> acceptTrip(String tripId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/viajes/$tripId/tomar';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Map<String, dynamic>.from(jsonResponse['data']);
        } else {
          throw Exception('Error en la respuesta del servidor');
        }
      } else {
        throw Exception('Error al aceptar viaje: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en acceptTrip: $e');
      throw Exception('Error al aceptar el viaje');
    }
  }

  // Iniciar un viaje
  Future<Map<String, dynamic>> startTrip(String tripId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/viajes/$tripId/iniciar';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Map<String, dynamic>.from(jsonResponse['data']);
        } else {
          throw Exception('Error en la respuesta del servidor');
        }
      } else {
        throw Exception('Error al iniciar viaje: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en startTrip: $e');
      throw Exception('Error al iniciar el viaje');
    }
  }

  // Completar un viaje
  Future<Map<String, dynamic>> completeTrip(String tripId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/viajes/$tripId/completar';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Map<String, dynamic>.from(jsonResponse['data']);
        } else {
          throw Exception('Error en la respuesta del servidor');
        }
      } else {
        throw Exception('Error al completar viaje: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en completeTrip: $e');
      throw Exception('Error al completar el viaje');
    }
  }

  // Verificar si hay un viaje activo para el conductor
  Future<Map<String, dynamic>?> getActiveTrip() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return null;
      }

      // Primero obtenemos todos los viajes
      String url = '${ApiConstants.baseUrl}/viajes';

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

          // Filtrar viajes en estado 2 (ACEPTADO) o 3 (EN_CURSO)
          final activeTrips = tripsList.where((trip) {
            final estado = trip['estado'];
            return estado == 2 || estado == 3;
          }).toList();

          print("Viajes activos encontrados: ${activeTrips.length}");

          if (activeTrips.isNotEmpty) {
            return Map<String, dynamic>.from(activeTrips.first);
          }
        }
      } else {
        print("Error en getActiveTrip: ${response.statusCode}");
        print("Respuesta: ${response.body}");
      }

      return null;
    } catch (e) {
      print('Error en getActiveTrip: $e');
      return null;
    }
  }

  // Obtener historial de viajes del conductor
  Future<List<Map<String, dynamic>>> getTripHistory() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
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

          // Imprimir para depuración
          print("Respuesta de historial: ${jsonResponse['data']}");

          return tripsList
              .map((trip) => Map<String, dynamic>.from(trip))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al cargar historial: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getTripHistory: $e');
      throw Exception('Error al cargar el historial de viajes');
    }
  }


  Future<Map<String, dynamic>?> getDriverInfo() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/conductor/info';

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
          return Map<String, dynamic>.from(jsonResponse['data']);
        }
      }

      return null;
    } catch (e) {
      print('Error en getDriverInfo: $e');
      throw Exception('Error al obtener información del conductor');
    }
  }

// Guardar información del conductor
  Future<bool> saveDriverInfo(Map<String, dynamic> info) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/conductor/info';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(info),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['success'] == true;
      } else {
        throw Exception('Error al guardar información: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en saveDriverInfo: $e');
      throw Exception('Error al guardar información del conductor');
    }
  }

// Obtener información del vehículo
  Future<Map<String, dynamic>?> getVehicleInfo() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '${ApiConstants.baseUrl}/vehiculos';

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
          List<dynamic> vehicles = jsonResponse['data'];
          if (vehicles.isNotEmpty) {
            return Map<String, dynamic>.from(vehicles.first);
          }
        }
      }

      return null;
    } catch (e) {
      print('Error en getVehicleInfo: $e');
      throw Exception('Error al obtener información del vehículo');
    }
  }

// Guardar información del vehículo
  Future<bool> saveVehicleInfo(Map<String, dynamic> info) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Primero verificamos si ya tiene un vehículo
      final vehicleInfo = await getVehicleInfo();
      String url;

      if (vehicleInfo != null && vehicleInfo['id'] != null) {
        // Actualizar vehículo existente
        url = '${ApiConstants.baseUrl}/vehiculos/${vehicleInfo['id']}';

        final response = await http.put(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(info),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          return jsonResponse['success'] == true;
        }
      } else {
        // Crear nuevo vehículo
        url = '${ApiConstants.baseUrl}/vehiculos';

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(info),
        );

        if (response.statusCode == 201) {
          final jsonResponse = jsonDecode(response.body);
          return jsonResponse['success'] == true;
        }
      }

      throw Exception('Error al guardar información del vehículo');
    } catch (e) {
      print('Error en saveVehicleInfo: $e');
      throw Exception('Error al guardar información del vehículo');
    }
  }

  // Añadir estos métodos a la clase DriverService

  Future<Map<String, dynamic>> contraproponerPrecio(
      String tripId, double precio) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Depuración
      print('Inicio de contraproponerPrecio: tripId=$tripId, precio=$precio');

      // Verifica que tripId no sea vacío
      if (tripId.isEmpty) {
        print('Error: ID de viaje vacío');
        throw Exception('ID de viaje inválido');
      }

      String url = '${ApiConstants.baseUrl}/viajes/$tripId/contraproponer';

      // Depurar para ver qué valores se están enviando
      print('URL: $url');
      print('Precio a contrapropooner: $precio');
      print('Token disponible: ${token.isNotEmpty ? 'Sí' : 'No'}');

      final bodyJson = jsonEncode({
        'precio_contraoferta': precio,
      });
      print('Body enviado: $bodyJson');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: bodyJson,
      );

      // Depurar la respuesta
      print('Respuesta status: ${response.statusCode}');
      print('Respuesta body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Respuesta parseada: $jsonResponse');

        if (jsonResponse['success'] == true) {
          print('Operación exitosa, retornando datos');
          return jsonResponse['data'];
        } else {
          print('Error reportado por el servidor: ${jsonResponse['message']}');
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else {
        print('Error HTTP: ${response.statusCode}');
        throw Exception(
            'Error al contrapropooner precio: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error detallado en contraproponerPrecio: $e');
      throw Exception('Error al contrapropooner precio: $e');
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
