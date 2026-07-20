import 'package:flutter/material.dart';

class ConstantsFallas {
  static const Map<String, Map<String, dynamic>> tiposFalla = {
    "Eléctrica": {"color": Color(0xFFE5C100), "emoji": "⚡", "marker": Colors.amber},
    "Mecánica": {"color": Color(0xFF8B4513), "emoji": "⚙️", "marker": Colors.brown},
    "Hidráulica": {"color": Color(0xFF1E90FF), "emoji": "🔧", "marker": Colors.blue},
    "Neumática": {"color": Color(0xFF87CEEB), "emoji": "💨", "marker": Colors.lightBlue},
    "Software": {"color": Color(0xFF9370DB), "emoji": "💻", "marker": Colors.deepPurple},
    "Estructural": {"color": Color(0xFF708090), "emoji": "🏗️", "marker": Colors.blueGrey},
    "Inspección (OK)": {"color": Color(0xFF28A745), "emoji": "✅", "marker": Colors.green}
  };

  static const Map<String, Map<String, dynamic>> relacionFallas = {
    "Eléctrica": {"Falla General": {"l_min": "0", "costo": 0.0}},
    "Mecánica": {"Falla General": {"l_min": "0", "costo": 0.0}},
    "Hidráulica": {"Falla General": {"l_min": "0", "costo": 0.0}},
    "Neumática": {"Falla General": {"l_min": "0", "costo": 0.0}},
    "Software": {"Falla General": {"l_min": "0", "costo": 0.0}},
    "Estructural": {"Falla General": {"l_min": "0", "costo": 0.0}},
    "Inspección (OK)": {"Sin Falla": {"l_min": "0", "costo": 0.0}}
  };

  static const List<String> statusOptions = [
    'Reportada',
    'En diagnóstico',
    'En reparación',
    'Reparada',
    'Verificada',
    'Inspección (OK)'
  ];

  static Color getSeverityColor(String severity) {
    switch (severity) {
      case "Catastrófica": return const Color(0xFF8B0000); // Dark red
      case "Crítica": return const Color(0xFFFF0000); // Red
      case "Media": return const Color(0xFFFFA500); // Orange
      case "Leve": return const Color(0xFF28A745); // Green
      default: return const Color(0xFF333333);
    }
  }

  static Color getStatusColor(String estado, String tipoFalla) {
    if (estado == "Reparada" || estado == "Verificada" || tipoFalla == "Inspección (OK)") return const Color(0xFF28A745);
    if (estado == "Reportada") return const Color(0xFFd9534f);
    return const Color(0xFFf0ad4e); // En diagnóstico, En reparación
  }
}
