import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'service_form_view_model.dart';

class ServiceFormView extends StatefulWidget {
  const ServiceFormView({super.key});

  @override
  State<ServiceFormView> createState() => _ServiceFormViewState();
}

class _ServiceFormViewState extends State<ServiceFormView> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _duration = TextEditingController(text: '60');
  final _price = TextEditingController(text: '0');
  bool _active = true;
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save(ServiceFormViewModel vm) async {
    final ok = await vm.save(
      name: _name.text,
      description: _description.text,
      duration: _duration.text,
      price: _price.text,
      active: _active,
    );
    if (ok && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ServiceFormViewModel>();
    final s = vm.service;
    if (!vm.loading && !_seeded) {
      if (s != null) {
        _name.text = s.name;
        _description.text = s.description;
        _duration.text = '${s.durationMinutes}';
        _price.text = s.price == s.price.roundToDouble() ? '${s.price.toInt()}' : '${s.price}';
        _active = s.active;
      }
      _seeded = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text(vm.isNew ? 'Add service' : 'Edit service')),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.loadError != null
              ? Center(child: Text(vm.loadError!))
              : _form(vm),
    );
  }

  Widget _form(ServiceFormViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: vm.errors['name'],
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Description (shown on the website)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    helperText: 'Changes apply to new bookings only.',
                    errorText: vm.errors['duration'],
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'Price (R, use 0 for free)',
                    errorText: vm.errors['price'],
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show on website'),
                subtitle: const Text('Turn off to hide it without deleting it.'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              if (vm.saveError != null) ...[
                const SizedBox(height: 8),
                Text(vm.saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: vm.saving ? null : () => _save(vm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(vm.saving ? 'Saving…' : 'Save service'),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
