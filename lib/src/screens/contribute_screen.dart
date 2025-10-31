import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/locale_keys.dart';
import '../services/firebase_service.dart';

class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'contribute_screen',
      screenClass: 'ContributeScreen',
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.couldNotOpenUrl.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.contribute.tr()),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.contributeDescription.tr(),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Financial Support Section
            Text(
              LocaleKeys.financialSupport.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Patreon
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme.of(context).brightness == Brightness.dark
                      ? Image.asset(
                          'assets/images/patreon_white.png',
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          'assets/images/patreon_black.png',
                          fit: BoxFit.contain,
                        ),
                ),
                title: Text(LocaleKeys.supportOnPatreon.tr()),
                subtitle: Text(LocaleKeys.supportOnPatreonDescription.tr()),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  FirebaseService.instance.logEvent(
                    name: 'contribute_patreon_clicked',
                  );
                  _launchUrl('https://patreon.com/bluematterdev');
                },
              ),
            ),

            const SizedBox(height: 12),

            // Ko-fi
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/kofi_symbol.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                title: Text(LocaleKeys.supportOnKofi.tr()),
                subtitle: Text(LocaleKeys.supportOnKofiDescription.tr()),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  FirebaseService.instance.logEvent(
                    name: 'contribute_kofi_clicked',
                  );
                  _launchUrl('https://ko-fi.com/bluematter');
                },
              ),
            ),

            const SizedBox(height: 32),

            // Open Source Contribution Section
            Text(
              LocaleKeys.openSourceContributions.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Star Repository
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme.of(context).brightness == Brightness.dark
                      ? Image.asset(
                          'assets/images/github-mark-white.png',
                          fit: BoxFit.contain,
                        )
                      : ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/github-mark-white.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                title: Text(LocaleKeys.starRepository.tr()),
                subtitle: Text(LocaleKeys.starRepositoryDescription.tr()),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  FirebaseService.instance.logEvent(
                    name: 'contribute_star_clicked',
                  );
                  _launchUrl('https://github.com/RajnishOne/qbitconnect');
                },
              ),
            ),

            const SizedBox(height: 12),

            // Create Pull Request
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme.of(context).brightness == Brightness.dark
                      ? Image.asset(
                          'assets/images/github-mark-white.png',
                          fit: BoxFit.contain,
                        )
                      : ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/github-mark-white.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                title: Text(LocaleKeys.createPullRequest.tr()),
                subtitle: Text(LocaleKeys.createPullRequestDescription.tr()),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  FirebaseService.instance.logEvent(
                    name: 'contribute_pr_clicked',
                  );
                  _launchUrl(
                    'https://github.com/RajnishOne/qbitconnect/compare',
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Open Issue
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme.of(context).brightness == Brightness.dark
                      ? Image.asset(
                          'assets/images/github-mark-white.png',
                          fit: BoxFit.contain,
                        )
                      : ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/github-mark-white.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                title: Text(LocaleKeys.openIssue.tr()),
                subtitle: Text(LocaleKeys.openIssueDescription.tr()),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  FirebaseService.instance.logEvent(
                    name: 'contribute_issue_clicked',
                  );
                  _launchUrl(
                    'https://github.com/RajnishOne/qbitconnect/issues/new',
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

