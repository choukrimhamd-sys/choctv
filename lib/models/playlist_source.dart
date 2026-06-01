/// Une source de chaînes : soit une URL de playlist M3U, soit un M3U collé.
class PlaylistSource {
  final String name;
  final String type; // 'url' ou 'text'
  final String value;

  const PlaylistSource({
    required this.name,
    required this.type,
    required this.value,
  });

  bool get isUrl => type == 'url';

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'value': value,
      };

  factory PlaylistSource.fromJson(Map<String, dynamic> j) => PlaylistSource(
        name: (j['name'] ?? 'Source').toString(),
        type: (j['type'] ?? 'url').toString(),
        value: (j['value'] ?? '').toString(),
      );
}
