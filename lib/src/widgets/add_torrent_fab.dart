import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'expandable_fab.dart';
import '../screens/add_torrent_url_screen.dart';
import '../screens/add_torrent_file_screen.dart';
import '../constants/locale_keys.dart';

class AddTorrentFab extends StatelessWidget {
  final FocusNode? searchFocusNode;

  const AddTorrentFab({super.key, this.searchFocusNode});

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      distance: 72,
      onToggle: () => searchFocusNode?.unfocus(),
      children: [
        FloatingActionButton.small(
          heroTag: 'add_url',
          tooltip: LocaleKeys.addViaUrl.tr(),
          onPressed: () {
            // Unfocus search field when opening add torrent screen
            searchFocusNode?.unfocus();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddTorrentUrlScreen(),
              ),
            );
          },
          child: const Icon(Icons.link),
        ),
        FloatingActionButton.small(
          heroTag: 'add_file',
          tooltip: LocaleKeys.addTorrentFile.tr(),
          onPressed: () {
            // Unfocus search field when opening add torrent screen
            searchFocusNode?.unfocus();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddTorrentFileScreen(),
              ),
            );
          },
          child: const Icon(Icons.upload_file),
        ),
      ],
    );
  }
}
