import '../../models/expense.dart';
import '../api/api_response.dart';
import '../api/api_routes.dart';
import '../api/request.dart';

/// Endpoints de despesas fixas.
///
/// Como nos cartões, `create` e `update` respondem apenas com o id; use
/// `draft.withId(response.data!)` para remontar o objeto localmente.

String _parseId(Object? json) => (json! as Map)['id'] as String;

/// `GET /expenses`
Future<ApiResponse<List<Expense>>> fetchExpenses() {
  return requestData<List<Expense>>(
    endpoint: ExpenseRoutes.expenses,
    parse: (json) => (json! as List)
        .map((item) => Expense.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false),
  );
}

/// `POST /expenses` — devolve o id da despesa criada.
Future<ApiResponse<String>> createExpense(Expense draft) {
  return requestData<String>(
    endpoint: ExpenseRoutes.expenses,
    method: 'POST',
    data: draft.toJson(),
    parse: _parseId,
  );
}

/// `PUT /expenses/:id` — devolve o id da despesa atualizada.
Future<ApiResponse<String>> updateExpense(Expense expense) {
  return requestData<String>(
    endpoint: ExpenseRoutes.expense(expense.id),
    method: 'PUT',
    data: expense.toJson(),
    parse: _parseId,
  );
}

/// `DELETE /expenses/:id`
Future<ApiResponse<Object?>> deleteExpense(String id) {
  return requestData<Object?>(
    endpoint: ExpenseRoutes.expense(id),
    method: 'DELETE',
  );
}
