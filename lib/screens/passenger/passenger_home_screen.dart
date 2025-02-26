import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/passenger_service.dart';
import 'dart:async';
import 'package:movigo_frontend/data/services/socket_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});
  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _activeTrip;
  final PassengerService _passengerService = PassengerService();

  // Variables para el temporizador de cancelación
  bool _canCancel = true;
  int _remainingSeconds = 300; // 5 minutos por defecto
  Timer? _countdownTimer;
  Timer? _refreshTimer;

  // Getter para formatear el tiempo
  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Método para iniciar el timer de cuenta regresiva
  void _initializeTimer() {
    // Cancelar cualquier timer existente
    _countdownTimer?.cancel();

    // Crear un nuevo timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Actualizar el estado cada segundo
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canCancel = false;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _checkActiveTrip();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    // Quitar los listeners al salir de la pantalla
    SocketService.off('viaje-aceptado', _handleViajeAceptado);
    SocketService.off('viaje-iniciado', _handleViajeIniciado);
    SocketService.off('viaje-completado', _handleViajeCompletado);
    SocketService.off('viaje-cancelado', _handleViajeCancelado);

    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _originController.dispose();
    _destinationController.dispose();
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
      SocketService.on('viaje-aceptado', _handleViajeAceptado);
      SocketService.on('viaje-iniciado', _handleViajeIniciado);
      SocketService.on('viaje-completado', _handleViajeCompletado);
      SocketService.on('viaje-cancelado', _handleViajeCancelado);
    }
  }

  void _handleViajeAceptado(dynamic data) {
    print('📱 Viaje aceptado recibido: $data');
    if (data != null && mounted) {
      setState(() {
        _activeTrip = Map<String, dynamic>.from(data);
        _canCancel = false;
        _countdownTimer?.cancel();
      });
    }
  }

  void _handleViajeIniciado(dynamic data) {
    print('📱 Viaje iniciado recibido: $data');
    if (data != null && mounted) {
      setState(() {
        _activeTrip = Map<String, dynamic>.from(data);
      });
    }
  }

  void _handleViajeCompletado(dynamic data) {
    print('📱 Viaje completado recibido: $data');
    if (data != null && mounted) {
      setState(() {
        _activeTrip =
            null; // Limpiamos el viaje activo para volver al panel de solicitud
        _countdownTimer?.cancel();
      });

      // Mostrar notificación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tu viaje ha finalizado!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navegar al home del pasajero usando RouteHelper
      RouteHelper.goToPassengerHome(context);
    }
  }

  void _handleViajeCancelado(dynamic data) {
    print('📱 Viaje cancelado recibido: $data');
    if (data != null && mounted) {
      setState(() {
        _activeTrip = null;
        _countdownTimer?.cancel();
      });
    }
  }

  Future<void> _checkActiveTrip() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final activeTrip = await _passengerService.getActiveTrip();

      if (!mounted) return;

      if (activeTrip != null) {
        final tiempoCancelacionExpirado =
            activeTrip['tiempo_cancelacion_expirado'] == true;
        final estadoViaje = activeTrip['estado'] ?? 1;

        setState(() {
          _activeTrip = activeTrip;
          _isLoading = false;
          _canCancel = !tiempoCancelacionExpirado && estadoViaje == 1;

          // Si hay un viaje activo que se puede cancelar, iniciar el timer
          if (_canCancel) {
            _remainingSeconds = 300;
            _initializeTimer();
          }

          // Iniciar timer de respaldo para actualizaciones
          _startRefreshTimer();
        });
      } else {
        setState(() {
          _activeTrip = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Error al verificar viaje activo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoviGO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              RouteHelper.goToPassengerHistory(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => RouteHelper.goToProfile(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mapa (placeholder)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Mapa aquí'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Panel inferior que cambia según estado
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_activeTrip != null)
              _buildActiveTripPanel()
            else
              _buildRequestTripPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTripPanel() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _originController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on),
              hintText: '¿Dónde estás?',
              border: OutlineInputBorder(),
            ),
            onTap: () {
              // Mostrar búsqueda de origen
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_searching),
              hintText: '¿A dónde vas?',
              border: OutlineInputBorder(),
            ),
            onTap: () {
              // Mostrar búsqueda de destino
            },
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Solicitar Viaje',
            onPressed: () async {
              try {
                final origin = _originController.text;
                final destination = _destinationController.text;

                if (origin.isEmpty || destination.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor ingresa origen y destino')),
                  );
                  return;
                }

                // Mostrar indicador de carga
                setState(() => _isLoading = true);

                final trip =
                    await _passengerService.requestTrip(origin, destination);

                if (!mounted) return;

                setState(() {
                  _isLoading = false;
                  _activeTrip = trip;
                  _canCancel = true;
                  _remainingSeconds = 300; // 5 minutos
                  _initializeTimer(); // Iniciar el temporizador para el nuevo viaje
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Viaje solicitado con éxito!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripPanel() {
    // Determinar el estado del viaje
    int estado = _activeTrip!['estado'] ?? 1;
    String statusText = '';

    switch (estado) {
      case 1:
        statusText = 'Esperando conductor...';
        break;
      case 2:
        statusText = 'Conductor asignado';
        break;
      case 3:
        statusText = 'En camino';
        break;
      case 4:
        statusText = 'Viaje completado';
        break;
      case 5:
        statusText = 'Viaje cancelado';
        break;
      default:
        statusText = 'Estado desconocido';
    }

    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Agregar botón de actualización (opcional, puedes quitarlo luego)
          ElevatedButton(
            onPressed: () async {
              print("Actualizando manualmente...");
              await _refreshTripStatus();
            },
            child: const Text('Actualizar estado'),
          ),
          const SizedBox(height: 8),

          // Información de origen y destino
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_activeTrip!['origen'] ?? 'Origen no disponible'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_searching, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_activeTrip!['destino'] ?? 'Destino no disponible'),
              ),
            ],
          ),

          // Si podemos cancelar, mostrar temporizador y botón
          if (_canCancel) ...[
            const SizedBox(height: 16),
            Text(
              'Puedes cancelar en: $_formattedTime',
              style: TextStyle(
                color: _remainingSeconds < 60 ? Colors.red : Colors.blue,
              ),
            ),
            Text('Segundos restantes: $_remainingSeconds'),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Cancelar Viaje',
              onPressed: () async {
                try {
                  setState(() => _isLoading = true);
                  print(
                      "Iniciando cancelación de viaje ID: ${_activeTrip!['id']}");

                  bool cancelled =
                      await _passengerService.cancelTrip(_activeTrip!['id']);
                  print("Resultado de la cancelación: $cancelled");

                  if (!mounted) return;

                  if (cancelled) {
                    setState(() {
                      _activeTrip = null;
                      _isLoading = false;
                      _countdownTimer?.cancel();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Viaje cancelado con éxito!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No se pudo cancelar el viaje')),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  print("Error al cancelar viaje: $e");
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ],

          // Si hay conductor asignado, mostrar su información
          if (estado >= 2 &&
              estado <= 4 &&
              _activeTrip!['conductor_id'] != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
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
                      Text(_activeTrip!['conductor'] ?? 'Conductor'),
                      Text(_activeTrip!['vehiculo'] ?? 'Vehículo'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {
                    // Implementar llamada
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _startRefreshTimer() {
    // Cancelar cualquier timer anterior
    _refreshTimer?.cancel();

    // Usar un intervalo más largo (10 segundos) como respaldo a WebSockets
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _refreshTripStatus();
    });
  }

  Future<void> _refreshTripStatus() async {
    if (_activeTrip == null || !mounted) return;

    try {
      print("Consultando estado actual del viaje ID: ${_activeTrip!['id']}");
      final tripId = _activeTrip!['id'];
      final updatedTrip = await _passengerService.getTripById(tripId);

      if (!mounted) return;

      if (updatedTrip != null) {
        print(
            "Estado actual: ${_activeTrip!['estado']}, Nuevo estado: ${updatedTrip['estado']}");

        setState(() {
          _activeTrip = updatedTrip;

          // Actualizar el estado de cancelación
          bool tiempoCancelacionExpirado =
              updatedTrip['tiempo_cancelacion_expirado'] == true;
          int estadoViaje = updatedTrip['estado'] ?? 1;

          // Actualizar si podemos cancelar
          bool previousCanCancel = _canCancel;
          _canCancel = !tiempoCancelacionExpirado && estadoViaje == 1;

          // Si el estado de cancelación cambió
          if (previousCanCancel && !_canCancel) {
            _countdownTimer?.cancel();
          }
        });
      } else {
        print("El viaje ya no existe o no se pudo obtener");
        // Si el viaje ya no existe, limpiar estado
        setState(() {
          _activeTrip = null;
        });
      }
    } catch (e) {
      print('Error al actualizar estado del viaje: $e');
    }
  }
}
