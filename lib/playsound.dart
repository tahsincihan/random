import 'package:audioplayers/audioplayers.dart';

class PlaySound {

late AudioPlayer _player;
String _soundPath ="";

PlaySound({required String soundPath}) {

_player = AudioPlayer();

_player.setReleaseMode(ReleaseMode.stop);

_soundPath = soundPath;

}

Future play() async {

await _player.play(AssetSource(_soundPath));

}

Future stop() async {

await _player.stop();

}

Future pause() async {

await _player.pause();

}

}