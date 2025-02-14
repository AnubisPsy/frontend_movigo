// lib/services/tarifa_service.dart
class TarifaService {
  static double calcularCosto({
    required double distanciaKm,
    required int tiempoMinutos,
    required double tarifaBase,
    required double tarifaPorKm,
    required double tarifaPorMinuto,
  }) {
    double costoDistancia = distanciaKm * tarifaPorKm;
    double costoTiempo = tiempoMinutos * tarifaPorMinuto;
    return tarifaBase + costoDistancia + costoTiempo;
  }
}
