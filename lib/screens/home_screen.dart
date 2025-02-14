import 'package:flutter/material.dart';
import '../../services/viaje_service.dart';
import '../widgets/viaje/viaje_estado_widget.dart'; // Importamos el widget
import '../../widgets/viaje/solicitar_viaje_button.dart';
import '../../widgets/profile_button.dart';
import '../../models/viaje_estado.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _viajeActivo;
  bool _isLoading = true;
  final _viajeService = ViajeService();

  @override
  void initState() {
    super.initState();
    _verificarViajeActivo();
  }

  Future<void> _verificarViajeActivo() async {
    try {
      final viajeActivo = await _viajeService.obtenerViajeActivo();

      if (mounted) {
        setState(() {
          _viajeActivo = viajeActivo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar viaje: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleViajeSolicitado() {
    _verificarViajeActivo();
  }

  void _handleViajeCancelado() async {
    try {
      await _viajeService.cancelarViaje();
      if (mounted) {
        setState(() {
          _viajeActivo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar viaje: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _tieneViajeActivo {
    if (_viajeActivo == null) return false;
    final estado = _viajeActivo!['estado'];
    return estado != ViajeEstado.CANCELADO && estado != ViajeEstado.FINALIZADO;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoviGO'),
        actions: [
          ProfileButton(), // Quitamos el const de aquí
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _verificarViajeActivo,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      if (_tieneViajeActivo && _viajeActivo != null)
                        ViajeEstadoWidget(
                          estado: _viajeActivo!['estado'],
                          viajeData: _viajeActivo!,
                          onViajeCancelado: _handleViajeCancelado,
                        )
                      else
                        Center(
                          child: SolicitarViajeButton(
                            onViajeSolicitado: _handleViajeSolicitado,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
