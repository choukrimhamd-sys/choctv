/// Représente un match (à venir ou terminé) issu de l'API sportive.
class MatchEvent {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String? homeScore;
  final String? awayScore;
  final String league;
  final DateTime? dateTimeUtc;
  final String status; // ex: "Not Started", "Match Finished", "1H"...

  const MatchEvent({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.league,
    this.dateTimeUtc,
    this.status = '',
  });

  bool get hasScore => homeScore != null && awayScore != null;

  bool get isLive {
    final s = status.toLowerCase();
    return s.contains('1h') ||
        s.contains('2h') ||
        s.contains('half') ||
        s.contains('live') ||
        s.contains('play');
  }

  bool get isFinished {
    final s = status.toLowerCase();
    return s.contains('finished') || s.contains('ft') || s.contains('aet');
  }

  factory MatchEvent.fromJson(Map<String, dynamic> j) {
    DateTime? dt;
    final ts = j['strTimestamp'] as String?;
    if (ts != null && ts.isNotEmpty) {
      dt = DateTime.tryParse(ts)?.toUtc();
    }
    dt ??= _combineDateTime(j['dateEvent'] as String?, j['strTime'] as String?);

    return MatchEvent(
      id: (j['idEvent'] ?? '').toString(),
      homeTeam: (j['strHomeTeam'] ?? '?').toString(),
      awayTeam: (j['strAwayTeam'] ?? '?').toString(),
      homeScore: _str(j['intHomeScore']),
      awayScore: _str(j['intAwayScore']),
      league: (j['strLeague'] ?? '').toString(),
      dateTimeUtc: dt,
      status: (j['strStatus'] ?? '').toString(),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static DateTime? _combineDateTime(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final t = (time == null || time.isEmpty) ? '00:00:00' : time;
    return DateTime.tryParse('${date}T$t' 'Z')?.toUtc();
  }
}
