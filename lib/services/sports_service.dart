import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match_event.dart';

/// Récupère l'agenda et les scores via l'API gratuite TheSportsDB.
/// Données factuelles (équipes, horaires, scores) — utilisation légale.
class SportsService {
  // Clé de test gratuite fournie par TheSportsDB.
  static const String _key = '3';
  static const String _base = 'https://www.thesportsdb.com/api/v1/json';

  /// Compétitions proposées (nom -> identifiant de ligue TheSportsDB).
  static const Map<String, String> leagues = {
    'Premier League': '4328',
    'La Liga': '4335',
    'Serie A': '4332',
    'Bundesliga': '4331',
    'Ligue 1': '4334',
    'Champions League': '4480',
  };

  /// Renvoie les prochains matchs ET les derniers résultats d'une ligue,
  /// triés du plus ancien au plus récent.
  static Future<List<MatchEvent>> fetchLeagueEvents(String leagueId) async {
    final next = await _fetchEvents('$_base/$_key/eventsnextleague.php?id=$leagueId');
    final past = await _fetchEvents('$_base/$_key/eventspastleague.php?id=$leagueId');

    final all = <String, MatchEvent>{};
    for (final e in [...past, ...next]) {
      all[e.id] = e;
    }
    final list = all.values.toList()
      ..sort((a, b) {
        final da = a.dateTimeUtc;
        final db = b.dateTimeUtc;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    return list;
  }

  static Future<List<MatchEvent>> _fetchEvents(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
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
}
