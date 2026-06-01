import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match_event.dart';

/// Récupère l'agenda, les résultats et (si clé premium) les scores en direct
/// via TheSportsDB. Données factuelles (équipes, horaires, scores) = légal.
///
/// - Gratuit : matchs à venir + résultats terminés (pas de live en cours).
/// - Premium (~9 $/mois) : ajoute les scores en direct rafraîchis ~2 min,
///   via l'API v2 (clé envoyée dans l'en-tête X-API-KEY).
class SportsService {
  static const String _freeKey = '123'; // clé de test gratuite actuelle
  static const String _v1 = 'https://www.thesportsdb.com/api/v1/json';
  static const String _v2 = 'https://www.thesportsdb.com/api/v2/json';

  static const Map<String, String> leagues = {
    'Premier League': '4328',
    'La Liga': '4335',
    'Serie A': '4332',
    'Bundesliga': '4331',
    'Ligue 1': '4334',
    'Champions League': '4480',
  };

  /// Renvoie les matchs (passés + à venir), et superpose les scores live
  /// si [premiumKey] est fourni. Triés du plus ancien au plus récent.
  static Future<List<MatchEvent>> fetchLeagueEvents(
    String leagueId, {
    String premiumKey = '',
  }) async {
    final next =
        await _fetchV1('$_v1/$_freeKey/eventsnextleague.php?id=$leagueId');
    final past =
        await _fetchV1('$_v1/$_freeKey/eventspastleague.php?id=$leagueId');

    final byId = <String, MatchEvent>{};
    for (final e in [...past, ...next]) {
      byId[e.id] = e;
    }

    // Scores en direct (premium uniquement) : écrasent la version statique.
    if (premiumKey.trim().isNotEmpty) {
      final live = await _fetchLive(leagueId, premiumKey.trim());
      for (final e in live) {
        byId[e.id] = e;
      }
    }

    final list = byId.values.toList()
      ..sort((a, b) {
        final da = a.dateTimeUtc, db = b.dateTimeUtc;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    return list;
  }

  static Future<List<MatchEvent>> _fetchV1(String url) async {
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = (data['events'] ?? data['results']) as List<dynamic>?;
      if (raw == null) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(MatchEvent.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// API v2 livescore par ligue (premium). Clé dans l'en-tête X-API-KEY.
  static Future<List<MatchEvent>> _fetchLive(
      String leagueId, String key) async {
    try {
      final res = await http.get(
        Uri.parse('$_v2/livescore/$leagueId'),
        headers: {'X-API-KEY': key},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final raw = (data is Map)
          ? (data['livescore'] ?? data['events'] ?? data['results'])
          : data;
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(MatchEvent.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
