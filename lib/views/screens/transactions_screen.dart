import 'package:flutter/material.dart';

import '../../models/transaction_entry.dart';

enum TransactionSortOption { latest, oldest, highestAmount, lowestAmount }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.currencySymbol,
  });

  final List<TransactionEntry> transactions;
  final String currencySymbol;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransactionType? _selectedType;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  TransactionSortOption _sortOption = TransactionSortOption.latest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final Set<String> categories = <String>{};
    for (final TransactionEntry t in widget.transactions) {
      categories.add(t.category);
    }
    final List<String> sorted = categories.toList()..sort();
    return sorted;
  }

  List<TransactionEntry> get _filteredTransactions {
    final String query = _searchController.text.trim().toLowerCase();

    return widget.transactions.where((TransactionEntry t) {
      final DateTime txDate = DateTime(t.date.year, t.date.month, t.date.day);

      final bool matchesSearch =
          query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query);
      final bool matchesType = _selectedType == null || t.type == _selectedType;
      final bool matchesCategory =
          _selectedCategory == null || t.category == _selectedCategory;
      final bool matchesStart =
          _startDate == null || !txDate.isBefore(_startDate!);
      final bool matchesEnd = _endDate == null || !txDate.isAfter(_endDate!);

      return matchesSearch &&
          matchesType &&
          matchesCategory &&
          matchesStart &&
          matchesEnd;
    }).toList();
  }

  List<TransactionEntry> get _sortedFilteredTransactions {
    final List<TransactionEntry> items = List<TransactionEntry>.from(
      _filteredTransactions,
    );

    switch (_sortOption) {
      case TransactionSortOption.latest:
        items.sort((TransactionEntry a, TransactionEntry b) {
          return b.date.compareTo(a.date);
        });
      case TransactionSortOption.oldest:
        items.sort((TransactionEntry a, TransactionEntry b) {
          return a.date.compareTo(b.date);
        });
      case TransactionSortOption.highestAmount:
        items.sort((TransactionEntry a, TransactionEntry b) {
          return b.amount.compareTo(a.amount);
        });
      case TransactionSortOption.lowestAmount:
        items.sort((TransactionEntry a, TransactionEntry b) {
          return a.amount.compareTo(b.amount);
        });
    }

    return items;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initialDate =
        (isStart ? _startDate : _endDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
      _sortOption = TransactionSortOption.latest;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const Center(child: Text('No transactions yet.'));
    }

    final List<TransactionEntry> filtered = _sortedFilteredTransactions;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by title or category',
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    DropdownButton<TransactionType?>(
                      value: _selectedType,
                      hint: const Text('Type'),
                      items: const <DropdownMenuItem<TransactionType?>>[
                        DropdownMenuItem<TransactionType?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        DropdownMenuItem<TransactionType?>(
                          value: TransactionType.expense,
                          child: Text('Expense'),
                        ),
                        DropdownMenuItem<TransactionType?>(
                          value: TransactionType.income,
                          child: Text('Income'),
                        ),
                      ],
                      onChanged: (TransactionType? value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String?>(
                      value: _selectedCategory,
                      hint: const Text('Category'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((String c) {
                          return DropdownMenuItem<String?>(
                            value: c,
                            child: Text(c),
                          );
                        }),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<TransactionSortOption>(
                      value: _sortOption,
                      items: const <DropdownMenuItem<TransactionSortOption>>[
                        DropdownMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.latest,
                          child: Text('Latest'),
                        ),
                        DropdownMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.oldest,
                          child: Text('Oldest'),
                        ),
                        DropdownMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.highestAmount,
                          child: Text('Highest Amount'),
                        ),
                        DropdownMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.lowestAmount,
                          child: Text('Lowest Amount'),
                        ),
                      ],
                      onChanged: (TransactionSortOption? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _sortOption = value;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate == null
                            ? 'From'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      icon: const Icon(Icons.event),
                      label: Text(
                        _endDate == null
                            ? 'To'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No transactions match the filters.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final TransactionEntry t = filtered[index];
                    final bool isExpense = t.type == TransactionType.expense;
                    final Color amountColor = isExpense
                        ? const Color(0xFFD64545)
                        : const Color(0xFF0E9F6E);

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: amountColor.withValues(alpha: 0.12),
                          child: Icon(
                            isExpense ? Icons.remove : Icons.add,
                            color: amountColor,
                          ),
                        ),
                        title: Text(t.title),
                        subtitle: Text(
                          '${t.category}  |  ${t.date.day}/${t.date.month}/${t.date.year}',
                        ),
                        trailing: Text(
                          '${isExpense ? '-' : '+'}${widget.currencySymbol}${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
