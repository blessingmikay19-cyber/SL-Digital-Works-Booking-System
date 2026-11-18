import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_router.dart';
import '../../data/models/blocked_time.dart';
import 'time_off_view_model.dart';

class TimeOffView extends StatelessWidget {
  const TimeOffView({super.key});

  Future<void> _add(BuildContext context) async {
    final vm = context.read<TimeOffViewModel>();
    final changed = await context.push<bool>(Routes.timeOffNew);
    if (changed == true) vm.load();
  }

  Future<void> _delete(BuildContext context, BlockedTime b) async {
    final vm = context.read<TimeOffViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this time off?'),
        content: Text('${b.reason.isEmpty ? 'Blocked time' : b.reason}\n${b.label}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final done = await vm.remove(b);
    if (!done && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not remove it.')));
    }
  }

  Future<void> _extend(BuildContext context) async {
    final added = await context.read<TimeOffViewModel>().extendLunch();
    if (!context.mounted) return;
    final message = added == null
        ? 'Could not extend lunch breaks.'
        : added == 0
            ? 'Lunch breaks are already up to date.'
            : 'Added $added lunch breaks.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TimeOffViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time off'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: vm.load, icon: const Icon(Icons.refresh)),
          PopupMenuButton<String>(
            enabled: !vm.busy,
            onSelected: (_) => _extend(context),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'lunch', child: Text('Extend lunch breaks (90 days)')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Add time off'),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: vm.load, child: _list(context, vm)),
    );
  }

  Widget _list(BuildContext context, TimeOffViewModel vm) {
    const muted = TextStyle(color: Color(0xFF5B6C68));
    final items = vm.visible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Show lunch breaks (${vm.lunchCount})'),
                value: vm.showLunch,
                onChanged: vm.setShowLunch,
              ),
              if (vm.error != null || items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    vm.error ??
                        'No time off scheduled. Use "Add time off" for holidays, leave or appointments.',
                    style: muted,
                  ),
                ),
              for (final b in items)
                Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFDCE3DF)),
                  ),
                  child: ListTile(
                    title: Text(b.reason.isEmpty ? 'Blocked time' : b.reason,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(b.label, style: muted),
                    trailing: IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, b),
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
