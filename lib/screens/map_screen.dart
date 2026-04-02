import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/fugas_provider.dart';
import '../config/constants.dart';
import '../models/fuga.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/audit_timeline_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final double originalWidth  = 25600 / 256 / 32; // 3.125
  final double originalHeight = 16715 / 256 / 32; // 2.0385

  bool _isMetricsVisible = true; // ← esta línea faltaba

  // Dimensiones del PlanoHanon25K.png (Nuevo Mapa)
  final double ancho_real = 25600.0;
  final double alto_real  = 16715.0;

  LatLng storedToMap(double x_stored, double y_stored) {
    // Replicar exactamente el factor de Streamlit
    final factor_x = ancho_real / 1200.0;
    final factor_y = alto_real / (1200.0 * (alto_real / ancho_real));

    // Convertir a píxeles del plano real (igual que Streamlit)
    final px = x_stored * factor_x;
    final py = alto_real - (y_stored * factor_y); // Streamlit invierte Y

    // Normalizar al espacio 0..1 y proyectar al mapa de tiles nuevo
    final map_x =  (px / ancho_real) * originalWidth;
    final map_y = -((alto_real - py) / alto_real) * originalHeight;

    return LatLng(map_y, map_x);
  }

  @override
  Widget build(BuildContext context) {
    final filteredFugas = ref.watch(filteredFugasProvider);

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: FlutterMap(
              options: MapOptions(
                crs: const CrsSimple(),
                initialCenter: LatLng(-originalHeight / 2, originalWidth / 2),
                initialZoom: 3.5,
                minZoom: 2.5,
                maxZoom: 7,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'assets/tiles/{z}/{x}/{y}.png',
                  tileProvider: AssetTileProvider(),
                  errorTileCallback: (tile, error, stackTrace) {
                    print("ERROR LOADING TILE: ${tile.coordinates.z} / ${tile.coordinates.x} / ${tile.coordinates.y}. Error: $error");
                  },
                ),
                _buildInspectionZonesLayer(filteredFugas),
                _buildMarkersLayer(filteredFugas),
              ],
            ),
          ),
          // Toggle button for metrics
          Positioned(
            top: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildToggleButton(),
                  if (_isMetricsVisible) ...[
                    const SizedBox(height: 8),
                    _buildMetricsRow(filteredFugas),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return InkWell(
      onTap: () => setState(() => _isMetricsVisible = !_isMetricsVisible),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161a22).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2d323d)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isMetricsVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _isMetricsVisible ? "Ocultar Métricas" : "Mostrar Métricas",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(List<Fuga> fugas) {
    int total = fugas.length;
    int highPriority = fugas.where((f) => f.severidad == 'Alta').length;
    double totalImpact = fugas.fold(0, (sum, f) => sum + f.costoAnual);
    
    final completadas = fugas.where((f) => f.estado == 'Completada').toList();
    double savingGenerated = completadas.fold(0, (sum, f) => sum + f.costoAnual);
    
    final pendientes = fugas.where((f) => f.estado != 'Completada').toList();
    double toMitigate = pendientes.fold(0, (sum, f) => sum + f.costoAnual);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          _MetricCard(title: "Hallazgos Totales", value: "$total"),
          _MetricCard(title: "🚨 Prioridad Alta", value: "$highPriority", valueColor: const Color(0xFFFF4B4B)),
          _MetricCard(title: "💰 Impacto Total", value: "\$${totalImpact.toStringAsFixed(0)} USD"),
          _MetricCard(title: "✅ Ahorro Generado", value: "\$${savingGenerated.toStringAsFixed(0)} USD", subtitle: "¡Buen trabajo!", subtitleColor: const Color(0xFF28A745)),
          _MetricCard(title: "⏳ Por Mitigar", value: "\$${toMitigate.toStringAsFixed(0)} USD", subtitle: "-${pendientes.length} fugas", subtitleColor: const Color(0xFFFF4B4B)),
        ],
      ),
    );
  }

  PolygonLayer _buildInspectionZonesLayer(List<Fuga> fugas) {
    final inspections = fugas.where((f) => f.tipoFuga == 'Inspección (OK)').toList();
    final polygons = <Polygon>[];

    for (var ins in inspections) {
      final p1 = storedToMap(ins.x1, ins.y1);
      final p2 = storedToMap(ins.x2, ins.y2);
      
      polygons.add(Polygon(
        points: [
          LatLng(p1.latitude, p1.longitude),
          LatLng(p1.latitude, p2.longitude),
          LatLng(p2.latitude, p2.longitude),
          LatLng(p2.latitude, p1.longitude),
        ],
        color: const Color(0xFF28A745).withOpacity(0.2),
        borderColor: const Color(0xFF28A745),
        borderStrokeWidth: 1,
      ));
    }

    return PolygonLayer(polygons: polygons);
  }

  MarkerLayer _buildMarkersLayer(List<Fuga> fugas) {
    final markers = <Marker>[];

    for (var f in fugas) {
      final cx = (f.x1 + f.x2) / 2;
      final cy = (f.y1 + f.y2) / 2;
      final centerMap = storedToMap(cx, cy);

      final fluidInfo = AppConstants.fluidos[f.tipoFuga] ?? {"color": Colors.white, "emoji": "⚠️", "marker": Colors.red};
      final markerColor = fluidInfo['marker'] as Color;
      
      bool isAnimated = f.severidad == 'Alta';
      bool isOk = f.estado == 'Completada' || f.tipoFuga == 'Inspección (OK)';
      
      final fluidEmoji = fluidInfo['emoji'] as String;
      final statusColor = AppConstants.getStatusColor(f.estado, f.tipoFuga);

      markers.add(Marker(
        point: centerMap,
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _showPopup(f, fluidInfo),
          child: _buildPepoMarker(
            isOk: isOk,
            fluidEmoji: fluidEmoji,
            markerColor: markerColor,
            statusColor: statusColor,
            isAnimated: isAnimated,
            emoji: fluidEmoji,
            area: f.area,
            ubicacion: f.ubicacion,
            severidad: f.severidad,
            comentarios: f.comentarios,
          ),
        ),
      ));
    }

    return MarkerLayer(markers: markers);
  }

  Widget _buildPepoMarker({
    required bool isOk,
    required String fluidEmoji,
    required Color markerColor,
    required Color statusColor,
    required bool isAnimated,
    required String emoji,
    required String area,
    required String ubicacion,
    required String severidad,
    required String comentarios,
  }) {
    final ubiEmoji = ubicacion == 'Terrestre' ? '🚜' : '☁️';

    // Custom dark tooltip content
    final tooltipMessage = "$emoji $area\n$ubiEmoji Instalación: $ubicacion\nSeveridad: $severidad${comentarios.isNotEmpty ? '\n💬 ${comentarios.length > 50 ? '${comentarios.substring(0, 50)}...' : comentarios}' : ''}";

    // Inner content: checkmark for completed, fluid emoji for active fugas
    Widget innerContent;
    if (isOk) {
      innerContent = const Icon(Icons.check, color: Colors.white, size: 16);
    } else {
      innerContent = Text(fluidEmoji, style: const TextStyle(fontSize: 14));
    }

    Widget pinWidget = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: innerContent,
      ),
    );

    if (isAnimated) {
      pinWidget = TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 6),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, -value),
            child: child,
          );
        },
        child: pinWidget,
      );
    }

    return Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: tooltipMessage,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1d2129),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: markerColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: pinWidget,
    );
  }

  void _showPopup(Fuga f, Map<String, dynamic> fluidInfo) {
    final colorSev = AppConstants.getSeverityColor(f.severidad);
    final markerColor = fluidInfo['marker'] as Color;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF161a22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colorSev, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment, color: markerColor, size: 24),
                      const SizedBox(width: 8),
                      Text("📋 Ficha Técnica",
                        style: TextStyle(color: markerColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.history, size: 14, color: Colors.blueAccent),
                        label: const Text("Historial", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        onPressed: () {
                          // Cerrar el popup actual primero para que no estorbe (opcional, pero recomendado)
                          Navigator.of(context).pop();
                          
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
                                          child: AuditTimelineWidget(fuga: f),
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
                ),
                const SizedBox(height: 16),
                _buildDarkRow("ID Máquina:", f.idMaquina, isBold: true),
                _buildDarkRow("Área de Planta:", f.area),
                _buildDarkRow("Instalación:", "${f.ubicacion == 'Terrestre' ? '🚜' : '☁️'} ${f.ubicacion}"),
                _buildDarkRow("Estado:", f.estado),
                _buildDarkRow("Categoría:", f.categoria),
                _buildDarkRow("Caudal:", "${f.lMin} l/min"),
                _buildDarkRow("Costo/Año:", "\$${f.costoAnual} USD", valueColor: const Color(0xFFFF4B4B)),
                _buildDarkRow("Severidad:", f.severidad, valueColor: colorSev),
                _buildDarkRow("Fechas:", f.zona),
                if (f.comentarios.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1d2129),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2d323d)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("💬 Comentarios:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(f.comentarios, style: const TextStyle(color: Colors.white60, fontSize: 13, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
                if (f.fotoDeteccion != null || f.fotoReparacion != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (f.fotoDeteccion != null)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showFullScreenImage(context, f.fotoDeteccion!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                f.fotoDeteccion!,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => const SizedBox(height: 100, child: Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                              ),
                            ),
                          ),
                        ),
                      if (f.fotoDeteccion != null && f.fotoReparacion != null) const SizedBox(width: 12),
                      if (f.fotoReparacion != null)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showFullScreenImage(context, f.fotoReparacion!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                f.fotoReparacion!,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => const SizedBox(height: 100, child: Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF2d323d),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: (valueColor != null || isBold) ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final Color? subtitleColor;

  const _MetricCard({
    required this.title,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor ?? Colors.white)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(fontSize: 11, color: subtitleColor)),
            ]
          ],
        ),
      ),
    );
  }
}
