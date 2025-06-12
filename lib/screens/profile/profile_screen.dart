import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/movigo_button.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/storage_service.dart';
import '../../core/navigation/route_helper.dart';

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
        backgroundColor: movigoPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Verificar el rol del usuario que ya está cargado en _userData
            if (_userData != null && _userData!['rol'] == '2') {
              RouteHelper.goToDriverHome(context);
            } else {
              RouteHelper.goToPassengerHome(context);
            }
          },
        ),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              await RouteHelper.goToEditProfile(context, _userData ?? {});
              _loadUserData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: movigoPrimaryColor,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'No se pudo cargar la información',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: movigoDarkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Error desconocido',
            style: const TextStyle(
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          MovigoButton(
            text: 'Reintentar',
            onPressed: _loadUserData,
            color: movigoSecondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Perfil de usuario con avatar
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: movigoPrimaryColor.withOpacity(0.1),
                    child: Text(
                      _getUserInitials(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: movigoPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_userData?['nombre'] ?? ''} ${_userData?['apellido'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: movigoDarkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData?['rol'] == '1' ? 'Pasajero' : 'Conductor',
                    style: const TextStyle(
                      fontSize: 16,
                      color: movigoSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Sección de información personal
            _buildSectionTitle('Información Personal'),

            const SizedBox(height: 16),

            // Tarjeta con la información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(movigoButtonRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                      'Nombre', _userData?['nombre'] ?? '', Icons.person),
                  const Divider(height: 20),
                  _buildInfoRow('Apellido', _userData?['apellido'] ?? '',
                      Icons.person_outline),
                  const Divider(height: 20),
                  _buildInfoRow(
                      'Email', _userData?['email'] ?? '', Icons.email),
                  const Divider(height: 20),
                  _buildInfoRow('Teléfono',
                      _userData?['telefono'] ?? 'No especificado', Icons.phone),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Sección de acciones
            _buildSectionTitle('Opciones'),

            const SizedBox(height: 16),

            // Botones de acción
            MovigoButton(
              text: 'Cambiar Contraseña',
              onPressed: () => RouteHelper.goToChangePassword(context),
              color: movigoSecondaryColor,
            ),

            const SizedBox(height: 16),

            if (_userData?['rol'] == '2') // Solo para conductores
              MovigoButton(
                text: 'Información del Vehículo',
                onPressed: () => RouteHelper.goToVehicleInfo(context),
                color: movigoSecondaryColor,
              ),

            const SizedBox(height: 30),

            // Sección de cuenta
            _buildSectionTitle('Cuenta'),

            const SizedBox(height: 16),

            // Botón de cerrar sesión
            MovigoButton(
              text: 'Cerrar Sesión',
              onPressed: _logout,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: movigoPrimaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: movigoDarkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: movigoPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: movigoPrimaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: movigoGreyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: movigoDarkColor,
                  ),
                ),
              ],
            ),
          ),
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
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: movigoDarkColor,
          ),
        ),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
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
              'Cerrar Sesión',
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

    if (shouldLogout ?? false) {
      await StorageService.clearAll();
      if (mounted) {
        RouteHelper.goToLogin(context);
      }
    }
  }
}
