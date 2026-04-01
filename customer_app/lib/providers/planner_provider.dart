import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/planner_service.dart';
import '../models/product.dart';

final plannerServiceProvider = Provider<PlannerService>((ref) => PlannerService());

class PlannerState {
  final int guestCount;
  final String eventType;
  final List<PlannerSuggestion> suggestions;

  PlannerState({this.guestCount = 100, this.eventType = 'wedding', this.suggestions = const []});

  PlannerState copyWith({int? guestCount, String? eventType, List<PlannerSuggestion>? suggestions}) {
    return PlannerState(guestCount: guestCount ?? this.guestCount, eventType: eventType ?? this.eventType, suggestions: suggestions ?? this.suggestions);
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  final PlannerService _service;
  PlannerNotifier(this._service) : super(PlannerState());

  void setGuestCount(int count) => state = state.copyWith(guestCount: count);
  void setEventType(String type) => state = state.copyWith(eventType: type);

  void calculate(List<Product> products) {
    final suggestions = _service.estimateBeverages(guestCount: state.guestCount, eventType: state.eventType, availableProducts: products);
    state = state.copyWith(suggestions: suggestions);
  }
}

final plannerProvider = StateNotifierProvider<PlannerNotifier, PlannerState>((ref) => PlannerNotifier(ref.watch(plannerServiceProvider)));
