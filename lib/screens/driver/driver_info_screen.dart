import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/widgets/common/custom_text_field.dart';

class DriverInfoScreen extends StatefulWidget {
  const DriverInfoScreen({super.key});

  @override
  State<DriverInfoScreen> createState() => _DriverInfoScreenState();
}

class _DriverInfoScreenState extends State<DriverInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseRateController = TextEditingController();
  String _selectedRateType = 'standard';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Conductor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarifa base
              const Text(
                'Tarifa Base',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Tarifa base por minuto',
                controller: _baseRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.attach_money),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese una tarifa base';
                  }
                  final rate = double.tryParse(value!);
                  if (rate == null || rate <= 0) {
                    return 'Ingrese una tarifa válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tipo de tarifa
              const Text(
                'Tipo de Tarifa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRateTypeCard(
                title: 'Estándar',
                description: 'Tarifa base por minuto',
                value: 'standard',
                icon: Icons.timer,
              ),
              const SizedBox(height: 12),
              _buildRateTypeCard(
                title: 'Premium',
                description: 'Tarifa base + 20%',
                value: 'premium',
                icon: Icons.star,
              ),
              const SizedBox(height: 24),

              // Información adicional
              _buildInfoSection(
                icon: Icons.info_outline,
                title: '¿Cómo se calcula el costo?',
                content:
                    'El costo final se calcula multiplicando la tarifa base '
                    'por los minutos de viaje. Para tarifas premium, se aplica '
                    'un incremento del 20%.',
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                icon: Icons.access_time,
                title: 'Tiempo mínimo',
                content: 'Cada viaje tiene una duración mínima de 5 minutos '
                    'para el cálculo del costo.',
              ),
              const SizedBox(height: 32),

              // Botón guardar
              CustomButton(
                text: 'Guardar Información',
                isLoading: _isLoading,
                onPressed: _saveDriverInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateTypeCard({
    required String title,
    required String description,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedRateType == value;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: () => setState(() => _selectedRateType = value),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _selectedRateType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRateType = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveDriverInfo() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        // Aquí iría la lógica para guardar la información
        await Future.delayed(const Duration(seconds: 2)); // Simulación

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/driver/vehicle-info');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar la información'),
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
    _baseRateController.dispose();
    super.dispose();
  }
}
