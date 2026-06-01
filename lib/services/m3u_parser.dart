import '../models/channel.dart';

/// Analyse le contenu texte d'une playlist M3U et renvoie une liste de chaînes.
///
/// Format attendu d'une entrée :
/// #EXTINF:-1 tvg-logo="http://..." group-title="Info",France 24
/// http://exemple.com/flux.m3u8
class M3uParser {
  static List<Channel> parse(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final channels = <Channel>[];

    String? name;
    String? logo;
    String group = 'Autres';

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF')) {
        logo = _attribute(line, 'tvg-logo');
        group = _attribute(line, 'group-title') ?? 'Autres';
        final commaIndex = line.lastIndexOf(',');
        name = commaIndex != -1 && commaIndex + 1 < line.length
            ? line.substring(commaIndex + 1).trim()
            : 'Sans nom';
      } else if (!line.startsWith('#')) {
        // Ligne d'URL : on finalise la chaîne en cours.
        if (name != null) {
          channels.add(Channel(
            name: name,
            url: line,
            logo: (logo != null && logo.isNotEmpty) ? logo : null,
            group: group.isEmpty ? 'Autres' : group,
          ));
        }
        name = null;
        logo = null;
        group = 'Autres';
      }
    }
    return channels;
  }

  /// Extrait la valeur d'un attribut du type cle="valeur".
  static String? _attribute(String line, String key) {
    final match = RegExp('$key="([^"]*)"').firstMatch(line);
    return match?.group(1);
  }
}
