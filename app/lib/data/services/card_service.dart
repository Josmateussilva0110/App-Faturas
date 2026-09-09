import '../../models/card_model.dart';
import '../api/api_response.dart';
import '../api/api_routes.dart';
import '../api/request.dart';

/// Endpoints de cartões.
///
/// Como nas compras, `create` e `update` respondem apenas com o id; use
/// `draft.withId(response.data!)` para remontar o objeto localmente.

CardModel _parseCard(Object? json) =>
    CardModel.fromJson((json! as Map).cast<String, dynamic>());

String _parseId(Object? json) => (json! as Map)['id'] as String;

/// `GET /cards`
Future<ApiResponse<List<CardModel>>> fetchCards() {
  return requestData<List<CardModel>>(
    endpoint: CardRoutes.cards,
    parse: (json) => (json! as List)
        .map((item) => CardModel.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false),
  );
}

/// `GET /cards/:id`
Future<ApiResponse<CardModel>> fetchCard(String id) {
  return requestData<CardModel>(
    endpoint: CardRoutes.card(id),
    parse: _parseCard,
  );
}

/// `POST /cards` — devolve o id do cartão criado.
Future<ApiResponse<String>> createCard(CardModel draft) {
  return requestData<String>(
    endpoint: CardRoutes.cards,
    method: 'POST',
    data: draft.toJson(),
    parse: _parseId,
  );
}

/// `PUT /cards/:id` — devolve o id do cartão atualizado.
Future<ApiResponse<String>> updateCard(CardModel card) {
  return requestData<String>(
    endpoint: CardRoutes.card(card.id),
    method: 'PUT',
    data: card.toJson(),
    parse: _parseId,
  );
}

/// `DELETE /cards/:id`
Future<ApiResponse<Object?>> deleteCard(String id) {
  return requestData<Object?>(
    endpoint: CardRoutes.card(id),
    method: 'DELETE',
  );
}
