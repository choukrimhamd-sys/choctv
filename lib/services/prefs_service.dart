import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/channel.dart';
import '../models/playlist_source.dart';

/// Stockage local persistant : sources de chaînes, favoris, chaînes récentes.
class PrefsService {
  static const _kFavorites = 'favorites_urls';
  static const _kRecents = 'recent_channels';
  static const _kSources = 'playlist_sources';
  static const _kActiveSource = 'active_source_index';
  static const _kSportsKey = 'sports_api_key';
  static const _kLegacyUrl = 'playlist_url';
  static const int _maxRecents = 12;

  // --- Sources de chaînes ---

  static Future<List<PlaylistSource>> getSources() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSources);
    if (raw == null || raw.isEmpty) {
      // Migration : ancienne URL unique, sinon source par défaut.
      final oldUrl = p.getString(_kLegacyUrl);
      final defaults = [
        PlaylistSource(
          name: 'Par défaut',
          type: 'url',
          value: oldUrl ?? AppConfig.defaultPlaylistUrl,
        ),
      ];
      await setSources(defaults);
      return defaults;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final sources = list
          .whereType<Map<String, dynamic>>()
          .map(PlaylistSource.fromJson)
          .toList();
      return sources.isEmpty ? await _resetDefaults() : sources;
    } catch (_) {
      return _resetDefaults();
    }
  }

  static Future<List<PlaylistSource>> _resetDefaults() async {
    final defaults = [
      const PlaylistSource(
        name: 'Par défaut',
        type: 'url',
        value: AppConfig.defaultPlaylistUrl,
      ),
    ];
    await setSources(defaults);
    return defaults;
  }

  static Future<void> setSources(List<PlaylistSource> sources) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kSources,
      jsonEncode(sources.map((s) => s.toJson()).toList()),
    );
  }

  static Future<int> getActiveSourceIndex() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kActiveSource) ?? 0;
  }

  static Future<void> setActiveSourceIndex(int index) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kActiveSource, index);
  }

  /// Renvoie la source actuellement sélectionnée (indice borné).
  static Future<PlaylistSource> getActiveSource() async {
    final sources = await getSources();
    var idx = await getActiveSourceIndex();
    if (idx < 0 || idx >= sources.length) idx = 0;
    return sources[idx];
  }

  // --- Clé API premium TheSportsDB (scores en direct) ---

  static Future<String> getSportsKey() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kSportsKey) ?? '';
  }

  static Future<void> setSportsKey(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSportsKey, key.trim());
  }

  // --- Favoris (URLs des chaînes favorites) ---

  static Future<Set<String>> getFavorites() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kFavorites) ?? const []).toSet();
  }

  static Future<void> setFavorites(Set<String> favorites) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kFavorites, favorites.toList());
  }

  // --- Chaînes récentes ---

  static Future<List<Channel>> getRecents() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kRecents);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Channel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRecent(Channel channel) async {
    final p = await SharedPreferences.getInstance();
    final current = await getRecents();
    current.removeWhere((c) => c.url == channel.url);
    current.insert(0, channel);
    final trimmed = current.take(_maxRecents).toList();
    await p.setString(
      _kRecents,
      jsonEncode(trimmed.map((c) => c.toJson()).toList()),
    );
  }
}
