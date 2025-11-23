class Alert {
  final String id;
  final String elderId;
  final String message;
  final DateTime timestamp;
  final bool isResolved;

  Alert({
    required this.id,
    required this.elderId,
    required this.message,
    required this.timestamp,
    required this.isResolved,
  });
}
