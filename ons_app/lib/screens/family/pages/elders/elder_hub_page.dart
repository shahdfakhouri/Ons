import 'package:flutter/material.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/services/chat_h2h_api.dart';
import 'package:ons_app/screens/chat_h2h/chat_page.dart';

import 'elder_monitoring_page.dart';
import 'elder_location_page.dart';
import 'elder_visits_page.dart';
import 'elder_summaries_page.dart';
import 'elder_notes_page.dart';
import 'elder_contacts_page.dart';
import 'elder_consent_pin_page.dart';
import 'elder_gallery_page.dart';

class ElderHubPage extends StatefulWidget {
  final int elderId;
  final String elderName;

  const ElderHubPage({super.key, required this.elderId, required this.elderName});

  @override
  State<ElderHubPage> createState() => _ElderHubPageState();
}

class _ElderHubPageState extends State<ElderHubPage> {
  final _familyApi = FamilyApi();
  final _chatApi = ChatH2HApi();

  Future<void> _openChatWithCaregiver() async {
    try {
      final familyId = AuthService().myIdInt; // ✅ FIXED
      if (familyId == null) {
        showSnack(context, 'Missing family id (logout/login again).', isError: true);
        return;
      }

      final res = await _familyApi.getCaregiverContact(widget.elderId);

      Map<String, dynamic> caregiverMap = {};
      if (res['caregiver'] is Map) caregiverMap = Map<String, dynamic>.from(res['caregiver']);

      final dynamic rawId =
          caregiverMap['caregiver_id'] ??
          caregiverMap['id'] ??
          res['caregiver_id'] ??
          res['caregiverId'];

      final caregiverId = int.tryParse(rawId?.toString() ?? '');
      if (caregiverId == null) {
        showSnack(context, 'No caregiver assigned for this elder yet.', isError: true);
        return;
      }

      final conv = await _chatApi.createOrGetConversation(
        elderId: widget.elderId,
        caregiverId: caregiverId,
        familyId: familyId,
      );

      final conversationId = (conv['conversationId'] ?? '').toString();
      if (conversationId.isEmpty) {
        showSnack(context, 'Failed to create conversation.', isError: true);
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatH2HPage(conversationId: conversationId)),
      );
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, VoidCallback onTap) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    Widget tilePage(IconData icon, String title, Widget page) {
      return tile(icon, title, () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.elderName)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(widget.elderName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Elder ID: ${widget.elderId}'),
            ),
          ),
          const SizedBox(height: 10),

          const SectionTitle('Communication'),
          tile(Icons.chat_bubble_outline, 'Chat with caregiver', _openChatWithCaregiver),

          const SizedBox(height: 10),
          const SectionTitle('Elder tools'),
          tilePage(Icons.monitor_heart, 'Monitoring (Health / Meds)', ElderMonitoringPage(elderId: widget.elderId)),
          tilePage(Icons.location_on, 'Location (Latest / History / Safe zones)', ElderLocationPage(elderId: widget.elderId)),
          tilePage(Icons.calendar_month, 'Visits (Request & List)', ElderVisitsPage(elderId: widget.elderId)),
          tilePage(Icons.summarize, 'Daily Summaries + Comments', ElderSummariesPage(elderId: widget.elderId)),
          tilePage(Icons.note, 'Family Notes', ElderNotesPage(elderId: widget.elderId)),
          tilePage(Icons.photo_library, 'Gallery (List / Delete)', ElderGalleryPage(elderId: widget.elderId)),
          tilePage(Icons.contact_phone, 'Contacts (Caregiver/Home)', ElderContactsPage(elderId: widget.elderId)),
          tilePage(Icons.lock, 'Consent + Reset PIN', ElderConsentPinPage(elderId: widget.elderId)),
        ],
      ),
    );
  }
}
