import 'package:flutter/material.dart';
import 'app_config.dart';

class AppConstants {
  // Minutos de operación anual para Aceite y Agua (248 días laborados)
  static const double minutosAnualesAceite = 245520.0; // 248 días * 24h * 60min
  static const double minutosAnualesAgua = 245520.0; // 248 días * 24h * 60min
  // Minutos anuales para Helio, Aire y Gas Natural (365 días completos del año)
  static const double minutosAnualesHelioAire = 525600.0; // 365 días * 24h * 60min
  static const double minutosAnualesGas = 525600.0; // 365 días * 24h * 60min

  // Factor de demanda eléctrica para Aire: dem * costo_kWh / 60 = 0.0001909
  static const double factorDemandaAire = 0.0001909;
  // Costo por litro de agua (pesos/litro convertido a dólares o tarifa directa)
  static const double costoPorLitroAgua = 6.14;
  // Costo por metro cúbico de Gas Natural
  static const double costoPorM3Gas = 0.3;

  static AppConfig? _currentConfig;

  static void setConfig(AppConfig config) {
    _currentConfig = config;
  }

  static Map<String, Map<String, dynamic>> get relacionFugas => _currentConfig?.relacionFugas ?? {};
  static Map<String, Map<String, dynamic>> get fluidos => _currentConfig?.incidentTypes ?? {};

  static Color getSeverityColor(String severity) => _currentConfig?.getSeverityColor(severity) ?? const Color(0xFF333333);

  static Color getStatusColor(String estado, String tipoFuga) => _currentConfig?.getStatusColor(estado, tipoFuga) ?? const Color(0xFF333333);

  static String getFluidUnit(String tipoFuga) => _currentConfig?.getFluidUnit(tipoFuga) ?? '';
}
