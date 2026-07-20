import 'package:flutter/material.dart';

class ConstantsFugas {
  static const Map<String, Map<String, dynamic>> relacionFugas = {
    // Aire: l_min almacenado en DB representa cfm (se muestra como cfm en la app)
    // Fórmula: cfm * 525,600 min/año (= valor1) * 0.0001909 (factor demanda kW/h)
    "Aire": {
      "Fuga A": {"l_min": "2.0", "costo": 200.67},
      "Fuga B": {"l_min": "8.0", "costo": 802.69},
      "Fuga C": {"l_min": "20.5", "costo": 2056.90},
    },
    // Helio: l_min almacenado en DB representa m³/min (se muestra como m³/min en la app)
    // Fórmula: (m³/1440 min) * 525,600 min/año * 54.9 dlls/m³
    "Helio": {
      "Fuga A": {"l_min": "1.0", "costo": 20025.67},
      "Fuga B": {"l_min": "2.0", "costo": 40825.50},
      "Fuga C": {"l_min": "3.0", "costo": 60019.31},
    },
    // Agua: l_min almacenado en DB representa l/min
    // Fórmula: l/min * 245,520 min/año / 1000 (a m³) * 6.14 dlls/m³
    "Agua": {
      "Fuga A": {"l_min": "1.5", "costo": 2261.23},
      "Fuga B": {"l_min": "3.5", "costo": 5276.22},
      "Fuga C": {"l_min": "5.0", "costo": 7537.46},
    },
    // Aceite: l_min almacenado en DB representa l/min
    // Fórmula: l_min * 245,520 min/año / 1000 (a litros) * 2.91 dlls/litro
    "Aceite": {
      "Fuga A": {"l_min": "3.0", "costo": 2143.0},
      "Fuga B": {"l_min": "7.0", "costo": 5001.24},
      "Fuga C": {"l_min": "10.0", "costo": 7144.63},
    },
    // Gas Natural: l_min almacenado en DB representa m³/min
    // Fórmula: m³/min * 525,600 min/año / 1000 * 0.3 dlls/m³
    "Gas Natural": {
      "Fuga A": {"l_min": "1.0", "costo": 157.68},
      "Fuga B": {"l_min": "2.0", "costo": 315.36},
      "Fuga C": {"l_min": "3.0", "costo": 473.04},
    },
    "Inspección (OK)": {
      "Sin Fuga": {"l_min": "0", "costo": 0.0},
      "Sin Fuga (Aire)": {"l_min": "0", "costo": 0.0},
      "Sin Fuga (Gas Natural)": {"l_min": "0", "costo": 0.0},
      "Sin Fuga (Agua)": {"l_min": "0", "costo": 0.0},
      "Sin Fuga (Helio)": {"l_min": "0", "costo": 0.0},
      "Sin Fuga (Aceite)": {"l_min": "0", "costo": 0.0}
    }
  };

  static const Map<String, Map<String, dynamic>> fluidos = {
    "Aire": {"color": Color(0xFF0000FF), "emoji": "💨", "marker": Colors.blue},
    "Gas Natural": {"color": Color(0xFFFFA500), "emoji": "🔥", "marker": Colors.orange},
    "Agua": {"color": Color(0xFF00FFFF), "emoji": "💧", "marker": Colors.cyan},
    "Helio": {"color": Color(0xFFFF00FF), "emoji": "🎈", "marker": Colors.purple},
    "Aceite": {"color": Color(0xFFFFFF00), "emoji": "🛢️", "marker": Color(0xFF8B0000)}, // Dark red
    "Inspección (OK)": {"color": Color(0xFF28A745), "emoji": "✅", "marker": Colors.green}
  };

  static const List<String> statusOptions = [
    'Reportada',
    'Dañada',
    'En Proceso',
    'Programada',
    'Completada',
    'Inspección (OK)'
  ];

  static Color getSeverityColor(String severity) {
    switch (severity) {
      case "Alta": return const Color(0xFFFF4B4B);
      case "Media": return const Color(0xFFFFA500);
      case "Baja": return const Color(0xFF28A745);
      default: return const Color(0xFF333333);
    }
  }

  static Color getStatusColor(String estado, String tipoFuga) {
    if (estado == "Completada" || tipoFuga == "Inspección (OK)") return const Color(0xFF28A745);
    if (estado == "Dañada" || estado == "Reportada") return const Color(0xFFd9534f); // Red
    return const Color(0xFFf0ad4e); // En proceso, programada (Orange)
  }

  static String getFluidUnit(String tipoFuga) {
    switch (tipoFuga) {
      case "Aire":
        return "cfm"; // Cubic feet per minute
      case "Helio":
      case "Gas Natural":
        return "m³/min"; // Metros cúbicos por minuto
      default:
        return "l/min"; // Litros por minuto (Aceite, Agua)
    }
  }
}
