import 'package:flutter/material.dart';

class ConstantsSeguridad {
  static const Map<String, Map<String, dynamic>> tiposRiesgo = {
    "Caída": {"color": Color(0xFFD2691E), "emoji": "🧗", "marker": Colors.deepOrange},
    "Incendio": {"color": Color(0xFFFF4500), "emoji": "🔥", "marker": Colors.redAccent},
    "Químico": {"color": Color(0xFF00FA9A), "emoji": "🧪", "marker": Colors.greenAccent},
    "Eléctrico": {"color": Color(0xFFE5C100), "emoji": "⚡", "marker": Colors.amber},
    "Mecánico": {"color": Color(0xFF8B4513), "emoji": "⚙️", "marker": Colors.brown},
    "Ergonómico": {"color": Color(0xFF9370DB), "emoji": "🪑", "marker": Colors.deepPurple},
    "Psicosocial": {"color": Color(0xFF4682B4), "emoji": "🧠", "marker": Colors.indigo},
    "Inspección (OK)": {"color": Color(0xFF28A745), "emoji": "✅", "marker": Colors.green}
  };

  static const Map<String, Map<String, dynamic>> relacionRiesgos = {
    "Caída": {"Riesgo General": {"l_min": "0", "costo": 0.0}},
    "Incendio": {"Riesgo General": {"l_min": "0", "costo": 0.0}},
    "Químico": {"Riesgo General": {"l_min": "0", "costo": 0.0}},
    "Eléctrico": {"Riesgo General": {"l_min": "0", "costo": 0.0}},
    "Mecánico": {"Riesgo General": {"l_min": "0", "costo": 0.0}},
    "Ergonómico": {"Riesgo General": {"l_min": "0", "costo": 0.0}},
    "Psicosocial": {"Riesgo General": {"l_min": "0", "costo": 0.0}},
    "Inspección (OK)": {"Sin Riesgo": {"l_min": "0", "costo": 0.0}}
  };

  static const List<String> statusOptions = [
    'Identificado',
    'En evaluación',
    'En corrección',
    'Cerrado',
    'Verificado',
    'Inspección (OK)'
  ];

  static Color getSeverityColor(String severity) {
    switch (severity) {
      case "Crítico": return const Color(0xFFFF0000); // Red
      case "Alto": return const Color(0xFFFF4500); // OrangeRed
      case "Medio": return const Color(0xFFFFA500); // Orange
      case "Bajo": return const Color(0xFF28A745); // Green
      default: return const Color(0xFF333333);
    }
  }

  static Color getStatusColor(String estado, String tipoRiesgo) {
    if (estado == "Cerrado" || estado == "Verificado" || tipoRiesgo == "Inspección (OK)") return const Color(0xFF28A745);
    if (estado == "Identificado") return const Color(0xFFd9534f);
    return const Color(0xFFf0ad4e); // En evaluación, En corrección
  }
}
