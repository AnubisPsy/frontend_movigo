import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/data/services/passenger_service.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/socket_service.dart';

class TripPriceScreen extends StatefulWidget {
  final Map<String, dynamic>? tripData;

  const TripPriceScreen({Key? key, this.tripData}) : super(key: key);

  @override
  State<TripPriceScreen> createState() => _TripPriceScreenState();
}

class _TripPriceScreenState extends State<TripPriceScreen> {
  final TextEditingController _priceController = TextEditingController();
  final PassengerService _passengerService = PassengerService();
  bool _isLoading = false;
  Map<String, dynamic>? _tripData;

  // Estado de negociación
  String _estadoNegociacion = 'sin_negociar';
  double? _precioContrapropuesto;

  @override
  void initState() {
    super.initState();

    if (widget.tripData != null) {
      _tripData = widget.tripData;
      _estadoNegociacion = _tripData!['estado_negociacion'] ?? 'sin_negociar';
      _precioContrapropuesto =
          double.tryParse(_tripData!['precio_final']?.toString() ?? "0") ?? 0.0;
    }

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    if (_tripData != null) {
      // Escuchar eventos de contrapropuesta
      SocketService.on('precio-contrapropuesto', _handleContrapropuesta);
      SocketService.on('propuesta-rechazada', _handlePropuestaRechazada);
    }
  }

  void _handleContrapropuesta(dynamic data) {
    if (data != null && mounted && data['id'] == _tripData?['id']) {
      setState(() {
        _tripData = Map<String, dynamic>.from(data);
        _estadoNegociacion = 'contrapropuesto';
        _precioContrapropuesto = data['precio_final']?.toDouble();
      });

      _showContrapropuestaDialog();
    }
  }

  void _handlePropuestaRechazada(dynamic data) {
    if (data != null && mounted && data['id'] == _tripData?['id']) {
      setState(() {
        _tripData = Map<String, dynamic>.from(data);
        _estadoNegociacion = 'rechazado';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El conductor ha rechazado tu oferta'),
          backgroundColor: Colors.red,
        ),
      );

      // Volver a la pantalla anterior después de un tiempo
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _showContrapropuestaDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Contraoferta Recibida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'El conductor ha contrapropuesto un precio de:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Text(
              'L. ${_precioContrapropuesto?.toStringAsFixed(2) ?? "0.00"}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text('¿Aceptas este precio para el viaje?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              _rechazarContrapropuesta();
            },
            child: const Text('Rechazar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              _aceptarContrapropuesta();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _proponerPrecio() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un precio')),
      );
      return;
    }

    final precio = double.tryParse(_priceController.text);
    if (precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un precio válido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedTrip = await _passengerService.proponerPrecio(
        _tripData!['id'],
        precio,
      );

      setState(() {
        _tripData = updatedTrip;
        _estadoNegociacion = 'propuesto';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Precio propuesto con éxito. Esperando respuesta del conductor.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _aceptarContrapropuesta() async {
    setState(() => _isLoading = true);

    try {
      final updatedTrip =
          await _passengerService.aceptarContrapropuesta(_tripData!['id']);

      setState(() {
        _tripData = updatedTrip;
        _estadoNegociacion = 'aceptado';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Contraoferta aceptada! El viaje está en proceso.'),
          backgroundColor: Colors.green,
        ),
      );

      // Volver a la pantalla principal
      RouteHelper.goToPassengerHome(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _rechazarContrapropuesta() async {
    setState(() => _isLoading = true);

    try {
      await _passengerService.rechazarPropuesta(_tripData!['id']);

      setState(() {
        _estadoNegociacion = 'rechazado';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has rechazado la contraoferta'),
          backgroundColor: Colors.orange,
        ),
      );

      // Volver a la pantalla principal
      RouteHelper.goToPassengerHome(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    SocketService.off('precio-contrapropuesto', _handleContrapropuesta);
    SocketService.off('propuesta-rechazada', _handlePropuestaRechazada);
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proponer Precio'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información del viaje
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
                          _buildInfoRow(
                            'Origen:',
                            _tripData?['origen'] ?? 'No disponible',
                          ),
                          _buildInfoRow(
                            'Destino:',
                            _tripData?['destino'] ?? 'No disponible',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Estado de la negociación
                  if (_estadoNegociacion == 'sin_negociar') ...[
                    const Text(
                      'Propón un precio para tu viaje:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio (L.)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Proponer Precio',
                      onPressed: _proponerPrecio,
                    ),
                  ] else if (_estadoNegociacion == 'propuesto') ...[
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Precio Propuesto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'L. ${_tripData?['precio_propuesto']?.toString() ?? "0.00"}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Esperando respuesta del conductor...',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver'),
                    ),
                  ] else if (_estadoNegociacion == 'contrapropuesto') ...[
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Contraoferta del Conductor',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'L. ${_precioContrapropuesto?.toStringAsFixed(2) ?? "0.00"}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _rechazarContrapropuesta,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _aceptarContrapropuesta,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Aceptar'),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_estadoNegociacion == 'aceptado') ...[
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Precio Acordado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'L. ${_tripData?['precio_final']?.toString() ?? "0.00"}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '¡Precio acordado! Tu viaje está en proceso.',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Volver al Inicio',
                      onPressed: () => RouteHelper.goToPassengerHome(context),
                    ),
                  ] else if (_estadoNegociacion == 'rechazado') ...[
                    Card(
                      color: Colors.red.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Negociación Cancelada',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'La propuesta de precio ha sido rechazada.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Volver al Inicio',
                      onPressed: () => RouteHelper.goToPassengerHome(context),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
