import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/screens/passenger/searching_driver_screen.dart';

class RequestTripScreen extends StatefulWidget {
  final String origin;
  final String destination;

  const RequestTripScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<RequestTripScreen> createState() => _RequestTripScreenState();
}

class _RequestTripScreenState extends State<RequestTripScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Viaje'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del viaje
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildLocationInfo(
                      icon: Icons.location_on,
                      title: 'Origen',
                      address: widget.origin,
                    ),
                    const Divider(height: 32),
                    _buildLocationInfo(
                      icon: Icons.location_searching,
                      title: 'Destino',
                      address: widget.destination,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Información estimada
            const Text(
              'Información Estimada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEstimatedInfo(
              icon: Icons.access_time,
              title: 'Tiempo estimado',
              value: '15 min',
            ),
            const SizedBox(height: 12),
            _buildEstimatedInfo(
              icon: Icons.attach_money,
              title: 'Costo aproximado',
              value: '\$25.00 - \$30.00',
            ),

            const Spacer(),

            // Botón de confirmar
            CustomButton(
              text: 'Confirmar Viaje',
              isLoading: _isLoading,
              onPressed: _requestTrip,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required String title,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
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

  Widget _buildEstimatedInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _requestTrip() async {
    setState(() => _isLoading = true);

    try {
      // Aquí iría la lógica para solicitar el viaje
      await Future.delayed(const Duration(seconds: 2)); // Simulación

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchingDriverScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al solicitar el viaje'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
