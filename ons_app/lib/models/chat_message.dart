class ChatMessage {
  final String id;
  final String senderRole; // 'caregiver' or 'family'
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  bool get isFromCaregiver => senderRole == 'caregiver';
}
