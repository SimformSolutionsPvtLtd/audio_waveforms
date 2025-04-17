# Installation
#
## Prerequisites

Before you begin, ensure you have Flutter installed and configured properly.

### Add Dependency

Add the audio_waveforms dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  audio_waveforms: <latest-version>
```

Run the following commands to ensure clean installation:

```bash
flutter clean
flutter pub get
```

## Platform-Specific Setup

### Android

1. Change the minimum Android SDK version in your `android/app/build.gradle` file:

```gradle
minSdkVersion 21
```

2. Add RECORD_AUDIO permission in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

1. Add description for microphone usage in `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Add your own description.</string>
```

2. This plugin requires iOS 13.0 or higher. Add this line to your `Podfile`:

```ruby
platform :ios, '13.0'
```

## Verification

After completing the installation steps, you should be able to import and use the plugin in your Flutter application:

```dart
import 'package:audio_waveforms/audio_waveforms.dart';
```

If you encounter any issues during installation, make sure to:
- Delete the app from your device
- Perform `flutter clean` and `flutter pub get`
- Restart your IDE
