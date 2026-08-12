class RoseTransactionResult {
  const RoseTransactionResult({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    this.conversationId,
    this.note,
    this.updatedAt,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String? conversationId;
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory RoseTransactionResult.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final senderId = json['senderId']?.toString().trim() ?? '';
    final recipientId = json['recipientId']?.toString().trim() ?? '';
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (id.isEmpty ||
        senderId.isEmpty ||
        recipientId.isEmpty ||
        createdAt == null) {
      throw const FormatException('Rose transaction response is invalid.');
    }
    return RoseTransactionResult(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      conversationId: json['conversationId']?.toString(),
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: createdAt.toLocal(),
      updatedAt: DateTime.tryParse(
        json['updatedAt']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

class RoseSendResult {
  const RoseSendResult({required this.transaction, this.notificationId});

  final RoseTransactionResult transaction;
  final String? notificationId;

  factory RoseSendResult.fromJson(Map<String, dynamic> json) {
    final transaction = json['roseTransaction'];
    if (transaction is! Map) {
      throw const FormatException('Rose send response is invalid.');
    }
    final notification = json['notification'];
    return RoseSendResult(
      transaction: RoseTransactionResult.fromJson(
        transaction.cast<String, dynamic>(),
      ),
      notificationId: notification is Map
          ? notification['id']?.toString()
          : null,
    );
  }
}
