import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_text_field.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/data/services/auth_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';
import 'package:movigo_frontend/data/services/passenger_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MoviGO',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Correo electrónico',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor ingrese su correo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor ingrese su contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Iniciar Sesión',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    RouteHelper.goToRegister(context);
                  },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
                TextButton(
                  onPressed: () {
                    RouteHelper.goToForgotPassword(context);
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
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
            final passengerService = PassengerService();
            final activeTrip = await passengerService.getActiveTrip();

            // Solo considerar un viaje como activo si su estado es 1 (PENDIENTE), 2 (ACEPTADO) o 3 (EN_CURSO)
            // Los estados 4 (COMPLETADO) y 5 (CANCELADO) no son activos
            if (activeTrip != null &&
                (activeTrip['estado'] == 1 ||
                    activeTrip['estado'] == 2 ||
                    activeTrip['estado'] == 3)) {
              // Si hay un viaje activo, mantener en la pantalla del viaje
              RouteHelper.goToPassengerHome(context);
              return;
            } else {
              // Si no hay viaje activo o el viaje está completado/cancelado, ir al home
              RouteHelper.goToPassengerHome(context);
            }
          } else {
            // Para conductores, usar la redirección normal
            RouteHelper.goToHomeBasedOnRole(context, response['user']['rol']);
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
