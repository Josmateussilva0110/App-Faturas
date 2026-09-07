/// Validated output of [PurchaseFormFields], ready to become a `Purchase`.
class PurchaseFormValues {
  const PurchaseFormValues({
    required this.name,
    required this.amount,
    required this.installments,
    required this.isOther,
    required this.person,
    required this.cardId,
    required this.startOffset,
  });

  final String name;
  final double amount;
  final int installments;
  final bool isOther;
  final String person;
  final String cardId;
  final int startOffset;
}
