import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
import 'package:movigo_frontend/data/services/driver_service.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  Map<String, dynamic>? _vehicleInfo;

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
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método auxiliar para mostrar errores
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Validar el formulario manualmente
  bool _validateForm() {
    if (_marcaController.text.isEmpty) {
      _showError('Por favor ingresa la marca del vehículo');
      return false;
    }

    if (_modeloController.text.isEmpty) {
      _showError('Por favor ingresa el modelo del vehículo');
      return false;
    }

    if (_anioController.text.isEmpty) {
      _showError('Por favor ingresa el año del vehículo');
      return false;
    }

    // Validar formato de año
    final year = int.tryParse(_anioController.text);
    if (year == null) {
      _showError('Ingresa un año válido');
      return false;
    }
    if (year < 1900 || year > DateTime.now().year) {
      _showError('Ingresa un año entre 1900 y ${DateTime.now().year}');
      return false;
    }

    if (_placaController.text.isEmpty) {
      _showError('Por favor ingresa la placa del vehículo');
      return false;
    }

    if (_colorController.text.isEmpty) {
      _showError('Por favor ingresa el color del vehículo');
      return false;
    }

    return true;
  }

  Future<void> _saveVehicleInfo() async {
    if (!_validateForm() || !mounted) return;

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
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        title: const Text(
          'Información del Vehículo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: movigoPrimaryColor,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Icono de vehículo
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: movigoPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          size: 50,
                          color: movigoPrimaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Título y descripción
                    Text(
                      'Datos del Vehículo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: movigoDarkColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Por favor completa la información de tu vehículo para poder brindar un mejor servicio.',
                      style: TextStyle(
                        fontSize: 16,
                        color: movigoGreyColor,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Campos de formulario
                    MovigoTextField(
                      hintText: 'Marca',
                      controller: _marcaController,
                      prefixIcon: Icons.directions_car,
                    ),

                    const SizedBox(height: 16),

                    MovigoTextField(
                      hintText: 'Modelo',
                      controller: _modeloController,
                      prefixIcon: Icons.car_repair,
                    ),

                    const SizedBox(height: 16),

                    MovigoTextField(
                      hintText: 'Año',
                      controller: _anioController,
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    MovigoTextField(
                      hintText: 'Placa',
                      controller: _placaController,
                      prefixIcon: Icons.credit_card,
                    ),

                    const SizedBox(height: 16),

                    MovigoTextField(
                      hintText: 'Color',
                      controller: _colorController,
                      prefixIcon: Icons.color_lens,
                    ),

                    const SizedBox(height: 30),

                    // Información de consejos para conductores
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(movigoButtonRadius),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Importante',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Asegúrate que la información de tu vehículo coincida con tus documentos oficiales. Esta información será verificada por nuestro equipo.',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Botón guardar
                    MovigoButton(
                      text: 'Guardar Información',
                      onPressed: _saveVehicleInfo,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
