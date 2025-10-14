import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../state/app_state_manager.dart';
import '../services/language_manager.dart';
import '../services/firebase_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  LanguageInfo? _currentLanguage;

  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'language_selection_screen',
      screenClass: 'LanguageSelectionScreen',
    );
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final language = await LanguageManager.getCurrentLanguage();
    if (mounted) {
      setState(() {
        _currentLanguage = language;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid,
      top: false,
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.chooseLanguage.tr())),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: LanguageManager.availableLanguages.length,
          itemBuilder: (context, index) {
            final language = LanguageManager.availableLanguages[index];
            final isSelected = _currentLanguage?.code == language.code;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () => _selectLanguage(language),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Language flag or icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            _getLanguageFlag(language.code),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Language information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.nativeName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              language.name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Selection indicator
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getLanguageFlag(String languageCode) {
    // Simple flag emoji mapping for popular languages
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'zh':
        return '🇨🇳';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'pt':
        return '🇵🇹';
      case 'ru':
        return '🇷🇺';
      case 'it':
        return '🇮🇹';
      case 'nl':
        return '🇳🇱';
      case 'ar':
        return '🇸🇦';
      case 'hi':
        return '🇮🇳';
      default:
        return '🌐';
    }
  }

  Future<void> _selectLanguage(LanguageInfo language) async {
    // Update EasyLocalization directly
    await context.setLocale(language.locale);

    // Update the app language in storage
    await LanguageManager.setLanguage(language);

    // Update the app state
    await context.read<AppState>().setLanguage(language);

    // Update local state
    if (mounted) {
      setState(() {
        _currentLanguage = language;
      });
    }

    // Log language change
    FirebaseService.instance.logEvent(
      name: 'language_changed',
      parameters: {
        'language_code': language.code,
        'language_name': language.name,
        'language_native_name': language.nativeName,
      },
    );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${LocaleKeys.languageChangedTo.tr()} ${language.nativeName}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
