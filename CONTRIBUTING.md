# Contributing to QBitConnect

Thank you for your interest in contributing to QBitConnect! This document provides guidelines and information for contributors.

## 🚀 Quick Start

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/qbitconnect.git`
3. **Create** a feature branch: `git checkout -b feature/your-feature-name`
4. **Make** your changes
5. **Test** your changes: `flutter test`
6. **Commit** with a clear message: `git commit -m "Add feature: description"`
7. **Push** to your fork: `git push origin feature/your-feature-name`
8. **Create** a Pull Request

## 📋 Development Guidelines

### Code Style

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Keep functions small and focused (max 50 lines)
- Add comments for complex logic
- Use proper indentation (2 spaces)

### Commit Messages

Use conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(torrents): add batch selection functionality
fix(connection): resolve timeout issues with slow connections
docs(readme): update installation instructions
```

### Testing

- Write tests for new features
- Ensure existing tests pass: `flutter test`
- Test on both Android and iOS if possible
- Test different screen sizes and orientations

### Pull Request Guidelines

1. **Title**: Clear and descriptive
2. **Description**: Explain what and why, not how
3. **Screenshots**: Include for UI changes
4. **Tests**: Ensure all tests pass
5. **Documentation**: Update docs if needed

## 🏗️ Project Structure

```
lib/
├── src/
│   ├── api/          # API services and endpoints
│   ├── models/       # Data models
│   ├── screens/      # UI screens
│   ├── services/     # Business logic
│   ├── state/        # State management
│   ├── theme/        # App theming
│   ├── utils/        # Utility functions
│   └── widgets/      # Reusable widgets
└── main.dart         # App entry point
```

## 🐛 Reporting Issues

### Before Reporting

1. Check existing issues
2. Search closed issues
3. Try the latest version
4. Reproduce on a clean install

### Issue Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
A clear description of what you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - OS: [e.g. Android 12, iOS 15]
 - Device: [e.g. Samsung Galaxy S21, iPhone 13]
 - App Version: [e.g. 1.0.2]
 - qBittorrent Version: [e.g. 4.5.0]

**Additional context**
Add any other context about the problem.
```

## 💡 Feature Requests

### Before Requesting

1. Check if it's already planned
2. Consider if it fits the app's scope
3. Think about implementation complexity

### Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
A clear description of any alternative solutions.

**Additional context**
Add any other context or screenshots.
```

## 🔧 Development Setup

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / Xcode
- Git

### Setup Steps

1. **Clone** the repository
2. **Install** dependencies: `flutter pub get`
3. **Configure** Firebase (see README)
4. **Run** the app: `flutter run`

### Debug Mode

The app runs in debug mode by default. For development:
```bash
flutter run --debug
```

## 📱 Testing

### Manual Testing Checklist

- [ ] Connection to qBittorrent server
- [ ] Torrent listing and management
- [ ] Add torrents (URL and file)
- [ ] Real-time updates
- [ ] Theme switching
- [ ] Settings persistence
- [ ] Error handling
- [ ] Network connectivity issues

### Automated Testing

Run tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

## 🎨 UI/UX Guidelines

- Follow Material Design principles
- Ensure accessibility (screen readers, high contrast)
- Support both light and dark themes
- Test on different screen sizes
- Use consistent spacing and typography

## 🔒 Security

- Never commit sensitive data (API keys, passwords)
- Use secure storage for user credentials
- Validate all user inputs
- Follow Flutter security best practices

## 📞 Getting Help

- **Issues**: Use GitHub Issues
- **Discussions**: Use GitHub Discussions
- **Code Review**: Ask in PR comments
- **General Questions**: Open a discussion

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- App acknowledgments (if applicable)

Thank you for contributing to QBitConnect! 🚀
