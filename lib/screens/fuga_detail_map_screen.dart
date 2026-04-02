import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/fuga.dart';
import '../config/constants.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/audit_timeline_widget.dart';

class FugaDetailMapScreen extends StatelessWidget {
  final Fuga fuga;

  const FugaDetailMapScreen({super.key, required this.fuga});

  LatLng storedToMap(double x_stored, double y_stored) {
    final double originalWidth  = 25600 / 256 / 32; // 3.125
    final double originalHeight = 16715 / 256 / 32; // 2.0385
    final double ancho_real = 25600.0;
    final double alto_real  = 16715.0;

    final factor_x = ancho_real / 1200.0;
    final factor_y = alto_real / (1200.0 * (alto_real / ancho_real));

    final px = x_stored * factor_x;
    final py = alto_real - (y_stored * factor_y);

    final map_x =  (px / ancho_real) * originalWidth;
    final map_y = -((alto_real - py) / alto_real) * originalHeight;

    return LatLng(map_y, map_x);
  }

  @override
  Widget build(BuildContext context) {
    final cx = (fuga.x1 + fuga.x2) / 2;
    final cy = (fuga.y1 + fuga.y2) / 2;
    final centerMap = storedToMap(cx, cy);

    final statusColor = AppConstants.getStatusColor(fuga.estado, fuga.tipoFuga);
    final fluidInfo = AppConstants.fluidos[fuga.tipoFuga] ?? {"emoji": "⚠️"};
    final emoji = fluidInfo['emoji'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161a22),
        title: Text('📍 Fuga: ${fuga.idMaquina}'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              crs: const CrsSimple(),
              initialCenter: centerMap,
              initialZoom: 5,
              minZoom: 0,
              maxZoom: 7,
            ),
            children: [
              TileLayer(
                urlTemplate: 'assets/tiles/{z}/{x}/{y}.png',
                tileProvider: AssetTileProvider(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: centerMap,
                    width: 60,
                    height: 60,
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 10),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(0, -value),
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 12, spreadRadius: 4),
                          ],
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: MediaQuery.of(context).size.width > 800 ? MediaQuery.of(context).size.width / 2 - 200 : 20,
            right: MediaQuery.of(context).size.width > 800 ? MediaQuery.of(context).size.width / 2 - 200 : 20,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF161a22).withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${fuga.tipoFuga} | ${fuga.severidad}",
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Área: ${fuga.area} | Estado: ${fuga.estado}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Impacto: \$${fuga.costoAnual.toStringAsFixed(0)} USD",
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.history, size: 14, color: Colors.blueAccent),
                          label: const Text("Historial", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: const Color(0xFF161a22),
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (ctx) => Padding(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                                child: DraggableScrollableSheet(
                                  initialChildSize: 0.6,
                                  minChildSize: 0.3,
                                  maxChildSize: 0.9,
                                  expand: false,
                                  builder: (_, scrollController) => Column(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text("Trazabilidad de Fuga", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                      const Divider(color: Colors.white24),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          controller: scrollController,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: AuditTimelineWidget(fuga: fuga),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (fuga.fotoDeteccion != null || fuga.fotoReparacion != null) ...[
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        children: [
                          if (fuga.fotoDeteccion != null)
                            Expanded(child: _buildPhotoCol(context, "Detección", fuga.fotoDeteccion!)),
                          if (fuga.fotoDeteccion != null && fuga.fotoReparacion != null)
                            const SizedBox(width: 12),
                          if (fuga.fotoReparacion != null)
                            Expanded(child: _buildPhotoCol(context, "Reparación", fuga.fotoReparacion!)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPhotoCol(BuildContext context, String label, String url) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => showFullScreenImage(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => const SizedBox(height: 100, child: Center(child: Icon(Icons.broken_image, color: Colors.grey))),
            ),
          ),
        ),
      ],
    );
  }
}
