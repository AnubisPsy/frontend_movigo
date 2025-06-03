import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
import 'package:movigo_frontend/data/services/auth_service.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class MovigoForgotPasswordScreen extends StatefulWidget {
  const MovigoForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<MovigoForgotPasswordScreen> createState() =>
      _MovigoForgotPasswordScreenState();
}

class _MovigoForgotPasswordScreenState
    extends State<MovigoForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendCode() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingresa tu correo electrónico')),
      );
      return;
    }

    // Validación básica de formato de correo
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingresa un correo electrónico válido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.forgotPassword(_emailController.text);

      if (mounted) {
        setState(() => _isLoading = false);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se ha enviado un código a tu correo electrónico'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a la pantalla de verificación de código
        RouteHelper.goToVerifyCode(
          context,
          {'email': _emailController.text},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: movigoDarkColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(
            color: movigoDarkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Icono de recuperación
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: movigoPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 50,
                      color: movigoPrimaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Título y descripción
                const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: movigoDarkColor,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Ingresa tu correo electrónico para recibir un código de verificación y poder restablecer tu contraseña.',
                  style: TextStyle(
                    fontSize: 16,
                    color: movigoGreyColor,
                  ),
                ),

                const SizedBox(height: 30),

                // Campo de correo electrónico
                MovigoTextField(
                  hintText: 'Correo electrónico',
                  controller: _emailController,
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 30),

                // Botón para enviar código
                MovigoButton(
                  text: 'Enviar Código',
                  onPressed: _sendCode,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),

                // Volver a inicio de sesión
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Volver a Iniciar Sesión',
                      style: TextStyle(
                        color: movigoPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
