import '../../models/salary.dart';
import '../api/api_response.dart';
import '../api/api_routes.dart';
import '../api/request.dart';

/// Endpoints de salários.
///
/// Como nos cartões, `create` e `update` respondem apenas com o id; use
/// `draft.withId(response.data!)` para remontar o objeto localmente.

String _parseId(Object? json) => (json! as Map)['id'] as String;

/// `GET /salaries`
Future<ApiResponse<List<Salary>>> fetchSalaries() {
  return requestData<List<Salary>>(
    endpoint: SalaryRoutes.salaries,
    parse: (json) => (json! as List)
        .map((item) => Salary.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false),
  );
}

/// `POST /salaries` — devolve o id do salário criado.
Future<ApiResponse<String>> createSalary(Salary draft) {
  return requestData<String>(
    endpoint: SalaryRoutes.salaries,
    method: 'POST',
    data: draft.toJson(),
    parse: _parseId,
  );
}

/// `PUT /salaries/:id` — devolve o id do salário atualizado.
Future<ApiResponse<String>> updateSalary(Salary salary) {
  return requestData<String>(
    endpoint: SalaryRoutes.salary(salary.id),
    method: 'PUT',
    data: salary.toJson(),
    parse: _parseId,
  );
}

/// `DELETE /salaries/:id`
Future<ApiResponse<Object?>> deleteSalary(String id) {
  return requestData<Object?>(
    endpoint: SalaryRoutes.salary(id),
    method: 'DELETE',
  );
}
