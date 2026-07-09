import 'package:flutter/material.dart';

class AppConstants {
  // Minutos de operación anual para Aceite (248 días de trabajo de máquinas)
  static const double minutosAnualesAceite = 245520.0; // 248 días * 24h * 60min
  // Minutos anuales para Helio y Aire (365 días completos del año)
  static const double minutosAnualesHelioAire = 525600.0; // 365 días * 24h * 60min

  static const Map<String, Map<String, dynamic>> relacionFugas = {
    // Aire: l_min almacenado en DB representa cfm (se muestra como cfm en la app)
    // Fórmula: cfm * 525,600 min/año * 0.138 dlls/kWh
    "Aire": {
      "Fuga A": {"l_min": "2.0", "costo": 145065.0},
      "Fuga B": {"l_min": "8.0", "costo": 580262.4},
      "Fuga C": {"l_min": "20.5", "costo": 1486922.4},
    },
    // Helio: l_min almacenado en DB representa m³/min (se muestra como m³/min en la app)
    // Fórmula: (m³/1440 min) * 525,600 min/año * 54.9 dlls/m³
    "Helio": {
      "Fuga A": {"l_min": "1.0", "costo": 20025.67},
      "Fuga B": {"l_min": "2.0", "costo": 40825.50},
      "Fuga C": {"l_min": "3.0", "costo": 60019.31},
    },
    "Agua": {
      "Fuga A": {"l_min": "0.01-0.05", "costo": 114.0},
      "Fuga B": {"l_min": "0.05-0.10", "costo": 228.0},
      "Fuga C": {"l_min": "0.10-0.20", "costo": 456.0},
      "Fuga D": {"l_min": "0.20-1.50", "costo": 3400.0},
      "Fuga E": {"l_min": "1.50-3.00", "costo": 6840.0},
    },
    // Aceite: l_min almacenado en DB representa l/min
    // Fórmula: l_min * 245,520 min/año / 1000 (a litros) * 2.91 dlls/litro
    "Aceite": {
      "Fuga A": {"l_min": "3.0", "costo": 2143.0},
      "Fuga B": {"l_min": "7.0", "costo": 5001.24},
      "Fuga C": {"l_min": "10.0", "costo": 7144.63},
    },
    "Gas Natural": {
      "Fuga A": {"l_min": "1-50", "costo": 450.0},
      "Fuga B": {"l_min": "51-150", "costo": 1800.0},
      "Fuga C": {"l_min": "151-500", "costo": 5200.0},
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
    if (estado == "Dañada") return const Color(0xFFd9534f);
    return const Color(0xFFf0ad4e); // En proceso
  }

  /// Devuelve la etiqueta de unidad de flujo según el tipo de fluido.
  /// En la base de datos siempre se guarda como l_min, pero en la UI se muestra diferente.
  static String getFluidUnit(String tipoFuga) {
    switch (tipoFuga) {
      case "Aire":
        return "cfm"; // Cubic feet per minute
      case "Helio":
        return "m³/min"; // Metros cúbicos por minuto
      default:
        return "l/min"; // Litros por minuto (Aceite, Agua, Gas Natural)
    }
  }
}
