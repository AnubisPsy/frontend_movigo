import 'package:flutter/material.dart';
import 'package:movigo_frontend/data/services/driver_service.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  Map<String, dynamic>? _vehicleInfo;

  final _formKey = GlobalKey<FormState>();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _placaController = TextEditingController();
  final _colorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicleInfo();
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _placaController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleInfo() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final info = await _driverService.getVehicleInfo();

      if (mounted) {
        setState(() {
          _vehicleInfo = info;
          _isLoading = false;

          // Llenar controladores
          if (info != null) {
            _marcaController.text = info['marca'] ?? '';
            _modeloController.text = info['modelo'] ?? '';
            _anioController.text = (info['año'] ?? '').toString();
            _placaController.text = info['placa'] ?? '';
            _colorController.text = info['color'] ?? '';
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

  Future<void> _saveVehicleInfo() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final info = {
        'marca': _marcaController.text,
        'modelo': _modeloController.text,
        'año': int.tryParse(_anioController.text) ?? DateTime.now().year,
        'placa': _placaController.text,
        'color': _colorController.text,
      };

      await _driverService.saveVehicleInfo(info);

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Información del vehículo guardada con éxito'),
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
        title: const Text('Información del Vehículo'),
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
                              'Datos del Vehículo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _marcaController,
                              decoration: const InputDecoration(
                                labelText: 'Marca',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.directions_car),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa la marca';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _modeloController,
                              decoration: const InputDecoration(
                                labelText: 'Modelo',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.car_repair),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa el modelo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _anioController,
                              decoration: const InputDecoration(
                                labelText: 'Año',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa el año';
                                }
                                final year = int.tryParse(value);
                                if (year == null) {
                                  return 'Ingresa un año válido';
                                }
                                if (year < 1900 || year > DateTime.now().year) {
                                  return 'Ingresa un año entre 1900 y ${DateTime.now().year}';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _placaController,
                              decoration: const InputDecoration(
                                labelText: 'Placa',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.credit_card),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa la placa';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _colorController,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.color_lens),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa el color';
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
                      onPressed: _saveVehicleInfo,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
