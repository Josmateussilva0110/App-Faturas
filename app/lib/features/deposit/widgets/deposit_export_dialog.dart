import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/salary.dart';
import '../../../state/app_state.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/split_bar.dart';
import 'salary_split.dart';

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
  required double totalExpenses,
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
      totalExpenses: totalExpenses,
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
    required this.totalExpenses,
    required this.guardar,
  });

  final String monthLabel;
  final List<Salary> salaries;
  final double totalSalaries;
  final double ownTotal;
  final double afterCredit;
  final List<ExpenseRow> expenseRows;
  final double totalExpenses;
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
    rows.add('Resumo\tCartão no mês\t-${_num(widget.ownTotal)}');
    rows.add('Resumo\tSaldo após o cartão\t${_num(widget.afterCredit)}');
    for (final row in widget.expenseRows) {
      rows.add('Despesa\t${row.expense.name}\t-${_num(row.expense.value)}');
    }
    if (widget.expenseRows.isNotEmpty) {
      rows.add('Resumo\tTotal despesas\t-${_num(widget.totalExpenses)}');
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
    return AppDialog(
      title: 'Exportar resumo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: RepaintBoundary(
              key: _boundaryKey,
              // Tema claro fixo, com o próprio Material: a imagem sai igual
              // com o app no escuro, e o Material troca também o estilo de
              // texto herdado do diálogo, que é escuro.
              child: Theme(
                data: AppTheme.light(),
                child: Material(
                  color: Colors.white,
                  child: _ReceiptCard(
                monthLabel: widget.monthLabel,
                salaries: widget.salaries,
                totalSalaries: widget.totalSalaries,
                ownTotal: widget.ownTotal,
                afterCredit: widget.afterCredit,
                expenseRows: widget.expenseRows,
                totalExpenses: widget.totalExpenses,
                guardar: widget.guardar,
                  ),
                ),
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
    );
  }
}

/// A imagem compartilhada: o mesmo desenho da tela de Depositar — Guardar
/// em destaque, para onde vai o salário, e o detalhe embaixo —, num fundo
/// claro fixo para ler bem em qualquer conversa, independente do tema do app.
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.monthLabel,
    required this.salaries,
    required this.totalSalaries,
    required this.ownTotal,
    required this.afterCredit,
    required this.expenseRows,
    required this.totalExpenses,
    required this.guardar,
  });

  final String monthLabel;
  final List<Salary> salaries;
  final double totalSalaries;
  final double ownTotal;
  final double afterCredit;
  final List<ExpenseRow> expenseRows;
  final double totalExpenses;
  final double guardar;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    // Verde para o que entra e vermelho para o que sai, como na tela.
    final income = palette.iconTint(AppColors.hueSavings);
    final outgo = scheme.error;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Hero(amount: guardar, totalSalaries: totalSalaries, monthLabel: monthLabel),
          const SizedBox(height: AppSpacing.lg),
          Text('Para onde vai o salário', style: context.text.title),
          const SizedBox(height: AppSpacing.md),
          SplitBar(
            shares: salarySplit(card: ownTotal, expenses: totalExpenses, savings: guardar),
            total: totalSalaries,
            fullLegend: true,
            emptyMessage: 'Sem salário lançado.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(title: 'Salários', total: formatMoney(totalSalaries), totalColor: income),
          for (final salary in salaries) _Line(label: salary.name, value: formatMoney(salary.value)),
          _Line(label: 'Cartão no mês', value: '- ${formatMoney(ownTotal)}', color: outgo),
          if (expenseRows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _Section(title: 'Despesas fixas', total: '- ${formatMoney(totalExpenses)}', totalColor: outgo),
            for (final row in expenseRows)
              _Line(label: row.expense.name, value: '- ${formatMoney(row.expense.value)}'),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text('Faturas', style: context.text.caption.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

/// O bloco grafite do topo, igual ao card de Guardar da tela.
class _Hero extends StatelessWidget {
  const _Hero({required this.amount, required this.totalSalaries, required this.monthLabel});

  final double amount;
  final double totalSalaries;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = palette.onHero;
    final negative = amount < 0;

    final String detail;
    if (totalSalaries <= 0) {
      detail = 'Sem salário lançado';
    } else if (negative) {
      detail = 'Faltam ${formatMoney(-amount)} para fechar o mês';
    } else {
      detail = '${(amount / totalSalaries * 100).round()}% do salário';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.hero, palette.heroGradientEnd(palette.hero)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Guardar', style: context.text.field.copyWith(color: fg.withValues(alpha: 0.7))),
              ),
              // Aqui o mês fica: na imagem não há seletor em volta dizendo
              // de qual mês é.
              Text(monthLabel, style: context.text.caption.copyWith(color: fg.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatMoney(amount),
            style: context.text.hero.copyWith(fontSize: 30, color: negative ? palette.overLimitOnHero : fg),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            detail,
            style: context.text.caption.copyWith(
              color: negative ? palette.overLimitOnHero : fg.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de uma seção do detalhe, com o total à direita.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.total, required this.totalColor});

  final String title;
  final String total;
  final Color totalColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.label)),
          Text(total, style: context.text.label.copyWith(color: totalColor)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = context.text.field.copyWith(fontSize: 13, color: color ?? muted);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1, style: style)),
          const SizedBox(width: AppSpacing.smPlus),
          Text(value, style: style.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
