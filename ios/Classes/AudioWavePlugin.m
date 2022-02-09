#import "AudioWavePlugin.h"
#if __has_include(<audio_wave/audio_wave-Swift.h>)
#import <audio_wave/audio_wave-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "audio_wave-Swift.h"
#endif

@implementation AudioWavePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAudioWavePlugin registerWithRegistrar:registrar];
}
@end
