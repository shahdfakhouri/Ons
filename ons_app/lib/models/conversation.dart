class Conversation {
  final String id;
  final String elderName;
  final String familyName;
  final String lastMessageText;
  final DateTime lastMessageTime;

  Conversation({
    required this.id,
    required this.elderName,
    required this.familyName,
    required this.lastMessageText,
    required this.lastMessageTime,
  });
}
