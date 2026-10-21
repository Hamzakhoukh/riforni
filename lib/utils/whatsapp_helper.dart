import 'package:url_launcher/url_launcher.dart';

class WhatsappHelper {
  /// Validates if a phone number matches E.164 specifications (8 to 15 digits, optional leading +).
  static bool isValidE164(String? number) {
    if (number == null) return false;
    final trimmed = number.trim();
    if (trimmed.isEmpty) return false;
    final clean = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(clean);
  }

  /// Cleans phone number for wa.me URL (digits only, without leading +).
  static String cleanNumber(String number) {
    return number.replaceAll(RegExp(r'[^\d]'), '');
  }

  static Future<bool> sendWhatsApp(String number, String message) async {
    final cleaned = cleanNumber(number);
    if (cleaned.isEmpty) return false;
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleaned?text=$encoded');
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static Future<bool> sendEmail({
    required String email,
    required String subject,
    required String body,
  }) async {
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final url = Uri.parse('mailto:$email?subject=$encodedSubject&body=$encodedBody');
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url);
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}

