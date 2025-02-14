import 'package:flutter/material.dart';
import '../../services/viaje_service.dart';
import 'cronometro_widget.dart';

class ViajeActivoWidget extends StatelessWidget {
  final VoidCallback? onViajeCancelado;
  final Map<String, dynamic> viajeData; // Agregamos este campo

  const ViajeActivoWidget({
    Key? key,
    this.onViajeCancelado,
    required this.viajeData, // Lo hacemos requerido
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tiene 10 minutos para cancelar su viaje',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CronometroWidget(
              viajeData: viajeData, // Pasamos el mapa completo
              onTimeExpired: () {
                // Aquí puedes manejar lo que sucede cuando expira el tiempo
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ViajeService().cancelarViaje();
                  onViajeCancelado?.call();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Error al cancelar el viaje: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cancelar Viaje'),
            ),
          ],
        ),
      ),
    );
  }
}
