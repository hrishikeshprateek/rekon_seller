import 'dart:io';
import '../constants/branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

/// Simple in-app PDF viewer. Renders a local PDF [filePath] with swipe paging,
/// plus Save (to Downloads), Share and Print actions.
class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.filePath,
    this.title = 'Bill',
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  // Native channel that saves bytes into the public Downloads folder via
  // MediaStore (reused from order_detail_page).
  static const MethodChannel _filesChannel =
      MethodChannel('com.reckon.reckonbiz/files');

  bool _ready = false;
  bool _error = false;
  String _errorMsg = '';
  int _pages = 0;
  int _current = 0;
  bool _saving = false;

  /// Builds a safe PDF file name from the title (e.g. "Bill 2026.../SA-00242").
  String _fileName() {
    var base = widget.title
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (base.isEmpty) base = 'bill';
    return '$base.pdf';
  }

  /// Shares the bill PDF via the system share sheet.
  Future<void> _share() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.filePath, mimeType: 'application/pdf')],
        subject: widget.title,
        text: widget.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to share: $e')),
        );
      }
    }
  }

  /// Opens the system print dialog with the bill PDF, so the user can send it
  /// to any printer the OS knows about (Wi-Fi printer, "Save as PDF", or any
  /// printer with an Android print service).
  Future<void> _print() async {
    try {
      final bytes = await File(widget.filePath).readAsBytes();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _fileName(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to print: $e')),
        );
      }
    }
  }

  /// Saves the bill PDF into the device's Downloads folder (Android) or the
  /// app documents directory (iOS).
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await File(widget.filePath).readAsBytes();
      final fileName = _fileName();
      String savedAt;
      if (Platform.isAndroid) {
        savedAt = await _filesChannel.invokeMethod<String>(
              'saveToDownloads',
              {
                'fileName': fileName,
                'bytes': bytes,
                'mimeType': 'application/pdf',
              },
            ) ??
            'Downloads';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        savedAt = file.path;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill saved to $savedAt')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF424242),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Branding.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_ready && _pages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  '${_current + 1} / $_pages',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Save to Downloads',
            onPressed: (_ready && !_saving) ? _save : null,
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print',
            onPressed: _ready ? _print : null,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: _ready ? _share : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            // Wide Reckon bills: swipe horizontally to pan across the page,
            // keeping text at a legible width instead of clipping the right.
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            fitPolicy: FitPolicy.WIDTH,
            fitEachPage: true,
            onRender: (pages) {
              if (mounted) setState(() {
                _pages = pages ?? 0;
                _ready = true;
              });
            },
            onError: (e) {
              if (mounted) setState(() {
                _error = true;
                _errorMsg = e.toString();
              });
            },
            onPageError: (page, e) {
              if (mounted) setState(() {
                _error = true;
                _errorMsg = e.toString();
              });
            },
            onPageChanged: (page, total) {
              if (mounted) setState(() {
                _current = page ?? 0;
                _pages = total ?? _pages;
              });
            },
          ),
          if (_error)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to display the bill.${_errorMsg.isNotEmpty ? '\n$_errorMsg' : ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else if (!_ready)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
