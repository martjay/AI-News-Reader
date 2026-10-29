import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_core/news_core.dart';
import 'package:path_provider/path_provider.dart';

import '../services/edge_tts_client.dart';
import 'article_record.dart';

enum TtsStatus { idle, loading, playing, paused }

enum TtsError { none, empty, network, saved, saveFailed }

class SpeechChunk {
  const SpeechChunk({
    required this.text,
    required this.firstPart,
    required this.lastPart,
  });

  final String text;
  final int firstPart;
  final int lastPart;
}

class TtsState {
  const TtsState({
    this.articleId,
    this.status = TtsStatus.idle,
    this.error = TtsError.none,
    this.downloading = false,
    this.downloadDone = 0,
    this.downloadTotal = 0,
    this.speechParts = const [],
    this.chunkIndex = 0,
    this.chunkTotal = 0,
    this.partFrom = 0,
    this.partTo = -1,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.preparingChunk = false,
  });

  final String? articleId;
  final TtsStatus status;
  final TtsError error;
  final bool downloading;
  final int downloadDone;
  final int downloadTotal;
  final List<String> speechParts;
  final int chunkIndex;
  final int chunkTotal;
  final int partFrom;
  final int partTo;
  final Duration position;
  final Duration duration;
  final bool preparingChunk;

  bool get active =>
      status == TtsStatus.loading || status == TtsStatus.playing || status == TtsStatus.paused;

  Duration get remaining {
    final left = duration - position;
    return left.isNegative ? Duration.zero : left;
  }

  bool speaksText(String text) {
    final needle = text.trim();
    if (!active || needle.isEmpty || speechParts.isEmpty || partTo < partFrom) return false;
    for (var i = partFrom; i <= partTo && i < speechParts.length; i++) {
      final part = speechParts[i].trim();
      if (part.isEmpty) continue;
      if (part == needle) return true;
      if (needle.length >= 24 && part.contains(needle)) return true;
      if (part.length >= 24 && needle.contains(part)) return true;
    }
    return false;
  }

  TtsState copyWith({
    String? articleId,
    TtsStatus? status,
    TtsError? error,
    bool? downloading,
    int? downloadDone,
    int? downloadTotal,
    List<String>? speechParts,
    int? chunkIndex,
    int? chunkTotal,
    int? partFrom,
    int? partTo,
    Duration? position,
    Duration? duration,
    bool? preparingChunk,
    bool clearArticle = false,
    bool clearPlayback = false,
  }) {
    return TtsState(
      articleId: clearArticle ? null : (articleId ?? this.articleId),
      status: status ?? this.status,
      error: error ?? this.error,
      downloading: downloading ?? this.downloading,
      downloadDone: downloadDone ?? this.downloadDone,
      downloadTotal: downloadTotal ?? this.downloadTotal,
      speechParts: clearPlayback ? const [] : (speechParts ?? this.speechParts),
      chunkIndex: clearPlayback ? 0 : (chunkIndex ?? this.chunkIndex),
      chunkTotal: clearPlayback ? 0 : (chunkTotal ?? this.chunkTotal),
      partFrom: clearPlayback ? 0 : (partFrom ?? this.partFrom),
      partTo: clearPlayback ? -1 : (partTo ?? this.partTo),
      position: clearPlayback ? Duration.zero : (position ?? this.position),
      duration: clearPlayback ? Duration.zero : (duration ?? this.duration),
      preparingChunk: clearPlayback ? false : (preparingChunk ?? this.preparingChunk),
    );
  }
}

class _TtsCancelled implements Exception {}

class TtsController extends Notifier<TtsState> {
  final AudioPlayer _player = AudioPlayer();
  final _engine = EdgeTtsClient();
  final _prefetchEngine = EdgeTtsClient();
  final _downloadEngine = EdgeTtsClient();
  var _token = 0;
  var _downloadToken = 0;
  final _tempFiles = <File>[];
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  @override
  TtsState build() {
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
    _positionSub = _player.onPositionChanged.listen(_onPosition);
    _durationSub = _player.onDurationChanged.listen(_onDuration);
    ref.onDispose(() {
      unawaited(_positionSub?.cancel());
      unawaited(_durationSub?.cancel());
      unawaited(stop());
      unawaited(_player.dispose());
    });
    return const TtsState();
  }

  void _onPosition(Duration position) {
    if (!state.active || state.preparingChunk) return;
    if ((position - state.position).inMilliseconds.abs() < 200) return;
    state = state.copyWith(position: position);
  }

  void _onDuration(Duration duration) {
    if (!state.active) return;
    if (duration == state.duration) return;
    state = state.copyWith(duration: duration);
  }

  Future<void> toggle({
    required String articleId,
    required String text,
    required String voice,
  }) async {
    if (state.active && state.articleId == articleId) {
      await stop();
      return;
    }
    await speak(articleId: articleId, text: text, voice: voice);
  }

