import 'package:flutter/material.dart';
import 'package:movigo_frontend/data/services/profile_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/widgets/common/custom_text_field.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (userData != null) {
      _nombreController.text = userData['nombre'] ?? '';
      _apellidoController.text = userData['apellido'] ?? '';
      _emailController.text = userData['email'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Verificar si hay cambios sin guardar
            if (_hasUnsavedChanges()) {
              _showDiscardChangesDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Editar Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Nombre',
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese su nombre';
                  }
                  if (value!.length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
                    return 'El nombre solo debe contener letras';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Apellido',
                controller: _apellidoController,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese su apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese su email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value!)) {
                    return 'Ingrese un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Guardar Cambios',
                isLoading: _isLoading,
                onPressed: _updateProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
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

        await ProfileService.updateProfile(
          token: token,
          nombre: _nombreController.text,
          apellido: _apellidoController.text,
          email: _emailController.text,
        );

        if (mounted) {
          Navigator.pop(context); // Regresa a la pantalla de perfil
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado exitosamente'),
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

  bool _hasUnsavedChanges() {
    final userData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return userData != null &&
        (_nombreController.text != userData['nombre'] ||
            _apellidoController.text != userData['apellido'] ||
            _emailController.text != userData['email']);
  }

  Future<void> _showDiscardChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('¿Deseas descartar los cambios realizados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Descartar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
