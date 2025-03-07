import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:movigo_frontend/core/constants/api_constants.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/driver_service.dart';
import 'package:movigo_frontend/data/services/socket_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';

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
      print("getActiveTrip: Consultando ${url}");

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
        title: const Text('MoviGO - Conductor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              RouteHelper.goToDriverHistory(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => RouteHelper.goToProfile(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de viaje activo (solo visible si hay un viaje activo)
          if (_activeTrip != null)
            GestureDetector(
              onTap: () {
                RouteHelper.goToDriverActiveTrip(
                    context); // Usar el RouteHelper en lugar de Navigator
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Colors.green.shade700,
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: Colors.white,
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
                            ),
                          ),
                          if (_activeTrip != null &&
                              _activeTrip!['destino'] != null)
                            Text(
                              'Destino: ${_activeTrip!['destino']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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

          // Botón de actualizar (y resto del contenido original)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'Actualizar Viajes Disponibles',
              icon: Icons.refresh,
              onPressed: _loadAvailableTrips,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
          // Dentro del Column del body
          if (_activeTrip != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade700),
              ),
              child: ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.green),
                title: const Text('Viaje Activo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Destino: ${_activeTrip?['destino'] ?? 'No disponible'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    RouteHelper.goToDriverActiveTrip(context);
                  },
                  child: const Text('Ver'),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => RouteHelper.goToDriverInfo(context),
        tooltip: 'Configuración del conductor',
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
          Icon(
            Icons.directions_car,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay viajes disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los viajes pendientes aparecerán aquí',
            style: TextStyle(
              color: Colors.grey[500],
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
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showTripDetails(trip),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
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
                      Text(
                        'L. ${(trip['tarifa'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                          trip['destino'] ?? 'Destino no disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 8),
                      Text(
                        trip['Usuario'] != null
                            ? '${trip['Usuario']['nombre']} ${trip['Usuario']['apellido']}'
                            : 'Pasajero',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => _acceptTrip(trip),
                          child: const Text('Aceptar'),
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

  void _showTripDetails(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del Viaje',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Estado:', 'PENDIENTE'),
                  const Divider(),
                  _buildDetailRow('Origen:', trip['origen'] ?? 'No disponible'),
                  const Divider(),
                  _buildDetailRow(
                      'Destino:', trip['destino'] ?? 'No disponible'),
                  const Divider(),
                  _buildDetailRow(
                      'Pasajero:',
                      trip['Usuario'] != null
                          ? '${trip['Usuario']['nombre']} ${trip['Usuario']['apellido']}'
                          : 'No disponible'),
                  const Divider(),
                  _buildDetailRow('Tarifa:',
                      'L. ${(trip['tarifa'] ?? 0.0).toStringAsFixed(2)}'),
                ],
              ),
            ),
            const Spacer(),
            CustomButton(
              text: 'Aceptar Viaje',
              onPressed: () {
                Navigator.pop(context); // Cierra el modal
                _acceptTrip(trip); // Acepta el viaje y navega
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
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
