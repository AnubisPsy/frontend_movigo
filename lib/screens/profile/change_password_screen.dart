import 'package:flutter/material.dart';
import 'package:movigo_frontend/data/services/profile_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/widgets/common/custom_text_field.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Contraseña Actual',
                controller: _currentPasswordController,
                isPassword: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese su contraseña actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Nueva Contraseña',
                controller: _newPasswordController,
                isPassword: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese la nueva contraseña';
                  }
                  if ((value?.length ?? 0) < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Confirmar Nueva Contraseña',
                controller: _confirmPasswordController,
                isPassword: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor confirme la nueva contraseña';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Cambiar Contraseña',
                isLoading: _isLoading,
                onPressed: _changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
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
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
