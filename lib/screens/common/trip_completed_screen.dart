import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:intl/intl.dart';

class TripCompletedScreen extends StatelessWidget {
  final Map<String, dynamic> tripData;
  final bool isConductor;

  const TripCompletedScreen({
    Key? key,
    required this.tripData,
    this.isConductor = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraer datos del viaje
    final origen = tripData['origen'] ?? 'No disponible';
    final destino = tripData['destino'] ?? 'No disponible';
    final fechaInicio = tripData['fecha_inicio'] != null
        ? DateTime.parse(tripData['fecha_inicio'])
        : null;
    final fechaFin = tripData['fecha_fin'] != null
        ? DateTime.parse(tripData['fecha_fin'])
        : null;

    // Calcular duración del viaje
    String duracionTexto = 'No disponible';
    if (fechaInicio != null && fechaFin != null) {
      final duracion = fechaFin.difference(fechaInicio);
      final horas = duracion.inHours;
      final minutos = duracion.inMinutes.remainder(60);
      duracionTexto = horas > 0 ? '$horas h $minutos min' : '$minutos min';
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
        title: const Text('Viaje Completado'),
        automaticallyImplyLeading: false, // Eliminar botón de retroceso
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
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
                        'Fecha:',
                        fechaInicio != null
                            ? DateFormat('dd/MM/yyyy').format(fechaInicio)
                            : 'No disponible'),
                    const Divider(),
                    _buildDetailRow(
                        'Hora inicio:',
                        fechaInicio != null
                            ? DateFormat('HH:mm').format(fechaInicio)
                            : 'No disponible'),
                    const Divider(),
                    _buildDetailRow(
                        'Hora fin:',
                        fechaFin != null
                            ? DateFormat('HH:mm').format(fechaFin)
                            : 'No disponible'),
                    const Divider(),
                    _buildDetailRow('Duración:', duracionTexto),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Información personal
            _buildSectionTitle(isConductor ? 'Pasajero' : 'Conductor'),
            Card(
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
                            // Implementar calificación en el futuro
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Calificación guardada. ¡Gracias!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          iconSize: 36,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón para volver al inicio
            CustomButton(
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
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
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
