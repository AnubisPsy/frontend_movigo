import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/widgets/trip/trip_card.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late TripStatus _status;
  final double _currentCost = 0.0;
  final String _elapsedTime = "00:00";

  @override
  void initState() {
    super.initState();
    _status = TripStatus.driverAssigned;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevenir botón atrás
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitleByStatus()),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // Área del mapa (placeholder por ahora)
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Text('Mapa aquí'),
                ),
              ),
            ),

            // Panel de información
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado del viaje
                    _buildStatusIndicator(),
                    const Divider(height: 24),

                    // Información del conductor y vehículo
                    _buildDriverInfo(),
                    const SizedBox(height: 16),

                    // Información del viaje
                    if (_status == TripStatus.inProgress) ...[
                      _buildTripInfo(),
                      const Spacer(),
                      _buildEmergencyButton(),
                    ],

                    if (_status == TripStatus.completed) ...[
                      _buildTripSummary(),
                      const Spacer(),
                      CustomButton(
                        text: 'Finalizar',
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/passenger-home',
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getStatusMessage(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _getProgressValue(),
          backgroundColor: Colors.grey[200],
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Juan Pérez',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Toyota Corolla - ABC123',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            // Implementar llamada al conductor
          },
        ),
        IconButton(
          icon: const Icon(Icons.message),
          onPressed: () {
            // Implementar chat con el conductor
          },
        ),
      ],
    );
  }

  Widget _buildTripInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoItem(
          icon: Icons.timer,
          label: 'Tiempo',
          value: _elapsedTime,
        ),
        _buildInfoItem(
          icon: Icons.attach_money,
          label: 'Costo Actual',
          value: '\$$_currentCost',
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyButton() {
    return OutlinedButton.icon(
      onPressed: () {
        // Implementar botón de emergencia
      },
      icon: const Icon(Icons.emergency, color: Colors.red),
      label: const Text(
        'Emergencia',
        style: TextStyle(color: Colors.red),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildTripSummary() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen del Viaje',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        // Aquí irían más detalles del viaje
      ],
    );
  }

  String _getTitleByStatus() {
    switch (_status) {
      case TripStatus.driverAssigned:
        return 'Conductor en Camino';
      case TripStatus.inProgress:
        return 'Viaje en Curso';
      case TripStatus.completed:
        return 'Viaje Completado';
    }
  }

  String _getStatusMessage() {
    switch (_status) {
      case TripStatus.driverAssigned:
        return 'Tu conductor está en camino';
      case TripStatus.inProgress:
        return 'En camino a tu destino';
      case TripStatus.completed:
        return '¡Has llegado a tu destino!';
    }
  }

  double _getProgressValue() {
    switch (_status) {
      case TripStatus.driverAssigned:
        return 0.3;
      case TripStatus.inProgress:
        return 0.7;
      case TripStatus.completed:
        return 1.0;
    }
  }
}

enum TripStatus {
  driverAssigned,
  inProgress,
  completed,
}
