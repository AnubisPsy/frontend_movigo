import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
import 'package:movigo_frontend/data/services/profile_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
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
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Verificar si hay cambios sin guardar
            if (_hasUnsavedChanges()) {
              _showDiscardChangesDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Editar Perfil',
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
                // Icono de perfil
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: movigoPrimaryColor.withOpacity(0.1),
                        child: Text(
                          _getUserInitials(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: movigoPrimaryColor,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: movigoPrimaryColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Título y descripción
                Text(
                  'Editar información personal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: movigoDarkColor,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Actualiza tus datos personales y pulsa guardar para confirmar los cambios.',
                  style: TextStyle(
                    fontSize: 16,
                    color: movigoGreyColor,
                  ),
                ),

                const SizedBox(height: 30),

                // Campos de formulario
                MovigoTextField(
                  hintText: 'Nombre',
                  controller: _nombreController,
                  prefixIcon: Icons.person,
                ),

                const SizedBox(height: 20),

                MovigoTextField(
                  hintText: 'Apellido',
                  controller: _apellidoController,
                  prefixIcon: Icons.person_outline,
                ),

                const SizedBox(height: 20),

                MovigoTextField(
                  hintText: 'Email',
                  controller: _emailController,
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 30),

                // Información de privacidad
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
                            'Información de privacidad',
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
                        'Tu correo electrónico se utilizará solo para verificar tu identidad y enviarte notificaciones importantes relacionadas con tus viajes.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Botón de guardar cambios
                MovigoButton(
                  text: 'Guardar Cambios',
                  onPressed: _updateProfile,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método para validar el formulario
  bool _validateForm() {
    if (_nombreController.text.isEmpty) {
      _showError('Por favor ingresa tu nombre');
      return false;
    }

    if (_apellidoController.text.isEmpty) {
      _showError('Por favor ingresa tu apellido');
      return false;
    }

    if (_emailController.text.isEmpty) {
      _showError('Por favor ingresa tu email');
      return false;
    }

    // Validar formato de correo
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text)) {
      _showError('Por favor ingresa un email válido');
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

  Future<void> _updateProfile() async {
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
        title: Text(
          'Cambios sin guardar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: movigoDarkColor,
          ),
        ),
        content: const Text('¿Deseas descartar los cambios realizados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: movigoPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(movigoButtonRadius),
              ),
            ),
            child: const Text(
              'Descartar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(movigoButtonRadius),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
      ),
    );

    if (result ?? false) {
      Navigator.pop(context);
    }
  }

  String _getUserInitials() {
    final userData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (userData == null) return '';

    final nombre = userData['nombre'] ?? '';
    final apellido = userData['apellido'] ?? '';
    return '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}'
        .toUpperCase();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
