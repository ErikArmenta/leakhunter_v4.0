import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../providers/fugas_provider.dart';
import '../providers/auth_provider.dart';
import '../config/constants.dart';
import '../models/fuga.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ManagementScreen extends ConsumerStatefulWidget {
  const ManagementScreen({super.key});

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen> {
  final double originalWidth = 25600 / 256 / 32; // 3.125
  final double originalHeight = 16715 / 256 / 32; // 2.0385
  
  // Dimensiones del PlanoHanon25K.png (Nuevo Mapa)
  final double ancho_real = 25600.0;
  final double alto_real  = 16715.0;

  // Form State
  String _selectedFluido = AppConstants.fluidos.keys.first;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaTermino = DateTime.now();
  String _selectedCategoria = '';
  String _idEquipo = '';
  String _areaPlanta = '';
  String _severidad = 'Media';
  String _ubicacion = 'Terrestre';
  String _estado = 'En proceso de reparar';
  String _comentarios = '';
  
  // Custom Map Drawing State
  LatLng? _point1;
  LatLng? _point2;

  // Re-location State
  bool _modoReubicacion = false;
  Fuga? _fugaToMove;

  // Photo Evidence State
  XFile? _fotoDeteccionFile;
  XFile? _fotoReparacionFile;
  bool _isUploading = false;

  // Panel visibility
  bool _isPanelVisible = true;

  // Pagination
  int _currentPage = 0;
  static const int _pageSize = 20;

  final MapController _mapController = MapController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _updateCategoriaBaseOnFluido();
    _focusNode.requestFocus();
    
    // ✅ Registrar handler global de teclado para ESC
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    // ✅ Eliminar handler global
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _focusNode.dispose();
    super.dispose();
  }

  // ✅ Handler global para tecla ESC
  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && 
        (event.logicalKey == LogicalKeyboardKey.escape ||
         event.physicalKey == PhysicalKeyboardKey.escape)) {
      
      if (_point1 != null || _point2 != null) {
        setState(() {
          _point1 = null;
          _point2 = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Selección cancelada"),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true; // Evento manejado
    }
    return false; // Dejar pasar el evento
  }

  void _updateCategoriaBaseOnFluido() {
    final catMap = AppConstants.relacionFugas[_selectedFluido] ?? AppConstants.relacionFugas['Aire']!;
    if (catMap.isNotEmpty) {
      _selectedCategoria = catMap.keys.first;
    } else {
      _selectedCategoria = '';
    }
  }

  LatLng storedToMap(double x_stored, double y_stored) {
    // Replicar exactamente el factor de Streamlit
    final factor_x = ancho_real / 1200.0;
    final factor_y = alto_real / (1200.0 * (alto_real / ancho_real));

    // Convertir a píxeles del plano real (igual que Streamlit)
    final px = x_stored * factor_x;
    final py = alto_real - (y_stored * factor_y); // Streamlit invierte Y

    // Normalizar al espacio 0..1 y proyectar al mapa de tiles nuevo
    final map_x =  (px / ancho_real) * originalWidth;
    final map_y = -((alto_real - py) / alto_real) * originalHeight;

    return LatLng(map_y, map_x);
  }

  void mapToStored(LatLng p1, LatLng p2, Map<String, double> result) {
    double convertMapToX(double map_x) {
      double px = (map_x / originalWidth) * ancho_real;
      double factor_x = ancho_real / 1200.0;
      return px / factor_x;
    }
    
    double convertMapToY(double map_y) {
      double py = alto_real + (map_y / originalHeight) * alto_real;
      double factor_y = alto_real / (1200.0 * (alto_real / ancho_real));
      return (alto_real - py) / factor_y;
    }

    final xx1 = convertMapToX(p1.longitude);
    final yy1 = convertMapToY(p1.latitude);
    
    final xx2 = convertMapToX(p2.longitude);
    final yy2 = convertMapToY(p2.latitude);

    result['x1'] = xx1 < xx2 ? xx1 : xx2;
    result['x2'] = xx1 > xx2 ? xx1 : xx2;
    result['y1'] = yy1 < yy2 ? yy1 : yy2;
    result['y2'] = yy1 > yy2 ? yy1 : yy2;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.role == 'Admin Principal';

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.physicalKey.debugName == 'Escape' || 
              event.logicalKey.debugName == 'Escape') {
            if (_point1 != null || _point2 != null) {
              setState(() {
                _point1 = null;
                _point2 = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Selección cancelada"),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background Map
            SizedBox.expand(
              child: _buildDrawingMap(),
            ),
            // Toggle button for panel
            Positioned(
              top: 16,
              right: _isPanelVisible ? (MediaQuery.of(context).size.width >= 800 ? 520 : MediaQuery.of(context).size.width * 0.9 + 20) : 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _isPanelVisible = !_isPanelVisible),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161a22).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2d323d)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPanelVisible ? Icons.chevron_right : Icons.chevron_left,
                          color: Colors.white70,
                          size: 20,
                        ),
                        if (!_isPanelVisible) ...[
                          const SizedBox(width: 4),
                          const Text("Panel", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Foreground Floating Panel
            if (_isPanelVisible)
              Positioned(
                top: 16,
                right: 16,
                bottom: 16,
                width: MediaQuery.of(context).size.width >= 800 ? 500 : MediaQuery.of(context).size.width * 0.9,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF161a22).withOpacity(0.95),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isAdmin) ...[
                          SwitchListTile(
                            title: const Text("📍 Modo Reubicar Fugas", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: const Text("Selecciona una fuga, luego haz clic en su nueva ubicación real.", style: TextStyle(fontSize: 11, color: Colors.white70)),
                            value: _modoReubicacion,
                            activeColor: Colors.orangeAccent,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setState(() {
                                _modoReubicacion = val;
                                _fugaToMove = null;
                                _point1 = null;
                                _point2 = null;
                              });
                            },
                          ),
                          if (_fugaToMove != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orangeAccent)),
                              child: Row(
                                children: [
                                  const Icon(Icons.touch_app, color: Colors.orangeAccent),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("Fuga ${_fugaToMove!.idMaquina} seleccionada. ¡Haz clic en el mapa para soltarla!", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                              ),
                            ),
                          const Divider(color: Colors.white24, height: 16),
                        ],
                        const Text("Registro de Fuga", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Selecciona 2 puntos en el mapa maestro de fondo.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        _buildRegistrationForm(),
                        const SizedBox(height: 30),
                        const Text("📋 Historial de Gestión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _buildHistoryGrid(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Check if a point falls inside a fuga's bounding rectangle (in map coords)
  bool _pointInsideFuga(LatLng point, Fuga f) {
    final p1 = storedToMap(f.x1, f.y1);
    final p2 = storedToMap(f.x2, f.y2);
    final minLat = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
    final maxLat = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
    final minLng = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
    final maxLng = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;
    return point.latitude >= minLat && point.latitude <= maxLat &&
           point.longitude >= minLng && point.longitude <= maxLng;
  }

  void _showOverlappingFugas(LatLng point, List<Fuga> allFugas) {
    final hits = allFugas.where((f) => _pointInsideFuga(point, f)).toList();
    if (hits.isEmpty) return;
    
    // Si estamos en modo reubicacion y encontramos hits, seleccionamos el primero al hacer click derecho/long press
    if (_modoReubicacion) {
      setState(() {
        _fugaToMove = hits.first;
      });
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF161a22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("📍 ${hits.length} fuga(s) en esta zona",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF2d323d)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: hits.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF2d323d), height: 1),
                  itemBuilder: (context, i) {
                    final f = hits[i];
                    final fluidInfo = AppConstants.fluidos[f.tipoFuga] ?? {"emoji": "⚠️", "marker": Colors.red};
                    final emoji = fluidInfo['emoji'] as String;
                    final color = AppConstants.getStatusColor(f.estado, f.tipoFuga);
                    return ListTile(
                      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
                      title: Text("${f.idMaquina} — ${f.area}", style: const TextStyle(fontSize: 13)),
                      subtitle: Text("${f.tipoFuga} | ${f.severidad} | ${f.estado}",
                        style: TextStyle(fontSize: 11, color: color)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: color, size: 12),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDeleteFuga(f);
                            },
                          ),
                        ],
                      ),
                      dense: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showEditDialog(f);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingMap() {
    final fugas = ref.watch(filteredFugasProvider);
    return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          crs: const CrsSimple(),
          initialCenter: LatLng(-originalHeight / 2, originalWidth / 2),
          initialZoom: 3.5,
          minZoom: 2.5,
          maxZoom: 7,
          onTap: (tapPosition, point) {
            FocusScope.of(context).requestFocus(_focusNode);
            
            if (_modoReubicacion) {
              if (_fugaToMove != null) {
                // Reubicar
                _moveFugaToNewCenter(_fugaToMove!, point);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Primero selecciona una fuga (clic o click derecho) para reubicarla.")));
              }
              return;
            }

            setState(() {
              if (_point1 == null || (_point1 != null && _point2 != null)) {
                _point1 = point;
                _point2 = null;
              } else {
                _point2 = point;
              }
            });
          },
          onLongPress: (tapPosition, point) {
            _showOverlappingFugas(point, fugas);
          },
          onSecondaryTap: (tapPosition, point) {
            _showOverlappingFugas(point, fugas);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'assets/tiles/{z}/{x}/{y}.png',
            tileProvider: AssetTileProvider(),
          ),
          // Historical records layer (polygons)
          PolygonLayer(
            polygons: fugas.map((f) {
              final p1 = storedToMap(f.x1, f.y1);
              final p2 = storedToMap(f.x2, f.y2);
              final color = AppConstants.fluidos[f.tipoFuga]?['color'] ?? Colors.grey;
              return Polygon(
                points: [
                  LatLng(p1.latitude, p1.longitude),
                  LatLng(p1.latitude, p2.longitude),
                  LatLng(p2.latitude, p2.longitude),
                  LatLng(p2.latitude, p1.longitude),
                ],
                color: (color as Color).withOpacity(0.3),
                borderColor: color,
                borderStrokeWidth: 2,
              );
            }).toList(),
          ),
          // Hover tooltip markers at center of each historical polygon
          MarkerLayer(
            markers: fugas.map((f) {
              final cx = (f.x1 + f.x2) / 2;
              final cy = (f.y1 + f.y2) / 2;
              final center = storedToMap(cx, cy);
              final fluidInfo = AppConstants.fluidos[f.tipoFuga] ?? {"emoji": "⚠️", "marker": Colors.red, "color": Colors.grey};
              final emoji = fluidInfo['emoji'] as String;
              final markerColor = fluidInfo['marker'] as Color;
              final statusColor = AppConstants.getStatusColor(f.estado, f.tipoFuga);

              return Marker(
                point: center,
                width: 24,
                height: 24,
                child: Tooltip(
                  richMessage: TextSpan(
                    text: "$emoji ${f.area}\n🆔 ${f.idMaquina}\n${f.tipoFuga} | ${f.severidad}\nEstado: ${f.estado}${f.comentarios.isNotEmpty ? '\n💬 ${f.comentarios.length > 40 ? '${f.comentarios.substring(0, 40)}...' : f.comentarios}' : ''}",
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1d2129),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: markerColor, width: 4)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // User drawing layer
          if (_point1 != null) ...[
            MarkerLayer(
              markers: [
                Marker(point: _point1!, child: const Icon(Icons.location_pin, color: Colors.blue)),
                if (_point2 != null)
                  Marker(point: _point2!, child: const Icon(Icons.location_pin, color: Colors.blue)),
              ],
            ),
            if (_point2 != null)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: [
                      LatLng(_point1!.latitude, _point1!.longitude),
                      LatLng(_point1!.latitude, _point2!.longitude),
                      LatLng(_point2!.latitude, _point2!.longitude),
                      LatLng(_point2!.latitude, _point1!.longitude),
                    ],
                    color: Colors.blue.withOpacity(0.4),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  )
                ],
              )
          ]
        ],
      );
  }

Widget _buildRegistrationForm() {
  final catMap = AppConstants.relacionFugas[_selectedFluido] ?? AppConstants.relacionFugas['Aire']!;
  final validCategories = catMap.keys.toList();
  if (!validCategories.contains(_selectedCategoria)) {
    _selectedCategoria = validCategories.first;
  }
  
  final df = DateFormat('dd/MM/yyyy');

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF161a22),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF2d323d)),
    ),
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFormCol1(catMap, validCategories, df)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFormCol2(catMap)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFormCol3(catMap)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildFormCol1(catMap, validCategories, df),
                  const SizedBox(height: 12),
                  _buildFormCol2(catMap),
                  const SizedBox(height: 12),
                  _buildFormCol3(catMap),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Comentarios / Observaciones'),
          maxLines: 3,
          onChanged: (val) => _comentarios = val,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPhotoPicker("📷 Evidencia Detección", null, _fotoDeteccionFile, () async {
              final picker = ImagePicker();
              final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (file != null) setState(() => _fotoDeteccionFile = file);
            })),
            const SizedBox(width: 16),
            Expanded(child: _buildPhotoPicker("📷 Evidencia Reparación", null, _fotoReparacionFile, () async {
              final picker = ImagePicker();
              final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (file != null) setState(() => _fotoReparacionFile = file);
            })),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_point1 != null && _point2 != null && !_isUploading) ? _submitFuga : null,
                icon: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isUploading ? "Subiendo fotos..." : "🚰📝 Registrar fuga"),
              ),
            ),
            if (_point1 != null || _point2 != null) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _point1 = null;
                    _point2 = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Selección cancelada"),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text("Cancelar"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

