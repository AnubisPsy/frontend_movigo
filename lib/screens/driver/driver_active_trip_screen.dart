import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/driver_service.dart';
import 'dart:async';
import 'package:movigo_frontend/data/services/socket_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/widgets/map/mapa_en_tiempo_real.dart';

class DriverActiveTripScreen extends StatefulWidget {
  const DriverActiveTripScreen({super.key});

  @override
  State<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen> {
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  Map<String, dynamic>? _activeTrip;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveTrip();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripArg = ModalRoute.of(context)?.settings.arguments;
      if (tripArg != null && tripArg is Map<String, dynamic>) {
        setState(() {
          _activeTrip = tripArg;
          _isLoading = false;
        });
        _startRefreshTimer();
      } else {
        _loadActiveTrip(); // Si no hay argumento, intentar cargar normalmente
      }
    });
    _initializeWebSocket();
  }

  @override
  void dispose() {
    // Remover listeners al salir de la pantalla
    SocketService.off('viaje-cancelado', _handleViajeCancelado);

    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeWebSocket() async {
    // Inicializar Socket.IO
    await SocketService.init();

    // Obtener el ID del usuario
    final userId = await StorageService.getUserId();

    if (userId != null) {
      // Suscribirse a eventos del usuario
      SocketService.subscribeToUserEvents(userId);

      // Registrar handlers para diferentes tipos de eventos
      SocketService.on('viaje-cancelado', _handleViajeCancelado);
    }
  }

  void _handleViajeCancelado(dynamic data) {
    print('📱 Viaje cancelado recibido: $data');
    if (data != null && mounted) {
      // Si el viaje activo fue cancelado
      if (_activeTrip != null && _activeTrip!['id'] == data['id']) {
        setState(() {
          _activeTrip = null;
        });

        // Mostrar notificación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El viaje fue cancelado por el pasajero'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );

        // Navegar de regreso a la pantalla principal
        RouteHelper.goToDriverHome(context);
      }
    }
  }

  Future<void> _loadActiveTrip() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final activeTrip = await _driverService.getActiveTrip();

      if (!mounted) return;

      setState(() {
        _activeTrip = activeTrip;
        _isLoading = false;
      });

      // Si no hay viaje activo, volver a la pantalla principal
      if (_activeTrip == null) {
        // ← ESTE ES EL PROBLEMA
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes viajes activos'),
            backgroundColor: Colors.orange,
          ),
        );
        RouteHelper.goToDriverHome(
            context); // ← ESTA REDIRECCIÓN ES LA QUE TE MANDA AL HOME
      } else {
        // Iniciar timer de refresco para actualizaciones
        _startRefreshTimer();
      }
    } catch (e) {
      // ...
    }
  }

  void _startRefreshTimer() {
    // Cancelar cualquier timer anterior
    _refreshTimer?.cancel();

    // Usar un intervalo de 10 segundos como respaldo a WebSockets
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _refreshTripStatus();
    });
  }

  Future<void> _refreshTripStatus() async {
    if (_activeTrip == null || !mounted) return;

    try {
      final tripId = _activeTrip!['id'];
      // Aquí deberías implementar un método para obtener el estado actual del viaje
      // Por ahora, simplemente recargamos el viaje activo
      final updatedTrip = await _driverService.getActiveTrip();

      if (!mounted) return;

      if (updatedTrip != null) {
        setState(() {
          _activeTrip = updatedTrip;
        });
      } else {
        // Si ya no hay viaje activo (completado o cancelado)
        setState(() {
          _activeTrip = null;
        });
        RouteHelper.goToDriverHome(context);
      }
    } catch (e) {
      print('Error al actualizar estado del viaje: $e');
    }
  }

  Future<void> _startTrip() async {
    if (_activeTrip == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final tripId = _activeTrip!['id'];
      final updatedTrip = await _driverService.startTrip(tripId);

      if (!mounted) return;

      setState(() {
        _activeTrip = updatedTrip;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje iniciado con éxito!'),
          backgroundColor: Colors.green,
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

  Future<void> _completeTrip() async {
    if (_activeTrip == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final tripId = _activeTrip!['id'];
      await _driverService.completeTrip(tripId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje completado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar de regreso a la pantalla principal
      RouteHelper.goToDriverHome(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // No permitir volver atrás con el botón físico
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Viaje Activo'),
          automaticallyImplyLeading: false, // Evitar botón de retroceso
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activeTrip == null
                ? const Center(child: Text('No hay viaje activo'))
                : _buildTripDetails(),
      ),
    );
  }

  Widget _buildTripDetails() {
    // Determinar el estado del viaje
    int estado = _activeTrip!['estado'] ?? 2;
    String statusText = '';
    Color statusColor = Colors.blue;

    switch (estado) {
      case 2:
        statusText = 'ACEPTADO';
        statusColor = Colors.blue;
        break;
      case 3:
        statusText = 'EN CURSO';
        statusColor = Colors.amber;
        break;
      case 4:
        statusText = 'COMPLETADO';
        statusColor = Colors.green;
        break;
      default:
        statusText = 'ESTADO DESCONOCIDO';
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Área del mapa (placeholder)
          // En _buildTripDetails, reemplaza el placeholder del mapa con un componente real
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MapaEnTiempoReal(
                esViajePendiente: true,
                tripData: _activeTrip,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Panel de información del viaje
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'L. ${(_activeTrip!['tarifa'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Información de origen y destino
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeTrip!['origen'] ?? 'Origen no disponible',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_searching, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeTrip!['destino'] ?? 'Destino no disponible',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Información del pasajero
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeTrip!['pasajero'] ?? 'Pasajero',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _activeTrip!['telefono_pasajero'] ?? 'Sin teléfono',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función de llamada en desarrollo'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botones de acción según el estado
                if (estado == 2) // ACEPTADO - puede iniciar viaje
                  CustomButton(
                    text: 'Iniciar Viaje',
                    onPressed: _startTrip,
                  )
                else if (estado == 3) // EN CURSO - puede completar viaje
                  CustomButton(
                    text: 'Completar Viaje',
                    onPressed: _completeTrip,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
