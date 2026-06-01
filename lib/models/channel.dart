/// Représente une chaîne TV issue d'une playlist M3U.
class Channel {
  final String name;
  final String url;
  final String? logo;
  final String group;

  const Channel({
    required this.name,
    required this.url,
    this.logo,
    this.group = 'Autres',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'logo': logo,
        'group': group,
      };

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        name: (j['name'] ?? 'Sans nom').toString(),
        url: (j['url'] ?? '').toString(),
        logo: j['logo'] as String?,
        group: (j['group'] ?? 'Autres').toString(),
      );

  @override
  bool operator ==(Object other) =>
      other is Channel && other.url == url && other.name == name;

  @override
  int get hashCode => Object.hash(name, url);
}
