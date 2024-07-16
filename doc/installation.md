## Installing

1. Add dependencies to `pubspec.yaml`

   Get the latest version in the 'Installing' tab
   on [pub.dev](https://pub.dev/packages/audio_waveforms/install)

    ```yaml
    dependencies:
        audio_waveforms: <latest-version>
    ```

2. Run pub get.

   ```shell
   flutter pub get
   ```

3. Import package.

    ```dart
    import 'package:audio_waveforms/audio_waveforms.dart';
    ```

## Recorder

### Platform specific configuration


**Android**

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.
```
minSdkVersion 21
```

Add RECORD_AUDIO permission in `AndroidManifest.xml`
```
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```


**IOS**

Add this two rows in `ios/Runner/Info.plist`
```
<key>NSMicrophoneUsageDescription</key>
<string>This app requires Mic permission.</string>
```
This plugin requires ios 10.0 or higher. So add this line in `Podfile`
```
platform :ios, '12.0'
```
