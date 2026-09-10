import '../../models/card_statement.dart';
import '../api/api_response.dart';
import '../api/api_routes.dart';
import '../api/request.dart';

/// Endpoints das faturas informadas (conferência).
///
/// Não há `create` e `update` separados: `saveStatement` é um upsert na chave
/// natural (cartão, mês) e devolve apenas o id da linha gravada.

String _parseId(Object? json) => (json! as Map)['id'] as String;

/// `GET /statements` — todas as faturas do usuário, de todos os meses.
Future<ApiResponse<List<CardStatement>>> fetchStatements() {
  return requestData<List<CardStatement>>(
    endpoint: StatementRoutes.statements,
    parse: (json) => (json! as List)
        .map((item) => CardStatement.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false),
  );
}

/// `PUT /statements` — grava (ou sobrescreve) a fatura de um cartão/mês.
Future<ApiResponse<String>> saveStatement(CardStatement draft) {
  return requestData<String>(
    endpoint: StatementRoutes.statements,
    method: 'PUT',
    data: draft.toJson(),
    parse: _parseId,
  );
}

/// `DELETE /statements/:id`
Future<ApiResponse<Object?>> deleteStatement(String id) {
  return requestData<Object?>(
    endpoint: StatementRoutes.statement(id),
    method: 'DELETE',
  );
}
