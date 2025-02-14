import 'dart:async';
import 'package:flutter/material.dart';

class CronometroWidget extends StatefulWidget {
  final VoidCallback? onTimeExpired;
  final Map<String, dynamic> viajeData;
  final bool isActive;

  const CronometroWidget({
    Key? key,
    this.onTimeExpired,
    required this.viajeData,
    this.isActive = true,
  }) : super(key: key);

  @override
  State<CronometroWidget> createState() => _CronometroWidgetState();
}

class _CronometroWidgetState extends State<CronometroWidget> {
  Timer? _timer;
  late int _secondsRemaining;
  final int _tiempoLimite = 10 * 60; // 10 minutos en segundos
  late DateTime _startTime;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.parse(widget.viajeData['fecha_inicio']).toLocal();
    _calcularTiempoRestante();
    _startTimer();
  }

  void _calcularTiempoRestante() {
    _secondsRemaining = _tiempoLimite - _elapsedSeconds;

    if (_secondsRemaining <= 0) {
      _secondsRemaining = 0;
      _timer?.cancel();
      widget.onTimeExpired?.call();
    }
  }

  void _startTimer() {
    if (!widget.isActive) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _elapsedSeconds++;
        _calcularTiempoRestante();
      });
    });
  }

  String get _timeString {
    if (_secondsRemaining <= 0) return '00:00';
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tiempo para cancelar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _timeString,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _secondsRemaining < 60 ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
