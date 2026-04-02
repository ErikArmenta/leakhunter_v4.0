import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/fuga.dart';
import '../models/audit_log.dart';
import '../providers/fugas_provider.dart';

class AuditTimelineWidget extends ConsumerStatefulWidget {
  final Fuga fuga;

  const AuditTimelineWidget({super.key, required this.fuga});

  @override
  ConsumerState<AuditTimelineWidget> createState() => _AuditTimelineWidgetState();
}

class _AuditTimelineWidgetState extends ConsumerState<AuditTimelineWidget> {
  bool _isLoading = true;
  List<AuditLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (widget.fuga.id == null) return;
    final logs = await ref.read(supabaseServiceProvider).getFugaAuditLogs(widget.fuga.id!);
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (_logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Text(
          "No hay registros de auditoría para esta fuga aún o la tabla no ha sido creada.",
          style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final isFirst = index == 0;
        final isLast = index == _logs.length - 1;

        IconData iconData;
        Color iconColor;

        if (log.accion == 'CREACIÓN') {
          iconData = Icons.add_circle;
          iconColor = Colors.green;
        } else if (log.accion == 'CAMBIO DE ESTADO') {
          iconData = Icons.swap_horiz;
          iconColor = Colors.orange;
        } else {
          iconData = Icons.edit_note;
          iconColor = Colors.blue;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line and dot
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 2,
                        color: isFirst ? Colors.transparent : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF161a22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 18),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: 2,
                        color: isLast ? Colors.transparent : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1d2129),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2d323d)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.accion,
                              style: TextStyle(
                                color: iconColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(log.fecha.toLocal()),
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          log.detalles,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        if (log.userEmail != null && log.userEmail!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 12, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(
                                log.userEmail!,
                                style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
