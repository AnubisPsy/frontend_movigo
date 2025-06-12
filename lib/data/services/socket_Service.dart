import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/api_constants.dart';
import '../../data/services/storage_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _initialized = false;

  // Mapa para almacenar los callbacks por evento
  static final Map<String, List<Function(dynamic)>> _eventHandlers = {};

  // Inicializar la conexión Socket.IO
  static Future<void> init() async {
    if (_initialized) return;

    final String baseUrl = ApiConstants.baseUrl
        .substring(0, ApiConstants.baseUrl.lastIndexOf('/api'));
    print('Intentando conectar a Socket.IO en: $baseUrl');

    try {
      _socket = IO.io(baseUrl, <String, dynamic>{
        'transports': [
          'websocket',
          'polling'
        ], // Agregar 'polling' como fallback
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      });

      _socket!.onConnect((_) async {
        print('⚡ Socket.IO conectado');

        // Autenticar con token
        final token = await StorageService.getToken();
        if (token != null) {
          _socket!.emit('authenticate', token);
          print('Token enviado para autenticación');
        }
      });

      _socket!.onConnectError((error) {
        print('⚠️ Error de conexión Socket.IO: $error');
      });

      _socket!.onDisconnect((_) {
        print('❌ Socket.IO desconectado');
      });

      _initialized = true;
    } catch (e) {
      print('Error al inicializar Socket.IO: $e');
    }
  }

  // Suscribirse a eventos para un usuario específico
  static void subscribeToUserEvents(String userId) {
    if (_socket == null) return;

    final eventName = 'viaje-$userId';
    print('Suscribiéndose a eventos: $eventName');

    _socket!.on(eventName, (data) {
      print('📩 Evento recibido: $eventName');
      print('Datos: $data');

      if (data is Map && data.containsKey('tipo')) {
        final tipo = data['tipo'];
        final eventData = data['data'];

        // Disparar callbacks registrados para este tipo de evento
        if (_eventHandlers.containsKey(tipo)) {
          for (var callback in _eventHandlers[tipo]!) {
            callback(eventData);
          }
        }
      }
    });
  }

  // Registrar un handler para un tipo específico de evento
  static void on(String eventType, Function(dynamic) callback) {
    if (!_eventHandlers.containsKey(eventType)) {
      _eventHandlers[eventType] = [];
    }

    _eventHandlers[eventType]!.add(callback);
    print('Handler registrado para evento: $eventType');
  }

  // Eliminar un handler
  static void off(String eventType, Function(dynamic) callback) {
    if (_eventHandlers.containsKey(eventType)) {
      _eventHandlers[eventType]!.remove(callback);
      print('Handler eliminado para evento: $eventType');
    }
  }

  // Cerrar la conexión
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _initialized = false;
      _eventHandlers.clear();
      print('Socket.IO desconectado manualmente');
    }
  }
}
