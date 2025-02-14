import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/viaje_estado.dart'; // Si necesitas los modelos

class AuthService {
  //final String baseUrl = 'http://192.168.0.112:3000/api/auth';
  final String baseUrl = 'http://192.168.1.219:3000/api/auth';

  static String? _currentUserId;
  static String? get currentUserId => _currentUserId;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('====== DEBUG AUTH SERVICE ======');
      debugPrint('Iniciando login...');
      debugPrint('Email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'contraseña': password,
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Guardar en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', data['user']['id']);
        await prefs.setInt('userRole', data['user']['rol']);

        debugPrint(
            'userId guardado en SharedPreferences: ${data['user']['id']}');
        debugPrint(
            'userRole guardado en SharedPreferences: ${data['user']['rol']}');

        return data;
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      debugPrint('Error en login: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Registro
  Future<Map<String, dynamic>> register(
      String email, String password, String name, String lastName) async {
    try {
      debugPrint('Iniciando registro...');
      debugPrint('Datos a enviar: $email, $name, $lastName');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'contraseña': password,
          'nombre': name,
          'apellido': lastName,
          'rol': 1,
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      debugPrint('Error en registro: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Recuperar contraseña
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      debugPrint('Enviando solicitud de recuperación: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
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
      debugPrint('Error en forgotPassword: $e');
      throw Exception('Error al procesar la solicitud');
    }
  }

  // Resetear contraseña
  Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword) async {
    try {
      debugPrint('Enviando reset password - Email: $email, Code: $code');
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
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
      debugPrint('Error en resetPassword: $e');
      throw Exception('Error al restablecer contraseña: $e');
    }
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Código inválido');
    }
  }

  Future<Map<String, dynamic>> updatePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      debugPrint('Iniciando actualización de contraseña...');
      final response = await http.put(
        Uri.parse('$baseUrl/password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
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
      debugPrint('Error en updatePassword: $e');
      throw Exception('Error al actualizar contraseña: $e');
    }
  }
}
