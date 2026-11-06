import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _pink = Color(0xFFFF5FA2);

/// In-app privacy and help content, available from the account screen.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <(String, String)>[
    ('1. Information We Collect', '''Depending on how you use It’s Giving, we may collect:

Account Information
• Email address
• Authentication information
• Basic profile information you choose to provide

You may also be able to use certain parts of the app through anonymous authentication.

Photos and Images
It’s Giving includes features that allow you to upload or capture images, including images used for AI face and aesthetic analysis, personalized recommendations, wardrobe and outfit analysis, and AI-generated plans and guidance. Images are processed to provide the requested features. We do not sell your personal photos or use them for advertising.

App and Usage Information
We may collect information about features you use, preferences and selected aesthetics, plans and progress, subscription status, and basic technical information needed to operate and improve the app.

AI Interactions
When you use AI-powered features, information you provide may be processed by our AI services to generate responses, recommendations, plans, or analysis.'''),
    ('2. How We Use Your Information', '''We use collected information to:
• Provide and personalize It’s Giving’s features
• Generate aesthetic and style recommendations
• Provide AI Coach responses
• Create personalized lifestyle and glow-up plans
• Analyze uploaded images when you request an image-based feature
• Maintain your account and app data
• Process subscriptions and purchases
• Improve app performance, reliability, and security
• Detect and prevent misuse or unauthorized activity
• Provide customer support

We do not sell your personal information.'''),
    ('3. Photo and AI Processing', '''Some It’s Giving features require image processing.

When you submit a photo for analysis, the image may first undergo security and processing checks before being sent to the relevant AI service to perform the requested analysis.

Photos are used for the purpose of providing the feature you requested and are not intended to be publicly displayed.

Because AI services may be involved in processing your requests, information submitted to an AI feature may be transmitted securely to the services necessary to provide that feature.'''),
    ('4. Third-Party Services', '''It’s Giving uses trusted third-party services to operate certain parts of the application. These may include services for authentication and account management, secure cloud storage and databases, AI processing, subscription and payment management, and app analytics, security, and technical infrastructure.

These services may process information according to their own privacy policies and applicable laws.'''),
    ('5. Subscriptions and Payments', '''It’s Giving may offer free and paid subscription plans.

Payments and subscription management are handled through the applicable app-store payment system and/or subscription services used by It’s Giving. We do not directly receive or store your full credit-card number.

Your subscription status may be shared with our app infrastructure so that we can provide the features included with your selected plan.'''),
    ('6. Data Security', '''We use reasonable technical and organizational measures to help protect your information against unauthorized access, loss, misuse, or disclosure.

However, no internet-based service can guarantee absolute security.'''),
    ('7. Data Retention', '''We retain information for as long as reasonably necessary to provide our services, maintain your account, comply with legal obligations, resolve disputes, and enforce our agreements.

You may request deletion of your account and associated personal information as described below.'''),
    ('8. Your Choices and Data Deletion', '''You may request that we delete your account and associated personal information.

To request account deletion, contact us through the support information on our Support page. When a valid deletion request is received, we will take reasonable steps to delete or anonymize information associated with your account, subject to information that we may be required to retain for legal, security, or legitimate business purposes.'''),
    ('9. Children’s Privacy', '''It’s Giving is not intended for children under the age required by applicable law to independently consent to data processing.

We do not knowingly collect personal information from children in violation of applicable laws.'''),
    ('10. International Data Processing', '''It’s Giving may use service providers that process information in countries other than the country in which you live.

By using the app, you acknowledge that information may be processed in locations where our service providers operate, subject to applicable privacy laws.'''),
    ('11. Changes to This Privacy Policy', '''We may update this Privacy Policy from time to time as It’s Giving evolves.

When changes are made, we will update the Last Updated date on this page. Continued use of the app after changes become effective means you acknowledge the updated policy.'''),
    ('12. Contact Us', '''If you have questions about privacy, your data, or account deletion, please contact us through the It’s Giving Support page.

It’s Giving — Privacy & Support
Last Updated: November 6, 2026'''),
  ];

  @override
  Widget build(BuildContext context) => _DocumentPage(
    title: 'Privacy Policy',
    subtitle: 'Last Updated: November 6, 2026',
    sections: _sections,
  );
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _email = 'williamlebbie509@gmail.com';
  static const _sections = <(String, String)>[
    ('My AI feature isn’t working', '''Please check that you have a stable internet connection and that you are using the latest version of It’s Giving.

If the problem continues, contact support and tell us your device model, operating system, which feature you were using, and what happened or what error appeared.'''),
    ('My subscription isn’t showing', '''If you purchased a subscription but your premium features are not active, first try using the Restore Purchases option in the app.

If that doesn’t work, contact support and include the email associated with your It’s Giving account. Please do not send your full payment-card information.'''),
    ('I want to delete my account', '''You can request deletion of your It’s Giving account and associated personal information by contacting our support team. Include the email address associated with your account so we can locate it.'''),
    ('I have a problem with a photo or AI analysis', '''Tell us which feature you were using and what went wrong. If possible, include a screenshot of the problem.

Please do not send sensitive personal information that isn’t necessary to resolve the issue.'''),
  ];

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _email, queryParameters: {
      'subject': 'It’s Giving Support',
    });
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your email app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => _DocumentPage(
    title: 'It’s Giving Support',
    subtitle: 'Need help with It’s Giving? We’re here to help.',
    sections: _sections,
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Support', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('For technical problems, account issues, subscription problems, privacy questions, or account deletion requests:'),
        const SizedBox(height: 8),
        SelectableText('Email: $_email'),
        const SizedBox(height: 8),
        const Text('We aim to review support requests as soon as reasonably possible.'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _contactSupport(context),
          icon: const Icon(Icons.email_outlined),
          label: const Text('Email Support'),
        ),
        const SizedBox(height: 20),
        Text('Privacy', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('For information about how It’s Giving collects, uses, and protects information, see the Privacy Policy.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          icon: const Icon(Icons.privacy_tip_outlined),
          label: const Text('Read Privacy Policy'),
        ),
        const SizedBox(height: 20),
        Text('About It’s Giving', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('It’s Giving is an AI-powered aesthetic and personal style companion designed to help you explore your aesthetic, build personalized plans, improve your style, and work toward your personal goals.\n\nIt’s Giving — Your vibe. Your style. Your goals.'),
      ],
    ),
  );
}

class _DocumentPage extends StatelessWidget {
  const _DocumentPage({required this.title, required this.subtitle, required this.sections, this.footer});

  final String title;
  final String subtitle;
  final List<(String, String)> sections;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF3FA),
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(section.$1, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: _pink)),
                const SizedBox(height: 8),
                SelectableText(section.$2, style: const TextStyle(height: 1.5)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (footer != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: footer!)),
      ],
    ),
  );
}
