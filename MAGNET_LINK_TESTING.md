# Magnet Link Testing Guide

This document explains how to test the magnet link handling functionality in qBitConnect.

## What Was Implemented

1. **Android Manifest Updates**: Added intent filters to handle magnet links and torrent files
2. **Deep Link Handler**: Created a service to process incoming deep links
3. **Enhanced Screens**: Modified AddTorrentUrlScreen and AddTorrentFileScreen to accept pre-filled data
4. **App Integration**: Integrated deep link handling into the main app widget

## How to Test

### Method 1: Using ADB (Android Debug Bridge)

1. **Install the app** on your Android device or emulator
2. **Connect your device** via USB and enable USB debugging
3. **Open a terminal/command prompt** and run:

```bash
# Test magnet link
adb shell am start -W -a android.intent.action.VIEW -d "magnet:?xt=urn:btih:1234567890abcdef1234567890abcdef12345678&dn=Test%20Torrent" com.example.qbitconnect

# Test torrent file URL
adb shell am start -W -a android.intent.action.VIEW -d "https://example.com/test.torrent" com.example.qbitconnect
```

### Method 2: Using Browser

1. **Install the app** on your Android device
2. **Open a web browser** on the device
3. **Navigate to a page** with a magnet link
4. **Click the magnet link** - it should open qBitConnect

### Method 3: Using File Manager

1. **Download a .torrent file** to your device
2. **Open a file manager** app
3. **Tap on the .torrent file**
4. **Select qBitConnect** from the app chooser

## Expected Behavior

### For Magnet Links:
- App should open (if not already running)
- Should navigate to the "Add Torrent URL" screen
- The magnet link should be pre-filled in the URL field
- User can then configure options and add the torrent

### For Torrent Files:
- App should open (if not already running)
- Should navigate to the "Add Torrent File" screen
- The torrent file should be pre-selected
- User can then configure options and add the torrent

## Troubleshooting

### If the app doesn't open:
1. Check that the app is installed correctly
2. Verify the package name in the ADB command matches your app
3. Check Android logs: `adb logcat | grep qbitconnect`

### If the wrong screen opens:
1. Ensure the app is authenticated (connected to qBittorrent)
2. Check that the deep link handler is properly initialized
3. Look for error messages in the debug console

### If the link isn't pre-filled:
1. Check that the deep link handler is receiving the URI
2. Verify the URI parsing logic
3. Check for any error messages in the debug console

### If you see Navigator/ScaffoldMessenger errors:
1. The app now includes better error handling for these issues
2. Deep links are queued and processed when the app is fully ready
3. The app waits for authentication before processing deep links
4. Check the debug logs for "DeepLinkHandler" and "AppWidget" messages

### If you see Provider<AppState> not found errors:
1. This has been fixed by using the appState instance directly
2. The app no longer tries to access the provider context too early
3. Deep links are processed only when the app is fully initialized

## Debug Information

The app includes debug logging for deep link handling. To see the logs:

```bash
adb logcat | grep "DeepLinkHandler"
```

## Sample Magnet Links for Testing

Here are some sample magnet links you can use for testing:

```
magnet:?xt=urn:btih:1234567890abcdef1234567890abcdef12345678&dn=Test%20Torrent
magnet:?xt=urn:btih:abcdef1234567890abcdef1234567890abcdef12&dn=Sample%20File
```

## Notes

- The app needs to be authenticated (connected to qBittorrent) for the torrent addition to work
- The deep link handler includes a 500ms delay to ensure the app is fully initialized
- Error handling is included to show user-friendly messages if something goes wrong
