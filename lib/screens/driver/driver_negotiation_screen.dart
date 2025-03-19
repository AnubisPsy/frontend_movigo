import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/data/services/driver_service.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/socket_service.dart';

class DriverNegotiationScreen extends StatefulWidget {
  final Map<String, dynamic>? tripData;

  const DriverNegotiationScreen({Key? key, this.tripData}) : super(key: key);

  @override
  State<DriverNegotiationScreen> createState() =>
      _DriverNegotiationScreenState();
}

class _DriverNegotiationScreenState extends State<DriverNegotiationScreen> {
  final TextEditingController _priceController = TextEditingController();
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  Map<String, dynamic>? _tripData;

  // Estado de la negociación
  String _estadoNegociacion = 'propuesto';
  double? _precioPropuesto;

  @override
  void initState() {
    super.initState();

    if (widget.tripData != null) {
      _tripData = widget.tripData;
      print('Datos del viaje recibidos: $_tripData');
      print('ID del viaje: ${_tripData?['id']}');

      _estadoNegociacion = _tripData!['estado_negociacion'] ?? 'propuesto';
      _precioPropuesto =
          double.tryParse(_tripData!['precio_propuesto']?.toString() ?? "0") ??
              0.0;

      // Precargar el campo con un valor inicial basado en el precio propuesto
      if (_precioPropuesto != null) {
        _priceController.text = _precioPropuesto.toString();
      }
    } else {
      print('No se recibieron datos del viaje');
    }

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    if (_tripData != null) {
      // Escuchar eventos de respuesta del pasajero
      SocketService.on('contraoferta-aceptada', _handleContraofertaAceptada);
      SocketService.on('propuesta-rechazada', _handlePropuestaRechazada);
    }
  }

  void _handleContraofertaAceptada(dynamic data) {
    if (data != null && mounted && data['id'] == _tripData?['id']) {
      setState(() {
        _tripData = Map<String, dynamic>.from(data);
        _estadoNegociacion = 'aceptado';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡El pasajero ha aceptado tu contraoferta!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a la pantalla de viaje activo
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          RouteHelper.goToDriverActiveTrip(context, arguments: _tripData);
        }
      });
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
          content: Text('El pasajero ha rechazado tu contraoferta'),
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

  Future<void> _contraproponerPrecio() async {
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
      final updatedTrip = await _driverService.contraproponerPrecio(
        _tripData?['id'] ?? '',
        precio,
      );

      setState(() {
        _tripData = updatedTrip;
        _estadoNegociacion = 'contrapropuesto';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Contraoferta enviada con éxito. Esperando respuesta del pasajero.'),
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

// Reemplazar el método _rechazarPropuesta por este:
  void _salirSinRechazar() {
    // Mostrar un mensaje informativo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Has salido sin afectar el viaje. Otros conductores podrán tomarlo.'),
        backgroundColor: Colors.blue,
      ),
    );

    // Simplemente volver atrás
    Navigator.pop(context);
  }

  Future<void> _aceptarPrecioPropuesto() async {
    if (_tripData == null || (_precioPropuesto ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay un precio válido para aceptar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tripId = _tripData?['id']?.toString() ?? '';
      if (tripId.isEmpty) {
        throw Exception('ID de viaje no disponible');
      }

      // Usar el método acceptTrip que ya tienes para aceptar el viaje
      final updatedTrip = await _driverService.acceptTrip(tripId);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje aceptado con el precio propuesto!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a la pantalla de viaje activo
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        RouteHelper.goToDriverActiveTrip(context, arguments: updatedTrip);
      }
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
    SocketService.off('contraoferta-aceptada', _handleContraofertaAceptada);
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
        title: const Text('Negociar Precio'),
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
                          if (_tripData?['Usuario'] != null)
                            _buildInfoRow(
                              'Pasajero:',
                              '${_tripData!['Usuario']['nombre']} ${_tripData!['Usuario']['apellido']}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Estado de la negociación
                  if (_estadoNegociacion == 'propuesto') ...[
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Precio Propuesto por el Pasajero',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'L. ${_precioPropuesto?.toStringAsFixed(2) ?? "0.00"}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _aceptarPrecioPropuesto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              child: const Text('Aceptar este precio'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Propone tu precio:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Tu precio (L.)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _salirSinRechazar,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                            child: const Text('Salir'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _contraproponerPrecio,
                            child: const Text('Proponer'),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_estadoNegociacion == 'contrapropuesto') ...[
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Tu Contraoferta',
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
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Esperando respuesta del pasajero...',
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
                              '¡El pasajero ha aceptado tu contraoferta!',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Continuar con el Viaje',
                      onPressed: () => RouteHelper.goToDriverActiveTrip(context,
                          arguments: _tripData),
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
                      text: 'Volver',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
