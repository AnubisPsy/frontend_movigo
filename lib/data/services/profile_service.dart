import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:movigo_frontend/core/constants/api_constants.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      // Decodificar el token para obtener el ID del usuario
      final userData = JwtDecoder.decode(token);
      final userId = userData['id'];

      print('Obteniendo perfil para usuario ID: $userId'); // Debug

      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.getUserProfile}/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener el perfil');
      }
    } catch (e) {
      print('Error en getUserProfile: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String nombre,
    required String apellido,
    required String email,
  }) async {
    try {
      final userData = JwtDecoder.decode(token);
      final userId = userData['id'];
      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.getUserProfile}/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
        }),
      );

      print('Código de estado: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody;
      } else {
        throw Exception(
            responseBody['message'] ?? 'Error al actualizar el perfil');
      }
    } catch (e) {
      print('Error completo: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userData = JwtDecoder.decode(token);
      final userId = userData['id'];

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updatePassword}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Error al cambiar contraseña');
      }
    } catch (e) {
      print('Error detallado: $e');
      throw Exception('Error al cambiar contraseña: $e');
    }
  }
}
