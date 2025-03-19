import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
import 'package:movigo_frontend/data/services/profile_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Estado para las validaciones de contraseña
  bool _hasMinLength = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    // Agregar listeners para validar en tiempo real
    _newPasswordController.addListener(_checkPasswordRequirements);
    _confirmPasswordController.addListener(_checkPasswordRequirements);
  }

  void _checkPasswordRequirements() {
    setState(() {
      _hasMinLength = _newPasswordController.text.length >= 6;
      _passwordsMatch =
          _newPasswordController.text == _confirmPasswordController.text &&
              _confirmPasswordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        title: const Text(
          'Cambiar Contraseña',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono de contraseña
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: movigoPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 50,
                      color: movigoPrimaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Título y descripción
                Text(
                  'Actualiza tu contraseña',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: movigoDarkColor,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Ingresa tu contraseña actual y la nueva contraseña que deseas utilizar.',
                  style: TextStyle(
                    fontSize: 16,
                    color: movigoGreyColor,
                  ),
                ),

                const SizedBox(height: 30),

                // Campos de formulario
                MovigoTextField(
                  hintText: 'Contraseña actual',
                  controller: _currentPasswordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                MovigoTextField(
                  hintText: 'Nueva contraseña',
                  controller: _newPasswordController,
                  prefixIcon: Icons.lock,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                MovigoTextField(
                  hintText: 'Confirmar nueva contraseña',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_reset,
                  isPassword: true,
                ),

                const SizedBox(height: 24),

                // Requisitos de contraseña
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(movigoButtonRadius),
                    border: Border.all(color: movigoBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'La contraseña debe:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: movigoDarkColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRequirementRow(
                        'Tener al menos 6 caracteres',
                        _hasMinLength,
                      ),
                      const SizedBox(height: 8),
                      _buildRequirementRow(
                        'Coincidir en ambos campos',
                        _passwordsMatch,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Botón de cambio de contraseña
                MovigoButton(
                  text: 'Cambiar Contraseña',
                  onPressed: _changePassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isMet
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isMet ? Icons.check : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Método para validar el formulario
  bool _validateForm() {
    if (_currentPasswordController.text.isEmpty) {
      _showError('Por favor ingresa tu contraseña actual');
      return false;
    }

    if (_newPasswordController.text.isEmpty) {
      _showError('Por favor ingresa una nueva contraseña');
      return false;
    }

    if (_newPasswordController.text.length < 6) {
      _showError('La nueva contraseña debe tener al menos 6 caracteres');
      return false;
    }

    if (_confirmPasswordController.text != _newPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return false;
    }

    return true;
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

  Future<void> _changePassword() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (mounted) {
          RouteHelper.goToLogin(context);
        }
        return;
      }

      await ProfileService.changePassword(
        token: token,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
