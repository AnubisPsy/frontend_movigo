import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/driver_service.dart';
import 'package:movigo_frontend/widgets/map/mapa_en_tiempo_real.dart';
import 'package:movigo_frontend/screens/common/trip_completed_screen.dart';
import 'dart:async';
import 'package:movigo_frontend/data/services/socket_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';

class MovigoDriverActiveTripScreen extends StatefulWidget {
  const MovigoDriverActiveTripScreen({Key? key}) : super(key: key);

  @override
  State<MovigoDriverActiveTripScreen> createState() =>
      _MovigoDriverActiveTripScreenState();
}

class _MovigoDriverActiveTripScreenState
    extends State<MovigoDriverActiveTripScreen> {
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  Map<String, dynamic>? _activeTrip;
  Timer? _refreshTimer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Evitamos inicializar múltiples veces
    if (!_initialized) {
      _initialized = true;
      _initializeTrip();
    }
  }

  void _initializeTrip() {
    // Intentar obtener el viaje de los argumentos
    final tripArg = ModalRoute.of(context)?.settings.arguments;

    if (tripArg != null && tripArg is Map<String, dynamic>) {
      // Si hay un viaje en los argumentos, usarlo directamente
      setState(() {
        _activeTrip = tripArg;
        _isLoading = false;
      });

      print("Viaje encontrado en argumentos: ${_activeTrip?['id']}");
      _startRefreshTimer();
    } else {
      // Si no hay argumentos, intentar cargar desde el API
      print("No se encontró viaje en argumentos, intentando cargar desde API");
      _loadActiveTrip();
    }
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

      // Si hay viaje activo, iniciar timer de refresco
      if (_activeTrip != null) {
        _startRefreshTimer();
      } else {
        // Si no hay viaje, mostrar mensaje y opción para volver
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes viajes activos'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar viaje: ${e.toString()}')),
      );
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

      print("Refrescando estado del viaje ID: $tripId");

      // Obtener el estado actual del viaje mediante una llamada específica
      final response = await _driverService.getTripById(tripId);

      if (!mounted) return;

      if (response != null) {
        print(
            "Estado actual: ${_activeTrip!['estado']}, Nuevo estado: ${response['estado']}");

        setState(() {
          _activeTrip = response;
        });

        // Si el viaje ya fue completado o cancelado (estados 4 o 5)
        if (response['estado'] == 4 || response['estado'] == 5) {
          _refreshTimer?.cancel();

          if (response['estado'] == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Viaje completado'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
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
      print("Iniciando viaje ID: $tripId");

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
      print("Completando viaje ID: $tripId");

      final completedTrip = await _driverService.completeTrip(tripId);

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

      // Navegar a la pantalla de finalización de viaje
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovigoTripCompletedScreen(
            tripData: completedTrip,
            isConductor: true,
          ),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // No permitir volver atrás con el botón físico
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: movigoPrimaryColor,
          elevation: 0,
          title: const Text(
            'Viaje Activo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          automaticallyImplyLeading: false, // Evitar botón de retroceso
          actions: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Volver al inicio'),
                    content: const Text(
                        '¿Seguro que deseas regresar al inicio? Se mantendrá el viaje activo.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          RouteHelper.goToDriverHome(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: movigoPrimaryColor,
                        ),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activeTrip == null
                ? _buildNoActiveTrip()
                : _buildTripDetails(),
      ),
    );
  }

  Widget _buildNoActiveTrip() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay viaje activo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: movigoDarkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontró ningún viaje en estado activo',
            style: TextStyle(
              color: movigoGreyColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: MovigoButton(
              text: 'Volver al inicio',
              onPressed: () => RouteHelper.goToDriverHome(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails() {
    // Determinar el estado del viaje
    int estado = _activeTrip!['estado'] ?? 2;
    String statusText = '';
    Color statusColor = movigoPrimaryColor;

    switch (estado) {
      case 2:
        statusText = 'ACEPTADO';
        statusColor = Colors.blue;
        break;
      case 3:
        statusText = 'EN CURSO';
        statusColor = movigoSecondaryColor;
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
          // Área del mapa
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
              borderRadius: BorderRadius.circular(movigoBottomSheetRadius),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Text(
                      'L. ${(_activeTrip!['tarifa'] ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: movigoDarkColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Información de origen y destino
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green),
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
                    Icon(Icons.location_searching, color: Colors.red),
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: movigoDarkColor,
                            ),
                          ),
                          Text(
                            _activeTrip!['telefono_pasajero'] ?? 'Sin teléfono',
                            style: TextStyle(
                              color: movigoGreyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      color: movigoPrimaryColor,
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
                  MovigoButton(
                    text: 'Iniciar Viaje',
                    onPressed: _startTrip,
                    isLoading: _isLoading,
                  )
                else if (estado == 3) // EN CURSO - puede completar viaje
                  MovigoButton(
                    text: 'Completar Viaje',
                    onPressed: _completeTrip,
                    isLoading: _isLoading,
                    color: Colors.green,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
