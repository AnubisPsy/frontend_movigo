import 'package:flutter/material.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/driver_service.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';

class DriverInfoScreen extends StatefulWidget {
  const DriverInfoScreen({super.key});

  @override
  State<DriverInfoScreen> createState() => _DriverInfoScreenState();
}

class _DriverInfoScreenState extends State<DriverInfoScreen> {
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  Map<String, dynamic>? _driverInfo;

  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _licenciaController = TextEditingController();
  final _tarifaBaseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  @override
  void dispose() {
    _dniController.dispose();
    _licenciaController.dispose();
    _tarifaBaseController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverInfo() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final info = await _driverService.getDriverInfo();

      if (mounted) {
        setState(() {
          _driverInfo = info;
          _isLoading = false;

          // Llenar controladores
          if (info != null) {
            _dniController.text = info['dni'] ?? '';
            _licenciaController.text = info['licencia'] ?? '';
            _tarifaBaseController.text = (info['tarifa_base'] ?? '').toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveDriverInfo() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final info = {
        'dni': _dniController.text,
        'licencia': _licenciaController.text,
        'tarifa_base': double.tryParse(_tarifaBaseController.text) ?? 0.0,
      };

      await _driverService.saveDriverInfo(info);

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Información guardada con éxito'),
            backgroundColor: Colors.green,
          ),
        );

        // Volver a la pantalla anterior
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Conductor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Datos del Conductor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _dniController,
                              decoration: const InputDecoration(
                                labelText: 'DNI / Identidad',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu DNI';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _licenciaController,
                              decoration: const InputDecoration(
                                labelText: 'Número de Licencia',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu número de licencia';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _tarifaBaseController,
                              decoration: const InputDecoration(
                                labelText: 'Tarifa Base (L)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu tarifa base';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Ingresa un valor numérico válido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Guardar Información',
                      onPressed: _saveDriverInfo,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => RouteHelper.goToVehicleInfo(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                      ),
                      child: const Text('Administrar Información del Vehículo'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
