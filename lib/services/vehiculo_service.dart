// lib/services/vehiculo_service.dart
import 'package:dio/dio.dart';
import '../utils/dio_config.dart';
import 'package:flutter/src/foundation/print.dart';

// lib/services/vehiculo_service.dart
class VehiculoService {
  final Dio _dio = DioConfig.getInstance();

  Future<Map<String, dynamic>?> obtenerVehiculoConductor() async {
    try {

      final response = await _dio.get('/vehiculos/conductor');
      debugPrint('Response vehículo: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener vehículo: $e');
      return null;
    }
  }

  Future<void> actualizarVehiculo(Map<String, dynamic> datos) async {
    try {
      debugPrint('Actualizando vehículo con datos: $datos');

      final response =
          await _dio.post('/vehiculos/actualizar', data: datos);
      debugPrint('Response actualizar vehículo: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar datos del vehículo');
      }
    } catch (e) {
      debugPrint('Error al actualizar vehículo: $e');
      rethrow;
    }
  }
}
