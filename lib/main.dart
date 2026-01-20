import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/employees/employee_list_screen.dart';
import 'features/employees/employee_repository.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<EmployeeRepository>(create: (_) => EmployeeRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
