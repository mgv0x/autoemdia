import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/errors/error_mapper.dart';
import '../../../../../core/services/ad_manager.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/providers/analytics_provider.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../../vehicle/domain/vehicle_type_config.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../domain/expense_entity.dart';
import '../controllers/expense_controller.dart';

class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({super.key, this.expense, this.initialCategory});

  final ExpenseEntity? expense;
  final String? initialCategory;

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _description;
  late final TextEditingController _amount;
  String? _category;
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _category = e?.category ?? widget.initialCategory;
    _description = TextEditingController(text: e?.description ?? '');
    _amount = TextEditingController(
      text: e?.amount == null ? '' : e!.amount.toStringAsFixed(2),
    );
    _date = e?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vehicle = ref.read(activeVehicleProvider).value;
    if (vehicle == null) {
      showAppSnackBar(context, 'Nenhum veículo ativo.', isError: true);
      return;
    }
    final amount = Validators.parseMoney(_amount.text);
    if (amount == null) {
      showAppSnackBar(context, 'Valor inválido.', isError: true);
      return;
    }

    final existing = widget.expense;
    final entity = ExpenseEntity(
      id: existing?.id ?? const Uuid().v4(),
      vehicleId: vehicle.id,
      category: _category ?? 'Outros',
      description: _description.text.trim(),
      amount: amount,
      expenseDate: _date,
    );

    final controller = ref.read(expenseFormControllerProvider.notifier);
    final saved = _isEditing
        ? await controller.update(entity)
        : await controller.create(entity);

    if (!mounted) return;
    if (saved != null) {
      ref.read(analyticsServiceProvider).expenseCreated();
      final isPremium = ref.read(isPremiumProvider).value ?? false;
      context.pop(saved);
      AdManager.showInterstitialOnActionCompleted(
        origin: 'expense_form_saved',
        isPremium: isPremium,
      );
    } else {
      final err = ref.read(expenseFormControllerProvider).error;
      showAppSnackBar(context, handleError(err ?? '').message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(expenseFormControllerProvider).isLoading;
    final vehicle = ref.watch(activeVehicleProvider).value;
    final config = vehicle != null
        ? VehicleTypeConfig.of(vehicle.type)
        : VehicleTypeConfig.carConfig;
    final availableCategories =
        config.expenseCategories.contains(_category) || _category == null
            ? config.expenseCategories
            : [_category!, ...config.expenseCategories];

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar gasto' : 'Novo gasto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: availableCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) =>
                      v == null ? 'Selecione uma categoria.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => Validators.required(v, 'Descrição'),
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: Abastecimento completo',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.money,
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text('Data: ${_formatDate(_date)}'),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar gasto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
