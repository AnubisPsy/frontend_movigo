import 'package:flutter/material.dart';
import 'package:movigo_frontend/data/services/profile_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await StorageService.getToken();

      if (token == null || token.isEmpty) {
        if (mounted) {
          RouteHelper.goToLogin(context);
        }
        return;
      }

      final userData = await ProfileService.getUserProfile(token);

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => RouteHelper.goToPassengerHome(context)),
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await RouteHelper.goToEditProfile(context, _userData ?? {});
              _loadUserData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto de perfil (placeholder por ahora)
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                _getUserInitials(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Información del usuario
          _buildInfoTile('Nombre', _userData?['nombre'] ?? ''),
          _buildInfoTile('Apellido', _userData?['apellido'] ?? ''),
          _buildInfoTile('Email', _userData?['email'] ?? ''),
          _buildInfoTile(
            'Rol',
            _userData?['rol'] == '1' ? 'Pasajero' : 'Conductor',
          ),

          const SizedBox(height: 32),

          // Botones de acción
          CustomButton(
              text: 'Cambiar Contraseña',
              onPressed: () => RouteHelper.goToChangePassword(context)),
          const SizedBox(height: 16),

          if (_userData?['rol'] == '2') // Solo para conductores
            CustomButton(
              text: 'Información del Vehículo',
              onPressed: () => RouteHelper.goToVehicleInfo(context),
            ),

          const SizedBox(height: 32),

          CustomButton(
            text: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  String _getUserInitials() {
    final nombre = _userData?['nombre'] ?? '';
    final apellido = _userData?['apellido'] ?? '';
    return '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}'
        .toUpperCase();
  }

  Future<void> _logout() async {
    // Mostrar diálogo de confirmación
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
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
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout ?? false) {
      await StorageService.clearAll();
      if (mounted) {
        RouteHelper.goToLogin(context);
      }
    }
  }
}
