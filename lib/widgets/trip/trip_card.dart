import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';

class TripCard extends StatelessWidget {
  final String origin;
  final String destination;
  final String? driverName;
  final String? vehicleInfo;
  final DateTime? date;
  final double? cost;
  final VoidCallback? onAccept;
  final TripCardType type;

  const TripCard({
    super.key,
    required this.origin,
    required this.destination,
    this.driverName,
    this.vehicleInfo,
    this.date,
    this.cost,
    this.onAccept,
    this.type = TripCardType.available,
    required passengerName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (date != null) ...[
              Text(
                'Fecha: ${_formatDate(date!)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _buildLocationInfo(
              icon: Icons.location_on,
              label: 'Origen:',
              location: origin,
            ),
            const SizedBox(height: 8),
            _buildLocationInfo(
              icon: Icons.location_searching,
              label: 'Destino:',
              location: destination,
            ),
            if (driverName != null) ...[
              const Divider(),
              _buildDriverInfo(),
            ],
            if (vehicleInfo != null) ...[
              const SizedBox(height: 8),
              _buildVehicleInfo(),
            ],
            if (cost != null) ...[
              const Divider(),
              _buildCostInfo(),
            ],
            if (onAccept != null) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'Aceptar Viaje',
                onPressed: onAccept!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required String label,
    required String location,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return Row(
      children: [
        const Icon(Icons.person, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conductor:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                driverName!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    return Row(
      children: [
        const Icon(Icons.directions_car, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehículo:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                vehicleInfo!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Costo:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\$${cost!.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

enum TripCardType {
  available, // Para conductores viendo viajes disponibles
  active, // Para viajes en curso
  history // Para historial de viajes
}
