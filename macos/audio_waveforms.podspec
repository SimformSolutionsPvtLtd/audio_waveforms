#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audio_waveforms.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'audio_waveforms'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for recording audio with waveforms on macOS.'
  s.description      = <<-DESC
A Flutter plugin that allows you to generate waveforms while recording audio or from audio files on macOS.
                       DESC
  s.homepage         = 'https://github.com/SimformSolutionsPvtLtd/audio_waveforms'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Simform Solutions' => 'developer@simform.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
