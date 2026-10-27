/// XARITA — viloyatdagi murojaatlar.
///
/// ⚠️ OpenStreetMap PLITKALARI (`flutter_map`): mini-ilovadagi
/// Leaflet bilan AYNI manba. Google Maps SDK kalit, hisob va
/// to'lov talab qilardi — xarita esa faqat ko'rsatish uchun.
///
/// ⚠️ KOORDINATASIZ NUQTALAR TASHLANADI: server ularni ham
/// qaytaradi (murojaat joysiz yuborilishi mumkin) va `null` bilan
/// marker qo'yishga urinish ilovani yiqitardi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../shared/api/client.dart';
import '../shared/api/models.dart';
import '../shared/config/labels.dart';
import '../shared/config/theme.dart';
import '../shared/ui/widgets.dart';
import 'appeal_detail_screen.dart';

/// Andijon viloyati markazi — fuqaro hududi noma'lum bo'lsa.
const LatLng _fallbackCenter = LatLng(40.7821, 72.3442);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<MapPoint>> _future;
  final MapController _controller = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.get('/mobile/appeals/map').then(
      (d) => (d as List<dynamic>)
          .map((e) => MapPoint.fromJson(e as Map<String, dynamic>))
          .where((p) => p.lat != null && p.lng != null)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Murojaatlar xaritasi')),
    body: AsyncView<List<MapPoint>>(
      future: _future,
      loadingLabel: 'Xarita yuklanmoqda…',
      onRetry: () => setState(_load),
      builder: (context, points) {
        final center = points.isEmpty
            ? _fallbackCenter
            : LatLng(points.first.lat!, points.first.lng!);

        return Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: points.isEmpty ? 10 : 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // ⚠️ `userAgentPackageName` SHART: OSM anonim
                  // mijozlarga plitka bermay qo'yishi mumkin.
                  userAgentPackageName: 'uz.mysrv.nazoratchi',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    for (final point in points)
                      Marker(
                        point: LatLng(point.lat!, point.lng!),
                        width: 38,
                        height: 38,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AppealDetailScreen(id: point.id),
                            ),
                          ),
                          child: _Pin(point: point),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 90,
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${plural(points.length, "murojaat")} xaritada',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Pin extends StatelessWidget {
  const _Pin({required this.point});
  final MapPoint point;

  @override
  Widget build(BuildContext context) {
    // ⚠️ RANG HOLATDAN, TOIFADAN EMAS: xaritada eng muhim savol
    // "hal qilinganmi?" — toifa esa bosilganda ko'rinadi.
    final color = statusOf(point.status).color;

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(iconOf(point.category.icon), size: 17, color: Colors.white),
    );
  }
}
