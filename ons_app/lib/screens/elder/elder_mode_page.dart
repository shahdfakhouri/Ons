import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';

class ElderModePage extends StatefulWidget {
  final String elderName;

  /// For now this is just a text like:
  /// "اليوم الساعة ٤:٠٠ مساءً - زيارة سارة (الممرضة)"
  final String? nextVisitText;

  const ElderModePage({
    super.key,
    required this.elderName,
    this.nextVisitText,
  });

  @override
  State<ElderModePage> createState() => _ElderModePageState();
}

class _ElderModePageState extends State<ElderModePage> {
  String? _selectedMood; // "very_good", "good", "ok", "sad", "very_sad"

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl, // 👈 Arabic layout
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // good on tablet & web
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'السلام عليكم، ${widget.elderName} 🌿',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.deepNavy,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(now),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Next visit card
                    _NextVisitCard(
                      nextVisitText: widget.nextVisitText ??
                          'الساعة ٤:٠٠ مساءً - زيارة سارة (الممرضة)',
                    ),
                    const SizedBox(height: 20),

                    // Mood row
                    Text(
                      'مزاجي اليوم',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.deepNavy,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _MoodRow(
                      selectedMood: _selectedMood,
                      onMoodSelected: (moodKey) {
                        setState(() => _selectedMood = moodKey);

                        // later: send mood to backend
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'شكراً، تم تسجيل مزاجك اليوم 💚',
                              textDirection: TextDirection.rtl,
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Main actions
                    Text(
                      'ماذا نعمل اليوم؟',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.deepNavy,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Big buttons grid
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ActionCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'تحدث مع أنس!',
                          subtitle: 'تحدثي مع رفيقك الذكي بلطف وبساطة.',
                          onTap: () {
                            // TODO: open AI companion chat screen
                          },
                        ),
                        _ActionCard(
                          icon: Icons.mosque_outlined,
                          title: 'الركن الروحي',
                          subtitle: 'آيات، أذكار، وحديث قصير لليوم.',
                          onTap: () {
                            // TODO: open spiritual corner screen
                          },
                        ),
                        _ActionCard(
                          icon: Icons.extension_outlined,
                          title: 'لعبة الذاكرة',
                          subtitle: 'لعبة بسيطة لتنشيط الذاكرة.',
                          onTap: () {
                            // TODO: open memory game
                          },
                        ),
                        _ActionCard(
                          icon: Icons.music_note_outlined,
                          title: 'اقتراح اليوم',
                          subtitle: 'نشيد أو مقطع هادئ يناسب ذوقك.',
                          onTap: () {
                            // TODO: open daily suggestion (or link)
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // VERY simple formatting just to show something nice.
    // You can later replace with intl for Arabic months, etc.
    final hours = dt.hour.toString().padLeft(2, '0');
    final minutes = dt.minute.toString().padLeft(2, '0');
    final date = '${dt.day}/${dt.month}/${dt.year}';
    return '$date - $hours:$minutes';
  }
}

class _NextVisitCard extends StatelessWidget {
  final String nextVisitText;

  const _NextVisitCard({required this.nextVisitText});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.sage.withOpacity(0.4),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppTheme.denim,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الزيارة القادمة',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.deepNavy,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  nextVisitText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withOpacity(0.8),
                      ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String> onMoodSelected;

  const _MoodRow({
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoodItemData('very_good', '😍', 'ممتاز'),
      _MoodItemData('good', '😊', 'جيد'),
      _MoodItemData('ok', '😐', 'عادي'),
      _MoodItemData('sad', '😔', 'حزين'),
      _MoodItemData('very_sad', '😢', 'متعب'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((m) {
        final isSelected = selectedMood == m.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => onMoodSelected(m.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.sage.withOpacity(0.4)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.denim
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.label,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MoodItemData {
  final String key;
  final String emoji;
  final String label;

  _MoodItemData(this.key, this.emoji, this.label);
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 280, // good size on mobile + web
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.onSurface.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.sage.withOpacity(0.4),
                child: Icon(icon, color: AppTheme.denim),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepNavy,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
