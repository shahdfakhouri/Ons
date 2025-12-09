import 'package:ons_app/models/chat_message.dart';
import 'package:ons_app/models/conversation.dart';

class ChatService {
  // later: pass caregiverId from auth
  Future<List<Conversation>> getCaregiverConversations(
      String caregiverId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Conversation(
        id: 'conv1',
        elderName: 'Um Ahmad',
        familyName: 'Daughter – Lina',
        lastMessageText: 'Thank you for today 🩵',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Conversation(
        id: 'conv2',
        elderName: 'Abu Youssef',
        familyName: 'Son – Ahmad',
        lastMessageText: 'Can you focus on his knee pain?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // different fake histories per conversation, just for demo
    if (conversationId == 'conv1') {
      return [
        ChatMessage(
          id: 'm1',
          senderRole: 'family',
          text: 'How was my mother today?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        ChatMessage(
          id: 'm2',
          senderRole: 'caregiver',
          text:
              'She was calm, blood pressure normal, and she walked a little 💚',
          timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
        ),
        ChatMessage(
          id: 'm3',
          senderRole: 'family',
          text: 'Thank you for today 🩵',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ];
    } else {
      return [
        ChatMessage(
          id: 'm4',
          senderRole: 'family',
          text: 'Can you focus on his knee pain?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'm5',
          senderRole: 'caregiver',
          text: 'Of course, I will check his pain level and mobility.',
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        ),
      ];
    }
  }

  // For now this just pretends to send.
  Future<bool> sendMessage({
    required String conversationId,
    required String text,
    required String senderRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

    Future<List<Conversation>> getFamilyConversations(String familyId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // For now we’ll return the same mock conversations.
    // Later you can filter by real familyId.
    return [
      Conversation(
        id: 'conv1',
        elderName: 'Um Ahmad',
        familyName: 'You',
        lastMessageText: 'Thank you for today 🩵',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Conversation(
        id: 'conv2',
        elderName: 'Abu Youssef',
        familyName: 'You',
        lastMessageText: 'Can you focus on his knee pain?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

}
