import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/employees/employee_list_screen.dart';
import 'features/employees/employee_repository.dart';
import 'features/employees/offline_status_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OfflineStatus()),
        ChangeNotifierProvider(create: (_) => EmployeeRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OfflineStatus status = context.read<OfflineStatus>();
      status.addListener(_onOfflineStatusChanged);
      _wasOffline = status.isOffline;
    });
  }

  @override
  void dispose() {
    context.read<OfflineStatus>().removeListener(_onOfflineStatusChanged);
    super.dispose();
  }

  void _onOfflineStatusChanged() {
    final isOffline = context.read<OfflineStatus>().isOffline;
    if (_wasOffline && !isOffline) {
      context.read<EmployeeRepository>().syncPendingOperations();
    }
    _wasOffline = isOffline;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const EmployeeListScreen(),
    );
  }
}
