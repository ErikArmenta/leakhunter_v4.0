import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';

final authFluidsProvider = Provider<List<String>>((ref) {
  return AppConstants.fluidos.keys.toList();
});

class FluidFilterNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ref.read(authFluidsProvider);
  void updateFilters(List<String> newFilters) => state = newFilters;
}
final fluidFilterProvider = NotifierProvider<FluidFilterNotifier, List<String>>(() => FluidFilterNotifier());

class StatusFilterNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  void updateFilters(List<String> newFilters) => state = newFilters;
}
final statusFilterProvider = NotifierProvider<StatusFilterNotifier, List<String>>(() => StatusFilterNotifier());

class AreaFilterNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  void updateFilters(List<String> newFilters) => state = newFilters;
}
final areaFilterProvider = NotifierProvider<AreaFilterNotifier, List<String>>(() => AreaFilterNotifier());

class DateSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateSearch(String query) => state = query;
}
final dateSearchProvider = NotifierProvider<DateSearchNotifier, String>(() => DateSearchNotifier());
