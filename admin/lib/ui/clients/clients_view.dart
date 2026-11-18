import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_router.dart';
import 'clients_view_model.dart';

class ClientsView extends StatelessWidget {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientsViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: vm.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: vm.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name, email or phone',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: vm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(onRefresh: vm.load, child: _list(context, vm)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, ClientsViewModel vm) {
    final clients = vm.clients;
    if (vm.error != null || clients.isEmpty) {
      final message = vm.error ??
          (vm.hasAny
              ? 'No clients match your search.'
              : 'No clients yet. They appear when someone books on your website.');
      return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(message))]);
    }
    const muted = TextStyle(color: Color(0xFF5B6C68));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: clients.length,
      itemBuilder: (context, i) {
        final c = clients[i];
        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFDCE3DF)),
          ),
          child: ListTile(
            onTap: () => context.push(Routes.client(c.id)),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE9F2EE),
              foregroundColor: const Color(0xFF17645B),
              child: Text(c.initial),
            ),
            title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(c.phone.isEmpty ? c.email : '${c.email}\n${c.phone}'),
            isThreeLine: c.phone.isNotEmpty,
            trailing: Text('${c.bookingCount} ${c.bookingCount == 1 ? 'booking' : 'bookings'}',
                style: muted),
          ),
        );
      },
    );
  }
}