  Future<void> togglePause() async {
    if (state.status == TtsStatus.playing) {
      await _player.pause();
      state = state.copyWith(status: TtsStatus.paused);
      return;
    }
    if (state.status == TtsStatus.paused) {
      await _player.resume();
      state = state.copyWith(status: TtsStatus.playing);
    }
  }

  Future<void> seek(Duration position) async {
    if (state.status != TtsStatus.playing && state.status != TtsStatus.paused) return;
    if (state.duration <= Duration.zero) return;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > state.duration ? state.duration : position);
    await _player.seek(clamped);
    state = state.copyWith(position: clamped);
  }

  Future<void> speak({
    required String articleId,
    required String text,
    required String voice,
  }) async {
    final spoken = text.trim();
    if (spoken.isEmpty) {
      state = state.copyWith(articleId: articleId, error: TtsError.empty);
      return;
    }
    await stop();
    final token = ++_token;
    final parts = speechPartsOf(spoken);
    final chunks = speechChunks(spoken);
    if (chunks.isEmpty) {
      state = state.copyWith(articleId: articleId, error: TtsError.empty);
      return;
    }
    state = state.copyWith(
      articleId: articleId,
      status: TtsStatus.loading,
      error: TtsError.none,
      speechParts: parts,
      chunkIndex: 0,
      chunkTotal: chunks.length,
      partFrom: chunks.isEmpty ? 0 : chunks.first.firstPart,
      partTo: chunks.isEmpty ? -1 : chunks.first.lastPart,
      position: Duration.zero,
      duration: Duration.zero,
      preparingChunk: true,
    );
    try {
      final dir = await getTemporaryDirectory();
      var prefetchReady = false;
      Future<Uint8List> pending = _synthesizeForPlay(
        engine: _engine,
        text: chunks.first.text,
        voice: voice,
        token: token,
      ).then((bytes) {
        prefetchReady = true;
        return bytes;
      });
      for (var i = 0; i < chunks.length; i++) {
        if (token != _token) throw _TtsCancelled();
        final chunk = chunks[i];
        if (i > 0 && !prefetchReady) {
          state = state.copyWith(
            articleId: articleId,
            chunkIndex: i,
            chunkTotal: chunks.length,
            partFrom: chunk.firstPart,
            partTo: chunk.lastPart,
            position: Duration.zero,
            duration: Duration.zero,
            preparingChunk: true,
          );
        }
        final bytes = await pending;
        if (token != _token) throw _TtsCancelled();
        final file = File('${dir.path}${Platform.pathSeparator}inkbrief_tts_${token}_$i.mp3');
        await file.writeAsBytes(bytes, flush: true);
        _tempFiles.add(file);
        if (token != _token) throw _TtsCancelled();
        if (i + 1 < chunks.length) {
          prefetchReady = false;
          pending = _synthesizeForPlay(
            engine: _prefetchEngine,
            text: chunks[i + 1].text,
            voice: voice,
            token: token,
          ).then((next) {
            prefetchReady = true;
            return next;
          });
        }
        state = state.copyWith(
          articleId: articleId,
          status: TtsStatus.playing,
          chunkIndex: i,
          chunkTotal: chunks.length,
          partFrom: chunk.firstPart,
          partTo: chunk.lastPart,
          preparingChunk: false,
          position: Duration.zero,
          duration: Duration.zero,
        );
        await _playUntilDone(file, token);
      }
      if (token == _token) {
        state = state.copyWith(
          status: TtsStatus.idle,
          clearArticle: !state.downloading,
          clearPlayback: true,
          error: TtsError.none,
        );
      }
    } on _TtsCancelled {
      return;
    } catch (e, st) {
      debugPrint('tts play failed: $e\n$st');
      if (token == _token) {
        state = state.copyWith(
          articleId: articleId,
          status: TtsStatus.idle,
          clearPlayback: true,
          error: TtsError.network,
        );
      }
    } finally {
      await _deleteTempFiles();
    }
  }

  Future<Uint8List> _synthesizeForPlay({
    required EdgeTtsClient engine,
    required String text,
    required String voice,
    required int token,
  }) {
    return _synthesizeWithRetry(
      engine: engine,
      text: text,
      voice: voice,
      alive: () => token == _token,
    );
  }

  Future<Uint8List> _synthesizeWithRetry({
    required EdgeTtsClient engine,
    required String text,
    required String voice,
    required bool Function() alive,
    int attempts = 4,
  }) async {
    Object? last;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (!alive()) throw _TtsCancelled();
      try {
        return await engine.synthesize(text: text, voice: voice);
      } catch (e) {
        last = e;
        if (attempt >= attempts - 1) break;
        await Future<void>.delayed(Duration(milliseconds: 400 * (1 << attempt)));
      }
    }
    if (!alive()) throw _TtsCancelled();
    throw last ?? StateError('Edge TTS failed');
  }

  Future<void> _deleteTempFiles() async {
    final files = List<File>.from(_tempFiles);
    _tempFiles.clear();
    for (final file in files) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  Future<void> _playUntilDone(File file, int token) async {
    if (token != _token) return;
    final done = Completer<void>();
    final completeSub = _player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    final stateSub = _player.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.stopped && !done.isCompleted) done.complete();
    });
    try {
      if (token != _token) return;
      await _player.play(DeviceFileSource(file.path));
      if (token != _token) return;
      await done.future;
    } finally {
      await completeSub.cancel();
      await stateSub.cancel();
    }
  }

  Future<void> download({
    required String articleId,
    required String text,
    required String voice,
    required String title,
  }) async {
    final spoken = text.trim();
    if (spoken.isEmpty) {
      state = state.copyWith(articleId: articleId, error: TtsError.empty);
      return;
    }
    if (state.downloading) return;
    final path = await _savePath(title);
    if (path == null) return;

    final token = ++_downloadToken;
    final chunks = speechChunks(spoken);
    state = state.copyWith(
      articleId: articleId,
      downloading: true,
      downloadDone: 0,
      downloadTotal: chunks.length,
      error: TtsError.none,
    );
    try {
      final out = BytesBuilder(copy: false);
      for (var i = 0; i < chunks.length; i++) {
        if (token != _downloadToken) return;
        out.add(
          await _synthesizeWithRetry(
            engine: _downloadEngine,
            text: chunks[i].text,
            voice: voice,
            alive: () => token == _downloadToken,
          ),
        );
        if (token != _downloadToken) return;
        state = state.copyWith(downloadDone: i + 1, downloadTotal: chunks.length);
      }
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(out.takeBytes(), flush: true);
      if (token == _downloadToken) {
        state = state.copyWith(downloading: false, downloadDone: chunks.length, error: TtsError.saved);
      }
    } on _TtsCancelled {
      return;
    } catch (e, st) {
      debugPrint('tts download failed: $e\n$st');
      if (token == _downloadToken) {
        state = state.copyWith(downloading: false, error: TtsError.saveFailed);
      }
    }
  }

  Future<void> stop() async {
    _token++;
    try {
      await _player.stop();
    } catch (e, st) {
      debugPrint('tts stop failed: $e\n$st');
    }
    if (state.status != TtsStatus.idle || state.speechParts.isNotEmpty) {
      state = state.copyWith(
        status: TtsStatus.idle,
        clearArticle: !state.downloading,
        clearPlayback: true,
        error: TtsError.none,
      );
    }
  }
}

