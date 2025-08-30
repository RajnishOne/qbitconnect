# qBitConnect

A Flutter app for managing qBittorrent remotely.

[![Flutter](https://img.shields.io/badge/Flutter-3.35+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9+-blue.svg)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev/)

A modern, cross-platform mobile application for remote qBittorrent management. Connect to your qBittorrent server from anywhere and manage your downloads with ease.

## 📱 Download

[<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play Store" width="200">](https://play.google.com/store/apps/details?id=com.bluematter.qbitconnect)
[<img src="https://user-images.githubusercontent.com/15032958/208871323-c1c5511c-d6bc-47c8-b82b-7ce2f95f244a.png" alt="Get it on GitHub" width="200">](https://github.com/RajnishOne/qbitconnect/releases)

## Features

- Connect to qBittorrent Web UI
- View and manage torrents
- Add new torrents via magnet links or files
- Monitor download/upload speeds
- Pause, resume, and delete torrents
- Dark/Light theme support

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / Xcode for mobile development
- qBittorrent with Web UI enabled

### Firebase Configuration

This app uses Firebase for analytics and crash reporting. To set up Firebase:

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your project
3. Download and place your configuration files:
   - Place your `google-services.json` in `android/app/google-services.json`
   - Place your `GoogleService-Info.plist` in `ios/Runner/GoogleService-Info.plist`
   - Update `lib/firebase_options.dart` with your Firebase configuration values

### Analytics Configuration

The app includes basic Firebase Analytics for understanding user behavior. For privacy and open-source considerations:

- **Disable Analytics**: Set `analyticsEnabled = false` in `lib/src/services/analytics_config.dart`
- **Selective Disabling**: You can disable specific features like screen tracking, event tracking, etc.
- **Privacy-Focused**: Analytics are configured to be privacy-friendly and don't collect sensitive user data

The analytics implementation is minimal and focused on:
- Screen views (connection, torrents, settings)
- Basic events (connection success/failure, theme changes, settings changes)
- App usage patterns (app opens)

No personal information, torrent data, or server credentials are tracked.

### Android Keystore Setup

For release builds, you'll need to configure your Android keystore:

1. Create a keystore file (if you don't have one):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Update `android/key.properties` with your actual values:
   ```properties
   storePassword=YOUR_ACTUAL_STORE_PASSWORD
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   keyAlias=YOUR_ACTUAL_KEY_ALIAS
   storeFile=YOUR_ACTUAL_KEYSTORE_FILE_PATH
   ```

### Local Properties

Update `android/local.properties` with your SDK paths:
```properties
sdk.dir=YOUR_ANDROID_SDK_PATH
flutter.sdk=YOUR_FLUTTER_SDK_PATH
```

**Note**: The configuration files in this repository are ignored by git. You need to place your own Firebase configuration files and update the local properties with your actual values.

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase and keystore as described above
4. Run `flutter run` to start the app

## Usage

1. Open the app
2. Enter your qBittorrent Web UI URL (e.g., `http://192.168.1.100:8080`)
3. Enter your username and password
4. Tap "Connect" to start managing your torrents

## Development

### Project Structure

```
lib/
├── src/
│   ├── api/          # API services and models
│   ├── models/       # Data models
│   ├── screens/      # UI screens
│   ├── services/     # Business logic services
│   ├── state/        # State management
│   ├── theme/        # App theming
│   ├── utils/        # Utility functions
│   └── widgets/      # Reusable widgets
└── main.dart         # App entry point
```

### Building for Release

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Development Setup

1. Ensure you have Flutter SDK installed
2. Clone your forked repository
3. Run `flutter pub get` to install dependencies
4. Make your changes
5. Run tests: `flutter test`
6. Ensure code follows the project's style guidelines

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Write tests for new features

### Reporting Issues

When reporting issues, please include:
- Device/OS information
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [qBittorrent](https://www.qbittorrent.org/) - The amazing torrent client that makes this possible
- [Flutter](https://flutter.dev/) - The framework that powers this app
- All contributors and users who provide feedback and suggestions

## 🆘 Support

### Common Issues

#### Connection Problems
- Verify qBittorrent Web UI is enabled
- Check firewall settings
- Ensure correct URL format
- Verify username/password

#### Real-time Updates Not Working
- Check network connectivity
- Verify qBittorrent is running
- Check for error messages in logs
- Restart the application

#### Performance Issues
- Reduce polling frequency if needed
- Close unnecessary torrent details pages
- Check device resources
- Update to latest version

### Getting Help

- **Issues**: Create an issue on GitHub
- **Discussions**: Use GitHub Discussions
- **Documentation**: Check this README and code comments
- **Logs**: Enable debug logging for troubleshooting

---

**Last Updated**: August 2025  
**Version**: 1.1.0  
**Flutter Version**: 3.35+  
**Dart Version**: 3.9+

---

⭐ **Star this repository if you find it helpful!**
