// lib/widgets/viaje/mapa_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaSelectorWidget extends StatefulWidget {
  final void Function(LatLng) onUbicacionSeleccionada;
  final LatLng? ubicacionInicial;

  const MapaSelectorWidget({
    Key? key,
    required this.onUbicacionSeleccionada,
    this.ubicacionInicial,
  }) : super(key: key);

  @override
  _MapaSelectorWidgetState createState() => _MapaSelectorWidgetState();
}

class _MapaSelectorWidgetState extends State<MapaSelectorWidget> {
  LatLng? _ubicacionSeleccionada;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.ubicacionInicial != null) {
      _ubicacionSeleccionada = widget.ubicacionInicial;
      _actualizarMarcador();
    }
  }

  void _actualizarMarcador() {
    if (_ubicacionSeleccionada != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: MarkerId('ubicacion_seleccionada'),
            position: _ubicacionSeleccionada!,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.ubicacionInicial ?? LatLng(-2.1962, -79.8862),
            zoom: 15,
          ),
          onTap: (LatLng position) {
            setState(() {
              _ubicacionSeleccionada = position;
              _actualizarMarcador();
              widget.onUbicacionSeleccionada(position);
            });
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
}
