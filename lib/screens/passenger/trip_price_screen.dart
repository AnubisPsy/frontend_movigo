import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
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
        title: const Text(
          'Contraoferta Recibida',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: movigoDarkColor,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'El conductor ha contrapropuesto un precio de:',
              style: TextStyle(color: movigoGreyColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: movigoSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(movigoButtonRadius),
                border:
                    Border.all(color: movigoSecondaryColor.withOpacity(0.5)),
              ),
              child: Text(
                'L. ${_precioContrapropuesto?.toStringAsFixed(2) ?? "0.00"}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: movigoSecondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Aceptas este precio para el viaje?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    _rechazarContrapropuesta();
                  },
                  child: const Text(
                    'Rechazar',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    _aceptarContrapropuesta();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: movigoPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(movigoButtonRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(movigoButtonRadius),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _proponerPrecio() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un precio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final precio = double.tryParse(_priceController.text);
    if (precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un precio válido'),
          backgroundColor: Colors.red,
        ),
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
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: movigoPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconForLabel(label),
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
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    if (label.contains('Origen')) {
      return Icons.location_on;
    } else if (label.contains('Destino')) {
      return Icons.location_searching;
    }
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        title: const Text(
          'Proponer Precio',
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
                    // Información del viaje
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
                            'Origen:',
                            _tripData?['origen'] ?? 'No disponible',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Destino:',
                            _tripData?['destino'] ?? 'No disponible',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Estado de la negociación
                    if (_estadoNegociacion == 'sin_negociar') ...[
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: movigoSecondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            size: 40,
                            color: movigoSecondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Propón un precio para tu viaje',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: movigoDarkColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa la cantidad que estás dispuesto a pagar por este viaje',
                        style: TextStyle(
                          fontSize: 16,
                          color: movigoGreyColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      MovigoTextField(
                        hintText: 'Precio (L.)',
                        controller: _priceController,
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      MovigoButton(
                        text: 'Proponer Precio',
                        onPressed: _proponerPrecio,
                        isLoading: _isLoading,
                      ),
                    ] else if (_estadoNegociacion == 'propuesto') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                Icons.hourglass_empty,
                                size: 30,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Precio Propuesto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'L. ${_tripData?['precio_propuesto']?.toString() ?? "0.00"}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Esperando respuesta del conductor...',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'El conductor evaluará tu oferta. Este proceso puede tardar unos minutos.',
                        style: TextStyle(
                          color: movigoGreyColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: movigoPrimaryColor,
                          side: const BorderSide(color: movigoPrimaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(movigoButtonRadius),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Volver',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ] else if (_estadoNegociacion == 'contrapropuesto') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: movigoSecondaryColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                          border: Border.all(
                              color: movigoSecondaryColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: movigoSecondaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.handshake_outlined,
                                size: 30,
                                color: movigoSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Contraoferta del Conductor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: movigoDarkColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'L. ${_precioContrapropuesto?.toStringAsFixed(2) ?? "0.00"}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: movigoSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'El conductor ha propuesto un nuevo precio para tu viaje',
                              style: TextStyle(
                                color: movigoGreyColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _rechazarContrapropuesta,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(movigoButtonRadius),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Rechazar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MovigoButton(
                              text: 'Aceptar',
                              onPressed: _aceptarContrapropuesta,
                              isLoading: _isLoading,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ] else if (_estadoNegociacion == 'aceptado') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 30,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Precio Acordado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'L. ${_tripData?['precio_final']?.toString() ?? "0.00"}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '¡Precio acordado! Tu viaje está en proceso.',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      MovigoButton(
                        text: 'Volver al Inicio',
                        onPressed: () => RouteHelper.goToPassengerHome(context),
                        color: Colors.green,
                      ),
                    ] else if (_estadoNegociacion == 'rechazado') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                Icons.cancel,
                                size: 30,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Negociación Cancelada',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'La propuesta de precio ha sido rechazada.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Puedes intentar con un nuevo viaje o con otro conductor.',
                              style: TextStyle(
                                color: movigoGreyColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      MovigoButton(
                        text: 'Volver al Inicio',
                        onPressed: () => RouteHelper.goToPassengerHome(context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
