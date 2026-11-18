import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import 'time_off_form_view_model.dart';

class TimeOffFormView extends StatefulWidget {
  const TimeOffFormView({super.key});

  @override
  State<TimeOffFormView> createState() => _TimeOffFormViewState();
}

class _TimeOffFormViewState extends State<TimeOffFormView> {
  final _reason = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  bool _allDay = true;
  TimeOfDay _from = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 17, minute: 0);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickDate({required bool isStart}) async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
        if (_end.isBefore(_start)) _start = _end;
      }
    });
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(context: context, initialTime: isFrom ? _from : _to);
    if (picked != null) setState(() => isFrom ? _from = picked : _to = picked);
  }

  String _t(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save(TimeOffFormViewModel vm) async {
    final ok = await vm.save(
      startDate: _start,
      endDate: _end,
      allDay: _allDay,
      startMinutes: _from.hour * 60 + _from.minute,
      endMinutes: _to.hour * 60 + _to.minute,
      reason: _reason.text,
    );
    if (ok && mounted) context.pop(true);
  }

  Widget _pickerRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TimeOffFormViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Add time off')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _reason,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    hintText: 'e.g. Public holiday, Leave, Dentist',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _pickerRow('Start date', dayLabel(_start), () => _pickDate(isStart: true)),
                const SizedBox(height: 16),
                _pickerRow('End date', dayLabel(_end), () => _pickDate(isStart: false)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('All day'),
                  value: _allDay,
                  onChanged: (v) => setState(() => _allDay = v),
                ),
                if (!_allDay) ...[
                  Row(children: [
                    Expanded(child: _pickerRow('From', _t(_from), () => _pickTime(isFrom: true))),
                    const SizedBox(width: 16),
                    Expanded(child: _pickerRow('Until', _t(_to), () => _pickTime(isFrom: false))),
                  ]),
                  const SizedBox(height: 8),
                ],
                const Text('Times are in South Africa time (SAST).',
                    style: TextStyle(color: Color(0xFF5B6C68))),
                if (vm.error != null) ...[
                  const SizedBox(height: 12),
                  Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: vm.saving ? null : () => _save(vm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(vm.saving ? 'Saving…' : 'Save time off'),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
