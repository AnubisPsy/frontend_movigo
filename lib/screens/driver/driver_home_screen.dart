import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/movigo_button.dart';
import '../../core/navigation/route_helper.dart';
import '../../data/services/driver_service.dart';
import '../../data/services/socket_service.dart';
import '../../data/services/storage_service.dart';
import '../../screens/driver/driver_negotiation_screen.dart';
import 'package:http/http.dart' as http;

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  bool _redirectingToActiveTrip = false;
  bool _suppressRedirection = false;

  List<Map<String, dynamic>> _availableTrips = [];
  Map<String, dynamic>? _activeTrip;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> &&
          args['fromActiveTripScreen'] == true) {
        // Si venimos de la pantalla de viaje activo, no redireccionar de vuelta
        _suppressRedirection = true;
      }

      _checkActiveTrip(); // Una sola llamada aquí
    });

    _loadAvailableTrips();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    // Remover listeners al salir de la pantalla
    SocketService.off('viaje-solicitado', _handleViajeSolicitado);
    SocketService.off('viaje-cancelado', _handleViajeCancelado);
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
      SocketService.on('viaje-solicitado', _handleViajeSolicitado);
      SocketService.on('viaje-cancelado', _handleViajeCancelado);
    }
  }

  void _handleViajeSolicitado(dynamic data) {
    print('📱 Nuevo viaje solicitado recibido: $data');
    // No actualizamos automáticamente, solo mostramos notificación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '¡Nuevo viaje disponible! Toca Actualizar para verlo.'),
          action: SnackBarAction(
            label: 'Actualizar',
            onPressed: _loadAvailableTrips,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleViajeCancelado(dynamic data) {
    print('📱 Viaje cancelado recibido: $data');
    if (data != null && mounted) {
      setState(() {
        // Eliminar el viaje cancelado de la lista
        _availableTrips.removeWhere((trip) => trip['id'] == data['id']);

        // Si el viaje activo fue cancelado, limpiarlo
        if (_activeTrip != null && _activeTrip!['id'] == data['id']) {
          _activeTrip = null;
        }
      });

      // Mostrar notificación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un viaje ha sido cancelado'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> getActiveTrip() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        print("getActiveTrip: No hay token de autenticación");
        return null;
      }

      // Primero obtenemos todos los viajes
      String url = '${ApiConstants.baseUrl}/viajes';
      print("getActiveTrip: Consultando $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("getActiveTrip: Código de respuesta ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          List<dynamic> tripsList = jsonResponse['data'];
          print("getActiveTrip: Se encontraron ${tripsList.length} viajes");

          // Filtrar viajes en estado 2 (ACEPTADO) o 3 (EN_CURSO)
          final activeTrips = tripsList.where((trip) {
            final estado = trip['estado'];
            return estado == 2 || estado == 3;
          }).toList();

          print(
              "getActiveTrip: Viajes activos filtrados: ${activeTrips.length}");

          if (activeTrips.isNotEmpty) {
            final activeTrip = activeTrips.first;
            print(
                "getActiveTrip: Viaje activo encontrado con ID: ${activeTrip['id']}");
            return Map<String, dynamic>.from(activeTrip);
          }
        }
      } else {
        print("Error en getActiveTrip: ${response.statusCode}");
        print("Respuesta: ${response.body}");
      }

      print("getActiveTrip: No se encontró ningún viaje activo");
      return null;
    } catch (e) {
      print('Error en getActiveTrip: $e');
      return null;
    }
  }

  Future<void> _checkActiveTrip() async {
    if (!mounted || _redirectingToActiveTrip) return;

    setState(() => _isLoading = true);

    try {
      final activeTrip = await _driverService.getActiveTrip();

      if (!mounted) return;

      setState(() {
        _activeTrip = activeTrip;
        _isLoading = false;
      });

      // Solo redireccionar si hay un viaje activo Y no estamos suprimiendo la redirección
      if (_activeTrip != null && !_suppressRedirection) {
        print(
            "Viaje activo encontrado, redirigiendo a pantalla de viaje activo");

        // Marcar que ya estamos redirigiendo para evitar múltiples redirecciones
        _redirectingToActiveTrip = true;

        // Usar un pequeño retraso para asegurar que la UI esté lista
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          RouteHelper.goToDriverActiveTrip(context);
        }
      } else {
        print("No se encontró viaje activo o redirección suprimida");
        _loadAvailableTrips(); // Cargar viajes disponibles
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Error al verificar viaje activo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error al verificar viajes activos: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadAvailableTrips() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final trips = await _driverService.getAvailableTrips();

      if (!mounted) return;

      setState(() {
        _availableTrips = trips;
        _isLoading = false;
      });

      print("Viajes disponibles cargados: ${_availableTrips.length}");

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_availableTrips.isEmpty
              ? 'No hay viajes disponibles en este momento'
              : 'Se encontraron ${_availableTrips.length} viajes disponibles'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        title: const Text(
          'MoviGO - Conductor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              RouteHelper.goToDriverHistory(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => RouteHelper.goToProfile(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de viaje activo (solo visible si hay un viaje activo)
          if (_activeTrip != null)
            Material(
              color: Colors.green.shade700,
              elevation: 4,
              child: InkWell(
                onTap: () {
                  RouteHelper.goToDriverActiveTrip(context);
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Viaje Activo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_activeTrip != null &&
                                _activeTrip!['destino'] != null)
                              Text(
                                'Destino: ${_activeTrip!['destino']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Botón de actualizar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: MovigoButton(
              text: 'Actualizar Viajes Disponibles',
              onPressed: _loadAvailableTrips,
              isLoading: _isLoading,
            ),
          ),

          // Lista de viajes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => RouteHelper.goToDriverInfo(context),
        tooltip: 'Configuración del conductor',
        backgroundColor: movigoPrimaryColor,
        elevation: 4,
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildBody() {
    if (_availableTrips.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildTripsList();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              size: 50,
              color: movigoGreyColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay viajes disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: movigoDarkColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los viajes pendientes aparecerán aquí',
            style: TextStyle(
              fontSize: 16,
              color: movigoGreyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableTrips.length,
      itemBuilder: (context, index) {
        final trip = _availableTrips[index];

        // Mostrar si tiene precio propuesto
        final tienePrecioPropuesto = trip['estado_negociacion'] == 'propuesto';
        final precioPropuesto = trip['precio_propuesto']?.toString() ?? '0.00';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(movigoButtonRadius),
          ),
          child: InkWell(
            onTap: () => _showTripDetails(trip),
            borderRadius: BorderRadius.circular(movigoButtonRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: movigoPrimaryColor,
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                        ),
                        child: const Text(
                          'PENDIENTE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Mostrar precio propuesto si existe
                      if (tienePrecioPropuesto)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: movigoSecondaryColor,
                            borderRadius:
                                BorderRadius.circular(movigoButtonRadius),
                          ),
                          child: Text(
                            'L. $precioPropuesto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['origen'] ?? 'Origen no disponible',
                          style: const TextStyle(
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
                      const Icon(Icons.location_searching, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['destino'] ?? 'Destino no disponible',
                          style: const TextStyle(
                            fontSize: 16,
                            color: movigoDarkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: movigoGreyColor),
                      const SizedBox(width: 8),
                      Text(
                        trip['Usuario'] != null
                            ? '${trip['Usuario']['nombre']} ${trip['Usuario']['apellido']}'
                            : 'Pasajero',
                        style: const TextStyle(
                          fontSize: 14,
                          color: movigoGreyColor,
                        ),
                      ),
                      const Spacer(),

                      // Botón según si hay precio propuesto o no
                      if (tienePrecioPropuesto)
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _navegarANegociacion(trip),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: movigoSecondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(movigoButtonRadius),
                              ),
                            ),
                            child: const Text(
                              'Negociar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _acceptTrip(trip),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: movigoPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(movigoButtonRadius),
                              ),
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
              ),
            ),
          ),
        );
      },
    );
  }

  void _navegarANegociacion(Map<String, dynamic> trip) {
    // Asegúrate de que el ID se imprime para depuración
    print('Viaje a negociar: ID=${trip['id']}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverNegotiationScreen(tripData: trip),
      ),
    );
  }

// Método alternativo que abre una pantalla completa en lugar de un modal
  void _showTripDetails(Map<String, dynamic> trip) {
    final tienePrecioPropuesto = trip['estado_negociacion'] == 'propuesto';
    final precioPropuesto = trip['precio_propuesto']?.toString() ?? '0.00';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(movigoBottomSheetRadius)),
      ),
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                // Título con estilo MoviGO
                const Text(
                  'Detalles del Viaje',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: movigoDarkColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Contenedor de detalles con estilo MoviGO
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(movigoButtonRadius),
                    border: Border.all(color: movigoBorderColor),
                  ),
                  child: Column(
                    children: [
                      // Estado
                      _buildDetailRow(
                          'Estado:', 'PENDIENTE', Icons.info_outline),
                      const Divider(height: 24),

                      // Precio propuesto si existe
                      if (tienePrecioPropuesto) ...[
                        _buildDetailRow('Precio propuesto:',
                            'L. $precioPropuesto', Icons.attach_money),
                        const Divider(height: 24),
                      ],

                      // Origen
                      _buildDetailRow('Origen:',
                          trip['origen'] ?? 'No disponible', Icons.location_on),
                      const Divider(height: 24),

                      // Destino
                      _buildDetailRow(
                          'Destino:',
                          trip['destino'] ?? 'No disponible',
                          Icons.location_searching),
                      const Divider(height: 24),

                      // Pasajero
                      _buildDetailRow(
                          'Pasajero:',
                          trip['Usuario'] != null
                              ? '${trip['Usuario']['nombre']} ${trip['Usuario']['apellido']}'
                              : 'No disponible',
                          Icons.person_outline),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Botón principal con estilo MoviGO
                MovigoButton(
                  text: tienePrecioPropuesto
                      ? 'Negociar Precio'
                      : 'Aceptar Viaje',
                  onPressed: () {
                    Navigator.pop(context);
                    if (tienePrecioPropuesto) {
                      _navegarANegociacion(trip);
                    } else {
                      _acceptTrip(trip);
                    }
                  },
                  color: tienePrecioPropuesto
                      ? movigoSecondaryColor
                      : movigoPrimaryColor,
                ),

                const SizedBox(height: 16),

                // Botón cancelar con estilo MoviGO
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: movigoPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // Margen adicional para prevenir desbordamientos
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
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

  Future<void> _acceptTrip(Map<String, dynamic> trip) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final tripId = trip['id'];
      if (tripId == null) {
        throw Exception('ID de viaje no disponible');
      }

      final updatedTrip = await _driverService.acceptTrip(tripId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _activeTrip = updatedTrip; // Establecer el viaje activo
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje aceptado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar directamente sin argumentos adicionales
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/driver/active-trip',
        (route) => false,
        arguments: updatedTrip,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
