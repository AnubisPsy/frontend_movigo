import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
import 'package:movigo_frontend/data/services/auth_service.dart';
import 'package:movigo_frontend/data/services/storage_service.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class MovigoRegisterScreen extends StatefulWidget {
  const MovigoRegisterScreen({Key? key}) : super(key: key);

  @override
  State<MovigoRegisterScreen> createState() => _MovigoRegisterScreenState();
}

class _MovigoRegisterScreenState extends State<MovigoRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController =
      TextEditingController(); // Nuevo controlador para teléfono
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = '1'; // 1: Pasajero por defecto
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController
        .dispose(); // Liberar recurso del controlador de teléfono
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          telefono: _telefonoController.text, // Añadir teléfono
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
              RouteHelper.goToPassengerHome(context);
            } else {
              // Los conductores primero deben configurar su información
              RouteHelper.goToDriverInfo(context);
            }
          } else {
            // Si no recibimos token, vamos a login
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registro exitoso. Por favor inicia sesión.'),
                backgroundColor: Colors.green,
              ),
            );
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

  // Añade este método para validar el formulario
  void _validateForm() {
    if (_nombreController.text.isEmpty) {
      _showError('Por favor ingresa tu nombre');
      return;
    }

    if (_apellidoController.text.isEmpty) {
      _showError('Por favor ingresa tu apellido');
      return;
    }

    if (_emailController.text.isEmpty) {
      _showError('Por favor ingresa tu correo electrónico');
      return;
    }

    // Validación de formato de correo
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text)) {
      _showError('Por favor ingresa un correo electrónico válido');
      return;
    }

    // Validación del teléfono
    if (_telefonoController.text.isEmpty) {
      _showError('Por favor ingresa tu número telefónico');
      return;
    }

    // Validar formato de teléfono (opcional, puedes ajustar según el formato esperado)
    final phoneRegExp = RegExp(r'^\+?[0-9]{8,}$');
    if (!phoneRegExp.hasMatch(_telefonoController.text)) {
      _showError(
          'Por favor ingresa un número telefónico válido (mínimo 8 dígitos)');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Por favor ingresa una contraseña');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (_confirmPasswordController.text != _passwordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    // Si todo está bien, proceder con el registro
    _register();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: movigoDarkColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Registro',
          style: TextStyle(
            color: movigoDarkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              'Iniciar Sesión',
              style: TextStyle(
                color: movigoPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: movigoDarkColor,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Completa tus datos para crear una cuenta',
                  style: TextStyle(
                    fontSize: 16,
                    color: movigoGreyColor,
                  ),
                ),

                const SizedBox(height: 30),

                // Nombre
                MovigoTextField(
                  hintText: 'Nombre',
                  controller: _nombreController,
                  prefixIcon: Icons.person,
                ),

                const SizedBox(height: 16),

                // Apellido
                MovigoTextField(
                  hintText: 'Apellido',
                  controller: _apellidoController,
                  prefixIcon: Icons.person_outline,
                ),

                const SizedBox(height: 16),

                // Email
                MovigoTextField(
                  hintText: 'Correo electrónico',
                  controller: _emailController,
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // Teléfono (nuevo campo)
                MovigoTextField(
                  hintText: 'Teléfono',
                  controller: _telefonoController,
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                // Contraseña
                MovigoTextField(
                  hintText: 'Contraseña',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock,
                ),

                const SizedBox(height: 16),

                // Confirmar contraseña
                MovigoTextField(
                  hintText: 'Confirmar contraseña',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                ),

                const SizedBox(height: 24),

                // Selector de rol
                Text(
                  'Tipo de cuenta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: movigoDarkColor,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: movigoBorderColor),
                    borderRadius: BorderRadius.circular(movigoButtonRadius),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Pasajero'),
                        value: '1',
                        groupValue: _selectedRole,
                        activeColor: movigoPrimaryColor,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      Divider(height: 1, color: movigoBorderColor),
                      RadioListTile<String>(
                        title: const Text('Conductor'),
                        value: '2',
                        groupValue: _selectedRole,
                        activeColor: movigoPrimaryColor,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Términos y condiciones
                RichText(
                  text: TextSpan(
                    text: 'Al hacer clic en "Registrarse" aceptas nuestros ',
                    style: TextStyle(color: movigoGreyColor),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'términos y condiciones',
                        style: TextStyle(
                          color: movigoPrimaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text: ' y la ',
                        style: TextStyle(color: movigoGreyColor),
                      ),
                      TextSpan(
                        text: 'política de privacidad',
                        style: TextStyle(
                          color: movigoPrimaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Botón de registro
                MovigoButton(
                  text: 'Registrarse',
                  onPressed: _validateForm,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
