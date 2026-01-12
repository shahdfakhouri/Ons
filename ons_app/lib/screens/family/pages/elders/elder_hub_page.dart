import 'package:flutter/material.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

import 'elder_monitoring_page.dart';
import 'elder_location_page.dart';
import 'elder_visits_page.dart';
import 'elder_summaries_page.dart';
import 'elder_notes_page.dart';
import 'elder_contacts_page.dart';
import 'elder_consent_pin_page.dart';
import 'elder_gallery_page.dart';

class ElderHubPage extends StatelessWidget {
  final int elderId;
  final String elderName;

  const ElderHubPage({super.key, required this.elderId, required this.elderName});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, Widget page) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(elderName)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(elderName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Elder ID: $elderId'),
            ),
          ),
          const SizedBox(height: 10),
          const SectionTitle('Elder tools'),
          tile(Icons.monitor_heart, 'Monitoring (Health / Meds)', ElderMonitoringPage(elderId: elderId)),
          tile(Icons.location_on, 'Location (Latest / History / Safe zones)', ElderLocationPage(elderId: elderId)),
          tile(Icons.calendar_month, 'Visits (Request & List)', ElderVisitsPage(elderId: elderId)),
          tile(Icons.summarize, 'Daily Summaries + Comments', ElderSummariesPage(elderId: elderId)),
          tile(Icons.note, 'Family Notes', ElderNotesPage(elderId: elderId)),
          tile(Icons.photo_library, 'Gallery (List / Delete)', ElderGalleryPage(elderId: elderId)),
          tile(Icons.contact_phone, 'Contacts (Caregiver/Home)', ElderContactsPage(elderId: elderId)),
          tile(Icons.lock, 'Consent + Reset PIN', ElderConsentPinPage(elderId: elderId)),
        ],
      ),
    );
  }
}
