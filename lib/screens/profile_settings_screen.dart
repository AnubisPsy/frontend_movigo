// lib/screens/profile_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'login_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _authService = AuthService();
  final _profileService = ProfileService();
  bool _isLoading = false;
  bool _showPasswordForm = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      debugPrint('ID recuperado: $userId'); // Para debug

      if (userId != null) {
        final userData = await _profileService.getProfile(userId);
        debugPrint('Datos del usuario: $userData'); // Para debug

        setState(() {
          _nameController.text = userData['nombre'] ?? '';
          _lastNameController.text = userData['apellido'] ?? '';
          _emailController.text = userData['email'] ?? '';
        });
      } else {
        throw Exception('No se encontró ID de usuario');
      }
    } catch (e) {
      debugPrint('Error en _loadUserData: $e'); // Para debug
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        if (userId == null) {
          throw Exception('No se encontró ID de usuario');
        }

        // Actualizar datos del perfil
        if (_nameController.text.isNotEmpty ||
            _lastNameController.text.isNotEmpty) {
          final response = await _profileService.updateProfile(
            userId,
            nombre: _nameController.text,
            apellido: _lastNameController.text,
          );

          // Actualizar SharedPreferences
          await prefs.setString('userName', _nameController.text);
          await prefs.setString('userLastName', _lastNameController.text);
        }

        // Actualizar contraseña si se proporcionó
        if (_currentPasswordController.text.isNotEmpty &&
            _newPasswordController.text.isNotEmpty) {
          await _authService.updatePassword(
            userId,
            _currentPasswordController.text,
            _newPasswordController.text,
          );

          // Limpiar campos de contraseña
          _currentPasswordController.clear();
          _newPasswordController.clear();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.person, size: 50, color: Colors.blue),
                    ),
                    SizedBox(height: 24),
                    // Datos del perfil
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Apellido',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      enabled: false,
                    ),
                    SizedBox(height: 24),

                    // Botón para mostrar/ocultar formulario de contraseña
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPasswordForm = !_showPasswordForm;
                        });
                      },
                      icon: Icon(_showPasswordForm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      label: Text(_showPasswordForm
                          ? 'Ocultar cambio de contraseña'
                          : 'Cambiar contraseña'),
                    ),

                    // Formulario de cambio de contraseña
                    if (_showPasswordForm) ...[
                      SizedBox(height: 24),
                      Text(
                        'Cambiar Contraseña',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña Actual',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_showPasswordForm && (value?.isEmpty ?? true)) {
                            return 'Ingrese la contraseña actual';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_showPasswordForm && (value?.isEmpty ?? true)) {
                            return 'Ingrese la nueva contraseña';
                          }
                          return null;
                        },
                      ),
                    ],

                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _logout,
                      child: Text('Cerrar Sesión'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
