import 'package:flutter/material.dart';
import '../../models/viaje_estado.dart';
import 'cronometro_widget.dart';

class ViajeEstadoWidget extends StatelessWidget {
  final String estado;
  final Map<String, dynamic> viajeData;
  final VoidCallback? onViajeCancelado;

  const ViajeEstadoWidget({
    Key? key,
    required this.estado,
    required this.viajeData,
    this.onViajeCancelado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con estado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorForEstado(estado),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                const Text(
                  'Estado del viaje',
                  style: TextStyle(color: Colors.white),
                ),
                const Spacer(),
                Text(
                  estado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildContentForEstado(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContentForEstado(BuildContext context) {
    switch (estado) {
      case ViajeEstado.PENDIENTE:
        return Column(
          children: [
            CronometroWidget(
              viajeData: viajeData,
              onTimeExpired: () {
                // Aquí podríamos cancelar automáticamente el viaje
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onViajeCancelado,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cancelar Viaje'),
            ),
          ],
        );

      case ViajeEstado.ACEPTADO:
        return Column(
          children: [
            _buildInfoSection('Datos del conductor', viajeData['conductor']),
            const SizedBox(height: 16),
            _buildInfoSection('Datos del vehículo', viajeData['vehiculo']),
          ],
        );

      case ViajeEstado.EN_CURSO:
        return Column(
          children: [
            _buildInfoSection('Datos del conductor', viajeData['conductor']),
            const SizedBox(height: 16),
            _buildInfoSection('Datos del vehículo', viajeData['vehiculo']),
          ],
        );

      case ViajeEstado.FINALIZADO:
        return Column(
          children: [
            _buildInfoSection('Datos del conductor', viajeData['conductor']),
            const SizedBox(height: 16),
            _buildInfoSection('Datos del vehículo', viajeData['vehiculo']),
            const SizedBox(height: 16),
            _buildInfoSection('Datos del costo', viajeData['costo']),
          ],
        );

      default:
        return const Center(
          child: Text('Estado no reconocido'),
        );
    }
  }

  Widget _buildInfoSection(String title, Map<String, dynamic>? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Aquí puedes mostrar los datos específicos según el tipo de información
          if (data != null) ...[
            const SizedBox(height: 8),
            // Implementar visualización de datos específicos
          ],
        ],
      ),
    );
  }

  Color _getColorForEstado(String estado) {
    switch (estado) {
      case ViajeEstado.PENDIENTE:
        return Colors.orange;
      case ViajeEstado.ACEPTADO:
        return Colors.cyan;
      case ViajeEstado.EN_CURSO:
        return Colors.yellow[700]!;
      case ViajeEstado.FINALIZADO:
        return Colors.green;
      case ViajeEstado.CANCELADO:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
