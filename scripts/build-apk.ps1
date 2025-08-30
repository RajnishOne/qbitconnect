# Build APK with custom naming script
# This script builds the APK and renames it to qBitConnect-android-<version>.apk

Write-Host "Building qBitConnect APK..." -ForegroundColor Green

# Kill any running Java processes that might lock files
Write-Host "Killing any running Java processes..." -ForegroundColor Yellow
taskkill /f /im java.exe 2>$null

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build the APK
Write-Host "Building APK..." -ForegroundColor Yellow
flutter build apk

# Check if build was successful
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# Extract version from pubspec.yaml (only version name, no build number)
Write-Host "Extracting version from pubspec.yaml..." -ForegroundColor Yellow
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match 'version:\s*([^+]+)') {
    $version = $matches[1].Trim()
    Write-Host "Version found: $version" -ForegroundColor Green
} else {
    Write-Host "Could not extract version from pubspec.yaml" -ForegroundColor Red
    exit 1
}

# Define source and destination paths
$sourcePath = "build\app\outputs\flutter-apk\app-release.apk"
$destPath = "build\app\outputs\flutter-apk\qBitConnect-android-$version.apk"

# Check if source file exists
if (-not (Test-Path $sourcePath)) {
    Write-Host "Source APK not found at: $sourcePath" -ForegroundColor Red
    exit 1
}

# Rename the APK
Write-Host "Renaming APK to: qBitConnect-android-$version.apk" -ForegroundColor Yellow
Move-Item -Path $sourcePath -Destination $destPath -Force

if (Test-Path $destPath) {
    $fileSize = [math]::Round((Get-Item $destPath).Length / 1MB, 2)
    Write-Host "Success! APK created: $destPath" -ForegroundColor Green
    Write-Host "File size: $fileSize MB" -ForegroundColor Green
} else {
    Write-Host "Failed to rename APK!" -ForegroundColor Red
    exit 1
}
