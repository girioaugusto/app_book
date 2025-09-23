// lib/screens/cafes_screen.dart
import 'package:flutter/material.dart';
import '../models/cafe.dart';
import '../services/location_services.dart';
import '../services/cafe_service.dart';

class CafesScreen extends StatefulWidget {
  const CafesScreen({super.key});

  @override
  State<CafesScreen> createState() => _CafesScreenState();
}

class _CafesScreenState extends State<CafesScreen> {
  bool _loading = true;
  String? _error;
  List<Cafe> _cafes = [];
  double? _userLat;
  double? _userLng;
  final _radius = ValueNotifier<int>(1500); // metros

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await LocationServices.ensurePermission();
      if (!ok) {
        setState(() {
          _loading = false;
          _error = 'Permissão de localização negada. Habilite para ver cafés próximos.';
        });
        return;
      }

      final pos = await LocationServices.currentPosition();
      _userLat = pos.latitude;
      _userLng = pos.longitude;

      final cafes = await CafesService.fetchNearby(
        lat: _userLat!, lng: _userLng!, radiusMeters: _radius.value,
      );

      setState(() { _cafes = cafes; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('☕ Cafés'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottom(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    if (_cafes.isEmpty) {
      return const _EmptyState(
        title: 'Nenhum café encontrado por perto',
        subtitle: 'Tente aumentar o raio de busca ou verifique o GPS.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _cafes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = _cafes[i];
        final meters = (_userLat == null || _userLng == null)
            ? null
            : LocationServices.distanceMeters(
                lat1: _userLat!, lon1: _userLng!, lat2: c.lat, lon2: c.lng);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.coffee)),
            title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.address != null)
                  Text(c.address!, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(meters == null ? '—' : c.distanceLabel(meters)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              // Futuro: abrir no Google Maps com url_launcher
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${c.name}\n(${c.lat.toStringAsFixed(6)}, ${c.lng.toStringAsFixed(6)})')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottom() {
    return SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: _radius,
        builder: (context, r, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Text('Raio:'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    min: 300,
                    max: 5000,
                    divisions: 47,
                    label: '${(r / 1000).toStringAsFixed(1)} km',
                    value: r.toDouble(),
                    onChanged: (v) => _radius.value = v.toInt(),
                    onChangeEnd: (_) => _load(),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee_outlined, size: 64, color: Colors.black38),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Ops!', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
