import 'models/channel.dart';

/// Stocke en mémoire la dernière liste de chaînes chargée et permet de
/// retrouver la chaîne associée à une compétition.
///
/// 👉 Adapte [leagueChannelKeywords] aux noms réels des chaînes de TA playlist.
class ChannelRepository {
  ChannelRepository._();
  static final ChannelRepository instance = ChannelRepository._();

  List<Channel> channels = [];

  /// Compétition -> mots-clés recherchés dans le nom/groupe d'une chaîne.
  /// Le premier mot-clé qui correspond gagne (du plus précis au plus large).
  static const Map<String, List<String>> leagueChannelKeywords = {
    'Premier League': ['premier league', 'premier', 'sport', 'football'],
    'La Liga': ['la liga', 'liga', 'sport', 'football'],
    'Serie A': ['serie a', 'sport', 'football', 'calcio'],
    'Bundesliga': ['bundesliga', 'sport', 'football'],
    'Ligue 1': ['ligue 1', 'ligue1', 'sport', 'football'],
    'Champions League': ['champions', 'ucl', 'sport', 'football'],
  };

  /// Renvoie la première chaîne dont le nom ou le groupe contient un des
  /// mots-clés de la compétition. Renvoie null si rien ne correspond.
  Channel? findForLeague(String league) {
    final keywords =
        leagueChannelKeywords[league] ?? const ['sport', 'football'];
    for (final kw in keywords) {
      final needle = kw.toLowerCase();
      for (final c in channels) {
        final haystack = '${c.name} ${c.group}'.toLowerCase();
        if (haystack.contains(needle)) return c;
      }
    }
    return null;
  }
}
