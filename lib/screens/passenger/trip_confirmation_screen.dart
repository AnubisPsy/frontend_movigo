import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/data/services/passenger_service.dart';
import 'package:movigo_frontend/screens/passenger/trip_price_screen.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class TripConfirmationScreen extends StatefulWidget {
  final String origin;
  final String destination;

  const TripConfirmationScreen({
    Key? key,
    required this.origin,
    required this.destination,
  }) : super(key: key);

  @override
  State<TripConfirmationScreen> createState() => _TripConfirmationScreenState();
}

class _TripConfirmationScreenState extends State<TripConfirmationScreen> {
  final PassengerService _passengerService = PassengerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print(
        "TripConfirmationScreen inicializada con origen: ${widget.origin}, destino: ${widget.destination}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Viaje'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles del Viaje',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Origen:', widget.origin),
                          _buildInfoRow('Destino:', widget.destination),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¿Desea proponer un precio para este viaje?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Proponer Precio',
                    onPressed: _proponerPrecio,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Solicitar Viaje Directamente',
                    onPressed: _solicitarViaje,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _proponerPrecio() async {
    print("Iniciando proponerPrecio");
    setState(() => _isLoading = true);

    try {
      // Primero creamos el viaje
      final trip = await _passengerService.requestTrip(
        widget.origin,
        widget.destination,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Luego navegamos a la pantalla de propuesta de precio
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripPriceScreen(tripData: trip),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _solicitarViaje() async {
    print("Iniciando solicitarViaje");

    setState(() => _isLoading = true);

    try {
      // Solicitar viaje directamente
      final trip = await _passengerService.requestTrip(
        widget.origin,
        widget.destination,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje solicitado con éxito!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Volver a la pantalla principal
      RouteHelper.goToPassengerHome(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
