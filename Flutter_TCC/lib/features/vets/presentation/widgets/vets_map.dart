import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/vet_entity.dart';

/// Mapa dos veterinários — flutter_map com tiles do OpenStreetMap.
///
/// O app **não** usa Google Maps: não há SDK nem chave de API envolvidos.
/// Os tiles vêm do servidor configurado em `MAPS_TILE_URL` (padrão: OSM
/// público). A política de uso do OSM exige um User-Agent identificando o
/// app; sem ele as requisições são bloqueadas (HTTP 403) e o mapa fica cinza.
class VetsMap extends StatelessWidget {
  const VetsMap({
    required this.vets,
    required this.userLat,
    required this.userLng,
    super.key,
  });

  /// Vets com `distanceKm` já calculado pelo provider.
  final List<VetEntity> vets;
  final double          userLat;
  final double          userLng;

  /// Identificador enviado no User-Agent das requisições de tiles.
  static const String userAgentPackageName = 'br.com.bovicare.bovicare';

  /// Tile server padrão (OSM público) — usado quando `.env` está ausente,
  /// vazio ou com um template inválido.
  static const String defaultTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String _osmCopyrightUrl =
      'https://www.openstreetmap.org/copyright';

  /// Acima desta distância o usuário é considerado fora da área de cobertura
  /// (ex.: emulador posicionado nos EUA) e o enquadramento inicial mostra só
  /// os veterinários, em vez de um zoom continental inútil.
  static const double _farFromVetsKm = 300;

  /// Valida o template vindo do `.env`: só aceita `https://` com os
  /// placeholders `{z}`, `{x}` e `{y}`. Qualquer outro valor cai no padrão —
  /// evita mapa quebrado por configuração errada e tráfego sem TLS.
  static String resolveTileUrl(String? configured) {
    final url = configured?.trim();
    if (url == null || url.isEmpty) return defaultTileUrl;
    final isValid = url.startsWith('https://') &&
        url.contains('{z}') &&
        url.contains('{x}') &&
        url.contains('{y}');
    return isValid ? url : defaultTileUrl;
  }

  /// dotenv pode não ter sido carregado (ex.: testes de widget) → padrão.
  static String _configuredTileUrl() => resolveTileUrl(
        dotenv.isInitialized ? dotenv.maybeGet('MAPS_TILE_URL') : null,
      );

  @override
  Widget build(BuildContext context) {
    final tileUrl   = _configuredTileUrl();
    final userPoint = LatLng(userLat, userLng);
    final vetPoints = [for (final v in vets) LatLng(v.lat, v.lng)];

    final userIsFar = vets.isNotEmpty &&
        vets.every((v) => (v.distanceKm ?? 0) > _farFromVetsKm);
    final fitPoints = [
      if (!userIsFar || vetPoints.isEmpty) userPoint,
      ...vetPoints,
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: userPoint,
          initialZoom:   10.5,
          // Enquadra usuário + veterinários quando há mais de um ponto.
          initialCameraFit: fitPoints.length > 1
              ? CameraFit.coordinates(
                  coordinates: fitPoints,
                  padding:     const EdgeInsets.all(32),
                  maxZoom:     12,
                )
              : null,
          minZoom: 3,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          // Tiles do OSM existem até o zoom 19 (maxNativeZoom padrão do
          // flutter_map); acima disso são ampliados em vez de requisitados.
          TileLayer(
            urlTemplate:          tileUrl,
            userAgentPackageName: userAgentPackageName,
          ),
          MarkerLayer(
            markers: [
              // Marcador do usuário
              Marker(
                point:  userPoint,
                width:  28,
                height: 28,
                child:  const _UserMarker(),
              ),
              // Marcadores dos vets
              ...vets.map(
                (v) => Marker(
                  point:  LatLng(v.lat, v.lng),
                  width:  32,
                  height: 32,
                  child:  _VetMarker(isAvailable: v.isAvailable),
                ),
              ),
            ],
          ),
          // Atribuição obrigatória pela licença ODbL do OpenStreetMap.
          RichAttributionWidget(
            alignment:                 AttributionAlignment.bottomLeft,
            showFlutterMapAttribution: false,
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(
                  Uri.parse(_osmCopyrightUrl),
                  mode: LaunchMode.externalApplication,
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
