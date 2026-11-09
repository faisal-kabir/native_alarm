import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/core/error/exceptions.dart';
import 'package:eala/core/network/media_url.dart';
import 'package:eala/features/alarm_audio/data/datasources/alarm_audio_file_store.dart';
import 'package:eala/features/alarm_audio/data/datasources/alarm_audio_local_data_source.dart';
import 'package:eala/features/alarm_audio/data/datasources/alarm_audio_remote_data_source.dart';
import 'package:eala/features/alarm_audio/data/models/alarm_audio_model.dart';
import 'package:eala/features/alarm_audio/data/repositories/alarm_audio_repository_impl.dart';
import 'package:eala/features/alarm_audio/domain/entities/alarm_audio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAudioRemote implements AlarmAudioRemoteDataSource {
  Map<AlarmAudioKind, List<AlarmAudioModel>> rows = {};
  bool offline = false;

  @override
  Future<List<AlarmAudioModel>> fetchAudio(AlarmAudioKind kind) async {
    if (offline) throw const ServerException('offline');
    return rows[kind] ?? const [];
  }
}

/// Files kept in memory; [failing] URLs can not be downloaded.
class FakeFileStore implements AlarmAudioFileStore {
  final Set<String> files = {};
  final List<String> downloads = [];
  final Set<String> failing = {};

  @override
  Future<String> folder() async => '/files';

  @override
  Future<bool> exists(String name) async => files.contains(name);

  @override
  Future<void> download(String url, String name) async {
    if (failing.contains(url)) throw ServerException('no $url');
    downloads.add(url);
    files.add(name);
  }

  @override
  Future<void> deleteAllBut(Set<String> keep) async =>
      files.removeWhere((name) => !keep.contains(name));
}

AlarmAudioModel row(
  AlarmAudioKind kind,
  int id, {
  String? icon,
  String? audio,
  String updatedAt = '2026-11-01T00:00:00Z',
}) => AlarmAudioModel(
  kind: kind,
  id: id,
  title: 'Sound $id',
  icon: icon,
  audio: audio,
  updatedAt: updatedAt,
);

