import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

// Import remaining linked pages
import 'profile/reviews_page.dart';
import 'profile/emergency_page.dart';
import 'profile/events_page.dart';

class FamilyProfilePage extends StatefulWidget {
  const FamilyProfilePage({super.key});

  @override
  State<FamilyProfilePage> createState() => _FamilyProfilePageState();
}

class _FamilyProfilePageState extends State<FamilyProfilePage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  // 🎨 Signature Theme Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  final name = TextEditingController();
  final phone = TextEditingController();
  final city = TextEditingController();
  final budget = TextEditingController();
  final preference = TextEditingController(text: 'caregiver');
  final skills = TextEditingController();
  final hours = TextEditingController();

  @override
  void dispose() {
    name.dispose(); phone.dispose(); city.dispose();
    budget.dispose(); preference.dispose();
    skills.dispose(); hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await api.updateProfile({
        'name': name.text.trim().isEmpty ? null : name.text.trim(),
        'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
        'city': city.text.trim().isEmpty ? null : city.text.trim(),
        'budget': double.tryParse(budget.text.trim()),
        'preference': preference.text.trim().isEmpty ? null : preference.text.trim(),
        'skills_required': skills.text.trim().isEmpty ? null : skills.text.trim(),
        'hours_needed': int.tryParse(hours.text.trim()),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated ✅'), 
          backgroundColor: _sage, 
          behavior: SnackBarBehavior.floating
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()), 
          backgroundColor: Colors.redAccent, 
          behavior: SnackBarBehavior.floating
        ),
      );
    }
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _deepNavy,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: FutureBuilder(
        future: api.getMyProfile(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _deepNavy));
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final p = (data['profile'] as Map?) ?? {};

          // Fill controllers with existing data
          if (name.text.isEmpty) name.text = (p['name'] ?? '').toString();
          if (phone.text.isEmpty) phone.text = (p['phone'] ?? '').toString();
          if (city.text.isEmpty) city.text = (p['city'] ?? '').toString();
          if (budget.text.isEmpty) budget.text = (p['budget'] ?? '').toString();
          if (preference.text.isEmpty) preference.text = (p['preference'] ?? 'caregiver').toString();
          if (skills.text.isEmpty) skills.text = (p['skills_required'] ?? '').toString();
          if (hours.text.isEmpty) hours.text = (p['hours_needed'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              _buildHeader(p['name'] ?? 'Family User'),
              const SizedBox(height: 32),
              
              _buildSection("Personal Information", [
                _buildField(name, "Full Name", Icons.person_outline),
                _buildField(phone, "Mobile Number", Icons.phone_outlined),
                _buildField(city, "Residence City", Icons.location_city_outlined),
              ]),

              const SizedBox(height: 24),
              
              _buildSection("Care Preferences", [
                _buildField(budget, "Monthly Budget", Icons.monetization_on_outlined, isNum: true),
                _buildField(preference, "Preference", Icons.favorite_border_rounded),
                _buildField(skills, "Required Skills", Icons.psychology_outlined, maxLines: 2),
                _buildField(hours, "Weekly Hours Needed", Icons.timer_outlined, isNum: true),
              ]),

              const SizedBox(height: 32),
              _buildSaveButton(),

              const SizedBox(height: 48),
              _buildSection("Safety & Activity", [
                _actionTile(Icons.star_outline_rounded, 'My Care Reviews', const ReviewsPage()),
                _actionTile(Icons.sos_rounded, 'Emergency Protocol', const EmergencyPage()),
                _actionTile(Icons.calendar_month_outlined, 'Scheduled Events', const EventsPage(), isLast: true),
              ], isActionCard: true),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String username) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: _deepNavy,
          child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', 
            style: const TextStyle(color: _cream, fontSize: 32, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _deepNavy)),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children, {bool isActionCard = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _denim, letterSpacing: 1.5)),
        ),
        Container(
          padding: isActionCard ? EdgeInsets.zero : const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon, {bool isNum = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _denim, size: 20),
          filled: true,
          fillColor: _cream.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _deepNavy,
          foregroundColor: _cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text('Update Profile Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, Widget page, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: _denim),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: _deepNavy)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _denim),
          onTap: () => _open(page),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        ),
        if (!isLast) const Divider(height: 1, indent: 60),
      ],
    );
  }
}