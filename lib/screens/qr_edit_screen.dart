import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/fugas_provider.dart';
import '../config/constants.dart';
import '../models/fuga.dart';

class QREditScreen extends ConsumerStatefulWidget {
  final int fugaId;
  const QREditScreen({super.key, required this.fugaId});

  @override
  ConsumerState<QREditScreen> createState() => _QREditScreenState();
}

class _QREditScreenState extends ConsumerState<QREditScreen> {
  // Form State
  String? editFluido;
  String? editCategoria;
  String? editZona;
  String? editArea;
  String? editIdMaquina;
  String? editSeveridad;
  String? editUbicacion;
  String? editEstado;
  String? editComentarios;
  String? editComentariosReparacion;
  
  XFile? editFotoDeteccionFile;
  XFile? editFotoReparacionFile;
  bool isUploading = false;
  bool isInitialized = false;

  void _initForm(Fuga f) {
    if (isInitialized) return;
    editFluido = f.tipoFuga;
    editCategoria = f.categoria;
    editZona = f.zona;
    editArea = f.area;
    editIdMaquina = f.idMaquina;
    editSeveridad = f.severidad;
    editUbicacion = f.ubicacion;
    editEstado = f.estado;
    editComentarios = f.comentarios;
    editComentariosReparacion = f.comentariosReparacion;
    
    final validSeverities = ["Baja", "Media", "Alta"];
    if (!validSeverities.contains(editSeveridad)) editSeveridad = "Media";
    final validUbicaciones = ["Terrestre", "Aérea"];
    if (!validUbicaciones.contains(editUbicacion)) editUbicacion = "Terrestre";
    final validEstados = ["En proceso de reparar", "Dañada", "Completada"];
    if (!validEstados.contains(editEstado)) editEstado = "Dañada";
    
    isInitialized = true;
  }

  static bool isVideoUrl(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.endsWith('.avi');
  }

  Future<void> _handleMediaPick(BuildContext context, ImagePicker picker, Function(XFile) onPicked) async {
    final file = await picker.pickMedia(imageQuality: 70);
    if (file != null) {
      final len = await file.length();
      if (len > 10 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ El archivo excede los 10 MB.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
        return;
      }
      onPicked(file);
    }
  }

