import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fuga.dart';
import '../services/supabase_service.dart';
import 'filter_provider.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());

class FugasNotifier extends AsyncNotifier<List<Fuga>> {
  late SupabaseService _service;

  @override
  Future<List<Fuga>> build() async {
    _service = ref.watch(supabaseServiceProvider);
    return _loadFugas();
  }

  Future<List<Fuga>> _loadFugas() async {
    final data = await _service.getFugas();
    _updateFilterDefaults(data);
    return data;
  }

  Future<void> loadFugas() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadFugas());
  }

  void _updateFilterDefaults(List<Fuga> data) {
    final statuses = data.map((e) => e.estado).toSet().toList();
    final areas = data.map((e) => e.area).toSet().toList();

    ref.read(statusFilterProvider.notifier).updateFilters(statuses);
    ref.read(areaFilterProvider.notifier).updateFilters(areas);
  }

  Future<void> insertFuga(Fuga f) async {
    final result = await _service.insertFuga(f);
    if (result != null) {
      await loadFugas();
    }
  }

  Future<void> updateFuga(Fuga f) async {
    final result = await _service.updateFuga(f);
    if (result != null) {
      await loadFugas();
    }
  }

  Future<void> deleteFuga(int id) async {
    final success = await _service.deleteFuga(id);
    if (success) {
      await loadFugas();
    }
  }
}

final fugasProvider = AsyncNotifierProvider<FugasNotifier, List<Fuga>>(() {
  return FugasNotifier();
});

final filteredFugasProvider = Provider<List<Fuga>>((ref) {
  final fugasState = ref.watch(fugasProvider);
  
  if (fugasState is! AsyncData<List<Fuga>>) {
    return [];
  }
  
  final fugas = fugasState.value!;
  final fluidFilter = ref.watch(fluidFilterProvider);
  final statusFilter = ref.watch(statusFilterProvider);
  final areaFilter = ref.watch(areaFilterProvider);
  final dateSearch = ref.watch(dateSearchProvider).toLowerCase();

  return fugas.where((f) {
    final matchFluid = fluidFilter.contains(f.tipoFuga);
    final matchStatus = statusFilter.isEmpty || statusFilter.contains(f.estado);
    final matchArea = areaFilter.isEmpty || areaFilter.contains(f.area);
    final matchDate = dateSearch.isEmpty || f.zona.toLowerCase().contains(dateSearch);

    return matchFluid && matchStatus && matchArea && matchDate;
  }).toList();
});
