import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:movigo_frontend/widgets/movigo_button.dart';
import 'package:movigo_frontend/data/services/auth_service.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class MovigoVerifyCodeScreen extends StatefulWidget {
  const MovigoVerifyCodeScreen({Key? key}) : super(key: key);

  @override
  State<MovigoVerifyCodeScreen> createState() => _MovigoVerifyCodeScreenState();
}

class _MovigoVerifyCodeScreenState extends State<MovigoVerifyCodeScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    // Obtener el email de los argumentos
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
      });
    } else {
      // Si no hay argumentos, regresar a la pantalla anterior
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información incompleta'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // Liberar controladores y nodos de foco
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyCode() async {
    // Obtener el código completo
    String code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el código completo de 6 dígitos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar el correo electrónico'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.verifyCode(_email!, code);

      if (mounted) {
        setState(() => _isLoading = false);

        // Si el código es válido, navegamos a la pantalla de reset password
        RouteHelper.goToResetPassword(
          context,
          {
            'email': _email!,
            'code': code,
          },
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

  void _resendCode() async {
    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar el correo electrónico'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.forgotPassword(_email!);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Se ha enviado un nuevo código a tu correo electrónico'),
            backgroundColor: Colors.green,
          ),
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
          'Verificar Código',
          style: TextStyle(
            color: movigoDarkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icono de verificación
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: movigoPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 50,
                  color: movigoPrimaryColor,
                ),
              ),

              const SizedBox(height: 30),

              // Título y descripción
              const Text(
                'Ingresa el código de verificación',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: movigoDarkColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Hemos enviado un código de 6 dígitos a tu correo electrónico ${_email ?? ''}',
                style: const TextStyle(
                  fontSize: 16,
                  color: movigoGreyColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Campos para el código de verificación
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: movigoDarkColor,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                          borderSide: const BorderSide(color: movigoBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(movigoButtonRadius),
                          borderSide:
                              const BorderSide(color: movigoPrimaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        // Mover al siguiente campo si se ingresó un dígito
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        // Mover al campo anterior si se borró un dígito
                        else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              // Botón de verificación
              MovigoButton(
                text: 'Verificar Código',
                onPressed: _verifyCode,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 20),

              // Opción para reenviar código
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No recibiste el código?',
                    style: TextStyle(
                      color: movigoGreyColor,
                    ),
                  ),
                  TextButton(
                    onPressed: _resendCode,
                    child: const Text(
                      'Reenviar',
                      style: TextStyle(
                        color: movigoPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
