import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livros_app/models/book.dart';
import 'package:livros_app/widgets/book_card.dart';

class ReadingScreen extends StatelessWidget {
  final List<Book> toRead; // livros "Ler"
  final List<Book> read;   // livros "Lido"
  final void Function(Book) onOpenDetails;

  const ReadingScreen({
    super.key,
    required this.toRead,
    required this.read,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // ===== APPBAR: sólido (sem blur) e com bom contraste =====
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          bottomOpacity: 1,
          shadowColor: theme.colorScheme.shadow.withOpacity(0.05),
          title: Text(
            'Sua leitura 📖',
            style: GoogleFonts.lobster(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: TabBar(
                isScrollable: false,
                dividerColor: Colors.transparent,
                // ===== Indicador “pill” leve (não cobre toda a barra) =====
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.22),
                    width: 1,
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withOpacity(0.6),

                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),

                tabs: const [
                  Tab(child: _TabLabel(icon: Icons.menu_book_rounded, text: 'Ler')),
                  Tab(child: _TabLabel(icon: Icons.check_circle_rounded, text: 'Lido')),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Sortear rápido (LER)',
              onPressed: toRead.isEmpty
                  ? null
                  : () {
                      final picked = (toRead.toList()..shuffle()).first;
                      onOpenDetails(picked);
                    },
              icon: const Icon(Icons.shuffle),
            ),
          ],
        ),

        // ===== BODY: fundo suave que não “lava” o conteúdo =====
        body: Stack(
          children: [
            const _CleanGradientBackground(),
            TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _BooksGrid(
                  books: toRead,
                  onTap: onOpenDetails,
                  overlayBuilder: (_) => const SizedBox.shrink(),
                ),
                _BooksGrid(
                  books: read,
                  onTap: onOpenDetails,
                  overlayBuilder: (b) => Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.check_circle,
                          color: theme.colorScheme.secondary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        floatingActionButton: toRead.isEmpty
            ? null
            : FloatingActionButton.extended(
                icon: const Icon(Icons.casino),
                label: const Text('Roleta'),
                onPressed: () async {
                  await showGeneralDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    barrierDismissible: false,
                    pageBuilder: (_, __, ___) => SizedBox.expand(
                      child: SafeArea(
                        child: BookRouletteFullScreen(
                          allBooks: toRead,
                          onPick: onOpenDetails,
                          maxSlices: 12,
                        ),
                      ),
                    ),
                    transitionBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  );
                },
              ),
      ),
    );
  }
}

/// Fundo com gradiente leve (sem blur e sem overlays por cima)
class _CleanGradientBackground extends StatelessWidget {
  const _CleanGradientBackground();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
          colors: [
            c.primary.withOpacity(0.06),
            c.tertiary.withOpacity(0.05),
            c.surfaceVariant.withOpacity(0.04),
          ],
        ),
      ),
    );
  }
}

// Label horizontal (ícone + texto) para as abas
class _TabLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TabLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class _BooksGrid extends StatelessWidget {
  final List<Book> books;
  final void Function(Book) onTap;
  final Widget Function(Book) overlayBuilder;

  const _BooksGrid({
    required this.books,
    required this.onTap,
    required this.overlayBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.library_books_outlined,
                  size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 10),
              Text('Nenhum livro aqui ainda',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Adicione livros nesta aba.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      );
    }

    final isWide = MediaQuery.sizeOf(context).width >= 560;
    final crossAxisCount = isWide ? 4 : 2;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: books.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) {
        final b = books[i];
        return Stack(
          children: [
            BookCard(book: b, onTap: () => onTap(b)),
            Positioned.fill(child: overlayBuilder(b)),
          ],
        );
      },
    );
  }
}

/// ======================================
/// ROLETA 🎡 — Full-screen (mantida), AppBar com bom contraste
/// ======================================
class BookRouletteFullScreen extends StatefulWidget {
  final List<Book> allBooks;              // todos os "Ler"
  final void Function(Book) onPick;       // callback ao finalizar
  final int maxSlices;                    // quantos setores desenhar

  const BookRouletteFullScreen({
    super.key,
    required this.allBooks,
    required this.onPick,
    this.maxSlices = 12,
  });

  @override
  State<BookRouletteFullScreen> createState() => _BookRouletteFullScreenState();
}

