# CarCutter Employee Manager

A Flutter employee management app demonstrating clean architecture, stream-based state management, and smooth list animations.

## Features

- List all employees with animated insert/delete
- View employee details (live updates via streams)
- Create/edit employees
- Swipe-to-delete with confirmation
- Offline-first with local caching
- Optimistic UI updates with automatic rollback on failure

## Architecture

### Layered Design

```
┌─────────────────────────────────────┐
│           Views (UI Layer)          │
│  employee_list_view.dart            │
│  employee_details_view.dart         │
│  employee_form_view.dart            │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│           State Layer               │
│  employee_list_state.dart           │
│  ChangeNotifier, coordinates repo   │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│         Repository Layer            │
│  employee_repository.dart           │
│  CRUD + stream + optimistic updates │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│         Data Sources                │
│  employee_api.dart (HTTP)           │
│  employee_local_storage.dart (Cache)│
└─────────────────────────────────────┘
```

### Key Patterns

| Pattern | Implementation | Purpose |
|---------|----------------|---------|
| **Repository Pattern** | `EmployeeRepository` | Single source of truth, coordinates API + local storage |
| **Stream-based Events** | `StreamController<EmployeeChange>` | Decoupled change propagation |
| **Optimistic Updates** | CRUD methods | Immediate UI updates, rollback on failure |
| **Provider Pattern** | `ChangeNotifierProvider` | State management across widget tree |
| **Sealed Classes** | `EmployeeChange{Created,Updated,Deleted}` | Type-safe change events |

### Data Flow

**Read Operations:**
```
View → State.loadEmployees() → Repository.fetchEmployees() 
→ yield local cache → yield API response → State updates UI
```

**Write Operations (Fire-and-Forget):**
```
View.deleteEmployee(id) → State.removeAt() [immediate] 
→ Repository.delete(id).ignore() [async, no await]
```

**Stream Rollback Pattern:**
1. Optimistic update (UI immediately reflects change)
2. Repository emits `EmployeeChange` via stream
3. If API fails, repository emits compensating change:
   - Create failed → `EmployeeChangeDeleted`
   - Update failed → `EmployeeChangeUpdated(prevLocal)`
   - Delete failed → `EmployeeChangeCreated(employee)`

## Project Structure

```
lib/
├── main.dart                      # Bootstrap, MultiProvider
├── common/
│   ├── animated_list_model.dart   # AnimatedList wrapper
│   ├── invalid_http_response.dart # HTTP error wrapper
│   └── lock.dart                  # Concurrency utility
└── features/employees/
    ├── employee_model.dart        # Data models, JSON serialization
    ├── employee_api.dart          # HTTP client (dummy.restapiexample.com)
    ├── employee_local_storage.dart # SharedPreferences persistence
    ├── employee_repository.dart   # Business logic + persistence
    ├── employee_list_state.dart   # List state management
    ├── employee_list_view.dart    # Main screen
    ├── employee_details_view.dart # Read-only detail view
    └── employee_form_view.dart    # Create/edit form
```

## Running Tests

```bash
flutter test --no-pub
```

All 55 tests pass, covering:
- API integration
- Model serialization
- Local storage persistence
- Repository operations
- View rendering and interactions

## Dependencies

- `provider` - State management
- `http` - HTTP client
- `path_provider` - Local storage paths

## Technical Notes

- **API**: Uses [Dummy REST API](https://dummy.restapiexample.com/) for testing
- **Animations**: 300ms insert, 250ms delete via `AnimatedList`
- **Sorting**: Auto-sorts by employee name after every change
- **Offline Support**: Local cache serves data immediately, synced with API
