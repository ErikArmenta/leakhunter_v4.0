import 'package:flutter/material.dart' hide Border;
import 'package:flutter/painting.dart' show Border;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../config/constants.dart';
import '../providers/fugas_provider.dart';
import '../models/fuga.dart';
import '../widgets/drill_down_dialog.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    final fugas = ref.watch(filteredFugasProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0d1117), Color(0xFF161a22)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSummaryCards(fugas),

            const SizedBox(height: 48),
            const Text(
              "📈 Historial de Reparaciones",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildHistoryChart(fugas),

            const SizedBox(height: 48),
            const Text(
              "📊 Comparativa: Detección vs Reparación",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Análisis mensual de fugas identificadas vs reparaciones completadas",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            _buildComparisonChart(fugas),

            const SizedBox(height: 48),
            const Text(
              "📊 Análisis de Hallazgos",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildChartWrapper(
                        "Severidad",
                        _buildSeverityChart(fugas),
                        width: isDesktop ? 220 : constraints.maxWidth,
                      ),
                      _buildChartWrapper(
                        "Estatus",
                        _buildStatusChart(fugas),
                        width: isDesktop ? 220 : constraints.maxWidth,
                      ),
                      _buildChartWrapper(
                        "Impacto Económico",
                        _buildImpactChart(fugas),
                        width: isDesktop ? 220 : constraints.maxWidth,
                      ),
                      _buildChartWrapper(
                        "Eficiencia Reparación",
                        _buildEfficiencyChart(fugas),
                        width: isDesktop ? 220 : constraints.maxWidth,
                      ),
                      _buildChartWrapper(
                        "Cobertura Inspección",
                        _buildCoverageChart(fugas),
                        width: isDesktop ? 220 : constraints.maxWidth,
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 48),
            const Text(
              "🚨 Top Sectores Críticos",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildTopSectors(fugas),

            const SizedBox(height: 48),
            Center(child: _buildHeatmap(fugas)),

            const SizedBox(height: 48),
            const Divider(color: Color(0xFF2d323d)),
            const SizedBox(height: 24),

            const Text(
              "📥 Centro de Reportes",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            _buildExportButtons(fugas),

            const SizedBox(height: 60),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  void _showDrillDownDialog(String title, List<Fuga> fugas, String type) {
    if (fugas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay datos para mostrar")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => DrillDownDialog(
        title: title,
        fugas: fugas,
        type: type,
        onExportExcel: () {
          Navigator.pop(context);
          _exportExcel(fugas);
        },
      ),
    );
  }

  void _showMonthDetails(String monthName, List<Fuga> allFugas) {
    final parts = monthName.split('/');
    if (parts.length != 2) return;

    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);

    final fugasDelMes = allFugas.where((f) {
      final zona = f.zona;
      if (zona.isNotEmpty && zona.contains('-')) {
        try {
          final fechaInicioStr = zona.split('-')[0].trim();
          final fechaParts = fechaInicioStr.split('/');
          if (fechaParts.length == 3) {
            final mes = int.parse(fechaParts[1]);
            final anio = int.parse(fechaParts[2]);
            return mes == month && anio == year;
          }
        } catch (e) {}
      }
      return false;
    }).toList();

    _showDrillDownDialog(
      "Fugas - ${_getMonthName(month)} $year",
      fugasDelMes,
      'month',
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "📊 Panel de Control Operativo",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          "Gestión de fugas e impacto en tiempo real",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(List<Fuga> fugas) {
    final totalFugas = fugas.length;
    final totalImpact = fugas.fold(0.0, (sum, f) => sum + f.costoAnual);
    final reparadas = fugas.where((f) => f.estado == 'Completada').length;
    final efficiency = totalFugas > 0
        ? (reparadas / totalFugas * 100).toStringAsFixed(1)
        : "0.0";

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildKPICard(
          "Hallazgos",
          totalFugas.toString(),
          Icons.search,
          Colors.blueAccent,
        ),
        _buildKPICard(
          "Impacto Total",
          "\$${totalImpact.toStringAsFixed(0)}",
          Icons.attach_money,
          Colors.redAccent,
        ),
        _buildKPICard(
          "Reparaciones",
          reparadas.toString(),
          Icons.check_circle_outline,
          Colors.greenAccent,
        ),
        _buildKPICard(
          "Eficiencia",
          "$efficiency%",
          Icons.trending_up,
          Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    final trend = _getTrendForKPI(title);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: trend.contains('▲')
                  ? Colors.greenAccent.withValues(alpha: 0.1)
                  : Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trend,
              style: TextStyle(
                color: trend.contains('▲')
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTrendForKPI(String title) {
    if (title == "Hallazgos") return "▲ 12%";
    if (title == "Impacto Total") return "▼ 5%";
    if (title == "Reparaciones") return "▲ 8%";
    return "▲ 2.5%";
  }

  Widget _buildExportButtons(List<Fuga> fugas) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildDashboardButton(
          icon: Icons.grid_on_rounded,
          label: "Datos",
          color: Colors.greenAccent,
          onPressed: () => _exportExcel(fugas),
        ),
        _buildDashboardButton(
          icon: Icons.picture_as_pdf_rounded,
          label: "Reporte Ejecutivo",
          color: Colors.redAccent,
          onPressed: () => _exportExecutivePDF(fugas),
        ),
        _buildDashboardButton(
          icon: Icons.map_sharp,
          label: "Plano Interactivo (HTML)",
          color: Colors.blueAccent,
          onPressed: () => _exportInteractiveMapHTML(fugas),
        ),
      ],
    );
  }

  Widget _buildDashboardButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          hoverColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartWrapper(String title, Widget chart, {double width = 220}) {
    return Container(
      width: width,
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2d323d)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildSeverityChart(List<Fuga> fugas) {
    if (fugas.isEmpty) return const Center(child: Text("Sin datos"));

    int bajas = fugas.where((f) => f.severidad == 'Baja').length;
    int medias = fugas.where((f) => f.severidad == 'Media').length;
    int altas = fugas.where((f) => f.severidad == 'Alta').length;

    return GestureDetector(
      onTap: () => _showDrillDownDialog("Análisis de Severidad", fugas, 'severity'),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              ([bajas, medias, altas].reduce((a, b) => a > b ? a : b).toDouble() * 1.5)
                  .clamp(1.0, double.infinity),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1c2128),
              tooltipBorder: const BorderSide(
                color: Color(0xFF5271ff),
                width: 1.5,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String label;
                switch (group.x.toInt()) {
                  case 0:
                    label = 'Baja';
                    break;
                  case 1:
                    label = 'Media';
                    break;
                  case 2:
                    label = 'Alta';
                    break;
                  default:
                    label = '';
                }
                return BarTooltipItem(
                  '$label\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} hallazgos',
                      style: const TextStyle(
                        color: Color(0xFF5271ff),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  );
                  switch (value.toInt()) {
                    case 0:
                      return const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text('Baja', style: style),
                      );
                    case 1:
                      return const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text('Media', style: style),
                      );
                    case 2:
                      return const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text('Alta', style: style),
                      );
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: bajas.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF28A745), Color(0xFF5cb85c)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: medias.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: altas.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4B4B), Color(0xFFFF8A8A)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(List<Fuga> fugas) {
    if (fugas.isEmpty) return const Center(child: Text("Sin datos"));
    int completadas = fugas.where((f) => f.estado == 'Completada').length;
    int enProceso = fugas
        .where((f) => f.estado == 'En proceso de reparar')
        .length;
    int danadas = fugas.where((f) => f.estado == 'Dañada').length;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            ([completadas, enProceso, danadas].reduce((a, b) => a > b ? a : b).toDouble() * 1.5)
                .clamp(1.0, double.infinity),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1c2128),
            tooltipBorder: const BorderSide(
              color: Colors.orangeAccent,
              width: 1.5,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label;
              switch (group.x.toInt()) {
                case 0:
                  label = 'Dañada';
                  break;
                case 1:
                  label = 'En proceso';
                  break;
                case 2:
                  label = 'Completada';
                  break;
                default:
                  label = '';
              }
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()} fugas',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(fontSize: 10, color: Colors.white54);
                switch (value.toInt()) {
                  case 0:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Dam', style: style),
                    );
                  case 1:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Proc', style: style),
                    );
                  case 2:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('OK', style: style),
                    );
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: danadas.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFFd9534f), Color(0xFFFF5252)],
                ),
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: enProceso.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFFf0ad4e), Color(0xFFffca28)],
                ),
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: completadas.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5cb85c), Color(0xFF81c784)],
                ),
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactChart(List<Fuga> fugas) {
    if (fugas.isEmpty) return const Center(child: Text("Sin datos"));

    Map<String, double> impactMap = {};
    for (var f in fugas) {
      impactMap[f.categoria] = (impactMap[f.categoria] ?? 0) + f.costoAnual;
    }

    var sortedEntries = impactMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topEntries = sortedEntries.take(3).toList();

    if (topEntries.isEmpty) return const Center(child: Text("0 Impact"));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            (topEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.5)
                .clamp(1.0, double.infinity),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1c2128),
            tooltipBorder: const BorderSide(
              color: Colors.redAccent,
              width: 1.5,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = topEntries[group.x.toInt()];
              return BarTooltipItem(
                '${entry.key}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '\$${rod.toY.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < topEntries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      topEntries[value.toInt()].key.split(' ').first,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white38,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(topEntries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: topEntries[i].value,
                gradient: const LinearGradient(
                  colors: [Color(0xFFd9534f), Color(0xFFFF8A8A)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

Widget _buildEfficiencyChart(List<Fuga> fugas) {
  if (fugas.isEmpty) return const Center(child: Text("Sin datos"));

  int reparadas = fugas.where((f) => f.estado == 'Completada').length;
  int pendientes = fugas.where((f) => f.estado != 'Completada').length;
  int total = reparadas + pendientes;
  
  double pct = total > 0 ? (reparadas / total) * 100 : 0;
  
  // Calcular también el número total de fugas para el hover
  final totalFugas = fugas.length;

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {
        // Mostrar detalle al hacer click
        _showDrillDownDialog(
          "Eficiencia de Reparación\n${pct.toStringAsFixed(1)}% de eficiencia",
          fugas.where((f) => f.estado == 'Completada').toList(),
          'sector',
        );
      },
      child: Tooltip(
        richMessage: TextSpan(
          children: [
            const TextSpan(text: "Eficiencia de Reparación\n\n", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            TextSpan(text: "Reparadas: $reparadas\n", style: const TextStyle(color: Colors.green, fontSize: 12)),
            TextSpan(text: "Pendientes: $pendientes\n", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            TextSpan(text: "\nClick para ver detalles", style: TextStyle(color: Colors.blueAccent.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1d2129),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2d323d)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)],
        ),
        padding: const EdgeInsets.all(12),
        preferBelow: false,
        child: Stack(
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 45,
                sections: [
                  PieChartSectionData(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5cb85c), Color(0xFF28A745)],
                    ),
                    value: reparadas.toDouble(),
                    showTitle: false,
                    radius: 20,
                    title: "${pct.toStringAsFixed(0)}%",
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.white.withValues(alpha: 0.05),
                    value: pendientes.toDouble(),
                    showTitle: false,
                    radius: 12,
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${pct.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "EFIC",
                    style: TextStyle(fontSize: 8, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildCoverageChart(List<Fuga> fugas) {
  if (fugas.isEmpty) return const Center(child: Text("Sin datos"));

  int inspecciones = fugas
      .where((f) => f.tipoFuga == 'Inspección (OK)')
      .length;
  int fugasActivas = fugas
      .where(
        (f) => f.estado == 'Dañada' || f.estado == 'En proceso de reparar',
      )
      .length;
  int total = inspecciones + fugasActivas;

  double pct = total > 0 ? (inspecciones / total) * 100 : 0;
  
  // Calcular también el número total de fugas para el hover
  final totalFugas = fugas.length;

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {
        // Mostrar detalle al hacer click - mostrar las inspecciones OK
        _showDrillDownDialog(
          "Cobertura de Inspección\n${pct.toStringAsFixed(1)}% de cobertura",
          fugas.where((f) => f.tipoFuga == 'Inspección (OK)').toList(),
          'sector',
        );
      },
      child: Tooltip(
        richMessage: TextSpan(
          children: [
            const TextSpan(text: "Cobertura de Inspección\n\n", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            TextSpan(text: "Inspecciones OK: $inspecciones\n", style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
            TextSpan(text: "Fugas Activas: $fugasActivas\n", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
            TextSpan(text: "\nClick para ver detalles", style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1d2129),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2d323d)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)],
        ),
        padding: const EdgeInsets.all(12),
        preferBelow: false,
        child: Stack(
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 45,
                sections: [
                  PieChartSectionData(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                    ),
                    value: inspecciones.toDouble(),
                    showTitle: false,
                    radius: 20,
                    title: "${pct.toStringAsFixed(0)}%",
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.white.withValues(alpha: 0.05),
                    value: fugasActivas.toDouble(),
                    showTitle: false,
                    radius: 12,
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${pct.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "COB",
                    style: TextStyle(fontSize: 8, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildHistoryChart(List<Fuga> fugas) {
    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF0d1117),
              tooltipBorder: const BorderSide(
                color: Color(0xFF5271ff),
                width: 1.5,
              ),
              tooltipBorderRadius: const BorderRadius.all(Radius.circular(8)),
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                const months = ['Oct', 'Nov', 'Dic', 'Ene', 'Feb', 'Mar'];
                final idx = (spot.x / 2).round().clamp(0, 5);
                return LineTooltipItem(
                  '${months[idx]}\n',
                  const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '${spot.y.toStringAsFixed(1)} reparaciones',
                      style: const TextStyle(
                        color: Color(0xFF5271ff),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.white38, fontSize: 9);
                  switch (value.toInt()) {
                    case 0:
                      return const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Oct', style: style),
                      );
                    case 2:
                      return const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Nov', style: style),
                      );
                    case 4:
                      return const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Dic', style: style),
                      );
                    case 6:
                      return const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Ene', style: style),
                      );
                    case 8:
                      return const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Feb', style: style),
                      );
                    case 10:
                      return const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Mar', style: style),
                      );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(2, 4),
                FlSpot(4, 3.5),
                FlSpot(6, 5),
                FlSpot(8, 4.8),
                FlSpot(10, 6),
              ],
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Color(0xFF5271ff), Color(0xFF00c6ff)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF00c6ff),
                  strokeWidth: 1.5,
                  strokeColor: const Color(0xFF0d1117),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF5271ff).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(List<Fuga> fugas) {
    if (fugas.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF1c2128),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            "Sin datos para mostrar",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final Map<String, Map<String, int>> monthlyData = {};

    for (var fuga in fugas) {
      final zona = fuga.zona;
      if (zona.isNotEmpty && zona.contains('-')) {
        final fechaInicioStr = zona.split('-')[0].trim();

        try {
          final partes = fechaInicioStr.split('/');
          if (partes.length == 3) {
            final dia = int.parse(partes[0]);
            final mes = int.parse(partes[1]);
            final anio = int.parse(partes[2]);

            final fecha = DateTime(anio, mes, dia);
            final monthYear = "${fecha.month}/${fecha.year}";

            if (!monthlyData.containsKey(monthYear)) {
              monthlyData[monthYear] = {'detectadas': 0, 'reparadas': 0};
            }

            monthlyData[monthYear]!['detectadas'] =
                (monthlyData[monthYear]!['detectadas'] ?? 0) + 1;

            if (fuga.estado == 'Completada') {
              monthlyData[monthYear]!['reparadas'] =
                  (monthlyData[monthYear]!['reparadas'] ?? 0) + 1;
            }
          }
        } catch (e) {
          print('Error parsing date from zona: $zona');
        }
      }
    }

    if (monthlyData.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1c2128),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 40, color: Colors.white38),
              SizedBox(height: 12),
              Text(
                "No hay datos con fechas válidas en el campo Zona",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              SizedBox(height: 8),
              Text(
                "Formato esperado: DD/MM/AAAA-DD/MM/AAAA",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    final sortedMonths = monthlyData.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('/');
        final bParts = b.split('/');
        final aDate = DateTime(int.parse(aParts[1]), int.parse(aParts[0]));
        final bDate = DateTime(int.parse(bParts[1]), int.parse(bParts[0]));
        return aDate.compareTo(bDate);
      });

    final detectadasValues = sortedMonths
        .map((month) => monthlyData[month]!['detectadas']!.toDouble())
        .toList();
    final reparadasValues = sortedMonths
        .map((month) => monthlyData[month]!['reparadas']!.toDouble())
        .toList();

    final List<FlSpot> detectadasSpots = [];
    final List<FlSpot> reparadasSpots = [];
    for (int i = 0; i < sortedMonths.length; i++) {
      detectadasSpots.add(FlSpot(i.toDouble(), detectadasValues[i]));
      reparadasSpots.add(FlSpot(i.toDouble(), reparadasValues[i]));
    }

    final maxY =
        [...detectadasValues, ...reparadasValues].reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      height: 420,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(Colors.redAccent, "Fugas Detectadas"),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.greenAccent, "Fugas Reparadas"),
              const SizedBox(width: 16),
              Container(width: 20, height: 3, color: Colors.redAccent),
              const SizedBox(width: 6),
              const Text(
                "Tendencia Detectadas",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(width: 16),
              Container(width: 20, height: 3, color: Colors.greenAccent),
              const SizedBox(width: 6),
              const Text(
                "Tendencia Reparadas",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                          if (event is FlTapUpEvent && response != null && response.spot != null) {
                            final month = sortedMonths[response.spot!.touchedBarGroupIndex];
                            _showMonthDetails(month, fugas);
                          }
                        },
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1c2128),
                          tooltipBorder: const BorderSide(
                            color: Color(0xFF5271ff),
                            width: 1.5,
                          ),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final month = sortedMonths[group.x.toInt()];
                            final monthName = _getMonthName(
                              int.parse(month.split('/')[0]),
                            );
                            final year = month.split('/')[1];
                            final value = rod.toY.toInt();
                            final type = rodIndex == 0 ? "Detectadas" : "Reparadas";
                            final color = rodIndex == 0 ? Colors.redAccent : Colors.greenAccent;

                            return BarTooltipItem(
                              '$monthName $year\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: '$type: $value fugas',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < sortedMonths.length) {
                                final month = sortedMonths[index];
                                final monthNum = int.parse(month.split('/')[0]);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _getShortMonthName(monthNum),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(sortedMonths.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: detectadasValues[index],
                              color: Colors.redAccent,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                            BarChartRodData(
                              toY: reparadasValues[index],
                              color: Colors.greenAccent,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                          barsSpace: 12,
                        );
                      }),
                    ),
                  ),
                  // Líneas de tendencia superpuestas con IgnorePointer
                  IgnorePointer(
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => const Color(0xFF1c2128),
                            tooltipBorder: const BorderSide(
                              color: Color(0xFF5271ff),
                              width: 1.5,
                            ),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final month = sortedMonths[spot.x.toInt()];
                                final monthName = _getMonthName(
                                  int.parse(month.split('/')[0]),
                                );
                                final year = month.split('/')[1];
                                final value = spot.y.toInt();
                                final type = spot.barIndex == 0
                                    ? "Tendencia Detectadas"
                                    : "Tendencia Reparadas";
                                final color = spot.barIndex == 0
                                    ? Colors.redAccent
                                    : Colors.greenAccent;

                                return LineTooltipItem(
                                  '$monthName $year\n',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$type: $value fugas',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: detectadasSpots,
                            isCurved: false,
                            color: Colors.redAccent,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                          LineChartBarData(
                            spots: reparadasSpots,
                            isCurved: false,
                            color: Colors.greenAccent,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                        minY: 0,
                        maxY: maxY,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEfficiencyMetric(
                  "Total Detectadas",
                  detectadasValues.reduce((a, b) => a + b).toInt(),
                  Icons.analytics,
                  Colors.redAccent,
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildEfficiencyMetric(
                  "Total Reparadas",
                  reparadasValues.reduce((a, b) => a + b).toInt(),
                  Icons.check_circle,
                  Colors.greenAccent,
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildEfficiencyMetric(
                  "Eficiencia Global",
                  "${((reparadasValues.reduce((a, b) => a + b) / detectadasValues.reduce((a, b) => a + b)) * 100).toStringAsFixed(1)}%",
                  Icons.trending_up,
                  Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyMetric(
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 10)),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }

  String _getShortMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }

  Widget _buildHeatmap(List<Fuga> fugas) {
    final Map<String, int> tiposCount = {};

    for (var fuga in fugas) {
      String tipo = fuga.tipoFuga;
      tiposCount[tipo] = (tiposCount[tipo] ?? 0) + 1;
    }

    final List<Map<String, dynamic>> tiposConfig = [
      {'nombre': 'Aire', 'color': Colors.green, 'severidad': 'Baja'},
      {'nombre': 'Gas Natural', 'color': Colors.yellow, 'severidad': 'Media'},
      {'nombre': 'Agua', 'color': Colors.orange, 'severidad': 'Media-Alta'},
      {'nombre': 'Helio', 'color': Colors.deepOrange, 'severidad': 'Alta'},
      {'nombre': 'Aceite', 'color': Colors.red, 'severidad': 'Crítica'},
      {'nombre': 'Inspección OK', 'color': Colors.blue, 'severidad': 'Control'},
    ];

    final valoresReales = tiposConfig.map((config) {
      return tiposCount[config['nombre']]?.toDouble() ?? 0.0;
    }).toList();

    final maxVal = valoresReales.reduce((a, b) => a > b ? a : b);

    final normalized = valoresReales.map((v) {
      if (maxVal == 0) return 0.5;
      return (v / maxVal * 5).clamp(0.5, 5.0);
    }).toList();

    final totalFugas = valoresReales.reduce((a, b) => a + b);

    int? hoveredIndex;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          height: 500,
          width: 550,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1c2128),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("🚦", style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      const Text(
                        "Matriz de Riesgo por Tipo de Fuga",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.3),
                          Colors.purpleAccent.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      "Total: $totalFugas fugas",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(Colors.green, "Baja"),
                    _buildLegendItem(Colors.yellow, "Media"),
                    _buildLegendItem(Colors.orange, "Media-Alta"),
                    _buildLegendItem(Colors.deepOrange, "Alta"),
                    _buildLegendItem(Colors.red, "Crítica"),
                    _buildLegendItem(Colors.blue, "Control"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 50,
                child: hoveredIndex != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              tiposConfig[hoveredIndex!]['color'].withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tiposConfig[hoveredIndex!]['color'].withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: tiposConfig[hoveredIndex!]['color'],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: tiposConfig[hoveredIndex!]['color'].withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              tiposConfig[hoveredIndex!]['nombre'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tiposConfig[hoveredIndex!]['color'].withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${valoresReales[hoveredIndex!].toInt()} fugas',
                                style: TextStyle(
                                  color: tiposConfig[hoveredIndex!]['color'],
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${totalFugas > 0 ? ((valoresReales[hoveredIndex!] / totalFugas) * 100).toStringAsFixed(1) : "0"}%)',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tiposConfig[hoveredIndex!]['severidad'],
                                style: TextStyle(
                                  color: tiposConfig[hoveredIndex!]['color'],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.touch_app,
                              size: 16,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "👆 Pasa el mouse sobre el gráfico para ver detalles",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: RadarChart(
                  RadarChartData(
                    radarBorderData: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    gridBorderData: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                    tickBorderData: const BorderSide(color: Colors.transparent),
                    ticksTextStyle: const TextStyle(color: Colors.transparent),
                    titleTextStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    radarTouchData: RadarTouchData(
                      touchCallback: (event, response) {
                        if (response != null && response.touchedSpot != null) {
                          setLocalState(() {
                            hoveredIndex = response.touchedSpot!.touchedDataSetIndex >= 0
                                ? response.touchedSpot!.touchedRadarEntryIndex
                                : null;
                          });
                        } else {
                          setLocalState(() => hoveredIndex = null);
                        }
                      },
                    ),
                    getTitle: (index, angle) {
                      final config = tiposConfig[index];
                      final valor = valoresReales[index];

                      return RadarChartTitle(
                        text: '${config['nombre']}\n${valor.toInt()}',
                        angle: angle,
                      );
                    },
                    dataSets: [
                      RadarDataSet(
                        fillColor: const Color(0xFF5271ff).withOpacity(0.3),
                        borderColor: const Color(0xFF5271ff),
                        entryRadius: 5,
                        borderWidth: 2,
                        dataEntries: normalized.asMap().entries.map((entry) {
                          return RadarEntry(value: entry.value);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: tiposConfig.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final config = entry.value;
                    final valor = valoresReales[idx];
                    final porcentaje = totalFugas > 0
                        ? (valor / totalFugas * 100).toStringAsFixed(1)
                        : "0";

                    if (valor == 0) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: config['color'].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: config['color'].withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: config['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${config['nombre']}:",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${valor.toInt()}",
                            style: TextStyle(
                              color: config['color'],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "($porcentaje%)",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String severity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 2),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          severity,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSectors(List<Fuga> fugas) {
    final totalImpact = fugas.fold(0.0, (sum, f) => sum + f.costoAnual);
    Map<String, double> zoneImpact = {};
    for (var f in fugas) {
      zoneImpact[f.area] = (zoneImpact[f.area] ?? 0) + f.costoAnual;
    }
    var sortedZones = zoneImpact.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topZones = sortedZones.take(3).toList();

    return Column(
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: topZones.map((entry) {
            final color = Colors.redAccent;
            final pct = totalImpact > 0 ? (entry.value / totalImpact * 100) : 0;
            return GestureDetector(
              onTap: () {
                final fugasSector = fugas
                    .where((f) => f.area == entry.key)
                    .toList();
                _showDrillDownDialog(
                  "Sector: ${entry.key}",
                  fugasSector,
                  'sector',
                );
              },
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1c2128),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.05), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          "${pct.toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Impacto Económico:",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "\$${entry.value.toStringAsFixed(0)} USD/Año",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      color: color,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF161a22),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF2d323d)),
      ),
      child: const Column(
        children: [
          Text(
            "🏭💧 Leak Hunter Digital Twin v4.0",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Developed by: Master Engineer Erik Armenta",
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            "\"Accuracy is our signature, and innovation is our nature.\"",
            style: TextStyle(
              color: Color(0xFF5271ff),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel(List<Fuga> fugas) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Excel...")));

    var excel = xl.Excel.createExcel();
    xl.Sheet sheetObject = excel['Sheet1'];

    // Estilo para el encabezado
    xl.CellStyle headerStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.white,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1F497D'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    List<String> headerText = [
      'ID', 'Fecha/Zona', 'Tipo Fuga', 'Área', 'Ubicación', 
      'ID Máquina', 'Severidad', 'Categoría', 'L/min', 
      'Costo Anual (USD)', 'Estado', 'Comentarios'
    ];
    
    List<xl.CellValue> header = headerText.map((t) => xl.TextCellValue(t)).toList();
    sheetObject.appendRow(header);

    // Aplicar estilo al encabezado
    for (int i = 0; i < header.length; i++) {
      var cell = sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // Ajustar anchos de columnas
    sheetObject.setColumnWidth(0, 10.0); // ID
    sheetObject.setColumnWidth(1, 25.0); // Fecha/Zona
    sheetObject.setColumnWidth(2, 20.0); // Tipo Fuga
    sheetObject.setColumnWidth(3, 25.0); // Área
    sheetObject.setColumnWidth(4, 20.0); // Ubicación
    sheetObject.setColumnWidth(5, 18.0); // ID Máquina
    sheetObject.setColumnWidth(6, 15.0); // Severidad
    sheetObject.setColumnWidth(7, 20.0); // Categoría
    sheetObject.setColumnWidth(8, 12.0); // L/min
    sheetObject.setColumnWidth(9, 20.0); // Costo Anual
    sheetObject.setColumnWidth(10, 20.0); // Estado
    sheetObject.setColumnWidth(11, 45.0); // Comentarios

    for (var f in fugas) {
      sheetObject.appendRow([
        xl.TextCellValue(f.id?.toString() ?? '0'),
        xl.TextCellValue(f.zona),
        xl.TextCellValue(f.tipoFuga),
        xl.TextCellValue(f.area),
        xl.TextCellValue(f.ubicacion),
        xl.TextCellValue(f.idMaquina),
        xl.TextCellValue(f.severidad),
        xl.TextCellValue(f.categoria),
        xl.TextCellValue(f.lMin.toStringAsFixed(2)),
        xl.TextCellValue(f.costoAnual.toStringAsFixed(2)),
        xl.TextCellValue(f.estado),
        xl.TextCellValue(f.comentarios),
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final dateStr = "${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}";
      await _saveAndShareFile(
        bytes,
        'Reporte_Fugas_$dateStr.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Reporte de Fugas Excel',
        'xlsx',
      );
    }
  }

  Future<void> _exportExecutivePDF(List<Fuga> fugas) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generando Reporte Ejecutivo PDF...")),
    );

    final pdf = pw.Document();
    final totalImpact = fugas.fold(0.0, (sum, f) => sum + f.costoAnual);
    final reparadas = fugas.where((f) => f.estado == 'Completada').length;
    final enProceso = fugas.where((f) => f.estado == 'En proceso de reparar').length;
    final danadas = fugas.where((f) => f.estado == 'Dañada').length;
    final eficiencia = fugas.isNotEmpty ? (reparadas / fugas.length * 100).toStringAsFixed(1) : "0";
    
    // Cargar el logo
    ByteData? logoBytes;
    pw.MemoryImage? logoImage;
    try {
      logoBytes = await rootBundle.load('assets/images/EA_2.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Error loading logo: $e');
    }

    // Paleta corporativa
    final colorPrimario = PdfColor.fromHex('#1a237e');
    final colorSecundario = PdfColor.fromHex('#4db6ac');
    final colorTexto = PdfColor.fromHex('#424242');
    final colorFondoGris = PdfColor.fromHex('#f5f5f5');
    final colorBlanco = PdfColors.white;

    // Página 1: PORTADA
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: pw.BoxDecoration(color: colorFondoGris),
            child: pw.Stack(
               children: [
                 pw.Positioned(
                   top: 0, left: 0, right: 0,
                   child: pw.Container(
                     height: 150,
                     decoration: pw.BoxDecoration(
                       gradient: pw.LinearGradient(
                         colors: [colorPrimario, colorSecundario],
                         begin: pw.Alignment.topLeft,
                         end: pw.Alignment.bottomRight,
                       )
                     ),
                   )
                 ),
                 pw.Positioned(
                   top: 100, left: 0, right: 0,
                   child: pw.Center(
                     child: pw.Container(
                       width: 120, height: 120,
                       decoration: pw.BoxDecoration(
                         color: colorBlanco,
                         shape: pw.BoxShape.circle,
                         boxShadow: [pw.BoxShadow(color: PdfColors.grey400, blurRadius: 10)]
                       ),
                       padding: const pw.EdgeInsets.all(15),
                       child: logoImage != null ? pw.Image(logoImage) : pw.SizedBox(),
                     )
                   )
                 ),
                 pw.Positioned(
                   top: 280, left: 0, right: 0,
                   child: pw.Column(
                     mainAxisAlignment: pw.MainAxisAlignment.center,
                     children: [
                       pw.Text(
                         "REPORTE EJECUTIVO",
                         style: pw.TextStyle(
                           fontSize: 36,
                           fontWeight: pw.FontWeight.bold,
                           color: colorPrimario,
                           letterSpacing: 2,
                         ),
                       ),
                       pw.SizedBox(height: 10),
                       pw.Text(
                         "AUDITORÍA Y GESTIÓN DE FUGAS INDUSTRIALES",
                         style: pw.TextStyle(
                           fontSize: 14,
                           color: colorTexto,
                           letterSpacing: 1.5,
                         ),
                       ),
                       pw.SizedBox(height: 40),
                       pw.Container(
                         padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                         decoration: pw.BoxDecoration(
                           color: colorBlanco,
                           borderRadius: pw.BorderRadius.circular(20),
                           border: pw.Border.all(color: colorSecundario, width: 1.5),
                         ),
                         child: pw.Text(
                           "Fecha de emisión: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                           style: pw.TextStyle(fontSize: 14, color: colorTexto, fontWeight: pw.FontWeight.bold),
                         )
                       ),
                     ],
                   )
                 ),
                 pw.Positioned(
                   bottom: 50, left: 0, right: 0,
                   child: pw.Column(
                     children: [
                       pw.Text("Leak Hunter Digital Twin v4.1", style: pw.TextStyle(color: PdfColors.grey600, fontSize: 12)),
                       pw.Text("Reporte automatizado generado para uso directivo", style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                     ]
                   )
                 ),
               ]
            )
          );
        }
      )
    );

    // Página 2+: CONTENIDO
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1))
            ),
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                 pw.Text("Leak Hunter Digital Twin", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                 pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ]
            )
          );
        },
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 1,
              child: pw.Text("1. Resumen Ejecutivo (KPI)", style: pw.TextStyle(color: colorPrimario, fontSize: 20)),
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: colorSecundario, width: 2))),
            ),
            pw.SizedBox(height: 15),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildKPIBox("Hallazgos\nTotales", "${fugas.length}", PdfColors.blueGrey700),
                _buildKPIBox("Impacto Económico", "\$${totalImpact.toStringAsFixed(0)}", PdfColors.red700),
                _buildKPIBox("Fugas\nReparadas", "$reparadas", PdfColors.green700),
                _buildKPIBox("Eficiencia\nGlobal", "$eficiencia%", colorSecundario),
              ]
            ),
            pw.SizedBox(height: 30),

            pw.Header(
              level: 1,
              child: pw.Text("2. Perfil de Daños", style: pw.TextStyle(color: colorPrimario, fontSize: 20)),
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: colorSecundario, width: 2))),
            ),
            pw.SizedBox(height: 15),
            
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Estado Actual", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: colorTexto)),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        height: 120,
                        child: pw.Chart(
                          left: pw.Container(),
                          bottom: pw.ChartLegend(),
                          grid: pw.CartesianGrid(
                            xAxis: pw.FixedAxis([0, 1, 2], buildLabel: (v) => pw.Text(v==0?"Dañadas":v==1?"Proc.":"Reparadas", style: pw.TextStyle(fontSize: 8))),
                            yAxis: pw.FixedAxis([0, 5, 10, 15, 20], buildLabel: (v) => pw.Text(v.toInt().toString(), style: const pw.TextStyle(fontSize: 8))),
                          ),
                          datasets: [
                             pw.BarDataSet(
                               color: PdfColors.blueAccent,
                               width: 20,
                               data: [
                                 pw.PointChartValue(0, danadas.toDouble()),
                                 pw.PointChartValue(1, enProceso.toDouble()),
                                 pw.PointChartValue(2, reparadas.toDouble()),
                               ]
                             )
                          ]
                        )
                      )
                    ]
                  )
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Severidad de Fugas", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: colorTexto)),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        height: 120,
                        child: pw.Chart(
                          left: pw.Container(),
                          bottom: pw.ChartLegend(),
                          grid: pw.CartesianGrid(
                            xAxis: pw.FixedAxis([0, 1, 2], buildLabel: (v) => pw.Text(v==0?"Baja":v==1?"Media":"Alta", style: pw.TextStyle(fontSize: 8))),
                            yAxis: pw.FixedAxis([0, 5, 10, 15, 20], buildLabel: (v) => pw.Text(v.toInt().toString(), style: const pw.TextStyle(fontSize: 8))),
                          ),
                          datasets: [
                             pw.BarDataSet(
                               color: PdfColors.orangeAccent,
                               width: 20,
                               data: [
                                 pw.PointChartValue(0, fugas.where((f) => f.severidad == 'Baja').length.toDouble()),
                                 pw.PointChartValue(1, fugas.where((f) => f.severidad == 'Media').length.toDouble()),
                                 pw.PointChartValue(2, fugas.where((f) => f.severidad == 'Alta').length.toDouble()),
                               ]
                             )
                          ]
                        )
                      )
                    ]
                  )
                ),
              ]
            ),
            
            pw.SizedBox(height: 30),
            
            pw.Header(
              level: 1,
              child: pw.Text("3. Desglose de Puntos Críticos", style: pw.TextStyle(color: colorPrimario, fontSize: 20)),
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: colorSecundario, width: 2))),
            ),
            pw.SizedBox(height: 15),
            
            pw.TableHelper.fromTextArray(
              headerAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: colorPrimario),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              oddRowDecoration: pw.BoxDecoration(color: colorFondoGris),
              data: <List<String>>[
                <String>['ID', 'Área', 'Máquina', 'Tipo', 'Severidad', 'Costo/Año', 'Estado'],
                ...fugas.take(40).map((f) => [
                  f.id.toString(),
                  f.area,
                  f.idMaquina,
                  f.tipoFuga,
                  f.severidad,
                  "\$${f.costoAnual.toStringAsFixed(0)}",
                  f.estado,
                ]),
              ],
            ),
          ];
        },
      ),
    );

    // ======== ANEXO: Fichas Técnicas Fotográficas ========
    final fugasConFoto = fugas.where((f) => f.fotoDeteccion != null || f.fotoReparacion != null).take(30).toList();
    
    if (fugasConFoto.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Descargando evidencia fotográfica para el PDF...")),
        );
      }

      Map<String, pw.ImageProvider> photosDeteccion = {};
      Map<String, pw.ImageProvider> photosReparacion = {};

      await Future.wait(fugasConFoto.map((f) async {
        if (f.fotoDeteccion != null) {
          try { photosDeteccion[f.id!.toString()] = await networkImage(f.fotoDeteccion!); } catch(_) {}
        }
        if (f.fotoReparacion != null) {
          try { photosReparacion[f.id!.toString()] = await networkImage(f.fotoReparacion!); } catch(_) {}
        }
      }));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          footer: (context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1))
              ),
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text("Leak Hunter Digital Twin", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                   pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ]
              )
            );
          },
          build: (context) {
            return [
              pw.Header(
                level: 1,
                child: pw.Text("4. Anexo: Fichas Técnicas Fotográficas", style: pw.TextStyle(color: colorPrimario, fontSize: 20)),
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: colorSecundario, width: 2))),
              ),
              pw.SizedBox(height: 15),
              ...fugasConFoto.map((f) {
                final detImg = photosDeteccion[f.id!.toString()];
                final repImg = photosReparacion[f.id!.toString()];

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    borderRadius: pw.BorderRadius.circular(8)
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(color: colorFondoGris, borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Ficha: ${f.id} | Máquina: ${f.idMaquina}", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: colorPrimario)),
                            pw.Text("Área: ${f.area}", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                          ]
                        )
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Categoría: ${f.tipoFuga} (${f.severidad})", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                          pw.Text("Status: ${f.estado}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: f.estado == 'Completada' ? PdfColors.green700 : PdfColors.orange700)),
                          pw.Text("Impacto: \$${f.costoAnual.toStringAsFixed(0)}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                        ]
                      ),
                      if (f.comentarios.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text("Comentarios: ${f.comentarios}", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                      ],
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          if (detImg != null)
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  pw.Text("Evidencia de Detección", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                                  pw.SizedBox(height: 4),
                                  pw.Container(
                                    height: 180,
                                    child: pw.ClipRRect(
                                      horizontalRadius: 4, verticalRadius: 4,
                                      child: pw.Image(detImg, fit: pw.BoxFit.cover)
                                    )
                                  )
                                ]
                              )
                            ),
                          if (detImg != null && repImg != null) pw.SizedBox(width: 12),
                          if (repImg != null)
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  pw.Text("Evidencia de Reparación", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                                  pw.SizedBox(height: 4),
                                  pw.Container(
                                    height: 180,
                                    child: pw.ClipRRect(
                                      horizontalRadius: 4, verticalRadius: 4,
                                      child: pw.Image(repImg, fit: pw.BoxFit.cover)
                                    )
                                  )
                                ]
                              )
                            ),
                        ]
                      )
                    ]
                  )
                );
              }).toList()
            ];
          }
        )
      );
    }
    final bytes = await pdf.save();
    final dateStr = "${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}";
    await _saveAndShareFile(
      bytes,
      'Reporte_Ejecutivo_$dateStr.pdf',
      'application/pdf',
      'Reporte Ejecutivo Leak Hunter',
      'pdf',
    );
  }

  pw.Widget _buildKPIBox(String title, String value, PdfColor color) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(title, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        ]
      )
    );
  }

  Future<void> _exportInteractiveMapHTML(List<Fuga> fugas) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generando Mapa HTML Interactivo...")),
    );

    try {
      final ByteData bytes = await rootBundle.load('assets/images/PlanoHanon25K.png');
      final base64Image = base64Encode(bytes.buffer.asUint8List());

      String escapeJs(String? val) {
        if (val == null) return "";
        return val
            .replaceAll('\\', '\\\\')
            .replaceAll('`', '\\`')
            .replaceAll('\$', '\\\$')
            .replaceAll('\r', '')
            .replaceAll('\n', '<br>');
      }

      String colorToHex(Color c) => '#${c.value.toRadixString(16).substring(2).padLeft(6, '0')}';

      // Create JS array of markers
      StringBuffer markersJs = StringBuffer();
      
      // Construir polígonos de inspecciones
      final inspections = fugas.where((f) => f.tipoFuga == 'Inspección (OK)').toList();
      for (var f in inspections) {
        final factor_x = 25600.0 / 1200.0;
        final factor_y = 16715.0 / (1200.0 * (16715.0 / 25600.0));
        
        final px1 = f.x1 * factor_x;
        final py1 = 16715.0 - (f.y1 * factor_y);
        final px2 = f.x2 * factor_x;
        final py2 = 16715.0 - (f.y2 * factor_y);
        
        markersJs.writeln('''
          L.polygon([
            [$py1, $px1], [$py1, $px2], [$py2, $px2], [$py2, $px1]
          ], {color: '#28A745', weight: 1, fillColor: '#28A745', fillOpacity: 0.2}).addTo(map);
        ''');
      }

      for (var f in fugas) {
        final cx = (f.x1 + f.x2) / 2;
        final cy = (f.y1 + f.y2) / 2;
        final factor_x = 25600.0 / 1200.0;
        final factor_y = 16715.0 / (1200.0 * (16715.0 / 25600.0));
        
        final px = cx * factor_x;
        final py = 16715.0 - (cy * factor_y);
        
        final fluidInfo = AppConstants.fluidos[f.tipoFuga] ?? {"color": Colors.white, "emoji": "⚠️", "marker": Colors.red};
        final Color markerColorObj = fluidInfo['marker'] as Color;
        final String fluidEmoji = fluidInfo['emoji'] as String;
        
        bool isOk = f.estado == 'Completada' || f.tipoFuga == 'Inspección (OK)';
        final emojiStr = isOk ? '✔️' : fluidEmoji;
        final markerColorHex = colorToHex(markerColorObj);
        final cleanSevColorHex = colorToHex(AppConstants.getSeverityColor(f.severidad));

        final cleanId = escapeJs(f.idMaquina);
        final cleanArea = escapeJs(f.area);
        final cleanUbi = escapeJs(f.ubicacion);
        final cleanEstado = escapeJs(f.estado);
        final cleanCateg = escapeJs(f.categoria);
        final cleanSev = escapeJs(f.severidad);
        final cleanFechas = escapeJs(f.zona);
        final cleanNotas = escapeJs(f.comentarios);
        
        markersJs.writeln('''
          L.marker([$py, $px], {icon: getIcon('$markerColorHex', '$emojiStr')})
           .addTo(map)
           .bindPopup(`
           <div style="min-width: 260px; font-family: sans-serif;">
             <div style="border-bottom: 2px solid $markerColorHex; padding-bottom: 8px; margin-bottom: 12px; display: flex; align-items: center;">
               <span style="font-size: 16px; font-weight: bold; color: $markerColorHex;">📋 Ficha Técnica</span>
             </div>
             <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
               <tr><td style="color: #8b949e; width: 40%; padding: 3px 0;">ID Máquina:</td><td style="font-weight: bold; padding: 3px 0; color: white;">$cleanId</td></tr>
               <tr><td style="color: #8b949e; padding: 3px 0;">Área de Planta:</td><td style="padding: 3px 0; color: white;">$cleanArea</td></tr>
               <tr><td style="color: #8b949e; padding: 3px 0;">Instalación:</td><td style="padding: 3px 0; color: white;">\${'$cleanUbi' === 'Terrestre' ? '🚜' : '☁️'} $cleanUbi</td></tr>
               <tr><td style="color: #8b949e; padding: 3px 0;">Estado:</td><td style="padding: 3px 0; color: white;">$cleanEstado</td></tr>
               <tr><td style="color: #8b949e; padding: 3px 0;">Categoría:</td><td style="padding: 3px 0; color: white;">$cleanCateg</td></tr>
               <tr><td style="color: #8b949e; padding: 3px 0;">Caudal:</td><td style="padding: 3px 0; color: white;">\${${f.lMin}} l/min</td></tr>
               <tr><td style="color: #8b949e; padding: 3px 0;">Costo/Año:</td><td style="color: #FF4B4B; font-weight: bold; padding: 3px 0;">\\\$\${${f.costoAnual.toStringAsFixed(0)}} USD</td></tr>
               <tr><td style="color: #8b949e; padding: 3px 0;">Severidad:</td><td style="color: $cleanSevColorHex; font-weight: bold; padding: 3px 0;">$cleanSev</td></tr>
               <tr><td style="color: #8b949e; padding: 3px 0;">Fechas:</td><td style="padding: 3px 0; color: white;">$cleanFechas</td></tr>
             </table>
             \${'$cleanNotas'.length > 0 ? `<div style="margin-top: 10px; background: #1d2129; padding: 8px; border: 1px solid #2d323d; border-radius: 6px;"><div style="color: #8b949e; margin-bottom: 4px; font-size: 11px; font-weight: bold;">💬 Comentarios:</div><div style="color: #c9d1d9; font-style: italic; font-size: 12px;">$cleanNotas</div></div>` : ''}
           </div>
           `);
        ''');
      }

      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <title>Leak Hunter - Interactive Map</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        body, html { margin: 0; padding: 0; height: 100%; background: #161a22; font-family: Arial, sans-serif; }
        #map { height: 100vh; width: 100vw; }
        .leaflet-popup-content-wrapper { background: #1c2128; color: white; border: 1px solid #2d323d; }
        .leaflet-popup-tip { background: #1c2128; }
        .leaflet-popup-content b { color: #5271ff; }
        
        .toolbar {
            position: absolute;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(28, 33, 40, 0.9);
            padding: 10px 20px;
            border-radius: 20px;
            color: white;
            z-index: 1000;
            border: 1px solid #2d323d;
            box-shadow: 0 4px 15px rgba(0,0,0,0.5);
            font-weight: bold;
            display: flex;
            align-items: center;
            gap: 15px;
        }
    </style>
</head>
<body>
    <div class="toolbar">
        <span>🏭 Leak Hunter Digital Twin</span>
        <span style="color: #28a745;">✅ Completadas: ${fugas.where((f) => f.estado == 'Completada').length}</span>
        <span style="color: #dc3545;">🚨 Pendientes: ${fugas.where((f) => f.estado != 'Completada').length}</span>
    </div>
    <div id="map"></div>
    <script>
        var map = L.map('map', {
            crs: L.CRS.Simple,
            minZoom: -3,
            maxZoom: 2
        });

        var bounds = [[0, 0], [16715, 25600]];
        var image = L.imageOverlay('data:image/png;base64,$base64Image', bounds).addTo(map);
        map.fitBounds(bounds);

        function getIcon(color, emoji) {
            var markerHtml = `<div style="display:flex; align-items:center; justify-content:center; background-color: \${color}; width: 22px; height: 22px; border-radius: 50%; border: 2px solid white; box-shadow: 0 0 10px rgba(0,0,0,0.5); font-size: 12px; color: white; font-family: 'Segoe UI Emoji', Arial;">\${emoji}</div>`;
            return L.divIcon({
                html: markerHtml,
                className: '',
                iconSize: [26, 26],
                iconAnchor: [13, 13]
            });
        }

        $markersJs
    </script>
</body>
</html>
      ''';

      final dateStr = "${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}";
      final htmlBytes = utf8.encode(htmlContent);

      if (kIsWeb) {
        // En web: abrir directamente en nueva pestaña (blob de ~8MB no se puede descargar via click)
        final blob = html.Blob([htmlBytes], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        // Revocar después de un delay para que la pestaña cargue
        Future.delayed(const Duration(seconds: 3), () => html.Url.revokeObjectUrl(url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🗺️ Plano interactivo abierto en nueva pestaña")),
          );
        }
      } else {
        await _saveAndShareFile(
          htmlBytes,
          'Plano_Interactivo_$dateStr.html',
          'text/html',
          'Plano Interactivo HTML',
          'html',
        );
      }
    } catch (e) {
      print('Error exporting interactive map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al generar el plano interactivo.")),
      );
    }
  }

  Future<void> _saveAndShareFile(List<int> bytes, String fileName, String mimeType, String subject, String extension) async {
    try {
      if (kIsWeb) {
        // En web: descarga directa desde el browser
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        (html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click());
        html.Url.revokeObjectUrl(url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ $subject descargado")),
          );
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar $subject',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [extension],
        );
        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes, flush: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Archivo guardado en: $outputFile")),
            );
          }
        }
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        
        final xFile = XFile(file.path, mimeType: mimeType);
        await Share.shareXFiles(
          [xFile], 
          subject: subject,
          text: 'Adjunto $subject.',
        );
      }
    } catch (e) {
      print('Error saving/sharing file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
      }
    }
  }
}