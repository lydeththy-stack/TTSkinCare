import 'package:url_launcher/url_launcher.dart';

class UrlUtil {
  Future<void> open(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}