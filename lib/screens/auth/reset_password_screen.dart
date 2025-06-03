import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/widgets/movigo_text_field.dart';
import 'package:movigo_frontend/data/services/auth_service.dart';

class MovigoResetPasswordScreen extends StatefulWidget {
  const MovigoResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<MovigoResetPasswordScreen> createState() =>
      _MovigoResetPasswordScreenState();
}

class _MovigoResetPasswordScreenState extends State<MovigoResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Variables para almacenar datos de la pantalla anterior
  String? _email;
  String? _code;

  @override
  void initState() {
    super.initState();
    // Obtener los argumentos en el siguiente frame después de construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getArguments();
    });
  }

  void _getArguments() {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      setState(() {
        _email = arguments['email'];
        _code = arguments['code'];
      });
    } else {
      // Si no hay argumentos, regresar a la pantalla de inicio de sesión
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hubo un error al procesar tu solicitud'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (_email == null || _code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Información incompleta para restablecer la contraseña'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        await AuthService.resetPassword(
          email: _email!,
          code: _code!,
          newPassword: _passwordController.text,
        );

        if (mounted) {
          setState(() => _isLoading = false);

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Contraseña restablecida con éxito!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar a la pantalla de inicio de sesión
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
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
          'Nueva Contraseña',
          style: TextStyle(
            color: movigoDarkColor,
            fontWeight: FontWeight.bold,
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
                const SizedBox(height: 20),

                // Icono de restablecimiento
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: movigoSecondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.lock_open,
                      size: 50,
                      color: movigoSecondaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Título y descripción
                const Text(
                  'Crea tu nueva contraseña',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: movigoDarkColor,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Tu nueva contraseña debe ser diferente a la anterior y tener al menos 6 caracteres.',
                  style: TextStyle(
                    fontSize: 16,
                    color: movigoGreyColor,
                  ),
                ),

                const SizedBox(height: 30),

                // Nueva contraseña
                MovigoTextField(
                  hintText: 'Nueva contraseña',
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

                const SizedBox(height: 16),

                // Requisitos de la contraseña
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(movigoButtonRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'La contraseña debe:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: movigoDarkColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirementRow(
                        'Tener al menos 6 caracteres',
                        _passwordController.text.length >= 6,
                      ),
                      _buildRequirementRow(
                        'Coincidir en ambos campos',
                        _confirmPasswordController.text ==
                                _passwordController.text &&
                            _confirmPasswordController.text.isNotEmpty,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Botón para restablecer contraseña
                MovigoButton(
                  text: 'Cambiar Contraseña',
                  onPressed: _resetPassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
