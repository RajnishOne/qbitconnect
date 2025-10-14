import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';

/// Warning card that auto-dismisses after 3 seconds
class AutoConnectWarningCard extends StatefulWidget {
  const AutoConnectWarningCard({super.key});

  @override
  State<AutoConnectWarningCard> createState() => _AutoConnectWarningCardState();
}

class _AutoConnectWarningCardState extends State<AutoConnectWarningCard> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Card(
          color: Colors.orange.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    LocaleKeys.selectedServerNotAvailable.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
