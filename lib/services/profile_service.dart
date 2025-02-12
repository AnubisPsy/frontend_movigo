// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ProfileService {
  final String baseUrl = 'http://192.168.0.112:3000/api/perfil';

  //final String baseUrl = 'http://192.168.1.219:3000/api/perfil';

  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      debugPrint('Obteniendo datos del perfil...');
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      debugPrint('Error en getProfile: $e');
      throw Exception('Error al obtener perfil: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String userId, {
    String? nombre,
    String? apellido,
  }) async {
    try {
      debugPrint('Actualizando perfil...');
      final response = await http.put(
        Uri.parse('$baseUrl/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          if (nombre != null) 'nombre': nombre,
          if (apellido != null) 'apellido': apellido,
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      debugPrint('Error en updateProfile: $e');
      throw Exception('Error al actualizar perfil: $e');
    }
  }
}
