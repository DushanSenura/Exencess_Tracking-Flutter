import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/transaction_entry.dart';

class ExportService {
  Future<String> exportCsv(List<TransactionEntry> transactions) async {
    final StringBuffer csv = StringBuffer('type,title,category,amount,date\n');
    for (final TransactionEntry t in transactions) {
      csv.writeln(
        '${t.type.name},"${t.title}",${t.category},${t.amount.toStringAsFixed(2)},${t.date.toIso8601String()}',
      );
    }

    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath =
        '${directory.path}${Platform.pathSeparator}transactions_export.csv';
    final File file = File(filePath);
    await file.writeAsString(csv.toString());
    return filePath;
  }

  Future<String> exportPdf({
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required List<TransactionEntry> transactions,
  }) async {
    final pw.Document document = pw.Document();

    document.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'Expense Trainer Pro - Financial Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Income: \$${totalIncome.toStringAsFixed(2)}'),
            pw.Text('Expense: \$${totalExpense.toStringAsFixed(2)}'),
            pw.Text('Balance: \$${balance.toStringAsFixed(2)}'),
            pw.SizedBox(height: 12),
            pw.Text(
              'Recent Transactions',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: <String>['Type', 'Title', 'Category', 'Amount', 'Date'],
              data: transactions
                  .take(15)
                  .map(
                    (TransactionEntry t) => <String>[
                      t.type.name,
                      t.title,
                      t.category,
                      '\$${t.amount.toStringAsFixed(2)}',
                      '${t.date.day}/${t.date.month}/${t.date.year}',
                    ],
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await document.save();
    if (Platform.isWindows || Platform.isLinux) {
      return _savePdfToFile(bytes);
    }

    try {
      await Printing.sharePdf(bytes: bytes, filename: 'financial_report.pdf');
      return 'shared';
    } on MissingPluginException {
      return _savePdfToFile(bytes);
    }
  }

  Future<String> _savePdfToFile(Uint8List bytes) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath =
        '${directory.path}${Platform.pathSeparator}financial_report.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }
}
