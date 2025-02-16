// lib/widgets/conductor/viajes_pendientes_widget.dart
import 'package:flutter/material.dart';

class ViajesPendientesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> viajes;
  final Function(String) onAceptarViaje;

  const ViajesPendientesWidget({
    Key? key,
    required this.viajes,
    required this.onAceptarViaje,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: viajes.length,
      itemBuilder: (context, index) {
        final viaje = viajes[index];
        final usuario = viaje['usuario'];
        final origen = viaje['ubicacionOrigen'];
        final destino = viaje['ubicacionDestino'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${usuario['nombre']} ${usuario['apellido']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Estado: ${viaje['estado']}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildLocationInfo('Origen', origen['direccion_referencia']),
                const SizedBox(height: 4),
                _buildLocationInfo('Destino', destino['direccion_referencia']),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => onAceptarViaje(viaje['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aceptar Viaje'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationInfo(String title, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(address),
        ),
      ],
    );
  }
}
