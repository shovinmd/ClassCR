import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/update_dialog.dart';

class AppUpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final String title;
  final List<String> changelog;
  final String downloadUrl;
  final String? releasesPageUrl;
  final bool hasUpdate;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.title,
    required this.changelog,
    required this.downloadUrl,
    this.releasesPageUrl,
    required this.hasUpdate,
    this.isMandatory = false,
  });
}

class UpdateService {
  static const String versionJsonUrl =
      'https://raw.githubusercontent.com/shovinmd/ClassCR/main/version.json';
  static const String fallbackReleasesApiUrl =
      'https://api.github.com/repos/shovinmd/ClassCR/releases/latest';

  static bool _hasPromptedThisSession = false;

  /// Fetch update info by checking remote version against current app version
  static Future<AppUpdateInfo?> checkForUpdates() async {
    try {
      PackageInfo packageInfo;
      try {
        packageInfo = await PackageInfo.fromPlatform();
      } catch (e) {
        packageInfo = PackageInfo(
          appName: 'ClassCR',
          packageName: 'com.example.mobile',
          version: '1.0.0',
          buildNumber: '1',
        );
      }

      final currentVersion = packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      // 1. Try fetching primary version.json from GitHub raw
      try {
        final res = await http.get(Uri.parse(versionJsonUrl)).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final remoteVersion = data['version']?.toString() ?? '1.0.0';
          final remoteBuild = int.tryParse(data['buildNumber']?.toString() ?? '1') ?? 1;
          final title = data['title']?.toString() ?? 'New ClassCR Update Available';
          final downloadUrl = data['downloadUrl']?.toString() ??
              'https://github.com/shovinmd/ClassCR/releases/latest/download/app-release.apk';
          final releasesPageUrl = data['releasesPageUrl']?.toString() ??
              'https://github.com/shovinmd/ClassCR/releases';
          final isMandatory = data['isMandatory'] == true;

          List<String> changelog = [];
          if (data['changelog'] is List) {
            changelog = (data['changelog'] as List).map((e) => e.toString()).toList();
          }

          final hasUpdate = _isRemoteNewer(
            currentVersion: currentVersion,
            currentBuild: currentBuild,
            remoteVersion: remoteVersion,
            remoteBuild: remoteBuild,
          );

          return AppUpdateInfo(
            currentVersion: currentVersion,
            currentBuildNumber: currentBuild,
            latestVersion: remoteVersion,
            latestBuildNumber: remoteBuild,
            title: title,
            changelog: changelog,
            downloadUrl: downloadUrl,
            releasesPageUrl: releasesPageUrl,
            hasUpdate: hasUpdate,
            isMandatory: isMandatory,
          );
        }
      } catch (e) {
        debugPrint('UpdateService version.json check failed: $e');
      }

      // 2. Fallback: Check GitHub Releases API
      try {
        final res = await http.get(
          Uri.parse(fallbackReleasesApiUrl),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ).timeout(const Duration(seconds: 6));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final tagName = data['tag_name']?.toString().replaceAll('v', '').trim() ?? '1.0.0';
          final body = data['body']?.toString() ?? '';
          final htmlUrl = data['html_url']?.toString() ?? 'https://github.com/shovinmd/ClassCR/releases';

          // Look for APK asset in release
          String downloadUrl = 'https://github.com/shovinmd/ClassCR/releases/latest/download/app-release.apk';
          if (data['assets'] is List) {
            final assets = data['assets'] as List;
            for (final asset in assets) {
              final name = asset['name']?.toString() ?? '';
              if (name.endsWith('.apk')) {
                downloadUrl = asset['browser_download_url']?.toString() ?? downloadUrl;
                break;
              }
            }
          }

          final changelog = body.isNotEmpty
              ? body.split('\n').where((line) => line.trim().isNotEmpty).toList()
              : ['Performance improvements and latest feature updates'];

          final hasUpdate = _isRemoteNewer(
            currentVersion: currentVersion,
            currentBuild: currentBuild,
            remoteVersion: tagName,
            remoteBuild: 1,
          );

          return AppUpdateInfo(
            currentVersion: currentVersion,
            currentBuildNumber: currentBuild,
            latestVersion: tagName,
            latestBuildNumber: currentBuild + 1,
            title: 'ClassCR v$tagName Available',
            changelog: changelog,
            downloadUrl: downloadUrl,
            releasesPageUrl: htmlUrl,
            hasUpdate: hasUpdate,
            isMandatory: false,
          );
        }
      } catch (e) {
        debugPrint('UpdateService GitHub releases fallback failed: $e');
      }

      return null;
    } catch (e) {
      debugPrint('UpdateService generic error: $e');
      return null;
    }
  }

  /// Compares semantic versions (e.g. 1.0.1 vs 1.0.0) or build numbers
  static bool _isRemoteNewer({
    required String currentVersion,
    required int currentBuild,
    required String remoteVersion,
    required int remoteBuild,
  }) {
    if (remoteBuild > currentBuild) return true;

    try {
      final currentParts = currentVersion.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final remoteParts = remoteVersion.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (remoteParts.length < 3) {
        remoteParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
    } catch (_) {}

    return false;
  }

  /// Automatically prompt user once per session if update is available
  static Future<void> checkForUpdatesAutoPrompt(BuildContext context) async {
    if (_hasPromptedThisSession) return;
    _hasPromptedThisSession = true;

    // Small delay so app UI finishes initial layout
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!context.mounted) return;

    final info = await checkForUpdates();
    if (info != null && info.hasUpdate && context.mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastDismissed = prefs.getString('last_dismissed_update_version');
        final lastTime = prefs.getInt('last_dismissed_update_time') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (!info.isMandatory && lastDismissed == info.latestVersion && (now - lastTime) < 12 * 3600 * 1000) {
          return; // Already dismissed recently; don't bother user repeatedly
        }
      } catch (_) {}

      showDialog(
        context: context,
        barrierDismissible: !info.isMandatory,
        builder: (_) => UpdateDialog(updateInfo: info),
      );
    }
  }

  /// Record that the user dismissed or postponed this update version
  static Future<void> recordUpdateDismissed(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_dismissed_update_version', version);
      await prefs.setInt('last_dismissed_update_time', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Manually triggered from UI (e.g. "Check for Updates" button)
  static Future<void> checkForUpdatesManual(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          elevation: 8,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                SizedBox(width: 20),
                Text(
                  'Checking for updates...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final info = await checkForUpdates();

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Close loading

      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Unable to connect to update server. Please check internet connection.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      if (info.hasUpdate) {
        showDialog(
          context: context,
          barrierDismissible: !info.isMandatory,
          builder: (_) => UpdateDialog(updateInfo: info),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ClassCR is up to date! (v${info.currentVersion})'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  /// Open release URL in external browser as fallback
  static Future<void> launchWebDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
