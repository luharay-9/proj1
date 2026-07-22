import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

const privacyPolicyUrl =
    'https://doc-hosting.flycricket.io/shinpulse-privacy-policy/0410326e-36a6-4bb6-ac81-5530bda0bde0/privacy';
const termsAndConditionsUrl =
    'https://doc-hosting.flycricket.io/shinpulse-terms-of-use/2d07aaf9-96f7-4947-9356-73e8fe7eb17c/terms';

Future<void> openLegalDocument(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unable to open $title right now.')));
  }
}

class SignInLegalLinks extends StatelessWidget {
  const SignInLegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: AppColors.pulse,
      fontWeight: FontWeight.w800,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'By signing in, you agree to the ',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        TextButton(
          onPressed: () => openLegalDocument(
            context,
            url: termsAndConditionsUrl,
            title: 'Terms and Conditions',
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.pulse,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: linkStyle,
          ),
          child: const Text('Terms and Conditions'),
        ),
        const Text(
          ' and acknowledge the ',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        TextButton(
          onPressed: () => openLegalDocument(
            context,
            url: privacyPolicyUrl,
            title: 'Privacy Policy',
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.pulse,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: linkStyle,
          ),
          child: const Text('Privacy Policy'),
        ),
        const Text('.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}
