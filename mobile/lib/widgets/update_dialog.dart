import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import '../core/theme.dart';
import '../services/update_service.dart';

enum UpdateStatus {
  idle,
  downloading,
  installing,
  error,
}

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateStatus _status = UpdateStatus.idle;
  double _progress = 0.0;
  String _errorMessage = '';
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startUpdate() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      // Non-Android fallback: launch direct browser download
      UpdateService.launchWebDownload(widget.updateInfo.downloadUrl);
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _status = UpdateStatus.downloading;
      _progress = 0.0;
      _errorMessage = '';
    });

    try {
      final downloadUrl = widget.updateInfo.downloadUrl;
      final filename = 'classcr_v${widget.updateInfo.latestVersion}.apk';

      _otaSubscription = OtaUpdate().execute(downloadUrl, destinationFilename: filename).listen(
        (OtaEvent event) {
          if (!mounted) return;
          if (event.status == OtaStatus.DOWNLOADING) {
            final parsedVal = int.tryParse(event.value ?? '0') ?? 0;
            setState(() {
              _status = UpdateStatus.downloading;
              _progress = (parsedVal / 100.0).clamp(0.0, 1.0);
            });
          } else if (event.status == OtaStatus.INSTALLING) {
            setState(() {
              _status = UpdateStatus.installing;
              _progress = 1.0;
            });
          } else if (event.status == OtaStatus.ALREADY_RUNNING_ERROR) {
            setState(() {
              _status = UpdateStatus.error;
              _errorMessage = 'An update download is already in progress.';
            });
          } else if (event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
            setState(() {
              _status = UpdateStatus.error;
              _errorMessage = 'Permission required to install unknown apps. Please allow installation in Android Settings.';
            });
          } else if (event.status == OtaStatus.DOWNLOAD_ERROR) {
            setState(() {
              _status = UpdateStatus.error;
              _errorMessage = 'Failed to download APK. Check internet or use browser download.';
            });
          } else if (event.status == OtaStatus.INTERNAL_ERROR) {
            setState(() {
              _status = UpdateStatus.error;
              _errorMessage = 'Installation internal error occurred (${event.value ?? "unknown"}).';
            });
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _status = UpdateStatus.error;
            _errorMessage = 'Update error: $e';
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = UpdateStatus.error;
        _errorMessage = 'Could not start update: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;

    return PopScope(
      canPop: !info.isMandatory && _status != UpdateStatus.downloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.rocket_launch,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'UPDATE AVAILABLE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            info.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!info.isMandatory && _status != UpdateStatus.downloading)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          UpdateService.recordUpdateDismissed(info.latestVersion);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Version Diff Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_android, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'Installed: v${info.currentVersion}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${info.latestVersion}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (kIsWeb) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Note: On your Android phone, this updates and restarts 100% inside the app without opening any browser. (In this PC web preview, it downloads the APK file).',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Changelog Section
                    if (info.changelog.isNotEmpty) ...[
                      const Text(
                        "What's New in this update:",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: info.changelog.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Dynamic State Views (Downloading / Installing / Error)
                    if (_status == UpdateStatus.downloading) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Downloading APK from Server...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                Text(
                                  '${(_progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _progress > 0 ? _progress : null,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFDBEAFE),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Please wait. App installer will launch automatically once finished.',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_status == UpdateStatus.installing) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF10B981)),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Launching Android Installer...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Follow the prompt on your screen to install & update ClassCR.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_status == UpdateStatus.error) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 6),
                                const Text(
                                  'Update Failed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _errorMessage.isNotEmpty ? _errorMessage : 'Unable to complete in-app installation.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        if (!info.isMandatory && _status != UpdateStatus.downloading) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                UpdateService.recordUpdateDismissed(info.latestVersion);
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: AppColors.cardBorder),
                              ),
                              child: const Text('Later', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _status == UpdateStatus.downloading || _status == UpdateStatus.installing
                                ? null
                                : (_status == UpdateStatus.error
                                    ? () => UpdateService.launchWebDownload(info.downloadUrl)
                                    : _startUpdate),
                            icon: Icon(
                              _status == UpdateStatus.error
                                  ? Icons.open_in_browser
                                  : Icons.system_update_alt,
                              size: 18,
                            ),
                            label: Text(
                              _status == UpdateStatus.downloading
                                  ? 'Downloading...'
                                  : (_status == UpdateStatus.installing
                                      ? 'Installing...'
                                      : (_status == UpdateStatus.error
                                          ? 'Open in Browser'
                                          : 'Update & Install Now')),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
