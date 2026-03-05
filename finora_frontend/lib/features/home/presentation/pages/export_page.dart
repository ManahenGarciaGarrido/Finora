/// Página de Exportación — RF-34 + RF-35
///
/// RF-34: Exportación de transacciones a CSV
///  - Selector de rango de fechas y tipo de transacción
///  - Descarga y compartir vía sistema nativo (share_plus)
///
/// RF-35: Generación de informes financieros en PDF
///  - Selector de período (mes/año/personalizado)
///  - Resumen ejecutivo, gastos por categoría y tabla de transacciones
///  - Compartir PDF vía sistema nativo
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart' as di;

/// RF-34 + RF-35: Página de exportación de transacciones y generación de PDF.
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  // ── Estado CSV ─────────────────────────────────────────────────────────────
  DateTime _csvFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _csvTo = DateTime.now();
  String _csvType = 'all'; // 'all', 'income', 'expense'

  // ── Estado PDF ─────────────────────────────────────────────────────────────
  String _pdfPeriod = 'month'; // 'month', 'year', 'custom'
  int _pdfYear = DateTime.now().year;
  int _pdfMonth = DateTime.now().month;
  DateTime _pdfFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _pdfTo = DateTime.now();

  bool _csvLoading = false;
  bool _pdfLoading = false;

  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _apiClient = di.sl<ApiClient>();

  // ── RF-34: Exportar CSV ────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    setState(() => _csvLoading = true);
    try {
      final fromStr = DateFormat('yyyy-MM-dd').format(_csvFrom);
      final toStr = DateFormat('yyyy-MM-dd').format(_csvTo);

      final params = <String, dynamic>{'from': fromStr, 'to': toStr};
      if (_csvType != 'all') params['type'] = _csvType;

      final response = await _apiClient.get(
        '/export/csv',
        queryParameters: params,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList((response.data as List<int>));
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final filename = 'finora_transacciones_$dateStr.csv';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'text/csv'),
      ], subject: 'Transacciones Finora — $filename');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar CSV: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _csvLoading = false);
    }
  }

  // ── RF-35: Exportar PDF ────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    setState(() => _pdfLoading = true);
    try {
      final params = <String, dynamic>{'period': _pdfPeriod};
      if (_pdfPeriod == 'month') {
        params['year'] = _pdfYear;
        params['month'] = _pdfMonth;
      } else if (_pdfPeriod == 'year') {
        params['year'] = _pdfYear;
      } else {
        params['from'] = DateFormat('yyyy-MM-dd').format(_pdfFrom);
        params['to'] = DateFormat('yyyy-MM-dd').format(_pdfTo);
      }

      final response = await _apiClient.get(
        '/export/pdf-data',
        queryParameters: params,
      );
      final data = response.data as Map<String, dynamic>;

      final pdfBytes = await _buildPdf(data);
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final filename = 'finora_informe_$dateStr.pdf';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/pdf'),
      ], subject: 'Informe Financiero Finora');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  /// RF-35: Construye documento PDF con resumen ejecutivo + categorías + tabla.
  Future<Uint8List> _buildPdf(Map<String, dynamic> data) async {
    final doc = pw.Document();
    final meta = data['metadata'] as Map<String, dynamic>;
    final summary = data['summary'] as Map<String, dynamic>;
    final categories = (data['gastos_por_categoria'] as List)
        .cast<Map<String, dynamic>>();
    final transactions = (data['transacciones'] as List)
        .cast<Map<String, dynamic>>();

    final fmtMoney = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );
    final primaryC = PdfColor.fromHex('#0F172A');
    final successC = PdfColor.fromHex('#059669');
    final errorC = PdfColor.fromHex('#DC2626');
    final grayC = PdfColor.fromHex('#6B7280');
    final lightGrayC = PdfColor.fromHex('#F3F4F6');
    final borderC = PdfColor.fromHex('#E5E7EB');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'FINORA',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryC,
                  ),
                ),
                pw.Text(
                  'Informe Financiero',
                  style: pw.TextStyle(fontSize: 12, color: grayC),
                ),
              ],
            ),
            pw.Divider(color: primaryC),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Período: ${meta['period_label']}',
                  style: pw.TextStyle(fontSize: 9, color: grayC),
                ),
                pw.Text(
                  'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 9, color: grayC),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (_) => [
          // Resumen ejecutivo
          pw.Text(
            'Resumen Ejecutivo',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryC,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _statBox(
                'Ingresos',
                fmtMoney.format(summary['total_ingresos']),
                successC,
              ),
              pw.SizedBox(width: 8),
              _statBox(
                'Gastos',
                fmtMoney.format(summary['total_gastos']),
                errorC,
              ),
              pw.SizedBox(width: 8),
              _statBox(
                'Balance',
                fmtMoney.format((summary['balance'] as num).toDouble()),
                (summary['balance'] as num) >= 0 ? successC : errorC,
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Gastos por categoría
          if (categories.isNotEmpty) ...[
            pw.Text(
              'Gastos por Categoría',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryC,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: borderC, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGrayC),
                  children: [
                    _cell('Categoría', bold: true),
                    _cell('Total', bold: true),
                    _cell('Transacciones', bold: true),
                  ],
                ),
                ...categories.map(
                  (c) => pw.TableRow(
                    children: [
                      _cell(c['categoria'] as String),
                      _cell(fmtMoney.format((c['total'] as num).toDouble())),
                      _cell('${c['transacciones']}'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Tabla de transacciones
          if (transactions.isNotEmpty) ...[
            pw.Text(
              'Transacciones del Período',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryC,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: borderC, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGrayC),
                  children: [
                    _cell('Fecha', bold: true),
                    _cell('Descripción', bold: true),
                    _cell('Categoría', bold: true),
                    _cell('Importe', bold: true),
                  ],
                ),
                ...transactions.map((t) {
                  final isExp = t['tipo'] == 'expense';
                  return pw.TableRow(
                    children: [
                      _cell(t['fecha'] as String),
                      _cell(t['descripcion'] as String),
                      _cell(t['categoria'] as String),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          '${isExp ? "-" : "+"}${fmtMoney.format((t['cantidad'] as num).toDouble())}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: isExp ? errorC : successC,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],

          pw.SizedBox(height: 16),
          pw.Divider(color: grayC),
          pw.Center(
            child: pw.Text(
              'Finora — Tu gestor financiero personal',
              style: pw.TextStyle(fontSize: 8, color: grayC),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _statBox(String label, String value, PdfColor color) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );

  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
  );

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text('Exportar datos', style: AppTypography.titleMedium()),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'Exportar a CSV',
            subtitle: 'Ideal para Excel u otras hojas de cálculo',
            icon: Icons.table_chart_rounded,
            iconColor: AppColors.info,
            children: [
              Text(
                'Rango de fechas',
                style: AppTypography.labelSmall(color: AppColors.gray500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateBtn(
                      'Desde',
                      _csvFrom,
                      (d) => setState(() => _csvFrom = d),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateBtn(
                      'Hasta',
                      _csvTo,
                      (d) => setState(() => _csvTo = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tipo',
                style: AppTypography.labelSmall(color: AppColors.gray500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(
                    'Todos',
                    'all',
                    _csvType,
                    AppColors.info,
                    (v) => setState(() => _csvType = v),
                  ),
                  _filterChip(
                    'Ingresos',
                    'income',
                    _csvType,
                    AppColors.info,
                    (v) => setState(() => _csvType = v),
                  ),
                  _filterChip(
                    'Gastos',
                    'expense',
                    _csvType,
                    AppColors.info,
                    (v) => setState(() => _csvType = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _csvLoading ? null : _exportCsv,
                  icon: _csvLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _csvLoading ? 'Generando...' : 'Exportar y compartir CSV',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'Informe PDF',
            subtitle: 'Informe profesional con resumen y tablas',
            icon: Icons.picture_as_pdf_rounded,
            iconColor: AppColors.error,
            children: [
              Text(
                'Período',
                style: AppTypography.labelSmall(color: AppColors.gray500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(
                    'Mes',
                    'month',
                    _pdfPeriod,
                    AppColors.error,
                    (v) => setState(() => _pdfPeriod = v),
                  ),
                  _filterChip(
                    'Año',
                    'year',
                    _pdfPeriod,
                    AppColors.error,
                    (v) => setState(() => _pdfPeriod = v),
                  ),
                  _filterChip(
                    'Personalizado',
                    'custom',
                    _pdfPeriod,
                    AppColors.error,
                    (v) => setState(() => _pdfPeriod = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_pdfPeriod == 'month') ...[
                Row(
                  children: [
                    Expanded(child: _yearDropdown()),
                    const SizedBox(width: 8),
                    Expanded(child: _monthDropdown()),
                  ],
                ),
              ] else if (_pdfPeriod == 'year') ...[
                _yearDropdown(),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _dateBtn(
                        'Desde',
                        _pdfFrom,
                        (d) => setState(() => _pdfFrom = d),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dateBtn(
                        'Hasta',
                        _pdfTo,
                        (d) => setState(() => _pdfTo = d),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _pdfLoading ? null : _exportPdf,
                  icon: _pdfLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(
                    _pdfLoading
                        ? 'Generando PDF...'
                        : 'Generar y compartir PDF',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleSmall()),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.gray100),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBtn(
    String label,
    DateTime date,
    ValueChanged<DateTime> onChanged,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await _pickDate(date);
        if (picked != null) onChanged(picked);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(color: AppColors.gray300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall(color: AppColors.gray500),
          ),
          Text(_dateFmt.format(date), style: AppTypography.bodySmall()),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    String current,
    Color color,
    ValueChanged<String> onSelect,
  ) {
    final selected = current == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelect(value),
      selectedColor: color.withValues(alpha: 0.12),
      checkmarkColor: color,
      labelStyle: AppTypography.labelSmall(
        color: selected ? color : AppColors.gray600,
      ),
    );
  }

  Widget _yearDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _pdfYear,
      decoration: InputDecoration(
        labelText: 'Año',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: List.generate(
        5,
        (i) => DateTime.now().year - i,
      ).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
      onChanged: (v) => setState(() => _pdfYear = v!),
    );
  }

  Widget _monthDropdown() {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Sept.',
      'Octubre',
      'Nov.',
      'Dic.',
    ];
    return DropdownButtonFormField<int>(
      initialValue: _pdfMonth,
      decoration: InputDecoration(
        labelText: 'Mes',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: List.generate(
        12,
        (i) => DropdownMenuItem(value: i + 1, child: Text(months[i])),
      ),
      onChanged: (v) => setState(() => _pdfMonth = v!),
    );
  }
}
