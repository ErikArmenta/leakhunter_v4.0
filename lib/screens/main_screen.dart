import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/plant_provider.dart';
import '../widgets/filter_drawer.dart';
import 'map_screen.dart';
import 'management_screen.dart';
import 'report_screen.dart';
import 'admin_users_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Variables para arrastrar el panel
  Offset _panelPosition = const Offset(16, 30);
  bool _isDragging = false;
  bool _showPanel = true; // Estado para mostrar/ocultar TODO el panel (abierto por defecto)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plants = ref.watch(plantsProvider);
    final selectedPlant = ref.watch(selectedPlantProvider);
    
    // Responsive layout switch
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final screenSize = MediaQuery.of(context).size;
    
    final authState = ref.watch(authProvider);
    final String role = authState.role;
    final bool isInspector = role == 'Inspector';
    final bool isAdmin = role == 'Admin Principal';

    final List<Widget> dynamicPages = [
      const MapScreen(),
      const ManagementScreen(),
    ];
    if (!isInspector) {
      dynamicPages.add(const ReportScreen());
    }
    if (isAdmin) {
      dynamicPages.add(const AdminUsersScreen());
    }

    if (_selectedIndex >= dynamicPages.length) {
      _selectedIndex = dynamicPages.length - 1;
    }

    // Calcular top position dinámico basado en el índice seleccionado (solo para reset)
    double getDefaultTopPosition() {
      if (_selectedIndex == 0) return 30;
      if (_selectedIndex == 1) return 60;
      return 100;
    }

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: Text('🏭💧 ${selectedPlant?.name ?? 'Leak Hunter'}'),
        actions: [
          _buildPlantSelector(ref, plants, selectedPlant),
        ],
      ),
      drawer: isDesktop ? null : const FilterDrawer(),
      body: Stack(
        children: [
          // Fondo con transición suave
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_selectedIndex),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0d1117),
                    const Color(0xFF161a22),
                  ],
                ),
              ),
              child: dynamicPages[_selectedIndex],
            ),
          ),
          
          // Botón flotante para abrir el panel cuando está cerrado
          if (isDesktop && !_showPanel)
            Positioned(
              left: 16,
              top: _panelPosition.dy,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF161a22).withOpacity(0.95),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showPanel = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Menú',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Panel completo (visible cuando _showPanel es true)
          if (isDesktop && _showPanel)
            AnimatedPositioned(
              duration: _isDragging ? Duration.zero : const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              left: _panelPosition.dx,
              top: _panelPosition.dy,
              child: GestureDetector(
                onSecondaryTap: () {
                  setState(() {
                    _panelPosition = Offset(16, getDefaultTopPosition());
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Panel reubicado a posición predeterminada'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onPanUpdate: (details) {
                  setState(() {
                    _isDragging = true;
                    _panelPosition = Offset(
                      (_panelPosition.dx + details.delta.dx).clamp(0.0, screenSize.width - 400),
                      (_panelPosition.dy + details.delta.dy).clamp(0.0, screenSize.height - 650),
                    );
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _isDragging = false;
                  });
                },
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Material(
                      elevation: _isDragging ? 20 : 12,
                      borderRadius: BorderRadius.circular(24),
                      color: const Color(0xFF161a22).withOpacity(0.95),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        height: 620,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isDragging 
                                ? Colors.blueAccent.withOpacity(0.6) 
                                : Colors.blueAccent.withOpacity(0.3),
                            width: _isDragging ? 2 : 1,
                          ),
                          boxShadow: _isDragging ? [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Panel de navegación principal
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.blueAccent.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Logo
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                                    child: Image.asset(
                                      'assets/images/EA_2.png',
                                      height: 65,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.factory, size: 45, color: Colors.blue),
                                    ),
                                  ),
                                  // Plant Selector
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blueAccent.withOpacity(0.2),
                                      ),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 70,
                                        maxWidth: 90,
                                      ),
                                      child: _buildPlantSelector(ref, plants, selectedPlant),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: NavigationRail(
                                      selectedIndex: _selectedIndex,
                                      backgroundColor: Colors.transparent,
                                      onDestinationSelected: (int index) {
                                        final visiblePages = dynamicPages.length;
                                        if (index == visiblePages) {
                                          _showLogoutDialog();
                                          return;
                                        }
                                        setState(() {
                                          _selectedIndex = index;
                                        });
                                      },
                                      labelType: NavigationRailLabelType.all,
                                      selectedLabelTextStyle: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      unselectedLabelTextStyle: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                      destinations: [
                                        const NavigationRailDestination(
                                          icon: Icon(Icons.map_outlined, size: 24),
                                          selectedIcon: Icon(Icons.map, size: 24),
                                          label: Text('Mapa'),
                                        ),
                                        const NavigationRailDestination(
                                          icon: Icon(Icons.settings_outlined, size: 24),
                                          selectedIcon: Icon(Icons.settings, size: 24),
                                          label: Text('Gestión'),
                                        ),
                                        if (!isInspector)
                                          const NavigationRailDestination(
                                            icon: Icon(Icons.bar_chart_outlined, size: 24),
                                            selectedIcon: Icon(Icons.bar_chart, size: 24),
                                            label: Text('Reporte'),
                                          ),
                                        if (isAdmin)
                                          const NavigationRailDestination(
                                            icon: Icon(Icons.people_outline, size: 24),
                                            selectedIcon: Icon(Icons.people, size: 24),
                                            label: Text('Usuarios'),
                                          ),
                                        const NavigationRailDestination(
                                          icon: Icon(Icons.logout_outlined, size: 24),
                                          selectedIcon: Icon(Icons.logout, size: 24),
                                          label: Text('Salir'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón para ocultar panel
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showPanel = false;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.blueAccent.withOpacity(0.5),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.chevron_left,
                                              size: 16,
                                              color: Colors.blueAccent,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Ocultar',
                                              style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Indicador de versión
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      'v4.1',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Filter Drawer
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              child: SizedBox(
                                width: 280,
                                child: Column(
                                  children: [
                                    const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF2d323d)),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(24),
                                          bottomRight: Radius.circular(24),
                                        ),
                                        child: FilterDrawer(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          final visiblePages = dynamicPages.length;
          if (index == visiblePages) {
            _showLogoutDialog();
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        height: 55,
        elevation: 8,
        backgroundColor: const Color(0xFF161a22),
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.blueAccent.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined, size: 20),
            selectedIcon: Icon(Icons.map, size: 20),
            label: 'Mapa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 20),
            selectedIcon: Icon(Icons.settings, size: 20),
            label: 'Gestión',
          ),
          if (!isInspector)
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, size: 20),
              selectedIcon: Icon(Icons.bar_chart, size: 20),
              label: 'Reporte',
            ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.people_outline, size: 20),
              selectedIcon: Icon(Icons.people, size: 20),
              label: 'Usuarios',
            ),
          const NavigationDestination(
            icon: Icon(Icons.logout, size: 20),
            label: 'Salir',
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmación para logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1c2128),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2d323d)),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres salir?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              foregroundColor: Colors.redAccent,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSelector(WidgetRef ref, List<Plant> plants, Plant? selectedPlant) {
    return DropdownButton<Plant>(
      value: selectedPlant,
      dropdownColor: const Color(0xFF161a22),
      underline: const SizedBox(),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent, size: 18),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      isExpanded: true,
      onChanged: (Plant? newValue) {
        if (newValue != null) {
          ref.read(selectedPlantProvider.notifier).setPlant(newValue);
        }
      },
      items: plants.map<DropdownMenuItem<Plant>>((Plant plant) {
        return DropdownMenuItem<Plant>(
          value: plant,
          child: Text(
            plant.name,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}