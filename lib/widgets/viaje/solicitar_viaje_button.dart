import 'package:flutter/material.dart';
import '../../screens/viaje/solicitar_viaje_screen.dart';

class SolicitarViajeButton extends StatelessWidget {
  final VoidCallback? onViajeSolicitado;

  const SolicitarViajeButton({
    Key? key,
    this.onViajeSolicitado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitarViajeScreen(),
          ),
        );

        // Si el resultado es true, significa que se solicitó un viaje exitosamente
        if (result == true) {
          onViajeSolicitado?.call();
        }
      },
      icon: const Icon(Icons.local_taxi),
      label: const Text('Solicitar Viaje'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
