import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'session_view_model.dart';

class NotAuthorizedView extends StatelessWidget {
  const NotAuthorizedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This account does not have admin access.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<SessionViewModel>().signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