class _BookRouletteFullScreenState extends State<BookRouletteFullScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _angleAnim;

  double _currentAngle = 0.0;
  bool _spinning = false;

  // subconjunto visível + vencedor
  late List<Book> _wheelBooks;
  late int _winnerGlobalIndex; // índice no allBooks
  late int _winnerSlot;        // índice na roda
  int _livePointerSlot = 0;    // setor sob ponteiro (ao vivo)

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _prepareWheel();
  }

  void _prepareWheel() {
    final n = widget.allBooks.length;
    final r = Random();

    _winnerGlobalIndex = r.nextInt(n);

    final k = min(widget.maxSlices, n);
    final set = <int>{_winnerGlobalIndex};
    while (set.length < k) {
      set.add(r.nextInt(n));
    }
    final indices = set.toList()..shuffle(r);
    _winnerSlot = indices.indexOf(_winnerGlobalIndex);
    _wheelBooks = indices.map((i) => widget.allBooks[i]).toList();

    _livePointerSlot = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _slotUnderPointer() {
    final n = _wheelBooks.length;
    if (n == 0) return 0;
    final seg = (2 * pi) / n;
    double topAngle = -pi / 2 - _currentAngle; // topo da roda
    while (topAngle < 0) topAngle += 2 * pi;
    while (topAngle >= 2 * pi) topAngle -= 2 * pi;
    return (topAngle / seg).floor() % n;
  }

  double _computeTargetAngle() {
    final n = _wheelBooks.length;
    final seg = (2 * pi) / n;
    final centerOfWinner = (_winnerSlot * seg) + seg / 2;

    final alignToTop = -pi / 2 - centerOfWinner;
    const extraSpins = 4;
    final withSpins = alignToTop + extraSpins * 2 * pi;

    double delta = withSpins - _currentAngle;
    while (delta < 0) delta += 2 * pi;

    return _currentAngle + delta;
  }

  Future<void> _spin() async {
    if (_spinning || _wheelBooks.isEmpty) return;
    setState(() => _spinning = true);

    final targetAngle = _computeTargetAngle();
    final tween = Tween<double>(begin: _currentAngle, end: targetAngle);
    _angleAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic).drive(tween);

    _controller
      ..reset()
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          _currentAngle = targetAngle;
          _livePointerSlot = _slotUnderPointer();
          setState(() => _spinning = false);

          await Future.delayed(const Duration(milliseconds: 550));
          if (mounted) Navigator.of(context).pop();
          widget.onPick(widget.allBooks[_winnerGlobalIndex]);
        }
      })
      ..addListener(() {
        setState(() {
          _currentAngle = _angleAnim.value;
          _livePointerSlot = _slotUnderPointer();
        });
      })
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liveTitle = _wheelBooks.isEmpty ? '' : _wheelBooks[_livePointerSlot].title;

    return WillPopScope(
      onWillPop: () async => !_spinning,
      child: Scaffold(
        // AppBar simples e com contraste
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          leading: IconButton(
            onPressed: _spinning ? null : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
            tooltip: 'Fechar',
          ),
          toolbarHeight: 44,
          centerTitle: false,
          titleSpacing: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _spinning ? null : _spin,
                icon: const Icon(Icons.casino),
                label: Text(_spinning ? 'Girando...' : 'Girar'),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            const _CleanGradientBackground(), // mesmo fundo (leve)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  if (_wheelBooks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 140),
                        child: Text(
                          _spinning ? liveTitle : _wheelBooks[_winnerSlot].title,
                          key: ValueKey('${_spinning ? "live" : "win"}-$liveTitle'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ),

                  if (_wheelBooks.length < widget.allBooks.length)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Mostrando ${_wheelBooks.length} de ${widget.allBooks.length} livros (sorteio justo para todos).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final side = min(c.maxWidth, c.maxHeight) * 0.96;
                          return SizedBox(
                            width: side,
                            height: side,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.rotate(
                                  angle: _currentAngle,
                                  child: CustomPaint(
                                    painter: _RoulettePainter(
                                      books: _wheelBooks,
                                      onSurface: theme.colorScheme.onSurface,
                                      winnerSlot: _spinning ? null : _winnerSlot,
                                      highlight:
                                          theme.colorScheme.primary.withOpacity(0.18),
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _spinning ? null : _spin,
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  child: Icon(
                                    _spinning ? Icons.hourglass_top : Icons.casino,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: CustomPaint(
                                    size: const Size(28, 28),
                                    painter:
                                        _PointerPainter(color: theme.colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _spinning ? null : () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _spinning ? null : _spin,
                          icon: const Icon(Icons.casino),
                          label: Text(_spinning ? 'Girando...' : 'Girar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoulettePainter extends CustomPainter {
  final List<Book> books;
  final Color onSurface;
  final int? winnerSlot;   // destaca vencedor quando parar
  final Color highlight;

  _RoulettePainter({
    required this.books,
    required this.onSurface,
    required this.winnerSlot,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (books.isEmpty) return;

    final n = books.length;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.48;
    final seg = (2 * pi) / n;

    // fundo
    final base = Paint()
      ..style = PaintingStyle.fill
      ..color = onSurface.withOpacity(0.04);
    canvas.drawCircle(center, radius, base);

    // contorno externo
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = onSurface.withOpacity(0.20);
    canvas.drawCircle(center, radius, rim);

    for (int i = 0; i < n; i++) {
      final start = i * seg;

      final color = _hslColor(i, n).withOpacity(0.28);
      final bg = Paint()..color = color;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius), start, seg, false)
        ..close();
      canvas.drawPath(path, bg);

      // divisória
      final divider = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = onSurface.withOpacity(0.15);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        seg,
        false,
        divider,
      );

      // destaque do vencedor após parar
      if (winnerSlot != null && i == winnerSlot) {
        final glow = Paint()
          ..shader = RadialGradient(
            colors: [highlight, Colors.transparent],
            stops: const [0.0, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawPath(path, glow);
      }
    }
  }

  // Paleta HSL distribuída
  Color _hslColor(int i, int n) {
    final hue = (i * (360.0 / n)) % 360.0;
    final hsl = HSLColor.fromAHSL(1.0, hue, 0.55, 0.45);
    return hsl.toColor();
  }

  @override
  bool shouldRepaint(covariant _RoulettePainter old) {
    return old.books != books ||
        old.onSurface != onSurface ||
        old.winnerSlot != winnerSlot ||
        old.highlight != highlight;
  }
}

/// Ponteiro triangular no topo
class _PointerPainter extends CustomPainter {
  final Color color;
  _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h)
      ..lineTo(w, h)
      ..close();

    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => old.color != color;
}
