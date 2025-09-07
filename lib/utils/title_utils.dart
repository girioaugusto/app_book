// lib/utils/title_utils.dart
class TitleFormat {
  final String title;
  final String? subtitle;
  const TitleFormat(this.title, [this.subtitle]);
}

/// Formata o título cru vindo da API para algo mais apresentável.
/// - Remove colchetes/parenteses longos
/// - Separa título/subtítulo por ":" ou " - "
/// - Corrige CAIXA ALTA para Title Case (PT)
/// - Normaliza espaços e pontuação
TitleFormat prettyTitle(String raw) {
  String s = raw;

  // 1) Normalizar espaços e decodificar HTML básico
  s = _unescapeHtml(s).replaceAll(RegExp(r'\s+'), ' ').trim();

  // 2) Remover colchetes [ ... ] se muito longos (ex.: descrições da API)
  s = s.replaceAll(RegExp(r'\s*\[[^\]]{15,}\]\s*'), ' ').trim();

  // 3) Remover parenteses ( ... ) se muito longos
  s = s.replaceAll(RegExp(r'\s*\([^)]{20,}\)\s*'), ' ').trim();

  // 4) Limpar pontuação repetida e pontas
  s = s.replaceAll(RegExp(r'\s*[:;,\.\-–—]\s*$'), '').trim();

  // 5) Separar subtítulo por ":" ou " - " (apenas o primeiro)
  String? sub;
  final sep = RegExp(r'\s*[:\-–—]\s*');
  final parts = s.split(sep);
  if (parts.length >= 2) {
    final left = parts.first.trim();
    final right = parts.sublist(1).join(' - ').trim(); // reune resto
    // Só mantém subtítulo se for curtinho (até ~40 chars)
    if (right.length <= 40) {
      s = left;
      sub = right;
    } else {
      s = left; // descarta rabicho longo
    }
  }

  // 6) Se está "majoritariamente" em MAIÚSCULAS, aplicar Title Case PT
  if (_mostlyUppercase(s)) {
    s = _toTitleCasePt(s.toLowerCase());
  } else {
    // corrige só a primeira letra do título, sem mexer em nomes próprios
    s = _sentenceCapitalize(s);
  }
  if (sub != null) {
    sub = _mostlyUppercase(sub) ? _toTitleCasePt(sub.toLowerCase()) : _sentenceCapitalize(sub);
  }

  return TitleFormat(s, sub);
}

// ==== Helpers ====

String _unescapeHtml(String input) {
  return input
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

bool _mostlyUppercase(String s) {
  final letters = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');
  final uppers = RegExp(r'[A-ZÀ-ÖØ-Þ]');
  int total = 0, up = 0;
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (letters.hasMatch(ch)) {
      total++;
      if (uppers.hasMatch(ch)) up++;
    }
  }
  if (total == 0) return false;
  return up / total >= 0.7; // 70%+ maiúsculas = considera gritado
}

String _sentenceCapitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

final _ptSmallWords = <String>{
  'de','da','do','das','dos',
  'e','a','o','as','os',
  'um','uma','uns','umas',
  'para','pra','por',
  'em','no','na','nos','nas',
  'com','sem','que','se',
  'ao','aos','à','às',
  'dum','duma','num','numa',
  'sobre','entre','até','após','ante','trás','contra',
  'per','pelo','pelos','pela','pelas'
};


String _toTitleCasePt(String s) {
  final words = s.split(' ');
  for (var i = 0; i < words.length; i++) {
    var w = words[i];
    final wl = w.toLowerCase();


    // primeira palavra sempre capitalizada
    if (i == 0) {
      words[i] = _capFirst(wl);
      continue;
    }

    // palavras curtas comuns em minúsculas
    if (_ptSmallWords.contains(wl)) {
      words[i] = wl;
    } else {
      words[i] = _capFirst(wl);
    }
  }
  // Limpar duplas de espaço
  return words.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _capFirst(String w) {
  if (w.isEmpty) return w;
  return w[0].toUpperCase() + w.substring(1);
}
