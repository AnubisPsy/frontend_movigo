import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: movigoDarkColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Negociar Precio',
          style: TextStyle(
            color: movigoDarkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono de negociación
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: movigoSecondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.handshake,
                          size: 50,
                          color: movigoSecondaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Título según el estado de negociación
                    Text(
                      _getTitleForState(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: movigoDarkColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Descripción
                    Text(
                      _getDescriptionForState(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: movigoGreyColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Información del viaje
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(movigoButtonRadius),
                        side: const BorderSide(color: movigoBorderColor, width: 1),
                      ),
                      elevation: 0,
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
                                color: movigoDarkColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Origen:',
                              _tripData?['origen'] ?? 'No disponible',
                              Icons.location_on,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Destino:',
                              _tripData?['destino'] ?? 'No disponible',
                              Icons.location_searching,
                            ),
                            const SizedBox(height: 12),
                            if (_tripData?['Usuario'] != null)
                              _buildInfoRow(
                                'Pasajero:',
                                '${_tripData!['Usuario']['nombre']} ${_tripData!['Usuario']['apellido']}',
                                Icons.person,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Estado de la negociación
                    if (_estadoNegociacion == 'propuesto') ...[
                      // Precio propuesto por el pasajero
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                        ),
                        color: Colors.blue.shade50,
                        elevation: 0,
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
                              const SizedBox(height: 12),
                              Text(
                                'L. ${_precioPropuesto?.toStringAsFixed(2) ?? "0.00"}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: movigoPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              MovigoButton(
                                text: 'Aceptar este precio',
                                onPressed: _aceptarPrecioPropuesto,
                                isLoading: false,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Proponer tu precio
                      const Text(
                        'Propone tu precio:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: movigoDarkColor,
                        ),
                      ),

                      const SizedBox(height: 12),

                      MovigoTextField(
                        hintText: 'Tu precio (L.)',
                        controller: _priceController,
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _salirSinRechazar,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: movigoPrimaryColor,
                                side: const BorderSide(color: movigoPrimaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(movigoButtonRadius),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MovigoButton(
                              text: 'Proponer',
                              onPressed: _contraproponerPrecio,
                              isLoading: _isLoading,
                              color: movigoSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ] else if (_estadoNegociacion == 'contrapropuesto') ...[
                      // Tu contraoferta
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                        ),
                        color: Colors.amber.shade50,
                        elevation: 0,
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
                              const SizedBox(height: 12),
                              Text(
                                'L. ${_tripData?['precio_final']?.toString() ?? "0.00"}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildStatusIndicator(
                                  'Esperando respuesta del pasajero...'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      MovigoButton(
                        text: 'Volver',
                        onPressed: () => Navigator.pop(context),
                        isLoading: false,
                      ),
                    ] else if (_estadoNegociacion == 'aceptado') ...[
                      // Precio acordado
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                        ),
                        color: Colors.green.shade50,
                        elevation: 0,
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
                              const SizedBox(height: 12),
                              Text(
                                'L. ${_tripData?['precio_final']?.toString() ?? "0.00"}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    '¡El pasajero ha aceptado tu contraoferta!',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      MovigoButton(
                        text: 'Continuar con el Viaje',
                        onPressed: () => RouteHelper.goToDriverActiveTrip(
                            context,
                            arguments: _tripData),
                        isLoading: false,
                        color: Colors.green,
                      ),
                    ] else if (_estadoNegociacion == 'rechazado') ...[
                      // Negociación cancelada
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                        ),
                        color: Colors.red.shade50,
                        elevation: 0,
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Negociación Cancelada',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'La propuesta de precio ha sido rechazada',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      MovigoButton(
                        text: 'Volver',
                        onPressed: () => Navigator.pop(context),
                        isLoading: false,
                      ),
                    ],
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: movigoPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: movigoPrimaryColor,
            size: 20,
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

  Widget _buildStatusIndicator(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.amber.shade700,
          ),
        ),
      ],
    );
  }

  String _getTitleForState() {
    switch (_estadoNegociacion) {
      case 'propuesto':
        return 'Propuesta de Viaje';
      case 'contrapropuesto':
        return 'Esperando Respuesta';
      case 'aceptado':
        return '¡Propuesta Aceptada!';
      case 'rechazado':
        return 'Propuesta Rechazada';
      default:
        return 'Negociación de Precio';
    }
  }

  String _getDescriptionForState() {
    switch (_estadoNegociacion) {
      case 'propuesto':
        return 'El pasajero ha propuesto un precio para este viaje. Puedes aceptarlo o hacer una contraoferta.';
      case 'contrapropuesto':
        return 'Has enviado una contraoferta al pasajero. Espera mientras el pasajero decide si aceptarla.';
      case 'aceptado':
        return 'El pasajero ha aceptado tu precio. Puedes continuar con el viaje.';
      case 'rechazado':
        return 'El pasajero ha rechazado tu contraoferta.';
      default:
        return 'Acuerda un precio para este viaje con el pasajero.';
    }
  }
}
