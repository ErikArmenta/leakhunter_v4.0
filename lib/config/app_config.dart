import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants_fugas.dart';
import 'constants_fallas.dart';
import 'constants_seguridad.dart';
import 'constants.dart';
import '../providers/app_mode_provider.dart';

enum AppMode { fugas, fallas, seguridad }

class AppConfig {
  final AppMode mode;
  final String appTitle;
  final IconData icon;
  final Color primaryColor;
  final String incidentTypeLabel;
  final Map<String, Map<String, dynamic>> incidentTypes;
  final Map<String, Map<String, dynamic>> relacionFugas;
  final List<String> statusOptions;
  final List<String> severityLevels;
  final Color Function(String) getSeverityColor;
  final Color Function(String, String) getStatusColor;
  final String Function(String) getFluidUnit;
  final bool usesFluids;

  AppConfig({
    required this.mode,
    required this.appTitle,
    required this.icon,
    required this.primaryColor,
    required this.incidentTypeLabel,
    required this.incidentTypes,
    required this.relacionFugas,
    required this.statusOptions,
    required this.severityLevels,
    required this.getSeverityColor,
    required this.getStatusColor,
    required this.getFluidUnit,
    required this.usesFluids,
  });

  static AppConfig forMode(AppMode mode) {
    switch (mode) {
      case AppMode.fugas:
        return AppConfig(
          mode: AppMode.fugas,
          appTitle: 'Leak Hunter',
          icon: Icons.air,
          primaryColor: Colors.blueAccent,
          incidentTypeLabel: 'Tipo de Fluido',
          incidentTypes: ConstantsFugas.fluidos,
          relacionFugas: ConstantsFugas.relacionFugas,
          statusOptions: ConstantsFugas.statusOptions,
          severityLevels: ['Alta', 'Media', 'Baja'],
          getSeverityColor: ConstantsFugas.getSeverityColor,
          getStatusColor: ConstantsFugas.getStatusColor,
          getFluidUnit: ConstantsFugas.getFluidUnit,
          usesFluids: true,
        );
      case AppMode.fallas:
        return AppConfig(
          mode: AppMode.fallas,
          appTitle: 'Machine Failures',
          icon: Icons.build,
          primaryColor: Colors.amber,
          incidentTypeLabel: 'Tipo de Falla',
          incidentTypes: ConstantsFallas.tiposFalla,
          relacionFugas: ConstantsFallas.relacionFallas,
          statusOptions: ConstantsFallas.statusOptions,
          severityLevels: ['Catastrófica', 'Crítica', 'Media', 'Leve'],
          getSeverityColor: ConstantsFallas.getSeverityColor,
          getStatusColor: ConstantsFallas.getStatusColor,
          getFluidUnit: (s) => '',
          usesFluids: false,
        );
      case AppMode.seguridad:
        return AppConfig(
          mode: AppMode.seguridad,
          appTitle: 'Safety Tracker',
          icon: Icons.health_and_safety,
          primaryColor: Colors.redAccent,
          incidentTypeLabel: 'Tipo de Riesgo',
          incidentTypes: ConstantsSeguridad.tiposRiesgo,
          relacionFugas: ConstantsSeguridad.relacionRiesgos,
          statusOptions: ConstantsSeguridad.statusOptions,
          severityLevels: ['Crítico', 'Alto', 'Medio', 'Bajo'],
          getSeverityColor: ConstantsSeguridad.getSeverityColor,
          getStatusColor: ConstantsSeguridad.getStatusColor,
          getFluidUnit: (s) => '',
          usesFluids: false,
        );
    }
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  final mode = ref.watch(appModeProvider);
  return AppConfig.forMode(mode);
});
