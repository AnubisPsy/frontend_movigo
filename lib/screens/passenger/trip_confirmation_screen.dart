import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
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
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        title: const Text(
          'Confirmar Viaje',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: movigoPrimaryColor,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icono de confirmación
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: movigoPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.confirmation_num,
                          size: 50,
                          color: movigoPrimaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Título y descripción
                    const Text(
                      'Confirma tu viaje',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: movigoDarkColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Revisa los detalles de tu viaje antes de continuar.',
                      style: TextStyle(
                        fontSize: 16,
                        color: movigoGreyColor,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Detalles del viaje
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(movigoButtonRadius),
                        border: Border.all(color: movigoBorderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles del Viaje',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: movigoDarkColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                              'Origen:', widget.origin, Icons.location_on),
                          const SizedBox(height: 12),
                          _buildInfoRow('Destino:', widget.destination,
                              Icons.location_searching),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Opciones de precio
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(movigoButtonRadius),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Opciones de Precio',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¿Deseas proponer un precio para este viaje o solicitar el viaje directamente?',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Botones de acción
                    MovigoButton(
                      text: 'Proponer Precio',
                      onPressed: _proponerPrecio,
                      color: movigoSecondaryColor,
                    ),

                    const SizedBox(height: 16),

                    MovigoButton(
                      text: 'Solicitar Viaje Directamente',
                      onPressed: _solicitarViaje,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: movigoPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: movigoPrimaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: movigoGreyColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: movigoDarkColor,
                ),
              ),
            ],
          ),
        ),
      ],
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
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
