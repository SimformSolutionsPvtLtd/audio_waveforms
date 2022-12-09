# 0.1.5+1 to 1.0.0

From 1.0.0, waveform extraction has been reworked.

## New extraction function

```dart
extractWaveformData(path: 'path', noOfSamples: 100);  
```

## How to use?

First, extract waveform sample data using the above function which will return waveform data. Or you 
can directly use `preparPlayer` function and it will by default extract the waveform data. This can
be disabled by setting `shouldExtractWaveform` to false. You can access waveform data
using `waveformData` parameter from PlayerController or use `onCurrentExtractedWaveformData` 
stream to get the latest waveform data.

To extract the data first set the audio file path to `path` parameter and `noOfSamples` parameter will
determine no of waveform data in the returned list. So effectively it will determine no of waveform
bars.

Now, if you want the shorter waveforms which will fit inside the given width then you can calculate
no of samples by using `getSamplesForWidth` function from `PlayerWaveStyle`. This function requires
width and it will calculate no of samples based width and spacing (which was set during 
the initialization PlayerWaveStyle instance).

Now set this value like this,
```dart
final samples = getSamplesForWidth(200);
extractWaveformData(path: 'path', noOfSamples: samples);
```
If you need longer waveform then you can pass any no of sample directly.

If `preparePlayer` was used with `shouldExtractWaveform` enabled then `AudioFileWaveform` widget will 
directly receive the waveform data other wise you have to pass it manually.

Now let's create the widget,
```dart
AudioFileWaveforms(
    size: Size(200, 100),
    controller: controller,
    waveformType: WaveformType.fitWidth,
    continuousWaveform: true,
);
```
Now, there are two types of waveforms for this,
1. fitWidth
2. long

* fitWidth -: These waveforms are preferable for limited with as above we used. With these waveforms,
we can seek through them with continuous drag gestures or tap gestures.

* long -: These waveforms are preferable where waveform bars exceed the screen and need to be
scrolled to reach the end. With this waveform, we can seek through only by dragging them.

Extracting the waveform data is a resource heavy task so it may take some time to extract. Now based on
that, you can directly show the waveforms as soon as newer values get extracted by setting 
`continousWaveform` to true. If it's set to false then it will wait for the whole extraction process to 
complete.

As extraction process is resource heavy, we can directly provide waveformData to `AudioFileWaveforms`
widget and it will ignore the `continuousWaveform` flag and directly show the waveforms without any waiting.
So the process will be as below,
```dart
final waveformData = await extractWaveformData(path: 'path', noOfSamples: samples);
    ...
AudioFileWaveforms(
        waveformData: waveformData,
);
```

Now one last thing, as these waveformData have very small values, We can scale using scaleFactor.
And to provide some scale feedback while scrolling we can use scrollScale to scale waves while scrolling
and they will be scaled down to the original scale when scrolling ends.
```dart
PlayerWaveStyle(
    scaleFactor: 100,
    scrollScale: 1.2,
);
```

To see the list of all parameters and detailed description of parameters visit [documentation](https://pub.dev/documentation/audio_waveforms/latest/audio_waveforms/audio_waveforms-library.html).