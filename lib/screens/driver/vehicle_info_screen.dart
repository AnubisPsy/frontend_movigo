import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/widgets/common/custom_text_field.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Vehículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del vehículo (placeholder)
              Center(
                child: Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Formulario
              CustomTextField(
                label: 'Marca',
                controller: _brandController,
                prefixIcon: const Icon(Icons.branding_watermark),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese la marca';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Modelo',
                controller: _modelController,
                prefixIcon: const Icon(Icons.model_training),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese el modelo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Año',
                controller: _yearController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese el año';
                  }
                  final year = int.tryParse(value!);
                  if (year == null ||
                      year < 1990 ||
                      year > DateTime.now().year) {
                    return 'Ingrese un año válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Placa',
                controller: _plateController,
                prefixIcon: const Icon(Icons.pin),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese la placa';
                  }
                  // Aquí podrías agregar validación de formato de placa
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Color',
                controller: _colorController,
                prefixIcon: const Icon(Icons.color_lens),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese el color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'La información del vehículo debe coincidir con '
                        'los documentos registrados.',
                        style: TextStyle(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              CustomButton(
                text: 'Guardar Vehículo',
                isLoading: _isLoading,
                onPressed: _saveVehicleInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveVehicleInfo() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        // Aquí iría la lógica para guardar la información
        await Future.delayed(const Duration(seconds: 2)); // Simulación

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/driver/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar la información del vehículo'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }
}
