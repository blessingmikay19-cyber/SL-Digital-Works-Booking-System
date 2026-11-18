import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/models/booking.dart';
import '../widgets/status_chip.dart';
import 'client_detail_view_model.dart';

class ClientDetailView extends StatefulWidget {
  const ClientDetailView({super.key});

  @override
  State<ClientDetailView> createState() => _ClientDetailViewState();
}

class _ClientDetailViewState extends State<ClientDetailView> {
  final _notes = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save(ClientDetailViewModel vm) async {
    final ok = await vm.saveNotes(_notes.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Notes saved.' : 'Could not save notes.')));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientDetailViewModel>();
    final c = vm.client;
    if (c != null && !_seeded) {
      _notes.text = c.notes;
      _seeded = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text(c?.fullName ?? 'Client')),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : (c == null)
              ? Center(child: Text(vm.error ?? 'Client not found.'))
              : _content(vm, c),
    );
  }

  Widget _content(ClientDetailViewModel vm, dynamic c) {
    const muted = TextStyle(color: Color(0xFF5B6C68));
    const heading = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
                const SizedBox(height: 8),
                Text(c.email),
                if (c.phone.isNotEmpty) Text(c.phone),
                const SizedBox(height: 8),
                Text('Client since ${dayLabel(c.createdAt)} · ${c.bookingCount} '
                    '${c.bookingCount == 1 ? 'booking' : 'bookings'}', style: muted),
              ])),
              const SizedBox(height: 16),
              const Text('Notes', style: heading),
              const SizedBox(height: 8),
              _box(Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                TextField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                      hintText: 'Private notes about this client', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: vm.saving ? null : () => _save(vm),
                  child: Text(vm.saving ? 'Saving…' : 'Save notes'),
                ),
              ])),
              const SizedBox(height: 24),
              const Text('Booking history', style: heading),
              const SizedBox(height: 8),
              if (vm.bookings.isEmpty) const Text('No bookings yet.', style: muted),
              for (final b in vm.bookings) _bookingTile(b),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _bookingTile(Booking b) {
    return _box(
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${dayLabel(b.start)} · ${hm(b.start)}–${hm(b.end)}',
                style: const TextStyle(color: Color(0xFF5B6C68))),
            if (b.notes.isNotEmpty)
              Text('Notes: ${b.notes}', style: const TextStyle(color: Color(0xFF5B6C68))),
          ]),
        ),
        StatusChip(b.status),
      ]),
      margin: const EdgeInsets.only(bottom: 8),
    );
  }

  Widget _box(Widget child, {EdgeInsets margin = EdgeInsets.zero}) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE3DF)),
      ),
      child: child,
    );
  }
}
