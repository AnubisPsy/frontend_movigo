import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';

class ActiveTripDriverScreen extends StatefulWidget {
  const ActiveTripDriverScreen({super.key});

  @override
  State<ActiveTripDriverScreen> createState() => _ActiveTripDriverScreenState();
}

class _ActiveTripDriverScreenState extends State<ActiveTripDriverScreen> {
  late TripStatus _status;
  final double _currentCost = 0.0;
  final String _elapsedTime = "00:00";

  @override
  void initState() {
    super.initState();
    _status = TripStatus.drivingToPassenger;
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
            // Área del mapa
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

                    // Información del pasajero
                    _buildPassengerInfo(),
                    const SizedBox(height: 16),

                    // Información del viaje
                    if (_status == TripStatus.inProgress) ...[
                      _buildTripInfo(),
                      const Spacer(),
                      _buildActionButton(),
                    ] else ...[
                      const Spacer(),
                      _buildActionButton(),
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

  Widget _buildPassengerInfo() {
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
                'Juan Usuario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Pasajero',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            // Implementar llamada al pasajero
          },
        ),
        IconButton(
          icon: const Icon(Icons.message),
          onPressed: () {
            // Implementar chat con el pasajero
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
          label: 'Ganancia Actual',
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

  Widget _buildActionButton() {
    switch (_status) {
      case TripStatus.drivingToPassenger:
        return CustomButton(
          text: 'Llegué al punto de recogida',
          onPressed: _arrivedToPickup,
        );
      case TripStatus.waitingPassenger:
        return CustomButton(
          text: 'Iniciar Viaje',
          onPressed: _startTrip,
        );
      case TripStatus.inProgress:
        return CustomButton(
          text: 'Finalizar Viaje',
          onPressed: _finishTrip,
        );
      case TripStatus.completed:
        return CustomButton(
          text: 'Confirmar',
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/home',
              (route) => false,
            );
          },
        );
    }
  }

  String _getTitleByStatus() {
    switch (_status) {
      case TripStatus.drivingToPassenger:
        return 'Dirigiéndome al pasajero';
      case TripStatus.waitingPassenger:
        return 'Esperando pasajero';
      case TripStatus.inProgress:
        return 'Viaje en curso';
      case TripStatus.completed:
        return 'Viaje completado';
    }
  }

  String _getStatusMessage() {
    switch (_status) {
      case TripStatus.drivingToPassenger:
        return 'En camino al punto de recogida';
      case TripStatus.waitingPassenger:
        return 'Esperando al pasajero';
      case TripStatus.inProgress:
        return 'Llevando al pasajero a su destino';
      case TripStatus.completed:
        return '¡Viaje finalizado!';
    }
  }

  double _getProgressValue() {
    switch (_status) {
      case TripStatus.drivingToPassenger:
        return 0.25;
      case TripStatus.waitingPassenger:
        return 0.5;
      case TripStatus.inProgress:
        return 0.75;
      case TripStatus.completed:
        return 1.0;
    }
  }

  void _arrivedToPickup() {
    setState(() => _status = TripStatus.waitingPassenger);
  }

  void _startTrip() {
    setState(() => _status = TripStatus.inProgress);
    // Aquí iniciarías el temporizador y el cálculo de costos
  }

  void _finishTrip() {
    setState(() => _status = TripStatus.completed);
    // Aquí detendrías el temporizador y calcularías el costo final
  }
}

enum TripStatus {
  drivingToPassenger,
  waitingPassenger,
  inProgress,
  completed,
}
