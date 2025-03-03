import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _availableTrips = [];
  Map<String, dynamic>? _activeTrip;

  @override
  void initState() {
    super.initState();
    _checkActiveTrip();
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

  Future<void> _checkActiveTrip() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final activeTrip = await _driverService.getActiveTrip();

      if (!mounted) return;

      setState(() {
        _activeTrip = activeTrip;
        _isLoading = false;
      });

      // Si hay un viaje activo, navegar a la pantalla de viaje activo
      if (_activeTrip != null) {
        RouteHelper.goToDriverActiveTrip(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Error al verificar viaje activo: $e');
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
          // Botón de actualizar prominente en la parte superior
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'Actualizar Viajes Disponibles',
              icon: Icons.refresh,
              onPressed: _loadAvailableTrips,
            ),
          ),
          // Resto del contenido
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => RouteHelper.goToDriverInfo(context),
        child: const Icon(Icons.settings),
        tooltip: 'Configuración del conductor',
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
                _acceptTrip(trip);
                Navigator.pop(context);
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

      await _driverService.acceptTrip(tripId);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje aceptado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a la pantalla de viaje activo
      RouteHelper.goToDriverActiveTrip(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
