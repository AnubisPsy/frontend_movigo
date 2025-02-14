import 'package:flutter/material.dart';
import '../../services/viaje_service.dart';
import '../../services/auth_service.dart';

class SolicitarViajeScreen extends StatefulWidget {
  @override
  _SolicitarViajeScreenState createState() => _SolicitarViajeScreenState();
}

class _SolicitarViajeScreenState extends State<SolicitarViajeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  final _viajeService = ViajeService();
  bool _isLoading = false;

  Future<void> _solicitarViaje() async {
    try {
      setState(() => _isLoading = true);
      await _viajeService.solicitarViaje({
        'origen_referencia': _origenController.text,
        'destino_referencia': _destinoController.text,
      });

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje solicitado exitosamente!'),
        ),
      );

      // Volver al HomeScreen y actualizar
      Navigator.pop(context,
          true); // El true indica que se solicitó un viaje exitosamente
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al solicitar viaje: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Viaje'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          // Agregamos Form widget
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _origenController,
                decoration: const InputDecoration(
                  labelText: 'Origen',
                  hintText: 'Ej: Mi casa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Por favor ingrese el origen'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinoController,
                decoration: const InputDecoration(
                  labelText: 'Destino',
                  hintText: 'Ej: Centro comercial',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Por favor ingrese el destino'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _solicitarViaje();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Solicitar Viaje'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _origenController.dispose();
    _destinoController.dispose();
    super.dispose();
  }
}