  Widget _buildPhotoPicker(String label, String? existingUrl, XFile? selectedFile, VoidCallback onPick) {
    bool selectedIsVideo = selectedFile != null && isVideoUrl(selectedFile.name);
    bool existingIsVideo = existingUrl != null && isVideoUrl(existingUrl);

    Widget innerContent;
    if (selectedFile != null) {
      innerContent = Center(child: Text(selectedIsVideo ? "✅ Video listo" : "✅ Foto lista", style: const TextStyle(color: Colors.green)));
    } else if (existingUrl != null) {
      if (existingIsVideo) {
        innerContent = Stack(
          alignment: Alignment.center,
          children: [
            Container(color: Colors.black87),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_library, color: Colors.grey, size: 28),
                SizedBox(height: 4),
                Text("Video Actual", style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        );
      } else {
        innerContent = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(existingUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
        );
      }
    } else {
      innerContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, color: Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1d2129),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2d323d)),
        ),
        child: innerContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fugasState = ref.watch(fugasProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        title: const Text('Actualizar Fuga (QR)'),
        backgroundColor: const Color(0xFF161a22),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(pendingFugaIdProvider.notifier).set(null);
          },
        ),
      ),
      body: fugasState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (fugas) {
          final f = fugas.where((f) => f.id == widget.fugaId).firstOrNull;
          if (f == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 64),
                  const SizedBox(height: 16),
                  Text("No se encontró la fuga con ID ${widget.fugaId}."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(pendingFugaIdProvider.notifier).set(null),
                    child: const Text("Ir a la App Principal"),
                  )
                ],
              ),
            );
          }

          _initForm(f);
          
          final catMap = AppConstants.relacionFugas[editFluido] ?? AppConstants.relacionFugas['Aire']!;
          final validCategories = catMap.keys.toList();
          if (!validCategories.contains(editCategoria)) {
            editCategoria = validCategories.first;
          }
          final props = catMap[editCategoria] ?? {"l_min": "0", "costo": 0.0};

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(16),
              child: Card(
                color: const Color(0xFF161a22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Máquina: ${f.idMaquina}", style: const TextStyle(color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Fluido"),
                          value: editFluido,
                          items: AppConstants.fluidos.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) {
                            setState(() {
                              editFluido = val!;
                              if (editFluido == 'Inspección (OK)') {
                                editEstado = 'Completada';
                              }
                              final newCatMap = AppConstants.relacionFugas[editFluido] ?? AppConstants.relacionFugas['Aire']!;
                              if (newCatMap.isNotEmpty && !newCatMap.keys.contains(editCategoria)) {
                                editCategoria = newCatMap.keys.first;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "ID Equipo / Máquina"),
                          initialValue: editIdMaquina,
                          onChanged: (val) => editIdMaquina = val,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Nombre Zona"),
                          initialValue: editZona,
                          onChanged: (val) => editZona = val,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Categoría"),
                          value: editCategoria,
                          items: validCategories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => editCategoria = val!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: ValueKey("lMin_${editFluido}_$editCategoria"),
                          decoration: const InputDecoration(labelText: "I/min"),
                          initialValue: "${props['l_min']}",
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Área"),
                          initialValue: editArea,
                          onChanged: (val) => editArea = val,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Severidad"),
                          value: editSeveridad,
                          items: ["Baja", "Media", "Alta"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => editSeveridad = val!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: ValueKey("costo_${editFluido}_$editCategoria"),
                          decoration: const InputDecoration(labelText: "Costo/Año (USD)"),
                          initialValue: "${props['costo']}",
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Instalación"),
                          value: editUbicacion,
                          items: ["Terrestre", "Aérea"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => editUbicacion = val!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Estado"),
                          value: editEstado,
                          items: editFluido == 'Inspección (OK)'
                              ? [const DropdownMenuItem(value: 'Completada', child: Text('Completada'))]
                              : ["En proceso de reparar", "Dañada", "Completada"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => editEstado = val!),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: "Comentarios Detección"),
                                initialValue: editComentarios,
                                maxLines: 3,
                                onChanged: (val) => editComentarios = val,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: "Comentarios Reparación"),
                                initialValue: editComentariosReparacion,
                                maxLines: 3,
                                onChanged: (val) => editComentariosReparacion = val,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildPhotoPicker("📷 Evidencia Detección", f.fotoDeteccion, editFotoDeteccionFile, () async {
                              final picker = ImagePicker();
                              await _handleMediaPick(context, picker, (file) => setState(() => editFotoDeteccionFile = file));
                            })),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPhotoPicker("📷 Evidencia Reparación", f.fotoReparacion, editFotoReparacionFile, () async {
                              final picker = ImagePicker();
                              await _handleMediaPick(context, picker, (file) => setState(() => editFotoReparacionFile = file));
                            })),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: isUploading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save),
                            label: Text(isUploading ? "Subiendo..." : "💾 Guardar Cambios"),
                            onPressed: isUploading ? null : () async {
                              setState(() => isUploading = true);

                              final lMinStr = props['l_min']?.toString() ?? "0";
                              double lMinVal = 0;
                              try {
                                if (lMinStr.contains('-')) {
                                  final p = lMinStr.split('-');
                                  lMinVal = (double.parse(p[0]) + double.parse(p[1])) / 2;
                                } else {
                                  lMinVal = double.parse(lMinStr);
                                }
                              } catch (_) {}

                              String? urlDeteccion = f.fotoDeteccion;
                              String? urlReparacion = f.fotoReparacion;

                              try {
                                if (editFotoDeteccionFile != null) {
                                  final bytes = await editFotoDeteccionFile!.readAsBytes();
                                  final ext = editFotoDeteccionFile!.name.split('.').last;
                                  urlDeteccion = await ref.read(supabaseServiceProvider).uploadEvidencePhoto(bytes, "det_${DateTime.now().millisecondsSinceEpoch}.$ext");
                                  if (urlDeteccion == null) throw Exception();
                                }
                                if (editFotoReparacionFile != null) {
                                  final bytes = await editFotoReparacionFile!.readAsBytes();
                                  final ext = editFotoReparacionFile!.name.split('.').last;
                                  urlReparacion = await ref.read(supabaseServiceProvider).uploadEvidencePhoto(bytes, "rep_${DateTime.now().millisecondsSinceEpoch}.$ext");
                                  if (urlReparacion == null) throw Exception();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("❌ Error subiendo foto."), backgroundColor: Colors.redAccent)
                                  );
                                }
                                setState(() => isUploading = false);
                                return;
                              }

                              String finalZona = editZona ?? f.zona;
                              if (editEstado == 'Completada' && f.estado != 'Completada') {
                                final partes = finalZona.split('-');
                                if (partes.isNotEmpty) {
                                  final df = DateFormat('dd/MM/yyyy');
                                  finalZona = "${partes[0].trim()} - ${df.format(DateTime.now())}";
                                }
                              }

                              final updated = f.copyWith(
                                tipoFuga: editFluido,
                                idMaquina: editIdMaquina,
                                zona: finalZona,
                                area: editArea,
                                severidad: editSeveridad,
                                categoria: editCategoria,
                                lMin: lMinVal,
                                costoAnual: (props['costo'] as num?)?.toDouble() ?? 0.0,
                                estado: editEstado,
                                ubicacion: editUbicacion,
                                comentarios: editComentarios,
                                comentariosReparacion: editComentariosReparacion,
                                fotoDeteccion: urlDeteccion,
                                fotoReparacion: urlReparacion,
                              );
                              
                              await ref.read(fugasProvider.notifier).updateFuga(updated);
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("✅ Registro actualizado exitosamente.")),
                                );
                                // Clear pending ID to return to MainScreen
                                ref.read(pendingFugaIdProvider.notifier).set(null);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
