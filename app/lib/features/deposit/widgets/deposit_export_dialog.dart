import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/salary.dart';
import '../../../state/app_state.dart';

/// "Exportar resumo" dialog for the Deposit screen: previews a shareable
/// receipt-style summary of the selected month, then either copies it as
/// tab-separated values (paste straight into a spreadsheet) or shares it as
/// a PNG image.
Future<void> showDepositExportDialog(
  BuildContext context, {
  required String monthLabel,
  required List<Salary> salaries,
  required double totalSalaries,
  required double ownTotal,
  required double afterCredit,
  required List<ExpenseRow> expenseRows,
  required double guardar,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DepositExportDialog(
      monthLabel: monthLabel,
      salaries: salaries,
      totalSalaries: totalSalaries,
      ownTotal: ownTotal,
      afterCredit: afterCredit,
      expenseRows: expenseRows,
      guardar: guardar,
    ),
  );
}

class _DepositExportDialog extends StatefulWidget {
  const _DepositExportDialog({
    required this.monthLabel,
    required this.salaries,
    required this.totalSalaries,
    required this.ownTotal,
    required this.afterCredit,
    required this.expenseRows,
    required this.guardar,
  });

  final String monthLabel;
  final List<Salary> salaries;
  final double totalSalaries;
  final double ownTotal;
  final double afterCredit;
  final List<ExpenseRow> expenseRows;
  final double guardar;

  @override
  State<_DepositExportDialog> createState() => _DepositExportDialogState();
}

class _DepositExportDialogState extends State<_DepositExportDialog> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  String _num(double value) => value.toStringAsFixed(2);

  String _buildTsv() {
    final rows = <String>['Categoria\tItem\tValor'];
    for (final salary in widget.salaries) {
      rows.add('Salário\t${salary.name}\t${_num(salary.value)}');
    }
    rows.add('Resumo\tTotal salários\t${_num(widget.totalSalaries)}');
    rows.add('Resumo\tMeu crédito no cartão\t-${_num(widget.ownTotal)}');
    rows.add('Resumo\tSaldo após crédito\t${_num(widget.afterCredit)}');
    for (final row in widget.expenseRows) {
      rows.add('Despesa\t${row.expense.name}\t-${_num(row.expense.value)}');
    }
    rows.add('Resumo\tGuardar\t${_num(widget.guardar)}');
    return rows.join('\n');
  }

  Future<void> _copyToSpreadsheet() async {
    await Clipboard.setData(ClipboardData(text: _buildTsv()));
    if (mounted) Navigator.of(context).pop();
    AppToast.success('Copiado! Cole numa planilha (Excel, Sheets...).');
  }

  Future<void> _shareAsImage() async {
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('boundary not ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('failed to encode png');
      final bytes = byteData.buffer.asUint8List();
      if (!mounted) return;
      Navigator.of(context).pop();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'resumo-financeiro.png')],
          text: 'Resumo financeiro — ${widget.monthLabel}',
        ),
      );
    } catch (_) {
      AppToast.error('Não foi possível gerar a imagem.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Exportar resumo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: _ReceiptCard(
                      monthLabel: widget.monthLabel,
                      salaries: widget.salaries,
                      totalSalaries: widget.totalSalaries,
                      ownTotal: widget.ownTotal,
                      afterCredit: widget.afterCredit,
                      expenseRows: widget.expenseRows,
                      guardar: widget.guardar,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _copyToSpreadsheet,
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Copiar para planilha'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _shareAsImage,
                    icon: _sharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.image_outlined),
                    label: Text(_sharing ? 'Gerando...' : 'Compartilhar como imagem'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White, theme-independent "receipt" layout — captured as the shared PNG,
/// so it should look the same (and legible) regardless of the app's own
/// light/dark mode.
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.monthLabel,
    required this.salaries,
    required this.totalSalaries,
    required this.ownTotal,
    required this.afterCredit,
    required this.expenseRows,
    required this.guardar,
  });

  final String monthLabel;
  final List<Salary> salaries;
  final double totalSalaries;
  final double ownTotal;
  final double afterCredit;
  final List<ExpenseRow> expenseRows;
  final double guardar;

  static const _accent = Color(0xFF297CEF);
  static const _text = Colors.black87;
  static const _muted = Colors.black45;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: _accent, size: 20),
              const SizedBox(width: 8),
              const Text('Fatura', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _text)),
              const Spacer(),
              Text(monthLabel, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          _header('Salários'),
          for (final salary in salaries) _line(salary.name, formatMoney(salary.value)),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _line('Total salários', formatMoney(totalSalaries), bold: true),
          _line('Meu crédito no cartão', '- ${formatMoney(ownTotal)}', color: const Color(0xFFB3261E)),
          _line('Saldo após crédito', formatMoney(afterCredit), bold: true, color: _accent),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _header('Despesas'),
          for (final row in expenseRows) _line(row.expense.name, '- ${formatMoney(row.expense.value)}'),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GUARDAR',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.5),
              ),
              Text(
                formatMoney(guardar),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.5),
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 13, color: color ?? _text, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: color ?? _text, fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
