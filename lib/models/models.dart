class Order {
  final String id;
  final String customerName;
  final String pickupAddress;
  final String deliveryAddress;
  final String status;
  final double payout;

  const Order({
    required this.id,
    required this.customerName,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.status,
    required this.payout,
  });
}

class DeliveryHistory {
  final String id;
  final String date;
  final String summary;
  final double amount;

  const DeliveryHistory({
    required this.id,
    required this.date,
    required this.summary,
    required this.amount,
  });
}
