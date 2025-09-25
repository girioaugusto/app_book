// lib/widgets/rotating_quote_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livros_app/data/quotes.dart';

class RotatingQuoteCard extends StatefulWidget {
  final bool dailyOnly;
  final bool autoRotate;
  final Duration interval;
  final bool rememberLast;

  const RotatingQuoteCard({
    super.key,
    this.dailyOnly = true,
    this.autoRotate = true,
    this.interval = const Duration(seconds: 6),
    this.rememberLast = true,
  });

  @override
  State<RotatingQuoteCard> createState() => _RotatingQuoteCardState();
}

class _RotatingQuoteCardState extends State<RotatingQuoteCard> {
  static const _prefsKey = 'rotating_quote_index';
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _index = _initialIndex();

    if (!widget.dailyOnly && widget.rememberLast) {
      _loadLastIndex();
    }

    if (!widget.dailyOnly && widget.autoRotate) {
      _timer = Timer.periodic(widget.interval, (_) => _next());
    }
  }

  int _initialIndex() {
    if (widget.dailyOnly) {
      final days = DateTime.now()
          .toUtc()
          .difference(DateTime.utc(2020, 1, 1))
          .inDays;
      return days % quotes.length;
    }
    return 0;
  }

  Future<void> _loadLastIndex() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getInt(_prefsKey);
    if (saved != null && mounted) setState(() => _index = saved % quotes.length);
  }

  Future<void> _saveIndex() async {
    if (!widget.rememberLast || widget.dailyOnly) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefsKey, _index);
  }

  void _next() {
    setState(() => _index = (_index + 1) % quotes.length);
    _saveIndex();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = quotes[_index];

    return GestureDetector(
      onTap: () {
        if (!widget.dailyOnly) _next();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .08),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: _QuoteView(
            key: ValueKey(_index),
            text: q.text,
            author: q.author,
          ),
        ),
      ),
    );
  }
}

class _QuoteView extends StatelessWidget {
  final String text;
  final String author;
  const _QuoteView({super.key, required this.text, required this.author});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final body = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: cs.onSurface.withOpacity(0.87), // muda conforme tema
        );
    final authorStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant, // muda conforme tema
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.format_quote_rounded,
              size: 28, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: body)),
        ]),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text('— $author', style: authorStyle),
        ),
      ],
    );
  }
}
