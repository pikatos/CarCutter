import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'employee_repository.dart';
import 'employee_model.dart';
import 'employee_details_view.dart';
import 'employee_form_view.dart';
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
        builder: (context) => EmployeeDetailsView(employee: employee),
      ),
    );
  }

  void navigateToCreateEmployee() {
    Navigator.push<Employee>(
      this,
      MaterialPageRoute(builder: (context) => const EmployeeFormView()),
    );
  }

  void navigateToEditEmployee(Employee employee) {
    Navigator.push<Employee>(
      this,
      MaterialPageRoute(
        builder: (context) => EmployeeFormView(employee: employee),
      ),
    );
  }
}

class EmployeeListView extends StatefulWidget {
  final EmployeeRepository repository;

  const EmployeeListView({super.key, required this.repository});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  final _listKey = GlobalKey<AnimatedListState>();

  Widget _buildEmployeeTile(BuildContext context, Employee employee) {
    if (employee.id == -1) {
      return const SizedBox.shrink();
    }
    return Dismissible(
      key: ValueKey(employee.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await _showDeleteDialog(context, employee);
        return confirmed;
      },
      onDismissed: (direction) {
        context.read<EmployeeListState>().deleteEmployee(employee.id);
      },
      child: ListTile(
        leading: CircleAvatar(child: Text(employee.name[0])),
        title: Text(employee.name),
        subtitle: Text('Age: ${employee.age}'),
        onTap: () => context.navigateToEmployeeDetails(employee),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          EmployeeListState(repository: widget.repository, listKey: _listKey),
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
      child: AnimatedList(
        key: _listKey,
        padding: const EdgeInsets.only(bottom: 88),
        initialItemCount: state.employees.length,
        itemBuilder: (context, index, animation) {
          final employee = state.employees[index];
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: 0.0,
              child: _buildEmployeeTile(context, employee),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, Employee employee) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }
}
