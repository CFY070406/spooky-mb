import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_weather_bg_null_safety/flutter_weather_bg.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:spooky/core/file_manager/managers/sound_file_manager.dart';
import 'package:spooky/core/models/sound_model.dart';

class MiniSoundPlayerProvider extends ChangeNotifier {
  final SoundFileManager manager = SoundFileManager();
  final AudioPlayer player = AudioPlayer(
    mode: PlayerMode.MEDIA_PLAYER,
    playerId: "rain",
  );

  late final ValueNotifier<bool> currentlyPlayingNotifier;
  late final ValueNotifier<double> playerExpandProgressNotifier;
  late final MiniplayerController controller;

  final miniplayerPercentageDeclaration = 0.2;
  final double playerMinHeight = 48 + 16 * 2;
  final double playerMaxHeight = 232;

  SoundModel? _currentSound;
  SoundModel? get currentSound => _currentSound;

  void _setCurrentSound(SoundModel? value) {
    _currentSound = value;
    notifyListeners();
  }

  MiniSoundPlayerProvider() {
    currentlyPlayingNotifier = ValueNotifier(false);
    playerExpandProgressNotifier = ValueNotifier(playerMinHeight);
    controller = MiniplayerController();
    load();
  }

  List<SoundModel>? downloadedSounds;
  Future<void> load() async {
    downloadedSounds = await manager.downloadedSound();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  void play(SoundModel sound) async {
    if (manager.downloaded(sound)) {
      File? file = await manager.get(sound);
      if (file != null) {
        _setCurrentSound(sound);
        await player.setReleaseMode(ReleaseMode.LOOP);
        await player.play(file.path, isLocal: true);
      }
    }
  }

  void playNext() async {
    if (downloadedSounds == null) return;
    int index = downloadedSounds!.indexWhere((e) => currentSound?.fileName == e.fileName);
    int validatedIndex = (index + 1) % downloadedSounds!.length;
    play(downloadedSounds![validatedIndex]);
  }

  void playPrevious() {
    if (downloadedSounds == null) return;
    int index = downloadedSounds!.indexWhere((e) => currentSound?.fileName == e.fileName);
    int validatedIndex = (index - 1) % downloadedSounds!.length;
    play(downloadedSounds![validatedIndex]);
  }

  void onDismissed() {
    _setCurrentSound(null);
    currentlyPlayingNotifier.value = false;
    player.stop();
  }

  @override
  void dispose() {
    currentlyPlayingNotifier.dispose();
    playerExpandProgressNotifier.dispose();
    controller.dispose();
    player.dispose();
    super.dispose();
  }

  void togglePlayPause() {
    currentlyPlayingNotifier.value = !currentlyPlayingNotifier.value;
    if (currentlyPlayingNotifier.value) {
      player.pause();
    } else {
      player.resume();
    }
  }

  double offset(double percentage) {
    double offset = (percentage - playerMinHeight) / (playerMaxHeight - playerMinHeight);
    return offset;
  }

  double valueFromPercentageInRange({required final double min, max, percentage}) {
    return percentage * (max - min) + min;
  }

  double percentageFromValueInRange({required final double min, max, value}) {
    return (value - min) / (max - min);
  }
}