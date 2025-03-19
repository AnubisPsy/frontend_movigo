import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:intl/intl.dart';

class MovigoTripCompletedScreen extends StatelessWidget {
  final Map<String, dynamic> tripData;
  final bool isConductor;

  const MovigoTripCompletedScreen({
    Key? key,
    required this.tripData,
    this.isConductor = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // En trip_completed_screen.dart

// Extraer datos del viaje
    final origen = tripData['origen'] ?? 'No disponible';
    final destino = tripData['destino'] ?? 'No disponible';

// Procesar fechas correctamente
    final fechaInicio = tripData['fecha_inicio'] != null
        ? DateTime.parse(tripData['fecha_inicio'])
            .toLocal() // Convertir a hora local
        : DateTime.now().toLocal();
    final fechaFin = tripData['fecha_fin'] != null
        ? DateTime.parse(tripData['fecha_fin'])
            .toLocal() // Convertir a hora local
        : DateTime.now().toLocal();

// Las horas se deben mostrar en formato local
    _buildDetailRow('Hora inicio:', DateFormat('HH:mm').format(fechaInicio));
    _buildDetailRow('Hora fin:', DateFormat('HH:mm').format(fechaFin));

// Calcular duración del viaje
    // Calcular duración del viaje
    String duracionTexto = 'No disponible';

// IMPORTANTE: Priorizar el uso del campo duracion_minutos
    if (tripData['duracion_minutos'] != null) {
      // Convertir a entero explícitamente para evitar problemas de tipo
      final duracionMinutos =
          int.tryParse(tripData['duracion_minutos'].toString()) ?? 0;
      final horas = duracionMinutos ~/ 60;
      final minutos = duracionMinutos % 60;
      duracionTexto = horas > 0 ? '$horas h $minutos min' : '$minutos min';

      // Log para depuración
      print('Usando duracion_minutos del backend: $duracionMinutos minutos');
    } else {
      // Solo como fallback, aunque no debería llegar aquí si el backend envía duracion_minutos
      print(
          'ADVERTENCIA: duracion_minutos no disponible, calculando manualmente');
      final duracion = fechaFin.difference(fechaInicio);
      final minutos = duracion.inMinutes;
      final horas = minutos ~/ 60;
      final minutosRestantes = minutos % 60;
      duracionTexto =
          horas > 0 ? '$horas h $minutosRestantes min' : '$minutos min';

      // Log para depuración de la diferencia manual
      print('Fecha inicio: $fechaInicio');
      print('Fecha fin: $fechaFin');
      print('Duración calculada (minutos): $minutos');
    }

    // Datos del conductor o pasajero (según corresponda)
    final nombreConductor = tripData['conductor'] ?? 'No disponible';
    final vehiculo = tripData['vehiculo'] ?? 'No disponible';
    final nombrePasajero = tripData['Usuario'] != null
        ? '${tripData['Usuario']['nombre']} ${tripData['Usuario']['apellido']}'
        : 'No disponible';

    // Precio y datos de pago
    final costoNumerico = tripData['costo'] is String
        ? double.tryParse(tripData['costo']) ?? 0.0
        : (tripData['costo'] ?? 0.0);
    final costo = costoNumerico.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        title: const Text(
          'Viaje Completado',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false, // Quitar botón de retroceso
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta principal con confirmación
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Viaje Completado!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Costo Total: L. $costo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: movigoPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Detalles del viaje
            _buildSectionTitle('Detalles del Viaje'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Origen:', origen),
                    const Divider(),
                    _buildDetailRow('Destino:', destino),
                    const Divider(),
                    _buildDetailRow(
                        'Fecha:', DateFormat('dd/MM/yyyy').format(fechaInicio)),
                    const Divider(),
                    _buildDetailRow('Hora inicio:',
                        DateFormat('HH:mm').format(fechaInicio.toLocal())),
                    const Divider(),
                    _buildDetailRow('Hora fin:',
                        DateFormat('HH:mm').format(fechaFin.toLocal())),
                    const Divider(),
                    _buildDetailRow('Duración:', duracionTexto),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Información personal (conductor o pasajero)
            _buildSectionTitle(isConductor ? 'Pasajero' : 'Conductor'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isConductor
                      ? [
                          _buildDetailRow('Nombre:', nombrePasajero),
                        ]
                      : [
                          _buildDetailRow('Nombre:', nombreConductor),
                          const Divider(),
                          _buildDetailRow('Vehículo:', vehiculo),
                        ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sección de calificación (opcional)
            _buildSectionTitle('¿Cómo fue tu experiencia?'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Califica este viaje',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: const Icon(Icons.star_border),
                          onPressed: () {
                            // En una implementación completa, aquí guardarías la calificación
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Calificación guardada. ¡Gracias!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          iconSize: 36,
                          color: movigoSecondaryColor,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Botón para volver al inicio
            MovigoButton(
              text: 'Volver al Inicio',
              onPressed: () {
                if (isConductor) {
                  RouteHelper.goToDriverHome(context);
                } else {
                  RouteHelper.goToPassengerHome(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: movigoDarkColor,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
