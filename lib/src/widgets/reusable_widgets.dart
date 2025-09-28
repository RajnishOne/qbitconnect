import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

/// Reusable widgets with const constructors for optimal performance.
///
/// This file contains commonly used widgets that can be cached and reused
/// to reduce widget rebuilds and improve app performance.
class ReusableWidgets {
  // Private constructor to prevent instantiation
  ReusableWidgets._();

  // Common spacing widgets
  static const Widget smallSpacing = SizedBox(height: 8);
  static const Widget mediumSpacing = SizedBox(height: 16);
  static const Widget largeSpacing = SizedBox(height: 24);
  static const Widget extraLargeSpacing = SizedBox(height: 32);

  static const Widget smallHorizontalSpacing = SizedBox(width: 8);
  static const Widget mediumHorizontalSpacing = SizedBox(width: 16);
  static const Widget largeHorizontalSpacing = SizedBox(width: 24);

  // Common dividers
  static const Widget thinDivider = Divider(height: 1, thickness: 0.5);
  static const Widget mediumDivider = Divider(height: 1, thickness: 1);
  static const Widget thickDivider = Divider(height: 1, thickness: 2);

  // Common icons with consistent sizing
  static const Widget pauseIcon = Icon(Icons.pause, size: 20);
  static const Widget playIcon = Icon(Icons.play_arrow, size: 20);
  static const Widget recheckIcon = Icon(Icons.check_circle, size: 20);
  static const Widget editIcon = Icon(Icons.edit, size: 20);
  static const Widget folderIcon = Icon(Icons.folder, size: 20);
  static const Widget deleteIcon = Icon(
    Icons.delete,
    size: 20,
    color: Colors.red,
  );
  static const Widget infoIcon = Icon(Icons.info, size: 20);
  static const Widget filesIcon = Icon(Icons.folder, size: 20);
  static const Widget trackersIcon = Icon(Icons.link, size: 20);
  static const Widget selectAllIcon = Icon(Icons.select_all, size: 20);
  static const Widget closeIcon = Icon(Icons.close, size: 20);
  static const Widget refreshIcon = Icon(Icons.refresh, size: 20);
  static const Widget downloadIcon = Icon(Icons.download, size: 20);
  static const Widget uploadIcon = Icon(Icons.upload, size: 20);

  // Common text widgets
  static const Widget pauseText = Text(AppStrings.pause);
  static const Widget resumeText = Text(AppStrings.resume);
  static const Widget recheckText = Text(AppStrings.recheck);
  static const Widget renameText = Text(AppStrings.rename);
  static const Widget changeLocationText = Text(AppStrings.changeLocation);
  static const Widget deleteText = Text(
    AppStrings.delete,
    style: TextStyle(color: Colors.red),
  );
  static const Widget selectAllText = Text(AppStrings.selectAll);
  static const Widget cancelText = Text(AppStrings.cancel);
  static const Widget refreshText = Text(AppStrings.refresh);

  // Common action rows for popup menus
  static const Widget pauseActionRow = Row(
    children: [pauseIcon, smallHorizontalSpacing, pauseText],
  );

  static const Widget resumeActionRow = Row(
    children: [playIcon, smallHorizontalSpacing, resumeText],
  );

  static const Widget recheckActionRow = Row(
    children: [recheckIcon, smallHorizontalSpacing, recheckText],
  );

  static const Widget renameActionRow = Row(
    children: [editIcon, smallHorizontalSpacing, renameText],
  );

  static const Widget changeLocationActionRow = Row(
    children: [folderIcon, smallHorizontalSpacing, changeLocationText],
  );

  static const Widget deleteActionRow = Row(
    children: [deleteIcon, smallHorizontalSpacing, deleteText],
  );

  // Common popup menu items
  static const PopupMenuItem<String> pauseMenuItem = PopupMenuItem(
    value: 'pause',
    child: pauseActionRow,
  );

