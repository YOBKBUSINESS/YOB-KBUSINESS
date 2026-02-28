import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Cross-platform helper to save / share exported files (PDF, CSV).
class ExportHelper {
  ExportHelper._();

  /// Show a dialog to choose export format, then run the export.
  static Future<void> showExportDialog({
    required BuildContext context,
    required String title,
    required Future<Uint8List> Function() onPdf,
    required Future<List<int>> Function() onCsv,
    required String fileBaseName,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Exporter : $title',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              subtitle: const Text('Rapport formaté pour impression'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('CSV / Excel'),
              subtitle:
                  const Text('Données tabulaires pour analyse'),
              onTap: () => Navigator.pop(ctx, 'csv'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    try {
      if (choice == 'pdf') {
        final bytes = await onPdf();
        // printing package handles all platforms (web + mobile + desktop)
        await Printing.sharePdf(bytes: bytes, filename: '$fileBaseName.pdf');
      } else {
        final bytes = await onCsv();
        // Share CSV via share_plus (supports web, mobile, desktop)
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                Uint8List.fromList(bytes),
                name: '$fileBaseName.csv',
                mimeType: 'text/csv',
              ),
            ],
          ),
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export réussi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'export: $e')),
        );
      }
    }
  }

  /// Quick export as PDF only (no dialog).
  static Future<void> exportPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: '$fileName.pdf');
  }

  /// Quick export as CSV only (no dialog).
  static Future<void> exportCsv({
    required List<int> bytes,
    required String fileName,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: '$fileName.csv',
            mimeType: 'text/csv',
          ),
        ],
      ),
    );
  }
}
