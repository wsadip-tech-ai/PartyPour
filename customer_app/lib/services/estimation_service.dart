// lib/services/estimation_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estimation_rule.dart';

class EstimationService {
  final SupabaseClient _client;
  List<EstimationRule>? _cachedRules;

  EstimationService(this._client);

  Future<List<EstimationRule>> getRules() async {
    if (_cachedRules != null) return _cachedRules!;
    final data = await _client
        .from('estimation_rules')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    _cachedRules = data.map((json) => EstimationRule.fromJson(json)).toList();
    return _cachedRules!;
  }

  void clearCache() => _cachedRules = null;

  Future<Map<String, int>> estimateQuantities({
    required int totalPax,
    required int children,
    required int ladies,
    required String eventType,
    required List<String> selectedSlugs,
  }) async {
    final rules = await getRules();
    final result = <String, int>{};
    for (final rule in rules) {
      if (selectedSlugs.contains(rule.subcategorySlug)) {
        int estimated = rule.estimateBottles(
          totalPax: totalPax,
          children: children,
          eventType: eventType,
        );
        // Ladies boost: increase wine estimate by 30% of ladies ratio
        if (rule.subcategorySlug == 'wine' && ladies > 0) {
          final ladiesRatio = ladies / (totalPax - children).clamp(1, 9999);
          estimated = (estimated * (1 + ladiesRatio * 0.3)).ceil();
        }
        result[rule.subcategorySlug] = estimated;
      }
    }
    return result;
  }
}
