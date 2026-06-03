import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/vet_entity.dart';

class VetsMap extends StatelessWidget {
  const VetsMap({
    required this.vets,
    required this.userLat,
    required this.userLng,
    super.key,
  });

  final List<VetEntity> vets;
  final double          userLat;
  final double          userLng;

  @override
  Widget build(BuildContext context) {
    final tileUrl = dotenv.maybeGet('MAPS_TILE_URL') ??
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(userLat, userLng),
          initialZoom:   10.5,
        ),
        children: [
          TileLayer(urlTemplate: tileUrl),
          MarkerLayer(
            markers: [
              // Marcador do usuário
              Marker(
                point: LatLng(userLat, userLng),
                child: const _UserMarker(),
              ),
              // Marcadores dos vets
              ...vets.map(
                (v) => Marker(
                  point: LatLng(v.lat, v.lng),
                  child: _VetMarker(isAvailable: v.isAvailable),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width:       28,
      height:      28,
      decoration:  const BoxDecoration(
        color:  AppColors.info,
        shape:  BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x551A56A0), blurRadius: 8)],
      ),
      child: const Icon(
        Icons.my_location_rounded,
        color: Colors.white,
        size:  16,
      ),
    );
  }
}

class _VetMarker extends StatelessWidget {
  const _VetMarker({required this.isAvailable});
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:      32,
      height:     32,
      decoration: BoxDecoration(
        color:    isAvailable ? AppColors.brandGreen : AppColors.amber,
        shape:    BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:      (isAvailable ? AppColors.brandGreen : AppColors.amber)
                .withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Icon(
        Icons.medical_services_outlined,
        color: Colors.white,
        size:  16,
      ),
    );
  }
}
