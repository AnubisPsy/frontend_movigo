// lib/screens/conductor/home_screen.dart
class ConductorHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Panel de Conductor')),
      body: ViajesPendientesWidget(), // Widget que ya tienes creado
    );
  }
}
