import 'dart:async';

import 'package:flutter/material.dart';

import '../channel_repository.dart';
import '../models/channel.dart';
import '../services/ads_service.dart';
import '../services/playlist_service.dart';
import '../services/prefs_service.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

const String _kFavGroup = '★ Favoris';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Channel> _all = [];
  List<Channel> _recents = [];
  Set<String> _favorites = {};
  String _search = '';
  String _selectedGroup = 'Toutes';
  bool _loading = true;
  String? _error;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _autoRefresh =
        Timer.periodic(const Duration(minutes: 10), (_) => _load());
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _favorites = await PrefsService.getFavorites();
    _recents = await PrefsService.getRecents();
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final source = await PrefsService.getActiveSource();
      final channels = source.isUrl
          ? await PlaylistService.fetchFromUrl(source.value)
          : PlaylistService.parseText(source.value);
      ChannelRepository.instance.channels = channels;
      if (!mounted) return;
      setState(() {
        _all = channels;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger la playlist.\n$e';
        _loading = false;
      });
    }
  }

  List<String> get _groups {
    final set = _all.map((c) => c.group).toSet().toList()..sort();
    return ['Toutes', _kFavGroup, ...set];
  }

  List<Channel> get _filtered {
    return _all.where((c) {
      final matchesGroup = _selectedGroup == 'Toutes' ||
          (_selectedGroup == _kFavGroup && _favorites.contains(c.url)) ||
          c.group == _selectedGroup;
      final matchesSearch =
          c.name.toLowerCase().contains(_search.toLowerCase());
      return matchesGroup && matchesSearch;
    }).toList();
  }

  Future<void> _toggleFavorite(Channel channel) async {
    setState(() {
      if (_favorites.contains(channel.url)) {
        _favorites.remove(channel.url);
      } else {
        _favorites.add(channel.url);
      }
    });
    await PrefsService.setFavorites(_favorites);
  }

  Future<void> _openChannel(Channel channel) async {
    await PrefsService.addRecent(channel);
    _recents = await PrefsService.getRecents();
    if (!mounted) return;
    setState(() {});
    AdsService.instance.maybeShowInterstitial(() {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel)),
      );
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('chocTV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final showRecents = _recents.isNotEmpty && _search.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher une chaîne…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final g = _groups[i];
              return Center(
                child: ChoiceChip(
                  label: Text(g),
                  selected: _selectedGroup == g,
                  onSelected: (_) => setState(() => _selectedGroup = g),
                ),
              );
            },
          ),
        ),
        if (showRecents) _buildRecentsRow(),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('Aucune chaîne trouvée.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 140,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final channel = _filtered[i];
                    return ChannelCard(
                      channel: channel,
                      isFavorite: _favorites.contains(channel.url),
                      onToggleFavorite: () => _toggleFavorite(channel),
                      onTap: () => _openChannel(channel),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecentsRow() {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('Récemment vues',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _recents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _recents[i];
                return ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => _openChannel(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
