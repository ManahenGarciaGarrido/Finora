import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/ocr_bloc.dart';
import '../bloc/ocr_event.dart';
import '../bloc/ocr_state.dart';
import '../../domain/entities/extracted_receipt_entity.dart';
import '../../domain/entities/csv_preview_entity.dart';
import '../../../transactions/presentation/pages/add_transaction_page.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer();
  ExtractedReceiptEntity? _extracted;
  CsvPreviewEntity? _csvPreview;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String? _scannedImagePath; // Ruta de la foto escaneada para adjuntarla

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _textRecognizer.close();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => di.sl<OcrBloc>(),
      child: BlocConsumer<OcrBloc, OcrState>(
        listener: (ctx, state) {
          if (state is ReceiptExtracted) {
            setState(() {
              _extracted = state.receipt;
              _amountCtrl.text = state.receipt.amount?.toStringAsFixed(2) ?? '';
              _descCtrl.text = state.receipt.description;
              _dateCtrl.text = state.receipt.date;
            });
          } else if (state is ReceiptImported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.receiptImported),
                backgroundColor: AppColors.success,
              ),
            );
            setState(() => _extracted = null);
          } else if (state is CsvParsed) {
            setState(() => _csvPreview = state.preview);
            if (state.preview.rows.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'No se detectaron transacciones. Comprueba que el archivo tiene columnas de fecha, concepto e importe.',
                  ),
                  backgroundColor: AppColors.warning,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          } else if (state is CsvImported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${s.importConfirmed}: ${state.imported}  |  ${s.skipDuplicates}: ${state.skipped}',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            setState(() => _csvPreview = null);
          } else if (state is OcrError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (ctx, state) {
          final loading = state is OcrLoading;
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceLight,
              elevation: 0,
              title: Text(s.ocrTitle, style: AppTypography.titleMedium()),
              leading: const BackButton(),
              bottom: TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: s.scanReceipt),
                  Tab(text: s.importStatement),
                ],
              ),
            ),
            body: Builder(
              builder: (bctx) {
                final responsive = ResponsiveUtils(bctx);
                final tabBody = loading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _buildReceiptTab(ctx, s),
                          _buildCsvTab(ctx, s),
                        ],
                      );
                if (responsive.isTablet) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: tabBody,
                    ),
                  );
                }
                return tabBody;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptTab(BuildContext ctx, dynamic s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.scanReceiptDesc,
            style: AppTypography.bodyMedium(color: AppColors.gray600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ctx, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(s.fromCamera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ctx, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(s.fromGallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _pickImageFile(ctx),
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(s.fromFile),
          ),
          if (_extracted != null) ...[
            const SizedBox(height: 24),
            Text(s.extractedData, style: AppTypography.titleSmall()),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: s.extractedAmount,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: s.extractedMerchant,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateCtrl,
              decoration: InputDecoration(
                labelText: s.extractedDate,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                final amount = double.tryParse(_amountCtrl.text);
                if (amount == null) return;
                // Navegar a AddTransactionPage con los datos pre-rellenados y la foto adjunta
                DateTime? parsedDate;
                try {
                  final parts = _dateCtrl.text.split('-');
                  if (parts.length == 3) {
                    parsedDate = DateTime(
                      int.parse(parts[0]),
                      int.parse(parts[1]),
                      int.parse(parts[2]),
                    );
                  }
                } catch (_) {}
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionPage(
                      initialAmount: amount,
                      initialDescription: _descCtrl.text,
                      initialCategory: _extracted?.suggestedCategory,
                      initialDate: parsedDate,
                      initialPhotoPath: _scannedImagePath,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(s.confirmTransaction),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCsvTab(BuildContext ctx, dynamic s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.importStatementDesc,
            style: AppTypography.bodyMedium(color: AppColors.gray600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bancos compatibles:',
                  style: AppTypography.labelSmall(color: AppColors.infoDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'BBVA · Santander · CaixaBank · ING · Bankinter · Sabadell · '
                  'Openbank · N26 · Revolut · y cualquier CSV, TXT o PDF bancario.',
                  style: AppTypography.bodySmall(color: AppColors.infoDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickCsv(ctx),
                  icon: const Icon(Icons.table_chart_rounded),
                  label: const Text('CSV / TXT'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickPdf(ctx),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('PDF Bancario'),
                ),
              ),
            ],
          ),
          if (_csvPreview != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${s.importedTransactions}: ${_csvPreview!.rows.length}',
                  style: AppTypography.titleSmall(),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        for (final r in _csvPreview!.rows) {
                          r.selected = true;
                        }
                      }),
                      child: Text(s.selectAll),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        for (final r in _csvPreview!.rows) {
                          r.selected = false;
                        }
                      }),
                      child: Text(s.deselectAll),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _csvPreview!.rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final row = _csvPreview!.rows[i];
                return CheckboxListTile(
                  value: row.selected,
                  onChanged: (v) => setState(() => row.selected = v ?? false),
                  title: Text(
                    row.description,
                    style: AppTypography.bodyMedium(),
                  ),
                  subtitle: Text(row.date ?? ''),
                  secondary: Text(
                    row.amount.toStringAsFixed(2),
                    style: AppTypography.titleSmall(color: AppColors.primary),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final selected = _csvPreview!.rows
                    .where((r) => r.selected)
                    .toList();
                if (selected.isEmpty) return;
                ctx.read<OcrBloc>().add(
                  ImportCsvRows(selected, skipDuplicates: true),
                );
              },
              child: Text(s.importSelected),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext ctx, ImageSource source) async {
    final s = AppLocalizations.of(ctx);
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      setState(() => _scannedImagePath = file.path);
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(s.scanningReceipt),
          duration: const Duration(seconds: 1),
        ),
      );
      final inputImage = InputImage.fromFilePath(file.path);
      final recognized = await _textRecognizer.processImage(inputImage);
      final text = recognized.text;
      if (text.trim().isEmpty) {
        if (!ctx.mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(s.noTextDetected),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (!ctx.mounted) return;
      ctx.read<OcrBloc>().add(ExtractReceiptText(text));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  /// Pick an image file (jpg/png/webp) from the filesystem for OCR.
  Future<void> _pickImageFile(BuildContext ctx) async {
    final s = AppLocalizations.of(ctx);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;
      setState(() => _scannedImagePath = path);
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(s.scanningReceipt),
          duration: const Duration(seconds: 1),
        ),
      );
      final inputImage = InputImage.fromFilePath(path);
      final recognized = await _textRecognizer.processImage(inputImage);
      final text = recognized.text;
      if (text.trim().isEmpty) {
        if (!ctx.mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(s.noTextDetected),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (!ctx.mounted) return;
      ctx.read<OcrBloc>().add(ExtractReceiptText(text));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _pickCsv(BuildContext ctx) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      String? content;
      final bytes = result.files.first.bytes;
      final path = result.files.first.path;

      if (bytes != null) {
        // UTF-8 primero, latin-1 (ISO-8859-1) como fallback (bancos españoles)
        try {
          content = utf8.decode(bytes);
        } catch (_) {
          content = latin1.decode(bytes);
        }
      } else if (path != null) {
        final file = File(path);
        try {
          content = await file.readAsString(encoding: utf8);
        } catch (_) {
          final raw = await file.readAsBytes();
          try {
            content = utf8.decode(raw, allowMalformed: false);
          } catch (_) {
            content = latin1.decode(raw);
          }
        }
      }

      if (content == null || content.trim().isEmpty) return;
      if (!ctx.mounted) return;
      ctx.read<OcrBloc>().add(ParseCsv(content));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _pickPdf(BuildContext ctx) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null && result.files.first.path != null) {
        bytes = await File(result.files.first.path!).readAsBytes();
      }
      if (bytes == null) return;

      final base64Content = base64Encode(bytes);
      if (!ctx.mounted) return;
      ctx.read<OcrBloc>().add(ParsePdf(base64Content));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }
}
