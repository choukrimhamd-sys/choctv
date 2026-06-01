import 'package:flutter/material.dart';

import '../models/playlist_source.dart';
import '../services/prefs_service.dart';

/// Réglages : gérer plusieurs sources de chaînes (URL ou M3U collé).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<PlaylistSource> _sources = [];
  int _active = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _sources = await PrefsService.getSources();
    _active = await PrefsService.getActiveSourceIndex();
    if (_active >= _sources.length) _active = 0;
    setState(() => _loading = false);
  }

  Future<void> _persist() async {
    await PrefsService.setSources(_sources);
    await PrefsService.setActiveSourceIndex(_active);
  }

  Future<void> _selectActive(int i) async {
    setState(() => _active = i);
    await _persist();
  }

  Future<void> _delete(int i) async {
    if (_sources.length <= 1) return;
    setState(() {
      _sources.removeAt(i);
      if (_active >= _sources.length) _active = _sources.length - 1;
    });
    await _persist();
  }

  Future<void> _addSource() async {
    final result = await showDialog<PlaylistSource>(
      context: context,
      builder: (_) => const _AddSourceDialog(),
    );
    if (result == null) return;
    setState(() {
      _sources.add(result);
      _active = _sources.length - 1; // active la nouvelle
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _addSource,
              icon: const Icon(Icons.add),
              label: const Text('Source'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text('Sources de chaînes',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Choisis la source active. Ajoute une playlist par URL ou '
                  'en collant un M3U.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...List.generate(_sources.length, (i) {
                  final s = _sources[i];
                  return Card(
                    child: RadioListTile<int>(
                      value: i,
                      groupValue: _active,
                      onChanged: (v) => _selectActive(v!),
                      title: Text(s.name),
                      subtitle: Text(
                        s.isUrl ? s.value : 'M3U collé',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed:
                            _sources.length <= 1 ? null : () => _delete(i),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                Text('À propos',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'chocTV lit des playlists M3U et affiche l\'agenda et les '
                  'scores sportifs (données publiques). L\'app ne fournit aucun '
                  'flux : tu dois renseigner une source que tu as le droit de '
                  'rediffuser. La légalité de ce qui est diffusé relève de ta '
                  'responsabilité.',
                ),
              ],
            ),
    );
  }
}

class _AddSourceDialog extends StatefulWidget {
  const _AddSourceDialog();

  @override
  State<_AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends State<_AddSourceDialog> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  String _type = 'url';

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim().isEmpty ? 'Source' : _name.text.trim();
    final value = _value.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(
      PlaylistSource(name: name, type: _type, value: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une source'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'url', label: Text('URL')),
                ButtonSegment(value: 'text', label: Text('Coller M3U')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              maxLines: _type == 'url' ? 2 : 6,
              keyboardType: _type == 'url'
                  ? TextInputType.url
                  : TextInputType.multiline,
              decoration: InputDecoration(
                labelText: _type == 'url'
                    ? 'URL (.m3u)'
                    : 'Contenu M3U (#EXTM3U ...)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ajouter')),
      ],
    );
  }
}
