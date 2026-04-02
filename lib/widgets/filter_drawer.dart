import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/filter_provider.dart';
import '../providers/fugas_provider.dart';

class FilterDrawer extends ConsumerWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final allFluids = ref.watch(authFluidsProvider);
    final selectedFluids = ref.watch(fluidFilterProvider);
    
    final fugasState = ref.watch(fugasProvider);
    List<String> allStatuses = [];
    List<String> allAreas = [];
    
    if (fugasState is AsyncData) {
      allStatuses = fugasState.value!.map((e) => e.estado).toSet().toList();
      allAreas = fugasState.value!.map((e) => e.area).toSet().toList();
    }
    
    final selectedStatuses = ref.watch(statusFilterProvider);
    final selectedAreas = ref.watch(areaFilterProvider);
    final dateSearch = ref.watch(dateSearchProvider);

    return Drawer(
      backgroundColor: const Color(0xFF161a22),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo placeholder
            Container(
              height: 100,
              child: Center(
                child: Image.asset(
                  'assets/images/fabrica.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.factory, size: 50, color: Color(0xFF5271ff)),
                ),
              ),
            ),
            const Text(
              "Leak Hunter",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Divider(color: Color(0xFF2d323d)),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionTitle("Filtros Globales"),
                  
                  // Text Search for Area/Dates
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Buscar Fecha (ej: 2026)",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) {
                      ref.read(dateSearchProvider.notifier).updateSearch(val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // MultiSelect "Monitorear:" fluids
                  _buildExpansionFilter(
                    title: "Monitorear Fluidos",
                    options: allFluids,
                    selected: selectedFluids,
                    onChanged: (val, isChecked) {
                      final newSet = List<String>.from(selectedFluids);
                      if (isChecked) newSet.add(val);
                      else newSet.remove(val);
                      ref.read(fluidFilterProvider.notifier).updateFilters(newSet);
                    },
                  ),

                  // MultiSelect "Estado de Fuga:"
                  if (allStatuses.isNotEmpty)
                    _buildExpansionFilter(
                      title: "Estado de Fuga",
                      options: allStatuses,
                      selected: selectedStatuses,
                      onChanged: (val, isChecked) {
                        final newSet = List<String>.from(selectedStatuses);
                        if (isChecked) newSet.add(val);
                        else newSet.remove(val);
                        ref.read(statusFilterProvider.notifier).updateFilters(newSet);
                      },
                    ),

                  // MultiSelect "Área de Planta:"
                  if (allAreas.isNotEmpty)
                    _buildExpansionFilter(
                      title: "Área de Planta",
                      options: allAreas,
                      selected: selectedAreas,
                      onChanged: (val, isChecked) {
                        final newSet = List<String>.from(selectedAreas);
                        if (isChecked) newSet.add(val);
                        else newSet.remove(val);
                        ref.read(areaFilterProvider.notifier).updateFilters(newSet);
                      },
                    ),
                  
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28A745).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF28A745)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_done, color: Color(0xFF28A745)),
                        SizedBox(width: 8),
                        Text("Conexión: Cloud Sync", style: TextStyle(color: Color(0xFF28A745))),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      // Reload Data
                      ref.read(fugasProvider.notifier).loadFugas();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Recargar Datos (Borrar Caché)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2d323d),
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer Filter
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0e1117),
              child: const Column(
                children: [
                  Text("Developed by:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Master Engineer Erik Armenta", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5271ff))),
                  Text("Innovating Digital Twins for Industrial Excellence", 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildExpansionFilter({
    required String title,
    required List<String> options,
    required List<String> selected,
    required Function(String, bool) onChanged,
  }) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      initiallyExpanded: false,
      textColor: const Color(0xFF5271ff),
      iconColor: const Color(0xFF5271ff),
      children: options.map((option) {
        return CheckboxListTile(
          title: Text(option, style: const TextStyle(fontSize: 13)),
          value: selected.contains(option),
          onChanged: (bool? value) {
            if (value != null) {
              onChanged(option, value);
            }
          },
          dense: true,
          activeColor: const Color(0xFF5271ff),
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}
