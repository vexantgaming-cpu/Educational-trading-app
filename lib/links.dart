import 'package:url_launcher/url_launcher.dart';

/// Opens a web address outside the app. Returns false if it could not.
typedef LinkOpener = Future<bool> Function(Uri uri);

/// Opens [uri] in the phone's browser.
Future<bool> openInBrowser(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
