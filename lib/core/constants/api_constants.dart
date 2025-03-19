// lib/core/constants/api_constants.dart
class ApiConstants {
  //static const String baseUrl = 'https://movigo-service.onrender.com/api';
  static const String baseUrl = 'http://localhost:3000/api';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyCode = '/auth/verify-code';
  static const String resetPassword = '/auth/reset-password';
  static const String updatePassword = '/auth/update-password';

  // Perfil endopints
  static const String getUserProfile = '/usuarios';
  static const String updateUserProfile = '/usuarios/profile';
  static const String changePassword = '/usuarios/cambiar-password';

  static const String tripHistory = '/viajes/historial';
  static const String goToRequestTrip = '/viajes';
}
