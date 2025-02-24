import 'package:flutter/material.dart';
import 'package:movigo_frontend/widgets/common/custom_button.dart';
import 'package:movigo_frontend/core/navigation/route_helper.dart';

class SearchingDriverScreen extends StatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _canCancel = true; // Control para los primeros 5 minutos
  int _searchTimeInSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Timer para contar el tiempo de búsqueda
    _startSearchTimer();
  }

  void _startSearchTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _searchTimeInSeconds++;
        });
        if (_searchTimeInSeconds < 300) {
          // 5 minutos
          _startSearchTimer();
        } else {
          _canCancel = false;
        }
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevenir botón atrás
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animación de búsqueda
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.05)
                      .animate(_pulseController),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.local_taxi,
                      size: 64,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Texto de búsqueda
                const Text(
                  'Buscando conductor...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tiempo de búsqueda: ${_formatTime(_searchTimeInSeconds)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (_canCancel)
                  Text(
                    'Puedes cancelar durante los primeros 5 minutos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 40),

                // Botón de cancelar
                if (_canCancel)
                  CustomButton(
                    text: 'Cancelar Búsqueda',
                    onPressed: _cancelSearch,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _cancelSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar búsqueda'),
        content: const Text('¿Estás seguro que deseas cancelar la búsqueda?'),
        actions: [
          TextButton(
            onPressed: () => RouteHelper.closeDialog(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              RouteHelper.closeDialog(context);
              RouteHelper.goToPassengerHome(context);
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
