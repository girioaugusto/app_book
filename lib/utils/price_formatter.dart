String formatPrice(double? amount, String? currency) {
  if (amount == null) return 'Sem preço';
  final c = currency ?? 'USD';
  return '$c ${amount.toStringAsFixed(2)}';
}