void main() {
  late AppDatabase db;
  late FakeAudioRemote remote;
  late FakeFileStore files;
  late AlarmAudioRepositoryImpl repository;

  const sound = AlarmAudioKind.alarmSound;
  const track = AlarmAudioKind.soundTrack;

  Future<List<AlarmAudio>> saved(AlarmAudioKind kind) async =>
      (await repository.watchAudio(kind).first).getOrElse(
        () => throw 'no list',
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = FakeAudioRemote()
      ..rows = {
        sound: [row(sound, 1, icon: 'icons/bell.svg', audio: 'audio/bell.mp3')],
        track: [row(track, 1, audio: 'audio/rain.mp3')],
      };
    files = FakeFileStore();
    repository = AlarmAudioRepositoryImpl(
      remote,
      AlarmAudioLocalDataSourceImpl(db),
      files,
    );
  });

  tearDown(() => db.close());

  test('both lists are saved with their files downloaded', () async {
    expect((await repository.refreshAudio()).isRight(), isTrue);

    final sounds = await saved(sound);
    expect(sounds.single.title, 'Sound 1');
    expect(sounds.single.iconFile, startsWith('/files/alarm_sound-1-icon-'));
    expect(sounds.single.iconFile, endsWith('.svg'));
    expect(sounds.single.audioFile, endsWith('.mp3'));
    final tracks = await saved(track);
    expect(tracks.single.audioFile, startsWith('/files/sound_track-1-audio-'));
    expect(tracks.single.iconFile, isNull);
    expect(files.files, hasLength(3));
  });

  test('a refresh with nothing changed downloads nothing', () async {
    await repository.refreshAudio();
    files.downloads.clear();
    await repository.refreshAudio();
    expect(files.downloads, isEmpty);
    expect(files.files, hasLength(3));
  });

  test('a changed file is downloaded again and the old one deleted', () async {
    await repository.refreshAudio();
    final oldAudio = (await saved(sound)).single.audioFile!;

    // Same path, but the row was updated (a new file uploaded under that name).
    remote.rows[sound] = [
      row(
        sound,
        1,
        icon: 'icons/bell.svg',
        audio: 'audio/bell.mp3',
        updatedAt: '2026-11-05T00:00:00Z',
      ),
    ];
    files.downloads.clear();
    await repository.refreshAudio();

    final now = (await saved(sound)).single;
    expect(now.audioFile, isNot(oldAudio));
    expect(files.files, isNot(contains(oldAudio.split('/').last)));
    expect(files.files, contains(now.audioFile!.split('/').last));
    // Both of the row's files belong to its new version.
    expect(files.downloads, hasLength(2));
  });

  test('a row the server removed loses its row and its files', () async {
    await repository.refreshAudio();
    remote.rows[track] = [row(track, 2, audio: 'audio/waves.mp3')];
    await repository.refreshAudio();

    expect((await saved(track)).single.id, 2);
    expect(files.files.where((f) => f.startsWith('sound_track-1-')), isEmpty);
    expect(
      files.files.where((f) => f.startsWith('sound_track-2-')),
      hasLength(1),
    );
  });

  test('a file the server no longer has is deleted', () async {
    await repository.refreshAudio();
    remote.rows[sound] = [row(sound, 1, audio: 'audio/bell.mp3')]; // no icon
    await repository.refreshAudio();

    expect((await saved(sound)).single.iconFile, isNull);
    expect(files.files.where((f) => f.contains('-icon-')), isEmpty);
  });

  test('a failed download keeps the old file and is tried again', () async {
    await repository.refreshAudio();
    final oldAudio = (await saved(sound)).single.audioFile;
    remote.rows[sound] = [
      row(sound, 1, icon: 'icons/bell.svg', audio: 'audio/bell2.mp3'),
    ];
    files.failing.add(mediaUrl('audio/bell2.mp3'));

    expect((await repository.refreshAudio()).isLeft(), isTrue);
    // Still playable offline with the file it had.
    expect((await saved(sound)).single.audioFile, oldAudio);
    expect((await saved(sound)).single.audio, 'audio/bell2.mp3');

    files.failing.clear();
    expect((await repository.refreshAudio()).isRight(), isTrue);
    expect((await saved(sound)).single.audioFile, isNot(oldAudio));
  });

  test('offline keeps every saved row and file', () async {
    await repository.refreshAudio();
    remote.offline = true;
    expect((await repository.refreshAudio()).isLeft(), isTrue);
    expect(await saved(sound), hasLength(1));
    expect(await saved(track), hasLength(1));
    expect(files.files, hasLength(3));
  });

  test('a file lost from the device is downloaded again', () async {
    await repository.refreshAudio();
    files.files.clear();
    await repository.refreshAudio();
    expect(files.files, hasLength(3));
  });

  test('two refreshes at once run only once', () async {
    await Future.wait([repository.refreshAudio(), repository.refreshAudio()]);
    expect(files.downloads, hasLength(3));
  });

  test('file names change with the path or the update, and keep the type', () {
    final a = alarmAudioFileName(sound, 1, 'audio', 'a/b.MP3', 'x');
    expect(a, startsWith('alarm_sound-1-audio-'));
    expect(a, endsWith('.mp3'));
    expect(alarmAudioFileName(sound, 1, 'audio', 'a/b.MP3', 'x'), a);
    expect(alarmAudioFileName(sound, 1, 'audio', 'a/b.MP3', 'y'), isNot(a));
    expect(alarmAudioFileName(sound, 1, 'audio', 'a/c.MP3', 'x'), isNot(a));
    expect(
      alarmAudioFileName(sound, 1, 'icon', 'https://x/i.svg?v=2', null),
      endsWith('.svg'),
    );
  });
}
