import 'package:flutter/material.dart';

class AppConstants {
  static const Map<String, Map<String, dynamic>> relacionFugas = {
    "Aire": {
      "Fuga A": {"l_min": "0.1-10", "costo": 60.0},
      "Fuga B": {"l_min": "10.1-20", "costo": 300.0},
      "Fuga C": {"l_min": "20.1-30", "costo": 680.0},
      "Fuga D": {"l_min": "30.1-40", "costo": 890.0},
      "Fuga E": {"l_min": "40.1-50", "costo": 1090.0},
    },
    "Helio": {
      "Fuga A": {"l_min": "0.1-17", "costo": 13200.0},
      "Fuga B": {"l_min": "17.1-32", "costo": 26400.0},
      "Fuga C": {"l_min": "33.1-50", "costo": 132000.0},
    },
    "Aceite": {
      "Fuga A": {"l_min": "0.002-0.004", "costo": 2181.17},
      "Fuga B": {"l_min": "0.004-0.01", "costo": 10905.48},
      "Fuga C": {"l_min": "0.01-0.1", "costo": 109058.40},
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
}
