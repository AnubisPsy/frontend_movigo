import 'package:flutter/material.dart';
import '../../services/viaje_service.dart';
import '../../models/viaje_estado.dart';

class ViajesPendientesWidget extends StatefulWidget {
  const ViajesPendientesWidget({Key? key}) : super(key: key);

  @override
  State<ViajesPendientesWidget> createState() => _ViajesPendientesWidgetState();
}

class _ViajesPendientesWidgetState extends State<ViajesPendientesWidget> {
  final _viajeService = ViajeService();
  List<Map<String, dynamic>> _viajesPendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarViajesPendientes();
  }

  Future<void> _cargarViajesPendientes() async {
    try {
      final viajes = await _viajeService.obtenerViajesPendientes();
      if (mounted) {
        setState(() {
          _viajesPendientes = viajes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar viajes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _aceptarViaje(String viajeId) async {
    try {
      await _viajeService.aceptarViaje(viajeId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaje aceptado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarViajesPendientes(); // Recargar la lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar viaje: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viajesPendientes.isEmpty) {
      return const Center(
        child: Text('No hay viajes pendientes disponibles'),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarViajesPendientes,
      child: ListView.builder(
        itemCount: _viajesPendientes.length,
        itemBuilder: (context, index) {
          final viaje = _viajesPendientes[index];
          final usuario = viaje['Usuario'] ?? {};

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usuario: ${usuario['nombre']} ${usuario['apellido']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Origen: ${viaje['ubicacionOrigen']?['direccion_referencia'] ?? 'No especificado'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Destino: ${viaje['ubicacionDestino']?['direccion_referencia'] ?? 'No especificado'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _aceptarViaje(viaje['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tomar Viaje'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