List<String> speechPartsOf(String text) {
  return text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

List<SpeechChunk> speechChunks(String text, {int maxChars = 1400}) {
  final parts = speechPartsOf(text);
  final chunks = <SpeechChunk>[];
  final buf = StringBuffer();
  var first = 0;
  var last = -1;

  void flush() {
    final next = buf.toString().trim();
    if (next.isNotEmpty && last >= first) {
      chunks.add(SpeechChunk(text: next, firstPart: first, lastPart: last));
    }
    buf.clear();
  }

  for (var i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (part.length > maxChars) {
      flush();
      for (var offset = 0; offset < part.length; offset += maxChars) {
        chunks.add(
          SpeechChunk(
            text: part.substring(offset, math.min(offset + maxChars, part.length)),
            firstPart: i,
            lastPart: i,
          ),
        );
      }
      first = i + 1;
      last = i;
      continue;
    }
    if (buf.isNotEmpty && buf.length + part.length + 1 > maxChars) {
      flush();
    }
    if (buf.isEmpty) first = i;
    if (buf.isNotEmpty) buf.write('\n');
    buf.write(part);
    last = i;
  }
  flush();
  return chunks;
}

String speechTextFor(ArticleRecord rec) {
  final original = rec.body.trim().isNotEmpty ? rec.body.trim() : plaintextFromHtml(rec.item.summary).trim();
  final translated = rec.bodyZh.trim();
  final useTranslation = translated.isNotEmpty && translated != original;
  final title = useTranslation && rec.titleZh.trim().isNotEmpty ? rec.titleZh.trim() : rec.item.title.trim();
  final body = speechPlaintext(useTranslation ? translated : original);
  return [title, body].where((e) => e.isNotEmpty).join('\n\n');
}

String formatTtsClock(Duration duration) {
  final total = duration.isNegative ? 0 : duration.inSeconds;
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Future<String?> _savePath(String title) async {
  final name = '${_fileStem(title)}.mp3';
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}$name';
  }
  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'MP3', extensions: ['mp3']),
    ],
  );
  return location?.path;
}

String _fileStem(String title) {
  var stem = title.replaceAll(RegExp(r'[\\/:*?"<>|\n\r]+'), ' ').trim();
  stem = stem.replaceAll(RegExp(r'\s+'), ' ');
  if (stem.length > 72) stem = stem.substring(0, 72).trim();
  return stem.isEmpty ? 'inkbrief' : stem;
}

final ttsProvider = NotifierProvider<TtsController, TtsState>(TtsController.new);
