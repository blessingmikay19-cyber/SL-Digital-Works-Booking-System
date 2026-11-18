import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_router.dart';
import '../../data/models/service.dart';
import 'services_view_model.dart';

class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  Future<void> _open(BuildContext context, String path) async {
    final vm = context.read<ServicesViewModel>();
    final changed = await context.push<bool>(path);
    if (changed == true) vm.load();
  }

  Future<void> _toggle(BuildContext context, Service s, bool active) async {
    final ok = await context.read<ServicesViewModel>().setActive(s, active);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not update the service.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ServicesViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: vm.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, Routes.serviceNew),
        icon: const Icon(Icons.add),
        label: const Text('Add service'),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: vm.load, child: _list(context, vm)),
    );
  }

  Widget _list(BuildContext context, ServicesViewModel vm) {
    if (vm.error != null || vm.services.isEmpty) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vm.error ?? 'No services yet. Add your first one.'),
        ),
      ]);
    }
    const muted = TextStyle(color: Color(0xFF5B6C68));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
              for (final s in vm.services)
                Card(
                  color: s.active ? Colors.white : const Color(0xFFF1F3F0),
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFDCE3DF)),
                  ),
                  child: ListTile(
                    onTap: () => _open(context, Routes.service(s.id)),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${s.durationMinutes} min · ${s.priceLabel}'
                      '${s.description.isEmpty ? '' : '\n${s.description}'}'
                      '${s.active ? '' : '\nHidden from website'}',
                      style: muted,
                    ),
                    isThreeLine: s.description.isNotEmpty || !s.active,
                    trailing: Switch(
                      value: s.active,
                      onChanged: (v) => _toggle(context, s, v),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}
