enum TransactionType { expense, income }

class TransactionSplitPart {
  const TransactionSplitPart({required this.category, required this.amount});

  final String category;
  final double amount;
}

class TransactionEntry {
  TransactionEntry({
    String? id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.accountId,
    this.merchant,
    List<String>? tags,
    List<TransactionSplitPart>? splitParts,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       tags = tags ?? <String>[],
       splitParts = splitParts ?? <TransactionSplitPart>[],
       updatedAt = updatedAt ?? DateTime.now();

  final String id;

  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? accountId;
  final String? merchant;
  final List<String> tags;
  final List<TransactionSplitPart> splitParts;
  final DateTime updatedAt;

  bool get isSplit => splitParts.isNotEmpty;
}
