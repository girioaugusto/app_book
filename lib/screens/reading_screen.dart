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
        appBar: AppBar(
          centerTitle: true,
          toolbarHeight: 84, // 👈 dá respiro pro título
          title: Text(
            'Sua leitura 📖',
            style: GoogleFonts.lobster(
              fontSize: 32,              // 👈 maior
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: Colors.white // destaque no verde do app
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Builder(
              builder: (context) {
                final c = Theme.of(context).colorScheme;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.08), // “trilho” suave
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: c.primary,                       // ✅ verde do tema
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: c.onPrimary,                   // texto branco selecionada
                      unselectedLabelColor: Colors.blueGrey,           // texto cinza nas outras
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(icon: Icon(Icons.menu_book_rounded), text: 'Ler'),
                        Tab(icon: Icon(Icons.check_circle_rounded), text: 'Lido'),
                      ],
                    ),
                  ),
                );
              },
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
        body: TabBarView(
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
                  child: Icon(Icons.check_circle, color: theme.colorScheme.secondary),
                ),
              ),
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
                    barrierColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
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
/// ROLETA 🎡 — Full-screen (repaginada)
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

    // 1) vencedor justo no universo inteiro
    _winnerGlobalIndex = r.nextInt(n);

    // 2) subconjunto p/ desenhar (inclui vencedor)
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

    // ===== tamanhos/posicionamento =====
    const double pointerSize = 28.0; // tamanho da seta (PointerPainter)
    const double chipGap = 6.0;      // respiro padrão entre seta e chip
    const double chipLift = 12.0;    // elevação extra (acima da seta, sem grudar)

    return WillPopScope(
      onWillPop: () async => !_spinning,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          leading: IconButton(
            onPressed: _spinning ? null : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
            tooltip: 'Fechar',
          ),
          title: const Text(
            'Roleta de Livros',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),

        body: Stack(
          children: [
            const _RouletteBackdrop(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                children: [
                  if (_wheelBooks.length < widget.allBooks.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Text(
                        'Mostrando ${_wheelBooks.length} de ${widget.allBooks.length} livros (sorteio justo para todos).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  // ===== Roda =====
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
                              clipBehavior: Clip.none, // permite chip acima da seta
                              children: [
                                // aro/sombra
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        radius: 0.64,
                                        colors: [
                                          Theme.of(context).colorScheme.onSurface.withOpacity(0.10),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 1.0],
                                      ),
                                    ),
                                  ),
                                ),

                                // roleta
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

                                // chip acima da seta
                                if (_wheelBooks.isNotEmpty)
                                  Positioned(
                                    top: -(pointerSize + chipGap + chipLift),
                                    child: _TickerChip(
                                      text: _compactTitle(
                                        _spinning
                                            ? liveTitle
                                            : _wheelBooks[_winnerSlot].title,
                                      ),
                                      leading: const Icon(
                                        Icons.menu_book_rounded,
                                        size: 18,
                                      ),
                                      maxWidth: 240,
                                    ),
                                  ),

                                // botão central
                                _RoundActionButton(
                                  enabled: !_spinning,
                                  icon: _spinning ? Icons.hourglass_top : Icons.casino,
                                  onPressed: _spinning ? null : _spin,
                                ),

                                // ponteiro topo
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: CustomPaint(
                                    size: const Size(pointerSize, pointerSize),
                                    painter: _PointerPainter(
                                      color: theme.colorScheme.error,
                                      strokeColor: theme.colorScheme.onSurface.withOpacity(0.15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ===== Ações (rodapé) =====
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

/// Compacta o título: corta subtítulo após ":"/"/-/–/—" e limita caracteres.
String _compactTitle(String input) {
  var s = input.split(RegExp(r'[:\-–—]')).first.trim();
  const limit = 24;
  if (s.length > limit) {
    s = s.substring(0, limit).trimRight() + '…';
  }
  return s;
}

/// Fundo elegante: gradiente limpo + glows discretos nos cantos (sem blur)
class _RouletteBackdrop extends StatelessWidget {
  const _RouletteBackdrop();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                c.primary.withOpacity(0.06),
                c.tertiary.withOpacity(0.05),
                c.surfaceVariant.withOpacity(0.04),
              ],
            ),
          ),
        ),
        IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: -80,
                top: -60,
                child: _CornerGlow(color: c.primary.withOpacity(0.10), size: 240),
              ),
              Positioned(
                right: -70,
                bottom: -50,
                child: _CornerGlow(color: c.secondary.withOpacity(0.10), size: 220),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CornerGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _CornerGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Chip do ticker (título compacto do setor sob o ponteiro / vencedor)
class _TickerChip extends StatelessWidget {
  final String text;
  final Widget? leading;
  final double maxWidth;
  const _TickerChip({
    required this.text,
    this.leading,
    this.maxWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),

              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão circular no centro da roda, com leve sombra/realce
class _RoundActionButton extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundActionButton({
    required this.enabled,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: c.primary.withOpacity(enabled ? 0.30 : 0.12),
            blurRadius: enabled ? 18 : 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(18),
          backgroundColor: enabled ? c.primary : c.surfaceVariant,
          foregroundColor: enabled ? c.onPrimary : c.onSurfaceVariant,
          elevation: 0,
        ),
        child: Icon(icon, size: 22),
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
  final Color color;       // cor de preenchimento
  final Color strokeColor; // cor da borda

  _PointerPainter({
    required this.color,
    required this.strokeColor,
  });

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
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) =>
      old.color != color || old.strokeColor != strokeColor;
}
