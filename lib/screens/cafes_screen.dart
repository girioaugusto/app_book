import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cafe_service.dart';
import '../services/location_services.dart';

class CafesScreen extends StatefulWidget {
  const CafesScreen({Key? key}) : super(key: key);

  @override
  State<CafesScreen> createState() => _CafesScreenState();
}

class _CafesScreenState extends State<CafesScreen> {
  late Future<_Result> _future;
  String _query = '';
  _QuickOption? _selectedQuick; // chips rápidos

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Result> _load() async {
    final pos = await LocationServices.currentPosition();

    // ignore: avoid_print
    print('Using location: lat=${pos.latitude}, lon=${pos.longitude}');

    // 👉 Busca mais ampla (5 km) pra garantir dados
    final cafes = await CafeService.getCafesNearby(
      lat: pos.latitude,
      lon: pos.longitude,
      radiusMeters: 5000,
      limit: 80,
    );

    final items = cafes
        .map((c) {
          final d = LocationServices.distanceMeters(
            lat1: pos.latitude,
            lon1: pos.longitude,
            lat2: c.latitude,
            lon2: c.longitude,
          );
          return _CafeWithDistance(cafe: c, distanceMeters: d);
        })
        .toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return _Result(lat: pos.latitude, lon: pos.longitude, items: items);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  String _fmt(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  Future<void> _openMaps(double lat, double lon) async {
    final url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    // Tenta app; se falhar (emulador), vai de navegador
    if (await canLaunchUrl(url)) {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } else if (mounted) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  // Aplica busca + chip selecionado
  List<_CafeWithDistance> _applyFilters(List<_CafeWithDistance> items) {
    var filtered = items;

    // 1) Busca por nome
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      filtered = filtered
          .where((e) => e.cafe.name.toLowerCase().contains(q))
          .toList();
    }

    // 2) Chips rápidos
    switch (_selectedQuick) {
      case _QuickOption.near500:
        filtered = filtered.where((e) => e.distanceMeters <= 500).toList();
        break;
      case _QuickOption.near1000:
        filtered = filtered.where((e) => e.distanceMeters <= 1000).toList();
        break;
      case _QuickOption.near2000:
        filtered = filtered.where((e) => e.distanceMeters <= 2000).toList();
        break;
      case _QuickOption.bakery:
        filtered = filtered.where((e) {
          final n = e.cafe.name.toLowerCase();
          final a = e.cafe.address.toLowerCase();
          return n.contains('padaria') ||
              a.contains('padaria') ||
              n.contains('bakery') ||
              a.contains('bakery');
        }).toList();
        break;
      case _QuickOption.chain:
        filtered = filtered.where((e) {
          final n = e.cafe.name.toLowerCase();
          return n.contains('starbucks') ||
              n.contains('costa') ||
              n.contains('havanna') ||
              n.contains('coffee shop');
        }).toList();
        break;
      case _QuickOption.specialty:
        filtered = filtered.where((e) {
          final n = e.cafe.name.toLowerCase();
          final a = e.cafe.address.toLowerCase();
          return n.contains('especial') ||
              n.contains('specialty') ||
              n.contains('espresso') ||
              a.contains('especial');
        }).toList();
        break;
      case null:
        break;
    }

    filtered.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brown = Colors.brown;

    // Fundo do Scaffold: claro no light, "surface" no dark
    final scaffoldBg = isDark ? theme.colorScheme.surface : const Color(0xFFF6F7F9);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: FutureBuilder<_Result>(
        future: _future,
        builder: (context, snap) {
          final titleStyle = GoogleFonts.poppins(
            textStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          );

          if (snap.connectionState == ConnectionState.waiting) {
            return _ScaffoldWithHeader(
              title: 'Cafeterias próximas',
              subtitle: 'Carregando sua localização…',
              titleStyle: titleStyle,
              onRefresh: _refresh,
              onQuery: (q) => setState(() => _query = q),
              onSelectQuick: (opt) => setState(() => _selectedQuick = opt),
              selectedQuick: _selectedQuick,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snap.hasError) {
            return _ScaffoldWithHeader(
              title: 'Cafeterias próximas',
              subtitle: 'Algo deu errado :(',
              titleStyle: titleStyle,
              onRefresh: _refresh,
              onQuery: (q) => setState(() => _query = q),
              onSelectQuick: (opt) => setState(() => _selectedQuick = opt),
              selectedQuick: _selectedQuick,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 56, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      'Erro: ${snap.error}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snap.data!;
          final list = _applyFilters(data.items);

          final headerSubtitle =
              'Usando: ${data.lat.toStringAsFixed(5)}, ${data.lon.toStringAsFixed(5)}';

          return _ScaffoldWithHeader(
            title: 'Cafeterias próximas',
            subtitle: headerSubtitle,
            titleStyle: titleStyle,
            onRefresh: _refresh,
            onQuery: (q) => setState(() => _query = q),
            onSelectQuick: (opt) => setState(() => _selectedQuick = opt),
            selectedQuick: _selectedQuick,
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma cafeteria encontrada.\nTente outra opção.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.54),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

                    // ✅ Ajustes essenciais para funcionar dentro de SliverToBoxAdapter:
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    primary: false,

                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final e = list[i];
                      return _CafeCard(
                        name: e.cafe.name,
                        address: e.cafe.address,
                        distanceLabel: _fmt(e.distanceMeters),
                        onTapRoute: () =>
                            _openMaps(e.cafe.latitude, e.cafe.longitude),
                        accent: brown,
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refresh,
        icon: const Icon(Icons.my_location),
        label: const Text('Atualizar'),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }
}

/* --------------------------- Layout com header --------------------------- */

class _ScaffoldWithHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final Widget child;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onQuery;
  final ValueChanged<_QuickOption?> onSelectQuick;
  final _QuickOption? selectedQuick;

  const _ScaffoldWithHeader({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.child,
    required this.onRefresh,
    required this.onQuery,
    required this.onSelectQuick,
    required this.selectedQuick,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              title: title,
              subtitle: subtitle,
              titleStyle: titleStyle,
              topPadding: top,
              onQuery: onQuery,
              onSelectQuick: onSelectQuick,
              selectedQuick: selectedQuick,
            ),
          ),
          SliverToBoxAdapter(child: child),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final double topPadding;
  final ValueChanged<String> onQuery;
  final ValueChanged<_QuickOption?> onSelectQuick;
  final _QuickOption? selectedQuick;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.topPadding,
    required this.onQuery,
    required this.onSelectQuick,
    required this.selectedQuick,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [Colors.green.shade700, Colors.green.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 12),
      decoration: BoxDecoration(gradient: gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SearchField(onChanged: onQuery),
          const SizedBox(height: 10),
          _QuickOptionsRow(
            selected: selectedQuick,
            onSelect: onSelectQuick,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // No dark, usar a "surface" pra o campo não ficar branco
    final fill = isDark ? theme.colorScheme.surface : Colors.white;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por nome…',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: fill,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}

/* -------------------------- Opções rápidas (chips) ------------------------- */

enum _QuickOption {
  near500,
  near1000,
  near2000,
  bakery,
  chain,
  specialty,
}

extension on _QuickOption {
  String get label {
    switch (this) {
      case _QuickOption.near500:
        return 'Até 500 m';
      case _QuickOption.near1000:
        return 'Até 1 km';
      case _QuickOption.near2000:
        return 'Até 2 km';
      case _QuickOption.bakery:
        return 'Padaria';
      case _QuickOption.chain:
        return 'Starbucks & cia';
      case _QuickOption.specialty:
        return 'Café especial';
    }
  }

  IconData get icon {
    switch (this) {
      case _QuickOption.near500:
        return Icons.directions_walk;
      case _QuickOption.near1000:
        return Icons.directions_bike;
      case _QuickOption.near2000:
        return Icons.directions_car;
      case _QuickOption.bakery:
        return Icons.cookie_outlined;
      case _QuickOption.chain:
        return Icons.local_cafe_outlined;
      case _QuickOption.specialty:
        return Icons.emoji_food_beverage;
    }
  }
}

class _QuickOptionsRow extends StatelessWidget {
  final _QuickOption? selected;
  final ValueChanged<_QuickOption?> onSelect;
  const _QuickOptionsRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = _QuickOption.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final o in opts) ...[
            _QuickChip(
              label: o.label,
              icon: o.icon,
              selected: selected == o,
              onTap: () => onSelect(selected == o ? null : o),
            ),
            const SizedBox(width: 8),
          ],
          _QuickChip(
            label: 'Limpar',
            icon: Icons.close,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sel = selected;
    final bg = sel ? Colors.white : Colors.white.withOpacity(0.2);
    final fg = sel ? Colors.green.shade800 : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? Colors.white : Colors.white.withOpacity(0.6),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Card dos cafés --------------------------- */

class _CafeCard extends StatelessWidget {
  final String name;
  final String address;
  final String distanceLabel;
  final VoidCallback onTapRoute;
  final Color accent;

  const _CafeCard({
    required this.name,
    required this.address,
    required this.distanceLabel,
    required this.onTapRoute,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = GoogleFonts.poppins(
      textStyle:
          theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    final subtitle = GoogleFonts.inter(
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.54),
      ),
    );

    // Fundo do card: claro no light, "surface/surfaceVariant" no dark
    final cardStart = isDark ? theme.colorScheme.surface : Colors.white;
    final cardEnd = isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade50;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [cardStart, cardEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone arredondado
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.local_cafe, color: accent, size: 28),
          ),
          const SizedBox(width: 12),

          // Texto + ações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: title),
                const SizedBox(height: 4),
                Text(
                  address.isEmpty || address == 'Endereço indisponível'
                      ? 'Endereço não informado'
                      : address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: subtitle,
                ),
                const SizedBox(height: 10),

                // Só distância + botão Rotas (sem overflows)
                Row(
                  children: [
                    _DistanceChip(distanceLabel: distanceLabel, accent: accent),
                    const Spacer(),
                    _MiniAction(
                      icon: Icons.map_outlined,
                      label: 'Rotas',
                      onTap: onTapRoute,
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  final String distanceLabel;
  final Color accent;
  const _DistanceChip({required this.distanceLabel, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.near_me, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            distanceLabel,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------- modelos -------------------------------- */

class _Result {
  final double lat, lon;
  final List<_CafeWithDistance> items;
  _Result({required this.lat, required this.lon, required this.items});
}

class _CafeWithDistance {
  final Cafe cafe;
  final double distanceMeters;
  _CafeWithDistance({required this.cafe, required this.distanceMeters});
}
