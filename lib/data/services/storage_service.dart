// lib/core/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    //print('Token guardado: $token'); // Debug
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    //print('Token recuperado: $token'); // Debug
    return token;
  }

  // Guardar datos del usuario
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userData['id']);
  }

  // Obtener datos del usuario
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  // Limpiar datos (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> saveActiveTrip(Map<String, dynamic> trip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_trip', jsonEncode(trip));
  }

  static Future<Map<String, dynamic>?> getActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final tripJson = prefs.getString('active_trip');

    if (tripJson != null) {
      try {
        // Simplemente obtener del almacenamiento local
        return StorageService.getActiveTrip();
      } catch (e) {
        print('Error en getActiveTrip: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> removeActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_trip');
  }

  // En storage_service.dart
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}
