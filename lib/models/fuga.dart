import 'package:intl/intl.dart';

class Fuga {
  final int? id;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final String zona;
  final String tipoFuga;
  final String area;
  final String ubicacion;
  final String idMaquina;
  final String severidad;
  final String categoria;
  final double lMin;
  final double costoAnual;
  final String estado;
  final String comentarios;
  final String comentariosReparacion;
  final String? fotoDeteccion;
  final String? fotoReparacion;

  Fuga({
    this.id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.zona,
    required this.tipoFuga,
    required this.area,
    required this.ubicacion,
    required this.idMaquina,
    required this.severidad,
    required this.categoria,
    required this.lMin,
    required this.costoAnual,
    required this.estado,
    this.comentarios = '',
    this.comentariosReparacion = '',
    this.fotoDeteccion,
    this.fotoReparacion,
  });

  factory Fuga.fromJson(Map<String, dynamic> json) {
    return Fuga(
      id: json['id'],
      x1: (json['x1'] ?? 0).toDouble(),
      y1: (json['y1'] ?? 0).toDouble(),
      x2: (json['x2'] ?? 0).toDouble(),
      y2: (json['y2'] ?? 0).toDouble(),
      zona: json['zona'] ?? 'N/A',
      tipoFuga: json['tipo_fuga'] ?? json['tipofuga'] ?? 'N/A',
      area: json['area'] ?? 'N/A',
      ubicacion: json['ubicacion'] ?? 'N/A',
      idMaquina: json['id_maquina'] ?? json['idmaquina'] ?? 'N/A',
      severidad: json['severidad'] ?? 'Media',
      categoria: json['categoria'] ?? 'N/A',
      lMin: (json['l_min'] ?? json['lmin'] ?? 0).toDouble(),
      costoAnual: (json['costo_anual'] ?? json['costoanual'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'Dañada',
      comentarios: json['comentarios'] ?? json['comentario'] ?? '',
      comentariosReparacion: json['comentarios_reparacion'] ?? '',
      fotoDeteccion: json['foto_deteccion'],
      fotoReparacion: json['foto_reparacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
      'zona': zona,
      'tipo_fuga': tipoFuga,
      'area': area,
      'ubicacion': ubicacion,
      'id_maquina': idMaquina,
      'severidad': severidad,
      'categoria': categoria,
      'l_min': lMin,
      'costo_anual': costoAnual,
      'estado': estado,
      'comentarios': comentarios,
      'comentarios_reparacion': comentariosReparacion,
      if (fotoDeteccion != null) 'foto_deteccion': fotoDeteccion,
      if (fotoReparacion != null) 'foto_reparacion': fotoReparacion,
    };
  }

  Fuga copyWith({
    int? id,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    String? zona,
    String? tipoFuga,
    String? area,
    String? ubicacion,
    String? idMaquina,
    String? severidad,
    String? categoria,
    double? lMin,
    double? costoAnual,
    String? estado,
    String? comentarios,
    String? comentariosReparacion,
    String? fotoDeteccion,
    String? fotoReparacion,
  }) {
    return Fuga(
      id: id ?? this.id,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      zona: zona ?? this.zona,
      tipoFuga: tipoFuga ?? this.tipoFuga,
      area: area ?? this.area,
      ubicacion: ubicacion ?? this.ubicacion,
      idMaquina: idMaquina ?? this.idMaquina,
      severidad: severidad ?? this.severidad,
      categoria: categoria ?? this.categoria,
      lMin: lMin ?? this.lMin,
      costoAnual: costoAnual ?? this.costoAnual,
      estado: estado ?? this.estado,
      comentarios: comentarios ?? this.comentarios,
      comentariosReparacion: comentariosReparacion ?? this.comentariosReparacion,
      fotoDeteccion: fotoDeteccion ?? this.fotoDeteccion,
      fotoReparacion: fotoReparacion ?? this.fotoReparacion,
    );
  }

  DateTime? get fechaInicio {
    try {
      if (zona.isEmpty) return null;
      final partsStr = zona.split('-');
      if (partsStr.isEmpty) return null;
      final fParts = partsStr[0].trim().split('/');
      if (fParts.length != 3) return null;
      return DateTime(int.parse(fParts[2]), int.parse(fParts[1]), int.parse(fParts[0]));
    } catch (_) {
      return null;
    }
  }

  DateTime? get fechaTermino {
    try {
      if (zona.isEmpty) return null;
      final partsStr = zona.split('-');
      if (partsStr.length < 2) return null;
      final fParts = partsStr[1].trim().split('/');
      if (fParts.length != 3) return null;
      return DateTime(int.parse(fParts[2]), int.parse(fParts[1]), int.parse(fParts[0]));
    } catch (_) {
      return null;
    }
  }

  double get costoActual {
    if (estado == 'Inspección (OK)') return 0.0;
    
    final inicio = fechaInicio;
    if (inicio == null) return 0.0; 

    DateTime fin;
    if (estado == 'Completada') {
      fin = fechaTermino ?? DateTime.now();
    } else {
      fin = DateTime.now();
    }

    final double exactMinutes = fin.difference(inicio).inMinutes.toDouble();
    if (exactMinutes <= 0) return 0.0;

    // costoAnual ya incluye los días laborados en su valor precalculado.
    // Dividimos siempre entre los minutos reales del año (525,600)
    // para que el costo escale proporcionalmente al tiempo real transcurrido.
    // Así, tras 365 días reales -> costoActual = costoAnual exacto.
    const double minutesInFullYear = 525600.0; // 365 * 24 * 60

    final double costoPorMinuto = costoAnual / minutesInFullYear;
    
    return costoPorMinuto * exactMinutes;
  }

  double get consumoActualLitros {
    if (estado == 'Inspección (OK)') return 0.0;
    
    final inicio = fechaInicio;
    if (inicio == null) return 0.0; 

    DateTime fin;
    if (estado == 'Completada') {
      fin = fechaTermino ?? DateTime.now();
    } else {
      fin = DateTime.now();
    }

    final double exactMinutes = fin.difference(inicio).inMinutes.toDouble();
    if (exactMinutes <= 0) return 0.0;

    // Aplicar ratio de días laborados para que consumo sea consistente con costo.
    // Aceite y Agua: 248 días laborados / 365 días totales
    // Aire, Helio, Gas: operan 365/365 (ratio = 1.0)
    final double workingRatio;
    if (tipoFuga == 'Aceite' || tipoFuga == 'Agua') {
      workingRatio = 245520.0 / 525600.0; // ~0.467 (248 de 365 días)
    } else {
      workingRatio = 1.0;
    }

    return lMin * exactMinutes * workingRatio;
  }

  double get consumoActualM3 {
    if (estado == 'Inspección (OK)') return 0.0;
    
    final inicio = fechaInicio;
    if (inicio == null) return 0.0; 

    DateTime fin;
    if (estado == 'Completada') {
      fin = fechaTermino ?? DateTime.now();
    } else {
      fin = DateTime.now();
    }

    final double exactMinutes = fin.difference(inicio).inMinutes.toDouble();
    if (exactMinutes <= 0) return 0.0;

    // Aplicar ratio de días laborados
    final double workingRatio;
    if (tipoFuga == 'Aceite' || tipoFuga == 'Agua') {
      workingRatio = 245520.0 / 525600.0; // ~0.467 (248 de 365 días)
    } else {
      workingRatio = 1.0;
    }

    // Para Gas Natural y Helio: lMin ya está en m³/min, se usa directo
    if (tipoFuga == 'Gas Natural' || tipoFuga == 'Helio') {
      return lMin * exactMinutes * workingRatio; // lMin ya es m³/min
    }
    // Agua y otros: lMin es Litros/minuto. 1000 Litros = 1 m³
    return (lMin / 1000.0) * exactMinutes * workingRatio;
  }

  double get consumoActualKWh {
    if (estado == 'Inspección (OK)' || costoActual <= 0.0) return 0.0;
    
    // Convertir USD a MXN (Tipo de cambio: 19)
    final costoMXN = costoActual * 19.0;
    // Calcular kWh (Precio por kWh: 2.4 MXN)
    return costoMXN / 2.4;
  }

  String get consumoActualLitrosStr {
    final format = NumberFormat('#,##0.00', 'en_US');
    return format.format(consumoActualLitros);
  }

  String get consumoActualM3Str {
    final format = NumberFormat('#,##0.00', 'en_US');
    return format.format(consumoActualM3);
  }

  String get consumoActualKWhStr {
    final format = NumberFormat('#,##0.00', 'en_US');
    return format.format(consumoActualKWh);
  }

  int get diasTranscurridos {
    final inicio = fechaInicio;
    if (inicio == null) return 0;
    
    DateTime fin;
    if (estado == 'Completada') {
      fin = fechaTermino ?? DateTime.now();
    } else {
      fin = DateTime.now();
    }
    
    final days = fin.difference(inicio).inDays;
    return days < 0 ? 0 : days;
  }
}
