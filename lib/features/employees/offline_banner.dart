import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'offline_status_provider.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.select<OfflineStatus, bool>(
      (status) => status.isOffline,
    );
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      color: Colors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline - changes will sync when connected',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
