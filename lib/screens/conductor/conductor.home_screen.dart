import 'package:flutter/material.dart';
import '../../services/viaje_service.dart';
import '../../widgets/profile_button.dart'; // Añade esta importación

class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({Key? key}) : super(key: key);

  @override
  _ConductorHomeScreenState createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  final _viajeService = ViajeService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _viajesPendientes = [];

  @override
  void initState() {
    super.initState();
    _cargarViajesPendientes();
  }

  Future<void> _cargarViajesPendientes() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      debugPrint('====== DEBUG CARGAR VIAJES PENDIENTES ======');
      debugPrint('Iniciando carga de viajes pendientes...');

      final viajes = await _viajeService.obtenerViajesPendientes();
      debugPrint('Viajes obtenidos: ${viajes.length}');

      if (!mounted) return;

      setState(() {
        _viajesPendientes = viajes;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error detallado al cargar viajes: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar viajes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAceptarViaje(String viajeId) async {
    try {
      await _viajeService.aceptarViaje(viajeId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaje aceptado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarViajesPendientes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar viaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildViajeCard(Map<String, dynamic> viaje) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${viaje['usuario']?['nombre'] ?? 'N/A'} ${viaje['usuario']?['apellido'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Estado: ${viaje['estado'] ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Ubicaciones
            Text(
              'Origen: ${viaje['ubicacionOrigen']?['direccion_referencia'] ?? 'No especificado'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Destino: ${viaje['ubicacionDestino']?['direccion_referencia'] ?? 'No especificado'}',
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleAceptarViaje(viaje['id']),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tomar Viaje'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoviGO - Conductor'),
        actions: [
          ProfileButton(), // Reemplaza el IconButton por el ProfileButton
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarViajesPendientes,
              child: _viajesPendientes.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay viajes pendientes disponibles',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _viajesPendientes.length,
                      itemBuilder: (context, index) =>
                          _buildViajeCard(_viajesPendientes[index]),
                    ),
            ),
    );
  }
}
