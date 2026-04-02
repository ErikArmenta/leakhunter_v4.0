class AuditLog {
  final String id;
  final int fugaId;
  final String? userId;
  final String? userEmail;
  final String accion;
  final String? estadoAnterior;
  final String? estadoNuevo;
  final String detalles;
  final DateTime fecha;

  AuditLog({
    required this.id,
    required this.fugaId,
    this.userId,
    this.userEmail,
    required this.accion,
    this.estadoAnterior,
    this.estadoNuevo,
    required this.detalles,
    required this.fecha,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      fugaId: json['fuga_id'],
      userId: json['user_id'],
      userEmail: json['user_email'],
      accion: json['accion'],
      estadoAnterior: json['estado_anterior'],
      estadoNuevo: json['estado_nuevo'],
      detalles: json['detalles'] ?? '',
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fuga_id': fugaId,
      'user_id': userId,
      'user_email': userEmail,
      'accion': accion,
      'estado_anterior': estadoAnterior,
      'estado_nuevo': estadoNuevo,
      'detalles': detalles,
      'fecha': fecha.toIso8601String(),
    };
  }
}
