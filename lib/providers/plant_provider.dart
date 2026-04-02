import 'package:flutter_riverpod/flutter_riverpod.dart';

class Plant {
  final String id;
  final String name;
  final String location;

  Plant({required this.id, required this.name, required this.location});
}

final plantsProvider = Provider<List<Plant>>((ref) {
  return [
    Plant(id: 'P1', name: 'San Lorenzo 1', location: 'Cd. Juarez'),
    Plant(id: 'P2', name: 'Paso del norte', location: 'Cd. Juarez'),
    Plant(id: 'P3', name: 'Rivereño', location: 'Cd. Juarez'),
  ];
});

class SelectedPlantNotifier extends Notifier<Plant?> {
  @override
  Plant? build() {
    final plants = ref.watch(plantsProvider);
    return plants.isNotEmpty ? plants.first : null;
  }

  void setPlant(Plant plant) {
    state = plant;
  }
}

final selectedPlantProvider = NotifierProvider<SelectedPlantNotifier, Plant?>(() {
  return SelectedPlantNotifier();
});
