import 'package:flutter/material.dart';
import 'package:movigo_frontend/data/services/auth_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/widgets/common/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = '1'; // 1: Pasajero por defecto
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Nombre',
                controller: _nombreController,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese su nombre';
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
                label: 'Correo electrónico',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingrese su correo';
                  }
                  // Validación básica de email
                  if (!value!.contains('@')) {
                    return 'Ingrese un correo válido';
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
                  if ((value?.length ?? 0) < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de confirmación de contraseña
              CustomTextField(
                label: 'Confirmar Contraseña',
                controller: _confirmPasswordController,
                isPassword: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor confirme su contraseña';
                  }
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Selector de rol
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Pasajero'),
                      value: '1',
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Conductor'),
                      value: '2',
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Registrarse',
                isLoading: _isLoading,
                onPressed: _register,
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final response = await AuthService.register(
          email: _emailController.text,
          password: _passwordController.text,
          nombre: _nombreController.text,
          apellido: _apellidoController.text,
          rol: _selectedRole,
        );

        if (mounted) {
          setState(() => _isLoading = false);

          // Guardamos el token y datos del usuario si los recibimos
          if (response.containsKey('token')) {
            await StorageService.saveToken(response['token']);
            if (response.containsKey('usuario')) {
              await StorageService.saveUser(response['usuario']);
            }

            // Navegamos según el rol
            if (_selectedRole == '1') {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/passenger/home',
                (route) => false,
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/driver/info', // Los conductores primero deben configurar su información
                (route) => false,
              );
            }
          } else {
            // Si no recibimos token, vamos a login
            Navigator.pushReplacementNamed(context, '/login');
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
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController
        .dispose(); // No olvides dispose del nuevo controller
    super.dispose();
  }
}
