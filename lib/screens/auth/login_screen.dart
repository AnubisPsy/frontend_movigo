import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
import 'package:movigo_frontend/data/services/auth_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class MovigoLoginScreen extends StatefulWidget {
  const MovigoLoginScreen({Key? key}) : super(key: key);

  @override
  State<MovigoLoginScreen> createState() => _MovigoLoginScreenState();
}

class _MovigoLoginScreenState extends State<MovigoLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa email y contraseña')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Usar el servicio de autenticación existente
      final response = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );

      // Guardar el token y datos del usuario
      await StorageService.saveToken(response['token']);
      await StorageService.saveUser(response['user']);

      if (mounted) {
        setState(() => _isLoading = false);

        // Verificar si el usuario es un pasajero
        if (response['user']['rol'] == '1') {
          // Navegar a la pantalla de inicio del pasajero
          RouteHelper.goToPassengerHome(context);
        } else {
          // Navegar a la pantalla de inicio del conductor
          RouteHelper.goToDriverHome(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToForgotPassword() {
    RouteHelper.goToForgotPassword(context);
  }

  void _goToRegister() {
    RouteHelper.goToRegister(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo y título
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: movigoPrimaryColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MoviGO',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: movigoDarkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Viajes seguros y confiables',
                      style: TextStyle(
                        fontSize: 16,
                        color: movigoGreyColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Formulario de inicio de sesión
              Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: movigoDarkColor,
                ),
              ),
              const SizedBox(height: 16),

              MovigoTextField(
                hintText: 'Correo electrónico',
                controller: _emailController,
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              MovigoTextField(
                hintText: 'Contraseña',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: Icons.lock,
              ),
              const SizedBox(height: 8),

              // Olvidé mi contraseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _goToForgotPassword,
                  child: Text(
                    'Olvidé mi contraseña',
                    style: TextStyle(
                      color: movigoPrimaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón de inicio de sesión
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : MovigoButton(
                      text: 'Iniciar Sesión',
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),

              const SizedBox(height: 24),

              // Opción para registrarse
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes cuenta?'),
                    TextButton(
                      onPressed: _goToRegister,
                      child: Text(
                        'Regístrate',
                        style: TextStyle(
                          color: movigoPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
