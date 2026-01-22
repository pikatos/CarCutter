import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'employee_repository.dart';
import 'employee_model.dart';
import 'employee_details_screen.dart';
import 'employee_form_screen.dart';
import 'employee_list_state.dart';

extension ScaffoldHelper on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

extension EmployeeNavigation on BuildContext {
  void navigateToEmployeeDetails(Employee employee) async {
    await Navigator.push<Employee>(
      this,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailsScreen(employee: employee),
      ),
    );
  }

  void navigateToCreateEmployee() {
    Navigator.push<Employee>(
      this,
      MaterialPageRoute(builder: (context) => const EmployeeFormScreen()),
    );
  }

  void navigateToEditEmployee(Employee employee) {
    Navigator.push<Employee>(
      this,
      MaterialPageRoute(
        builder: (context) => EmployeeFormScreen(employee: employee),
      ),
    );
  }

  void showDeleteEmployeeDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<EmployeeListState>().deleteEmployee(employee.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class EmployeeListView extends StatelessWidget {
  final EmployeeRepository repository;

  const EmployeeListView({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmployeeListState(repository: repository),
      child: Builder(
        builder: (context) {
          final state = context.watch<EmployeeListState>();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.error != null) {
              context.showSnackBar('Error: ${state.error}');
            } else if (state.message != null) {
              context.showSnackBar(state.message!);
            }
            state.clearMessage();
          });

          return Scaffold(
            appBar: AppBar(title: const Text('Employees')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.navigateToCreateEmployee(),
              child: const Icon(Icons.add),
            ),
            body: _buildBody(state, context),
          );
        },
      ),
    );
  }

  Widget _buildBody(EmployeeListState state, BuildContext context) {
    if (state.isLoading && state.employees.isEmpty) {
      return _buildLoadingState();
    }

    if (state.error != null && state.employees.isEmpty) {
      return _buildErrorState(state, context);
    }

    if (state.employees.isEmpty) {
      return _buildEmptyState();
    }

    return _buildEmployeeList(state, context);
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(EmployeeListState state, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => state.loadEmployees(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No employees found'));
  }

  Widget _buildEmployeeList(EmployeeListState state, BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => state.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: state.employees.length,
        itemBuilder: (context, index) {
          final employee = state.employees[index];
          return EmployeeListRow(
            employee: employee,
            onTap: () => context.navigateToEmployeeDetails(employee),
            onDelete: () => context.showDeleteEmployeeDialog(context, employee),
          );
        },
      ),
    );
  }
}

class EmployeeListRow extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const EmployeeListRow({
    super.key,
    required this.employee,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(employee.name[0])),
      title: Text(employee.name),
      subtitle: Text('Age: ${employee.age}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
