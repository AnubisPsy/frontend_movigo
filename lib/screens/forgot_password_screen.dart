import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _currentStep = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearCurrentInputs() {
    switch (_currentStep) {
      case 0:
        _emailController.clear();
        break;
      case 1:
        _codeController.clear();
        break;
      case 2:
        _passwordController.clear();
        _confirmPasswordController.clear();
        break;
    }
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese su email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Por favor ingrese un email válido';
            }
            return null;
          },
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                debugPrint('Intentando enviar código...');
                final response =
                    await _authService.forgotPassword(_emailController.text);
                debugPrint('Respuesta recibida: $response');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Código enviado al correo')),
                );
                setState(() {
                  _currentStep = 1;
                });
              } catch (e) {
                debugPrint('Error al enviar código: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Text('Enviar Código'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      children: [
        TextFormField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: 'Código de Verificación',
            prefixIcon: Icon(Icons.lock_clock),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el código';
            }
            if (value.length != 6) {
              return 'El código debe tener 6 dígitos';
            }
            return null;
          },
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                // Verificar el código
                await _authService.verifyCode(
                  _emailController.text,
                  _codeController.text,
                );

                // Si llegamos aquí, el código es válido
                setState(() {
                  _currentStep = 2;
                });
              } catch (e) {
                // Si el código es inválido, mostrar error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Text('Verificar Código'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
          ),
        ),
        TextButton(
          onPressed: () async {
            try {
              await _authService.forgotPassword(_emailController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Nuevo código enviado')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Reenviar código'),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Nueva Contraseña',
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese su nueva contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirmar Nueva Contraseña',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor confirme su contraseña';
            }
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                await _authService.resetPassword(
                  _emailController.text,
                  _codeController.text, // Ya verificado en el paso anterior
                  _passwordController.text,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Contraseña actualizada exitosamente')),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Text('Actualizar Contraseña'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recuperar Contraseña'),
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  _clearCurrentInputs();
                  setState(() {
                    _currentStep--;
                  });
                },
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'Email'),
                    _buildStepDivider(),
                    _buildStepIndicator(1, 'Código'),
                    _buildStepDivider(),
                    _buildStepIndicator(2, 'Contraseña'),
                  ],
                ),
              ),
              SizedBox(height: 24),
              if (_currentStep == 0) _buildEmailStep(),
              if (_currentStep == 1) _buildVerificationStep(),
              if (_currentStep == 2) _buildNewPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green
                  : (isActive ? Theme.of(context).primaryColor : Colors.grey),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Theme.of(context).primaryColor : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 40,
      height: 1,
      color: Colors.grey,
    );
  }
}
