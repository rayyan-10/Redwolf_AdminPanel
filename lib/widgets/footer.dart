import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  Future<void> _launchRuditechUrl() async {
    final Uri url = Uri.parse('https://ruditech.com/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Built by',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _launchRuditechUrl,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Ruditech',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




