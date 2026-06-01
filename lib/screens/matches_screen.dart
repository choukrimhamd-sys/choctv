import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../channel_repository.dart';
import '../models/match_event.dart';
import '../services/sports_service.dart';
import 'player_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String _leagueName = SportsService.leagues.keys.first;
  List<MatchEvent> _events = [];
  bool _loading = true;
  String? _error;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _load();
    // Rafraîchissement automatique des scores toutes les 60 secondes.
    _autoRefresh = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final id = SportsService.leagues[_leagueName]!;
    try {
      final events = await SportsService.fetchLeagueEvents(id);
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les matchs.';
      });
    }
  }

  void _openMatch(MatchEvent event) {
    final channel = ChannelRepository.instance.findForLeague(_leagueName);
    if (channel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucune chaîne associée à « $_leagueName » dans ta playlist. '
            'Ajoute-la ou configure l\'association dans channel_repository.dart.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchs & scores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: SportsService.leagues.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final name = SportsService.leagues.keys.elementAt(i);
              return Center(
                child: ChoiceChip(
                  label: Text(name),
                  selected: _leagueName == name,
                  onSelected: (_) {
                    setState(() => _leagueName = name);
                    _load();
                  },
                ),
              );
            },
          ),
        ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_events.isEmpty) {
      return const Center(child: Text('Aucun match disponible.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _MatchTile(
          event: _events[i],
          onTap: () => _openMatch(_events[i]),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchEvent event;
  final VoidCallback onTap;
  const _MatchTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String trailing;
    Color? color;
    if (event.isLive) {
      trailing = 'EN DIRECT';
      color = Colors.redAccent;
    } else if (event.isFinished) {
      trailing = 'Terminé';
    } else if (event.dateTimeUtc != null) {
      final local = event.dateTimeUtc!.toLocal();
      trailing = DateFormat('dd/MM · HH:mm').format(local);
    } else {
      trailing = '—';
    }

    final scoreText = event.hasScore
        ? '${event.homeScore} - ${event.awayScore}'
        : 'vs';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  event.homeTeam,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  scoreText,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  event.awayTeam,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(
                  trailing,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: event.isLive ? FontWeight.bold : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
