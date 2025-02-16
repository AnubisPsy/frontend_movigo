// lib/screens/conductor/profile_conductor_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/vehiculo_service.dart';
import '../login_screen.dart';

class ProfileConductorScreen extends StatefulWidget {
  const ProfileConductorScreen({Key? key}) : super(key: key);

  @override
  State<ProfileConductorScreen> createState() => _ProfileConductorScreenState();
}

class _ProfileConductorScreenState extends State<ProfileConductorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  // Controladores para el vehículo
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _placaController = TextEditingController();
  final _colorController = TextEditingController();

  final _authService = AuthService();
  final _profileService = ProfileService();
  final _vehiculoService = VehiculoService();

  bool _isLoading = false;
  bool _showPasswordForm = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

// En _loadUserData() de ProfileConductorScreen
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

        // Intentar cargar datos del vehículo después
        try {
          final vehiculoData =
              await _vehiculoService.obtenerVehiculoConductor();
          if (vehiculoData != null) {
            setState(() {
              _marcaController.text = vehiculoData['marca'] ?? '';
              _modeloController.text = vehiculoData['modelo'] ?? '';
              _anioController.text = vehiculoData['anio']?.toString() ?? '';
              _placaController.text = vehiculoData['placa'] ?? '';
              _colorController.text = vehiculoData['color'] ?? '';
            });
          }
        } catch (vehiculoError) {
          debugPrint('Error al cargar vehículo: $vehiculoError');
          // No mostrar error al usuario por ahora
        }
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

        if (userId == null) throw Exception('No se encontró ID de usuario');

        // Actualizar datos del perfil
        if (_nameController.text.isNotEmpty ||
            _lastNameController.text.isNotEmpty) {
          await _profileService.updateProfile(
            userId,
            nombre: _nameController.text,
            apellido: _lastNameController.text,
          );

          await prefs.setString('userName', _nameController.text);
          await prefs.setString('userLastName', _lastNameController.text);
        }

        // Actualizar datos del vehículo
        await _vehiculoService.actualizarVehiculo({
          'marca': _marcaController.text,
          'modelo': _modeloController.text,
          'anio': _anioController.text,
          'placa': _placaController.text,
          'color': _colorController.text,
        });

        // Actualizar contraseña si se proporcionó
        if (_currentPasswordController.text.isNotEmpty &&
            _newPasswordController.text.isNotEmpty) {
          await _authService.updatePassword(
            userId,
            _currentPasswordController.text,
            _newPasswordController.text,
          );
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
        title: Text('Perfil del Conductor'),
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
                    // Avatar y datos personales (igual que en profile_settings_screen)
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.person, size: 50, color: Colors.blue),
                    ),
                    SizedBox(height: 24),

                    // Datos personales
                    Text(
                      'Datos Personales',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
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

                    // Datos del vehículo
                    Text(
                      'Datos del Vehículo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _marcaController,
                      decoration: InputDecoration(
                        labelText: 'Marca',
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _modeloController,
                      decoration: InputDecoration(
                        labelText: 'Modelo',
                        prefixIcon: Icon(Icons.car_repair),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _anioController,
                      decoration: InputDecoration(
                        labelText: 'Año',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Campo requerido';
                        final year = int.tryParse(value!);
                        if (year == null) return 'Año inválido';
                        if (year < 1900 || year > DateTime.now().year) {
                          return 'Año fuera de rango';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _placaController,
                      decoration: InputDecoration(
                        labelText: 'Placa',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: 'Color',
                        prefixIcon: Icon(Icons.color_lens),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    SizedBox(height: 24),

                    // Botón y formulario de cambio de contraseña (igual que en profile_settings_screen)
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

                    if (_showPasswordForm) ...[
                      SizedBox(height: 24),
                      // ... resto del formulario de contraseña igual que en profile_settings_screen
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
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _placaController.dispose();
    _colorController.dispose();
    super.dispose();
  }
}
