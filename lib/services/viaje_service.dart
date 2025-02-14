import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViajeService {
  //final String baseUrl = 'http://192.168.0.112:3000/api/viajes';

  final String baseUrl = 'http://192.168.1.219:3000/api/viajes';

  Future<Position> _obtenerUbicacionActual() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Servicios de ubicación desactivados');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de ubicación denegados');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> solicitarViaje(Map<String, dynamic> viajeData) async {
    try {
      debugPrint('====== DEBUG VIAJE SERVICE ======');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      debugPrint('userId obtenido de SharedPreferences: $userId');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/solicitar'),
        headers: {
          'Content-Type': 'application/json',
          'user-id': userId,
        },
        body: json.encode({
          ...viajeData,
          'usuario_id': userId,
        }),
      );

      debugPrint('Request headers: ${{
        'Content-Type': 'application/json',
        'user-id': userId
      }}');
      debugPrint(
          'Request body: ${json.encode({...viajeData, 'usuario_id': userId})}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Error al solicitar viaje: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en solicitarViaje: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> obtenerViajeActivo() async {
    try {
      // Usar SharedPreferences en lugar de AuthService.currentUserId
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      debugPrint('====== DEBUG OBTENER VIAJE ACTIVO ======');
      debugPrint('userId desde SharedPreferences: $userId');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Consultando viaje activo para usuario: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/activo/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error en obtenerViajeActivo: $e');
      throw Exception('Error al obtener viaje activo: $e');
    }
  }

  Future<void> cancelarViaje() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/cancelar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'usuario_id': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al cancelar el viaje');
      }
    } catch (e) {
      throw Exception('Error al cancelar el viaje: $e');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerViajesPendientes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pendientes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al obtener viajes pendientes');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> aceptarViaje(String viajeId) async {
    try {
      final conductorId = AuthService.currentUserId;
      if (conductorId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/aceptar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'viaje_id': viajeId,
          'conductor_id': conductorId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al aceptar el viaje');
      }
    } catch (e) {
      throw Exception('Error al aceptar el viaje: $e');
    }
  }
}
