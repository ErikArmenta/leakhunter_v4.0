import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/constants.dart';
import '../models/fuga.dart';
import '../screens/fuga_detail_map_screen.dart';
import 'fullscreen_image_viewer.dart';
import 'audit_timeline_widget.dart';
import 'media_thumbnail.dart';

class DrillDownDialog extends StatelessWidget {
  final String title;
  final List<Fuga> fugas;
  final String type; // 'month', 'severity', 'sector'
  final VoidCallback? onExportExcel;

  const DrillDownDialog({
    super.key,
    required this.title,
    required this.fugas,
    required this.type,
    this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1c2128),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF2d323d)),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onExportExcel != null)
                      IconButton(
                        icon: const Icon(Icons.file_download, color: Colors.green),
                        tooltip: "Exportar Fugas (Excel)",
                        onPressed: onExportExcel,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Color(0xFF2d323d)),
            const SizedBox(height: 16),
            Expanded(
              child: type == 'severity'
                  ? _buildSeverityDetail()
                  : _buildFugasList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityDetail() {
    final Map<String, int> severityCount = {};
    double totalCost = 0;

    for (var fuga in fugas) {
      severityCount[fuga.severidad] = (severityCount[fuga.severidad] ?? 0) + 1;
      totalCost += fuga.costoAnual;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Total fugas", fugas.length.toString(), Icons.bug_report),
        const SizedBox(height: 16),
        _buildInfoCard("Impacto económico", "\$${totalCost.toStringAsFixed(0)}", Icons.attach_money),
        const SizedBox(height: 24),
        const Text(
          "Desglose por severidad:",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...severityCount.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getSeverityColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(entry.key, style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              Text(
                "${entry.value} fugas",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildFugasList() {
    if (fugas.isEmpty) {
      return const Center(
        child: Text(
          "No hay fugas para mostrar",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    double totalCost = fugas.fold(0.0, (sum, f) => sum + f.costoAnual);

    return Column(
      children: [
        // Header Summary for the List
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161a22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2d323d)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total: ${fugas.length} filas",
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              Text(
                "Impacto: \$${totalCost.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: fugas.length,
            itemBuilder: (context, index) {
              final fuga = fugas[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FugaDetailMapScreen(fuga: fuga),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161a22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2d323d)),
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(fuga.severidad).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            fuga.severidad,
                            style: TextStyle(
                              color: _getSeverityColor(fuga.severidad),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(fuga.estado).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            fuga.estado,
                            style: TextStyle(
                              color: _getStatusColor(fuga.estado),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "\$${fuga.costoAnual.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fuga.tipoFuga,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fuga.area,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Máquina: ${fuga.idMaquina}",
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        Text(
                          "Instalación: ${fuga.ubicacion}",
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Fechas / Zona: ${fuga.zona}",
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.history, size: 14, color: Colors.blueAccent),
                          label: const Text("Historial", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
                    if (fuga.comentarios.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1d2129),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2d323d)),
                        ),
                        child: Text(
                          "💬 ${fuga.comentarios}",
                          style: const TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    if (fuga.fotoDeteccion != null || fuga.fotoReparacion != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (fuga.fotoDeteccion != null)
                            Expanded(
                              child: MediaThumbnail(url: fuga.fotoDeteccion!),
                            ),
                          if (fuga.fotoDeteccion != null && fuga.fotoReparacion != null) const SizedBox(width: 12),
                          if (fuga.fotoReparacion != null)
                            Expanded(
                              child: MediaThumbnail(url: fuga.fotoReparacion!),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161a22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2d323d)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Baja':
        return Colors.green;
      case 'Media':
        return Colors.orange;
      case 'Alta':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completada':
        return Colors.green;
      case 'En proceso de reparar':
        return Colors.orange;
      case 'Dañada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}