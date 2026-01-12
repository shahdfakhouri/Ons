class ElderProfile {
  final String name;
  final int? age;
  final String? gender;
  final double? fontSize;
  final String? language;
  final bool? voiceMode;

  ElderProfile({
    required this.name,
    this.age,
    this.gender,
    this.fontSize,
    this.language,
    this.voiceMode,
  });

  factory ElderProfile.fromJson(Map<String, dynamic> j) => ElderProfile(
        name: (j['name'] ?? '') as String,
        age: j['age'] is int ? j['age'] : int.tryParse('${j['age']}'),
        gender: j['gender']?.toString(),
        fontSize: (j['font_size'] is num) ? (j['font_size'] as num).toDouble() : double.tryParse('${j['font_size']}'),
        language: j['language']?.toString(),
        voiceMode: j['voice_mode'] == true || j['voice_mode'] == 1,
      );
}

class ElderConsent {
  final bool shareLocation;
  final bool shareHealth;
  final bool shareMedia;
  final bool shareSummary;

  ElderConsent({
    required this.shareLocation,
    required this.shareHealth,
    required this.shareMedia,
    required this.shareSummary,
  });

  factory ElderConsent.fromJson(Map<String, dynamic> j) => ElderConsent(
        shareLocation: j['share_location'] == true || j['share_location'] == 1,
        shareHealth: j['share_health'] == true || j['share_health'] == 1,
        shareMedia: j['share_media'] == true || j['share_media'] == 1,
        shareSummary: j['share_summary'] == true || j['share_summary'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'share_location': shareLocation,
        'share_health': shareHealth,
        'share_media': shareMedia,
        'share_summary': shareSummary,
      };
}