  static const PopupMenuItem<String> resumeMenuItem = PopupMenuItem(
    value: 'resume',
    child: resumeActionRow,
  );

  static const PopupMenuItem<String> recheckMenuItem = PopupMenuItem(
    value: 'recheck',
    child: recheckActionRow,
  );

  static const PopupMenuItem<String> renameMenuItem = PopupMenuItem(
    value: 'rename',
    child: renameActionRow,
  );

  static const PopupMenuItem<String> changeLocationMenuItem = PopupMenuItem(
    value: 'location',
    child: changeLocationActionRow,
  );

  static const PopupMenuItem<String> deleteMenuItem = PopupMenuItem(
    value: 'delete',
    child: deleteActionRow,
  );

  // Common tab widgets
  static const Tab infoTab = Tab(text: AppStrings.info, icon: infoIcon);

  static const Tab filesTab = Tab(text: AppStrings.files, icon: filesIcon);

  static const Tab trackersTab = Tab(
    text: AppStrings.trackers,
    icon: trackersIcon,
  );

  // Common loading and error widgets
  static const Widget loadingIndicator = Center(
    child: CircularProgressIndicator(),
  );

  static const Widget noDataMessage = Center(
    child: Text(AppStrings.noDataAvailable),
  );

  static const Widget errorMessage = Center(
    child: Text(AppStrings.anErrorOccurred),
  );

  // Common button widgets (these need to be functions since they need callbacks)
  static Widget selectAllButton(VoidCallback onPressed) => IconButton(
    onPressed: onPressed,
    icon: selectAllIcon,
    tooltip: AppStrings.selectAll,
    iconSize: 20,
  );

  static Widget cancelButton(VoidCallback onPressed) => IconButton(
    onPressed: onPressed,
    icon: closeIcon,
    tooltip: AppStrings.cancel,
    iconSize: 20,
  );

  static Widget refreshButton(VoidCallback onPressed) => IconButton(
    onPressed: onPressed,
    icon: refreshIcon,
    tooltip: AppStrings.refreshTorrents,
    iconSize: 20,
  );

  // Common chip widgets for status indicators
  static Widget downloadChip(String speed) => Chip(
    avatar: const Icon(Icons.download, color: Colors.green),
    label: Text(speed),
  );

  static Widget uploadChip(String speed) => Chip(
    avatar: const Icon(Icons.upload, color: Colors.red),
    label: Text(speed),
  );

  // Common card widgets
  static Widget infoCard(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          mediumSpacing,
          ...children,
        ],
      ),
    ),
  );

  // Common list tile widgets
  static Widget infoListTile(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        mediumHorizontalSpacing,
        Expanded(child: Text(value)),
      ],
    ),
  );
}

/// Extension methods for easy access to reusable widgets
extension ReusableWidgetsExtension on BuildContext {
  /// Get common spacing widgets
  Widget get smallSpacing => ReusableWidgets.smallSpacing;
  Widget get mediumSpacing => ReusableWidgets.mediumSpacing;
  Widget get largeSpacing => ReusableWidgets.largeSpacing;
  Widget get extraLargeSpacing => ReusableWidgets.extraLargeSpacing;

  Widget get smallHorizontalSpacing => ReusableWidgets.smallHorizontalSpacing;
  Widget get mediumHorizontalSpacing => ReusableWidgets.mediumHorizontalSpacing;
  Widget get largeHorizontalSpacing => ReusableWidgets.largeHorizontalSpacing;

  /// Get common dividers
  Widget get thinDivider => ReusableWidgets.thinDivider;
  Widget get mediumDivider => ReusableWidgets.mediumDivider;
  Widget get thickDivider => ReusableWidgets.thickDivider;

  /// Get common loading widgets
  Widget get loadingIndicator => ReusableWidgets.loadingIndicator;
  Widget get noDataMessage => ReusableWidgets.noDataMessage;
  Widget get errorMessage => ReusableWidgets.errorMessage;
}
