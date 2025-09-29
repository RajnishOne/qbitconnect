# Debug Guide: Torrent File Deep Linking

## Issue Fixed
- **Problem**: App was opening inside Files app instead of bringing existing app to foreground
- **Solution**: Removed `android:taskAffinity=""` from AndroidManifest.xml

## Testing Steps

### 1. Test Torrent File from Files App

1. **Download a `.torrent` file** to your device
2. **Open Files app** and navigate to the torrent file
3. **Tap the torrent file**
4. **Expected behavior**: 
   - qBitConnect should come to foreground (not open inside Files app)
   - App should navigate to Add Torrent File screen
   - File should be pre-selected

### 2. Check Debug Logs

When you tap a torrent file, look for these log messages:

```
AppWidget: Received deep link: file:///path/to/file.torrent
AppWidget: Torrent-related link detected, queuing for processing
AppWidget: Processing pending deep link: file:///path/to/file.torrent (retry: 0)
AppWidget: App is ready, storing deep link for later processing (authenticated: true)
TorrentsScreen: _checkForPendingDeepLink called
TorrentsScreen: Checking for pending deep links...
TorrentsScreen: Processing pending deep link: file:///path/to/file.torrent
DeepLinkHandler: Handling torrent link: file:///path/to/file.torrent
DeepLinkHandler: Handling torrent file: file:///path/to/file.torrent
DeepLinkHandler: Navigating to AddTorrentFileScreen
DeepLinkHandler: Successfully navigated to AddTorrentFileScreen
```

### 3. Common Issues and Solutions

#### Issue: App opens inside Files app
**Solution**: This should be fixed now. If it still happens, try:
- Force close qBitConnect completely
- Try again

#### Issue: No navigation to Add Torrent File screen
**Check logs for**:
- `TorrentsScreen: Processing pending deep link` - If missing, TorrentsScreen not loaded
- `DeepLinkHandler: Navigating to AddTorrentFileScreen` - If missing, navigation failed
- `DeepLinkHandler: Successfully navigated` - If missing, navigation error

#### Issue: "Failed to process torrent file"
**Possible causes**:
- File doesn't exist
- File permissions issue
- Invalid torrent file format

### 4. Test Different Scenarios

1. **App in background**: Open app, minimize, tap torrent file
2. **App killed**: Force close app, tap torrent file
3. **Different file sources**: Downloads folder, external storage, cloud storage

### 5. Expected Log Flow

```
1. AppWidget: Received deep link: [file URI]
2. AppWidget: Torrent-related link detected, queuing for processing
3. AppWidget: Processing pending deep link: [file URI] (retry: 0)
4. AppWidget: App is ready, storing deep link for later processing (authenticated: true)
5. TorrentsScreen: _checkForPendingDeepLink called
6. TorrentsScreen: Checking for pending deep links...
7. TorrentsScreen: Processing pending deep link: [file URI]
8. DeepLinkHandler: Handling torrent link: [file URI]
9. DeepLinkHandler: Handling torrent file: [file URI]
10. DeepLinkHandler: Navigating to AddTorrentFileScreen
11. DeepLinkHandler: Successfully navigated to AddTorrentFileScreen
```

### 6. Troubleshooting

If logs stop at step 4:
- TorrentsScreen not loaded yet
- Try bringing app to foreground first

If logs stop at step 7:
- Navigation context not available
- Check if app is fully loaded

If logs stop at step 10:
- Navigation failed
- Check for Navigator errors

## Success Indicators

✅ **App comes to foreground** (not inside Files app)
✅ **Navigates to Add Torrent File screen**
✅ **File is pre-selected**
✅ **Success message shows**: "Torrent file detected and pre-selected"
