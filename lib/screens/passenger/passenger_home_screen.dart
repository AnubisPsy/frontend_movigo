import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/passenger_service.dart';
import 'dart:async';
import 'package:movigo_frontend/data/services/socket_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/widgets/map/mapa_en_tiempo_real.dart';
import 'package:movigo_frontend/screens/passenger/trip_price_screen.dart';
import 'package:movigo_frontend/screens/passenger/trip_confirmation_screen.dart';
import 'package:movigo_frontend/screens/common/trip_completed_screen.dart';

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
  Timer? _refreshTimer;

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
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _initializeWebSocket() async {
    // Inicializar Socket.IO
    await SocketService.init();

    // Obtener el ID del usuario
    final userId = await StorageService.getUserId();
    print("Inicializando WebSocket para usuario: $userId");

    if (userId != null) {
      // Suscribirse a eventos del usuario
      SocketService.subscribeToUserEvents(userId);
      print("Suscrito a eventos para usuario: $userId");

      // Registrar handlers para diferentes tipos de eventos
      SocketService.on('viaje-aceptado', _handleViajeAceptado);
      SocketService.on('viaje-iniciado', _handleViajeIniciado);
      SocketService.on('viaje-completado', _handleViajeCompletado);
      SocketService.on('viaje-cancelado', _handleViajeCancelado);

      print("Handlers de WebSocket registrados correctamente");
    } else {
      print("ERROR: No se pudo obtener el ID del usuario para WebSocket");
    }
  }

  void _handleViajeAceptado(dynamic data) {
    print('📱 Viaje aceptado recibido: $data');
    if (data != null && mounted) {
      // Imprimir datos completos para verificar la estructura
      print("Datos completos del viaje aceptado: $data");
      print("Estado antes de actualizar: ${_activeTrip?['estado']}");

      // Convertir data a un mapa si no lo es ya
      Map<String, dynamic> dataMap;
      if (data is Map<String, dynamic>) {
        dataMap = data;
      } else {
        dataMap = Map<String, dynamic>.from(data);
      }

      setState(() {
        // IMPORTANTE: Verificar que los datos del conductor estén presentes
        if (dataMap['Conductor'] != null) {
          print("✅ Datos del conductor presentes en la actualización");
        } else {
          print("⚠️ Datos del conductor AUSENTES en la actualización");
        }

        _activeTrip = dataMap;
      });

      print("Estado después de actualizar: ${_activeTrip?['estado']}");

      // Mostrar un mensaje para confirmar la actualización
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Un conductor ha aceptado tu viaje!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      print('⚠️ Datos de viaje aceptado nulos o widget no montado');
    }
  }

  void _handleViajeIniciado(dynamic data) {
    print('📱 Viaje iniciado recibido: $data');
    if (data != null && mounted) {
      // Imprimir datos completos para verificar la estructura
      print("Datos completos del viaje iniciado: $data");
      print("Estado antes de actualizar: ${_activeTrip?['estado']}");

      setState(() {
        _activeTrip = Map<String, dynamic>.from(data);
      });

      print("Estado después de actualizar: ${_activeTrip?['estado']}");

      // Forzar la reconstrucción del UI
      setState(() {});

      // Mostrar un mensaje para confirmar la actualización
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tu viaje ha comenzado!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      print('⚠️ Datos de viaje iniciado nulos o widget no montado');
    }
  }

  void _handleViajeCompletado(dynamic data) {
    print('📱 Viaje completado recibido: $data');
    if (data != null && mounted) {
      // Imprimir los datos para depuración
      print("Datos completos del viaje completado: $data");

      setState(() {
        _activeTrip = null; // Limpiamos el viaje activo
        _refreshTimer?.cancel(); // Detener el timer de actualización
      });

      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovigoTripCompletedScreen(
                tripData: data,
                isConductor: false,
              ),
            ),
          );
        }
      });

      // Navegar a la pantalla de viaje completado
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovigoTripCompletedScreen(
            tripData: data,
            isConductor: false,
          ),
        ),
      );
    } else {
      print('⚠️ Datos de viaje completado nulos o widget no montado');
    }
  }

  // Método actualizado para manejar viaje cancelado
  void _handleViajeCancelado(dynamic data) {
    print('📱 Viaje cancelado recibido: $data');
    if (data != null && mounted) {
      setState(() {
        _activeTrip = null;
        _refreshTimer?.cancel(); // Detener el timer de actualización
      });

      // Mostrar diálogo de viaje cancelado
      _showCanceledDialog();
    }
  }

  Future<void> _checkActiveTrip() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Primer intento: buscar en almacenamiento local
      final activeTrip = await _passengerService.getActiveTrip();

      if (activeTrip != null) {
        // Si existe localmente, verificar si sigue existiendo en el servidor
        final tripId = activeTrip['id'];
        final serverTrip = await _passengerService.getTripById(tripId);

        if (serverTrip != null) {
          // El viaje sigue existiendo en el servidor
          setState(() {
            _activeTrip = serverTrip;
            _isLoading = false;
          });

          // Iniciar timer de respaldo para actualizaciones
          _startRefreshTimer();
          return; // Salir porque ya encontramos un viaje activo
        }
      }

      // Si no encontramos nada local o no es válido, hacer consulta directa al servidor
      final trips = await _passengerService.getTripHistory();

      // Buscar cualquier viaje que esté en estado pendiente(1), aceptado(2) o en curso(3)
      final pendingTrip = trips.firstWhere(
        (trip) =>
            trip['status'] == 1 || trip['status'] == 2 || trip['status'] == 3,
        orElse: () => <String, dynamic>{},
      );

      if (pendingTrip.isNotEmpty && pendingTrip['id'] != null) {
        // Obtener detalles completos del viaje
        final fullTripDetails =
            await _passengerService.getTripById(pendingTrip['id']);

        if (fullTripDetails != null) {
          setState(() {
            _activeTrip = fullTripDetails;
            _isLoading = false;
          });

          // Iniciar timer de respaldo para actualizaciones
          _startRefreshTimer();
          return;
        }
      }

      // Si no hay viaje activo, limpiar el estado
      if (mounted) {
        setState(() {
          _activeTrip = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Error al verificar viaje activo: $e');
      }
    }
  }

  void _startRefreshTimer() {
    // Cancelar cualquier timer anterior
    _refreshTimer?.cancel();

    // Usar un intervalo más corto (5 segundos) para una actualización más responsiva
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _refreshTripStatus();
    });

    print("⏰ Timer de actualización iniciado (cada 5 segundos)");
  }

  Future<void> _refreshTripStatus() async {
    if (_activeTrip == null || !mounted) return;

    try {
      final tripId = _activeTrip!['id'];
      print("⏰ Refrescando estado del viaje ID: $tripId");

      // Guardar datos importantes que no queremos perder
      final conductorActual = _activeTrip!['Conductor'];
      final vehiculoActual = _activeTrip!['Vehiculo'];

      final updatedTrip = await _passengerService.getTripById(tripId);

      if (!mounted) return;

      if (updatedTrip != null) {
        final oldState = _activeTrip!['estado'];
        final newState = updatedTrip['estado'];

        print("⏰ Estado actual: $oldState, Nuevo estado: $newState");

        // Preservar la información del conductor
        if (updatedTrip['Conductor'] == null && conductorActual != null) {
          print("⚠️ Preservando datos del conductor que se perderían");
          updatedTrip['Conductor'] = conductorActual;
        }

        // Preservar la información del vehículo
        if (updatedTrip['Vehiculo'] == null && vehiculoActual != null) {
          print("⚠️ Preservando datos del vehículo que se perderían");
          updatedTrip['Vehiculo'] = vehiculoActual;
        }

        setState(() {
          _activeTrip = updatedTrip;
        });

        // Mostrar mensaje solo si hay cambio de estado
        if (oldState != newState) {
          String mensaje = "";

          switch (newState) {
            case 2:
              mensaje = "¡Un conductor ha aceptado tu viaje!";
              break;
            case 3:
              mensaje = "¡Tu viaje ha comenzado!";
              break;
            case 4:
              mensaje = "¡Viaje completado!";
              break;
            case 5:
              mensaje = "Viaje cancelado";
              break;
          }

          if (mensaje.isNotEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(mensaje),
                backgroundColor: newState == 5 ? Colors.red : Colors.green,
              ),
            );
          }
        }
      } else {
        print("⏰ El viaje ya no existe o no se pudo obtener");
        // No eliminamos el viaje si no podemos obtener una actualización
        // Solo hacemos esto si estamos seguros de que el viaje se canceló
        /*
      setState(() {
        _activeTrip = null;
      });
      */
      }
    } catch (e) {
      print('⏰ Error al actualizar estado del viaje: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        title: const Text(
          'MoviGO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              RouteHelper.goToPassengerHistory(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => RouteHelper.goToProfile(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mapa en tiempo real
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(movigoButtonRadius),
                child: MapaEnTiempoReal(
                  esViajePendiente: _activeTrip != null,
                  tripData: _activeTrip,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Panel inferior que cambia según estado
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: movigoPrimaryColor,
                ),
              )
            else if (_activeTrip != null)
              _buildActiveTripPanel()
            else
              _buildRequestTripPanel(),
          ],
        ),
      ),
    );
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Viaje Completado'),
        content: const Text('Tu viaje ha sido completado exitosamente.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo
              RouteHelper.goToPassengerHome(context); // Redirigir al home
            },
            child: Text(
              'Aceptar',
              style: TextStyle(color: movigoPrimaryColor),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(movigoButtonRadius),
        ),
      ),
    );
  }

  void _showCanceledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Viaje Cancelado'),
        content: const Text('Tu viaje ha sido cancelado.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo
              RouteHelper.goToPassengerHome(context); // Redirigir al home
            },
            child: Text(
              'Aceptar',
              style: TextStyle(color: movigoPrimaryColor),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(movigoButtonRadius),
        ),
      ),
    );
  }

  Widget _buildRequestTripPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(movigoButtonRadius),
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
          MovigoTextField(
            hintText: '¿Dónde estás?',
            controller: _originController,
            prefixIcon: Icons.location_on,
          ),
          const SizedBox(height: 12),
          MovigoTextField(
            hintText: '¿A dónde vas?',
            controller: _destinationController,
            prefixIcon: Icons.location_searching,
          ),
          const SizedBox(height: 16),
          MovigoButton(
            text: 'Solicitar Viaje',
            onPressed: () {
              final origin = _originController.text;
              final destination = _destinationController.text;

              if (origin.isEmpty || destination.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa origen y destino'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              print(
                  "Navegando a pantalla de confirmación: origin=$origin, destination=$destination");

              // Solo navegamos a la pantalla de confirmación
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripConfirmationScreen(
                    origin: origin,
                    destination: destination,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripPanel() {
    if (_activeTrip == null) {
      print("ERROR: _activeTrip es nulo en _buildActiveTripPanel");
      return Container();
    }

    // Obtener y verificar el estado
    int estado;

    // Asegurar que el estado sea un entero
    if (_activeTrip!['estado'] is int) {
      estado = _activeTrip!['estado'];
    } else if (_activeTrip!['estado'] is String) {
      estado = int.tryParse(_activeTrip!['estado']) ?? 1;
    } else {
      // Si no es ninguno de los anteriores, usar valor por defecto
      estado = 1;
    }

    print(
        "Estado en _buildActiveTripPanel: $estado (tipo: ${_activeTrip!['estado'].runtimeType})");

    // Determinar el texto de estado
    String statusText = '';
    Color statusColor;

    switch (estado) {
      case 1:
        statusText = 'Esperando conductor...';
        statusColor = Colors.orange;
        break;
      case 2:
        statusText = 'Conductor asignado';
        statusColor = Colors.blue;
        break;
      case 3:
        statusText = 'En camino';
        statusColor = movigoSecondaryColor;
        break;
      case 4:
        statusText = 'Viaje completado';
        statusColor = Colors.green;
        break;
      case 5:
        statusText = 'Viaje cancelado';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'Estado desconocido';
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(movigoButtonRadius),
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
          // Indicador de estado con color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: movigoDarkColor,
                  ),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: movigoDarkColor,
                  ),
                ),
              ),
            ],
          ),

          // Solo mostrar el botón de cancelar si está en estado pendiente (1)
          if (estado == 1) ...[
            const SizedBox(height: 20),
            MovigoButton(
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
                      _refreshTimer?.cancel();
                    });

                    _showCanceledDialog();
                  } else {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo cancelar el viaje'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  print("Error al cancelar viaje: $e");
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              color: Colors.red,
            ),
          ],

          // Si hay conductor asignado, mostrar su información
          if (estado >= 2 &&
              estado <= 4 &&
              _activeTrip!['Conductor'] != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(movigoButtonRadius),
                border: Border.all(color: movigoBorderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: movigoPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.person,
                      color: movigoPrimaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Usar la información del conductor desde el objeto Conductor
                        Text(
                          _activeTrip!['Conductor'] != null
                              ? "${_activeTrip!['Conductor']['nombre']} ${_activeTrip!['Conductor']['apellido'] ?? ''}"
                              : "Conductor",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: movigoDarkColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activeTrip!['Vehiculo'] != null
                              ? "${_activeTrip!['Vehiculo']['marca']} ${_activeTrip!['Vehiculo']['modelo']} - ${_activeTrip!['Vehiculo']['placa'] ?? ''} (${_activeTrip!['Vehiculo']['color'] ?? ''})"
                              : "Vehículo",
                          style: TextStyle(
                            color: movigoGreyColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: movigoPrimaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.phone,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        // Lógica para llamar al conductor
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Llamando al conductor...'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
