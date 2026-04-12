import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String? releaseNotes;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.releaseNotes,
  });
}

class AppUpdater {
  static bool _hasChecked = false;

  static void resetCheck() {
    _hasChecked = false;
  }

  static Future<UpdateInfo?> check() async {
    if (_hasChecked) return null;
    _hasChecked = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      final response = await dio.get(AppConfig.updateCheckUrl);
      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final remoteVersion = data['version'] as String;
      final downloads = data['downloads'] as Map<String, dynamic>;

      if (!_isNewer(remoteVersion, info.version)) {
        AppLogger.info('App is up to date (v${info.version})', name: 'Updater');
        return null;
      }

      final platformKey = _getPlatformKey();
      if (platformKey == null || !downloads.containsKey(platformKey)) {
        AppLogger.warning('No download URL for platform: $platformKey', name: 'Updater');
        return null;
      }

      return UpdateInfo(
        version: remoteVersion,
        downloadUrl: downloads[platformKey] as String,
        releaseNotes: data['releaseNotes'] as String?,
      );
    } catch (e) {
      AppLogger.warning('Update check failed or timed out: $e', name: 'Updater');
      return null;
    }
  }

  static Future<void> downloadAndInstall(
    String url,
    void Function(double progress, double speedMbps, String eta) onProgress,
  ) async {
    final tmp = await getTemporaryDirectory();
    final filename = url.split('/').last;
    final filePath = '${tmp.path}/$filename';

    final stopwatch = Stopwatch()..start();
    int lastReceived = 0;
    double speedMbps = 0;

    await Dio().download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total <= 0) return;

        final elapsed = stopwatch.elapsedMilliseconds;
        if (elapsed > 500) {
          final bytesDelta = received - lastReceived;
          speedMbps = (bytesDelta / elapsed * 1000) / (1024 * 1024);
          lastReceived = received;
          stopwatch.reset();
        }

        final progress = received / total;
        final remaining = total - received;
        final etaSecs = speedMbps > 0
            ? (remaining / (speedMbps * 1024 * 1024)).round()
            : 0;

        final eta = etaSecs > 60
            ? '${etaSecs ~/ 60}m ${etaSecs % 60}s'
            : '${etaSecs}s';

        onProgress(progress, speedMbps, eta);
      },
    );

    await _install(filePath);
  }

  static Future<void> _install(String filePath) async {
    if (Platform.isWindows) {

      await Process.start(filePath, ['/SILENT'], runInShell: false);
      exit(0);
    } else if (Platform.isLinux) {

      await Process.start('pkexec', ['dpkg', '-i', filePath], runInShell: false);
      exit(0);
    } else if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
      exit(0);
    }
  }

  static String? _getPlatformKey() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    return null;
  }

  static bool _isNewer(String remote, String current) {
    List<int> parse(String v) =>
        v.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final r = parse(remote);
    final c = parse(current);

    for (int i = 0; i < 3; i++) {
      final rVal = i < r.length ? r[i] : 0;
      final cVal = i < c.length ? c[i] : 0;
      if (rVal > cVal) return true;
      if (rVal < cVal) return false;
    }
    return false;
  }
}
