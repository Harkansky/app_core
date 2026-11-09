import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web page in the system browser.
Future<bool> openWebPage(String url) async {
  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (error) {
    debugPrint('[app_core] Could not open $url: $error');
    return false;
  }
}

/// Opens the mail app with a pre-filled subject.
Future<bool> openSupportEmail(String email, {required String subject}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    query: 'subject=${Uri.encodeComponent(subject)}',
  );
  try {
    return await launchUrl(uri);
  } catch (error) {
    debugPrint('[app_core] Could not open mail app: $error');
    return false;
  }
}
