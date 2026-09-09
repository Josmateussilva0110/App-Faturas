import '../../models/purchase.dart';
import '../api/api_response.dart';
import '../api/api_routes.dart';
import '../api/request.dart';

/// Endpoints de compras.
///
/// `create` e `update` respondem apenas com o id — o resto do objeto o
/// cliente já enviou. Use `draft.withId(response.data!)` para remontá-lo sem
/// uma segunda ida à rede.

Purchase _parsePurchase(Object? json) =>
    Purchase.fromJson((json! as Map).cast<String, dynamic>());

String _parseId(Object? json) => (json! as Map)['id'] as String;

/// `GET /purchases`
Future<ApiResponse<List<Purchase>>> fetchPurchases() {
  return requestData<List<Purchase>>(
    endpoint: PurchaseRoutes.purchases,
    parse: (json) => (json! as List)
        .map((item) => Purchase.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false),
  );
}

/// `GET /purchases/:id`
Future<ApiResponse<Purchase>> fetchPurchase(String id) {
  return requestData<Purchase>(
    endpoint: PurchaseRoutes.purchase(id),
    parse: _parsePurchase,
  );
}

/// `POST /purchases` — devolve o id da compra criada.
Future<ApiResponse<String>> createPurchase(Purchase draft) {
  return requestData<String>(
    endpoint: PurchaseRoutes.purchases,
    method: 'POST',
    data: draft.toJson(),
    parse: _parseId,
  );
}

/// `PUT /purchases/:id` — devolve o id da compra atualizada.
Future<ApiResponse<String>> updatePurchase(Purchase purchase) {
  return requestData<String>(
    endpoint: PurchaseRoutes.purchase(purchase.id),
    method: 'PUT',
    data: purchase.toJson(),
    parse: _parseId,
  );
}

/// `DELETE /purchases/:id`
Future<ApiResponse<Object?>> deletePurchase(String id) {
  return requestData<Object?>(
    endpoint: PurchaseRoutes.purchase(id),
    method: 'DELETE',
  );
}
