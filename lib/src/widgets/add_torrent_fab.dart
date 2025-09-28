import 'package:flutter/material.dart';
import 'expandable_fab.dart';
import '../screens/add_torrent_url_screen.dart';
import '../screens/add_torrent_file_screen.dart';

class AddTorrentFab extends StatelessWidget {
  const AddTorrentFab({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      distance: 72,
      children: [
        FloatingActionButton.small(
          heroTag: 'add_url',
          tooltip: 'Add via URL',
          onPressed: () {
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
          tooltip: 'Add .torrent file',
          onPressed: () {
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