Widget _buildFormCol1(Map<String, dynamic> catMap, List<String> validCategories, DateFormat df) {
  return Column(
    children: [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Fluido'),
        value: _selectedFluido,
        items: AppConstants.fluidos.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() {
            _selectedFluido = val!;
            _updateCategoriaBaseOnFluido();
            if (_selectedFluido == 'Inspección (OK)') _estado = 'Completada';
          });
        },
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text("Fecha de Inicio"),
        subtitle: Text(df.format(_fechaInicio)),
        trailing: const Icon(Icons.calendar_month),
        onTap: () async {
          final dt = await showDatePicker(
            context: context,
            initialDate: _fechaInicio,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (dt != null) setState(() => _fechaInicio = dt);
        },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text("Fecha Estimada Término"),
        subtitle: Text(df.format(_fechaTermino)),
        trailing: const Icon(Icons.calendar_month),
        onTap: () async {
          final dt = await showDatePicker(
            context: context,
            initialDate: _fechaTermino,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (dt != null) setState(() => _fechaTermino = dt);
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Categoría Crítica'),
        value: _selectedCategoria,
        items: validCategories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() {
            _selectedCategoria = val!;
          });
        },
      ),
    ],
  );
}

Widget _buildFormCol2(Map<String, dynamic> catMap) {
  // Recalcular props cada vez que se construye
  final props = catMap[_selectedCategoria] ?? {"l_min": "0", "costo": 0.0};
  
  // ✅ Crear controladores con los valores actuales
  final idEquipoController = TextEditingController(text: _idEquipo);
  final areaPlantaController = TextEditingController(text: _areaPlanta);
  final lMinController = TextEditingController(text: "${props['l_min']}");
  
  // ✅ Sincronizar cambios
  idEquipoController.addListener(() => _idEquipo = idEquipoController.text);
  areaPlantaController.addListener(() => _areaPlanta = areaPlantaController.text);
  
  return Column(
    children: [
      TextFormField(
        controller: idEquipoController,
        decoration: const InputDecoration(labelText: 'ID Equipo / Máquina'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: areaPlantaController,
        decoration: const InputDecoration(labelText: 'Área Planta'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: lMinController,
        decoration: const InputDecoration(labelText: 'I/min (Estimación)'),
        readOnly: true,
      ),
    ],
  );
}

Widget _buildFormCol3(Map<String, dynamic> catMap) {
  // Recalcular props cada vez que se construye
  final props = catMap[_selectedCategoria] ?? {"l_min": "0", "costo": 0.0};

  // ✅ Crear controladores con los valores actuales
  final costoController = TextEditingController(text: "${props['costo']}");
  final severidadController = TextEditingController(text: _severidad);
  final ubicacionController = TextEditingController(text: _ubicacion);
  final estadoController = TextEditingController(text: _estado);

  return Column(
    children: [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Severidad Visual'),
        value: _severidad,
        items: ["Baja", "Media", "Alta"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() {
            _severidad = val!;
            severidadController.text = val!;
          });
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: costoController,
        decoration: const InputDecoration(labelText: 'Costo por año (USD)'),
        readOnly: true,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Tipo de Instalación'),
        value: _ubicacion,
        items: ["Terrestre", "Aérea"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() {
            _ubicacion = val!;
            ubicacionController.text = val!;
          });
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Estado Inicial'),
        value: _estado,
        items: _selectedFluido == 'Inspección (OK)' 
          ? [const DropdownMenuItem(value: 'Completada', child: Text('Completada'))]
          : ["En proceso de reparar", "Dañada", "Completada"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() {
            _estado = val!;
            estadoController.text = val!;
          });
        },
      ),
    ],
  );
}

  Widget _buildPhotoPicker(String label, String? existingUrl, XFile? selectedFile, VoidCallback onPick) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1d2129),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2d323d)),
        ),
        child: selectedFile != null
            ? const Center(child: Text("✅ Foto lista para subir", style: TextStyle(color: Colors.green)))
            : existingUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(existingUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Future<void> _submitFuga() async {
    if (_point1 == null || _point2 == null) return;
    
    setState(() => _isUploading = true);
    
    final df = DateFormat('dd/MM/yyyy');
    final String zona = "${df.format(_fechaInicio)} - ${df.format(_fechaTermino)}";

    final bounds = <String, double>{};
    mapToStored(_point1!, _point2!, bounds);

    final catProps = AppConstants.relacionFugas[_selectedFluido]?[_selectedCategoria];
    final lMinStr = catProps?['l_min']?.toString() ?? "0";
    double lMinVal = 0;
    try {
      if (lMinStr.contains('-')) {
        final p = lMinStr.split('-');
        lMinVal = (double.parse(p[0]) + double.parse(p[1])) / 2;
      } else {
        lMinVal = double.parse(lMinStr);
      }
      } catch (_) {}

    String? urlDeteccion;
    String? urlReparacion;

    try {
      if (_fotoDeteccionFile != null) {
        final bytes = await _fotoDeteccionFile!.readAsBytes();
        urlDeteccion = await ref.read(supabaseServiceProvider).uploadEvidencePhoto(bytes, "det_${DateTime.now().millisecondsSinceEpoch}.jpg");
        if (urlDeteccion == null) throw Exception("Upload failed");
      }
      if (_fotoReparacionFile != null) {
        final bytes = await _fotoReparacionFile!.readAsBytes();
        urlReparacion = await ref.read(supabaseServiceProvider).uploadEvidencePhoto(bytes, "rep_${DateTime.now().millisecondsSinceEpoch}.jpg");
        if (urlReparacion == null) throw Exception("Upload failed");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Error al subir foto. En Supabase ve a Storage -> Policies y crea una política INSERT para el bucket 'evidencia_fugas'."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          )
        );
      }
      setState(() => _isUploading = false);
      return; // Stop saving
    }

    final newFuga = Fuga(
      x1: bounds['x1']!,
      y1: bounds['y1']!,
      x2: bounds['x2']!,
      y2: bounds['y2']!,
      zona: zona,
      tipoFuga: _selectedFluido,
      area: _areaPlanta.isEmpty ? "N/A" : _areaPlanta,
      ubicacion: _ubicacion,
      idMaquina: _idEquipo.isEmpty ? "N/A" : _idEquipo,
      severidad: _severidad,
      categoria: _selectedCategoria,
      lMin: lMinVal,
      costoAnual: catProps?['costo'] ?? 0.0,
      estado: _estado,
      comentarios: _comentarios,
      fotoDeteccion: urlDeteccion,
      fotoReparacion: urlReparacion,
    );
    
    await ref.read(fugasProvider.notifier).insertFuga(newFuga);
    setState(() {
      _isUploading = false;
      _point1 = null;
      _point2 = null;
      _fotoDeteccionFile = null;
      _fotoReparacionFile = null;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Fuga registrada exitosamente.")));
    });
  }

  Widget _buildHistoryGrid() {
    final fugas = ref.watch(filteredFugasProvider);
    // Showing latest first
    final reversedList = fugas.reversed.toList();

    // Pagination
    final totalPages = (reversedList.length / _pageSize).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, reversedList.length);
    final pageItems = reversedList.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Pagination controls
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text(
                  "Página ${_currentPage + 1} de $totalPages",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
        Text(
          "${reversedList.length} fugas totales",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 200,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: pageItems.length,
          itemBuilder: (context, index) {
            final f = pageItems[index];
            final bdColor = AppConstants.getStatusColor(f.estado, f.tipoFuga);

            return Card(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: bdColor, width: 4)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(f.zona, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        Icon(Icons.circle, color: bdColor, size: 16),
                      ],
                    ),
                    Text("🆔 ${f.idMaquina} | 📍 ${f.area}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text("Estado: ${f.estado}"),
                    if (f.comentarios.isNotEmpty)
                      Text("💬 ${f.comentarios.length > 30 ? '${f.comentarios.substring(0, 30)}...' : f.comentarios}",
                        style: const TextStyle(fontSize: 11, color: Colors.white54, fontStyle: FontStyle.italic)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(f)),
                        IconButton(icon: const Icon(Icons.qr_code, color: Colors.white70), onPressed: () => _showQRDialog(f)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteFuga(f)),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
        // Bottom pagination
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text(
                  "Página ${_currentPage + 1} de $totalPages",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==================== DELETE CONFIRMATION ====================
  void _confirmDeleteFuga(Fuga f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161a22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text("⚠️ Confirmar Eliminación", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¿Estás seguro de eliminar esta fuga?", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text("ID: ${f.id} | Máquina: ${f.idMaquina}", style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Text("Área: ${f.area}", style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 12),
            const Text("Esta acción no se puede deshacer.", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(fugasProvider.notifier).deleteFuga(f.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("🗑️ Fuga ${f.id} eliminada.")),
              );
            },
            child: const Text("Sí, Eliminar"),
          ),
        ],
      ),
    );
  }

  // ==================== QR CODE DIALOG ====================
  void _showQRDialog(Fuga f) {
    // Same logic as Python: qrserver API with fuga_id
    final targetLink = "https://gemelodigital2d.streamlit.app/?fuga_id=${f.id}";
    final qrImgUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$targetLink";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF161a22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🖨️ Etiqueta QR Inteligente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("ID de Fuga: ${f.id} | Máquina: ${f.idMaquina}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1d2129),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2d323d)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.lightBlueAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text("Imprime o escanea este código para acceder directamente a la ficha técnica de esta fuga.",
                        style: TextStyle(color: Colors.lightBlueAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  qrImgUrl,
                  width: 200,
                  height: 200,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (ctx, error, stack) {
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: Text("Error cargando QR", style: TextStyle(color: Colors.red))),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1d2129),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  targetLink,
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== EDIT DIALOG ====================
  void _showEditDialog(Fuga f) {
    // Pre-fill with current data
    String editFluido = f.tipoFuga;
    String editCategoria = f.categoria;
    String editZona = f.zona;
    String editArea = f.area;
    String editSeveridad = f.severidad;
    String editUbicacion = f.ubicacion;
    String editEstado = f.estado;
    String editComentarios = f.comentarios;
    
    // Photo Evidence State for editing
    XFile? editFotoDeteccionFile;
    XFile? editFotoReparacionFile;
    bool isUploading = false;

    // Ensure valid values
    final validSeverities = ["Baja", "Media", "Alta"];
    if (!validSeverities.contains(editSeveridad)) editSeveridad = "Media";
    final validUbicaciones = ["Terrestre", "Aérea"];
    if (!validUbicaciones.contains(editUbicacion)) editUbicacion = "Terrestre";
    final validEstados = ["En proceso de reparar", "Dañada", "Completada"];
    if (!validEstados.contains(editEstado)) editEstado = "Dañada";

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final catMap = AppConstants.relacionFugas[editFluido] ?? AppConstants.relacionFugas['Aire']!;
            final validCategories = catMap.keys.toList();
            if (!validCategories.contains(editCategoria)) {
              editCategoria = validCategories.first;
            }
            final props = catMap[editCategoria] ?? {"l_min": "0", "costo": 0.0};

            return Dialog(
              backgroundColor: const Color(0xFF161a22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text("✏️ Editar Registro #${f.id}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text("Máquina: ${f.idMaquina}", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 16),
                      // Two-column layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column 1
                          Expanded(
                            child: Column(
                              children: [
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
                                  onChanged: (val) {
                                    setDialogState(() => editCategoria = val!);
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: const InputDecoration(labelText: "I/min"),
                                  initialValue: "${props['l_min']}",
                                  readOnly: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Column 2
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: const InputDecoration(labelText: "Área"),
                                  initialValue: editArea,
                                  onChanged: (val) => editArea = val,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: "Severidad"),
                                  value: editSeveridad,
                                  items: validSeverities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (val) => setDialogState(() => editSeveridad = val!),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: const InputDecoration(labelText: "Costo/Año (USD)"),
                                  initialValue: "${props['costo']}",
                                  readOnly: true,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: "Instalación"),
                                  value: editUbicacion,
                                  items: validUbicaciones.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (val) => setDialogState(() => editUbicacion = val!),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: "Estado"),
                                  value: editEstado,
                                  items: validEstados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (val) => setDialogState(() => editEstado = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Comentarios / Observaciones"),
                        initialValue: editComentarios,
                        maxLines: 3,
                        onChanged: (val) => editComentarios = val,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildPhotoPicker("📷 Evidencia Detección", f.fotoDeteccion, editFotoDeteccionFile, () async {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (file != null) setDialogState(() => editFotoDeteccionFile = file);
                          })),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPhotoPicker("📷 Evidencia Reparación", f.fotoReparacion, editFotoReparacionFile, () async {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (file != null) setDialogState(() => editFotoReparacionFile = file);
                          })),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancelar"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: isUploading 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save),
                            label: Text(isUploading ? "Subiendo..." : "💾 Guardar Cambios"),
                            onPressed: isUploading ? null : () async {
                              setDialogState(() => isUploading = true);

                              // Calculate l_min from props
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
                                  urlDeteccion = await ref.read(supabaseServiceProvider).uploadEvidencePhoto(bytes, "det_${DateTime.now().millisecondsSinceEpoch}.jpg");
                                  if (urlDeteccion == null) throw Exception();
                                }
                                if (editFotoReparacionFile != null) {
                                  final bytes = await editFotoReparacionFile!.readAsBytes();
                                  urlReparacion = await ref.read(supabaseServiceProvider).uploadEvidencePhoto(bytes, "rep_${DateTime.now().millisecondsSinceEpoch}.jpg");
                                  if (urlReparacion == null) throw Exception();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("❌ Error subiendo foto. Falta política INSERT en Supabase Storage."),
                                      backgroundColor: Colors.redAccent,
                                    )
                                  );
                                }
                                setDialogState(() => isUploading = false);
                                return; // Stop update
                              }

                              final updated = f.copyWith(
                                zona: editZona,
                                area: editArea,
                                severidad: editSeveridad,
                                categoria: editCategoria,
                                lMin: lMinVal,
                                costoAnual: (props['costo'] as num?)?.toDouble() ?? 0.0,
                                estado: editEstado,
                                ubicacion: editUbicacion,
                                comentarios: editComentarios,
                                fotoDeteccion: urlDeteccion,
                                fotoReparacion: urlReparacion,
                              );
                              
                              await ref.read(fugasProvider.notifier).updateFuga(updated);
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("✅ Registro actualizado exitosamente.")),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _moveFugaToNewCenter(Fuga f, LatLng center) {
    final double ancho_stored = (f.x2 - f.x1).abs();
    final double alto_stored = (f.y2 - f.y1).abs();

    double factor_x = ancho_real / 1200.0;
    double factor_y = alto_real / (1200.0 * (alto_real / ancho_real));

    double convertMapToX(double map_x) {
      double px = (map_x / originalWidth) * ancho_real;
      return px / factor_x;
    }

    double convertMapToY(double map_y) {
      double py = alto_real + (map_y / originalHeight) * alto_real;
      return (alto_real - py) / factor_y;
    }

    final double cx_stored = convertMapToX(center.longitude);
    final double cy_stored = convertMapToY(center.latitude);

    final double new_x1 = cx_stored - (ancho_stored / 2);
    final double new_x2 = cx_stored + (ancho_stored / 2);
    final double new_y1 = cy_stored - (alto_stored / 2);
    final double new_y2 = cy_stored + (alto_stored / 2);

    final Fuga updatedFuga = f.copyWith(
      x1: new_x1 < new_x2 ? new_x1 : new_x2,
      x2: new_x1 > new_x2 ? new_x1 : new_x2,
      y1: new_y1 < new_y2 ? new_y1 : new_y2,
      y2: new_y1 > new_y2 ? new_y1 : new_y2,
    );

    ref.read(fugasProvider.notifier).updateFuga(updatedFuga).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Fuga ${f.idMaquina} reubicada con éxito."), backgroundColor: Colors.green));
        setState(() {
          _fugaToMove = null;
        });
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error al reubicar: $e", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    });
  }
}