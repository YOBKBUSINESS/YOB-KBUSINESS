import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Service for generating PDF reports from data.
class PdfExportService {
  PdfExportService._();

  static final _currencyFormat = NumberFormat('#,###', 'fr_FR');

  static String _fcfa(num amount) =>
      '${_currencyFormat.format(amount)} FCFA';

  // ── Generic Table PDF ──

  /// Build a PDF from column headers and rows of strings.
  static Future<Uint8List> generateTablePdf({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now());

    // Split rows into pages of 25 each
    const rowsPerPage = 25;
    final pages = <List<List<String>>>[];
    for (var i = 0; i < rows.length; i += rowsPerPage) {
      pages.add(rows.sublist(
          i, i + rowsPerPage > rows.length ? rows.length : i + rowsPerPage));
    }

    if (pages.isEmpty) pages.add([]);

    for (var pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'YOB K BUSINESS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#2E7D32'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(title,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          )),
                      pw.Text(subtitle,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          )),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Généré le $now',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(
                          'Page ${pageIdx + 1} / ${pages.length}',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColor.fromHex('#2E7D32')),
              pw.SizedBox(height: 8),

              // Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2E7D32'),
                ),
                headerAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: headers,
                data: pages[pageIdx],
              ),

              pw.Spacer(),
              // Footer
              pw.Divider(color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('YOB K BUSINESS — Gestion Agricole',
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColors.grey600)),
                  pw.Text('Total: ${rows.length} enregistrements',
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  // ── Financial Report PDF ──

  /// Generate a financial report for a given month.
  static Future<Uint8List> generateFinancialReportPdf({
    required Map<String, dynamic> reportData,
    required int year,
    required int month,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now());
    final monthName = DateFormat('MMMM yyyy', 'fr_FR')
        .format(DateTime(year, month));

    final totalIncome = (reportData['totalIncome'] as num?)?.toDouble() ?? 0;
    final totalExpense = (reportData['totalExpense'] as num?)?.toDouble() ?? 0;
    final balance = totalIncome - totalExpense;
    final txCount = reportData['transactionCount'] as int? ?? 0;
    final categories =
        (reportData['categories'] as List<dynamic>?) ?? [];
    final topTx =
        (reportData['topTransactions'] as List<dynamic>?) ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'YOB K BUSINESS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2E7D32'),
                  ),
                ),
                pw.Text('Généré le $now',
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColor.fromHex('#2E7D32')),
          ],
        ),
        build: (context) => [
          pw.Text(
            'Rapport Financier — $monthName',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),

          // Summary boxes
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('Revenus', _fcfa(totalIncome), '#388E3C'),
              _summaryBox('Dépenses', _fcfa(totalExpense), '#D32F2F'),
              _summaryBox(
                'Solde',
                _fcfa(balance),
                balance >= 0 ? '#388E3C' : '#D32F2F',
              ),
              _summaryBox('Transactions', '$txCount', '#1976D2'),
            ],
          ),
          pw.SizedBox(height: 20),

          // Category breakdown
          if (categories.isNotEmpty) ...[
            pw.Text('Répartition par Catégorie',
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#2E7D32')),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              headers: ['Catégorie', 'Type', 'Montant', 'Nb'],
              data: categories.map((c) {
                final cat = c as Map<String, dynamic>;
                return [
                  cat['category']?.toString() ?? '',
                  cat['type'] == 'income' ? 'Revenu' : 'Dépense',
                  _fcfa((cat['total'] as num?)?.toDouble() ?? 0),
                  '${cat['count'] ?? 0}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Top transactions
          if (topTx.isNotEmpty) ...[
            pw.Text('Top Transactions',
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#2E7D32')),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              headers: ['Description', 'Type', 'Catégorie', 'Montant', 'Date'],
              data: topTx.map((t) {
                final tx = t as Map<String, dynamic>;
                return [
                  tx['description']?.toString() ?? '',
                  tx['type'] == 'income' ? 'Revenu' : 'Dépense',
                  tx['category']?.toString() ?? '',
                  _fcfa((tx['amount'] as num?)?.toDouble() ?? 0),
                  _formatDate(tx['date']?.toString()),
                ];
              }).toList(),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ── Investor Report PDF ──

  static Future<Uint8List> generateInvestorReportPdf({
    required List<Map<String, dynamic>> investors,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'YOB K BUSINESS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2E7D32'),
                  ),
                ),
                pw.Text('Généré le $now',
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Divider(color: PdfColor.fromHex('#2E7D32')),
          ],
        ),
        build: (context) => [
          pw.Text(
            'Rapport Investisseurs',
            style:
                pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#2E7D32')),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            headers: [
              'Nom',
              'Organisation',
              'Montant Investi',
              'Retour Attendu',
              'Projet',
            ],
            data: investors.map((inv) {
              return [
                inv['name']?.toString() ?? '',
                inv['organization']?.toString() ?? '',
                _fcfa((inv['amount_invested'] as num?)?.toDouble() ?? 0),
                '${inv['expected_return'] ?? 0}%',
                inv['project_name']?.toString() ?? '-',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Helpers ──

  static pw.Widget _summaryBox(String label, String value, String colorHex) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex(colorHex)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromHex(colorHex),
              )),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              )),
        ],
      ),
    );
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
