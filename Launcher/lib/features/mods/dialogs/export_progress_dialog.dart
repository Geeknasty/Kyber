import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:kyber_launcher/core/config/colors.dart';
import 'package:kyber_launcher/gen/fonts.gen.dart';

class ExportProgressDialog extends StatefulWidget {
  const ExportProgressDialog({
    required this.packName,
    required this.exportFuture,
    required this.progressStream,
    super.key,
  });

  final String packName;
  final Future<String?> exportFuture;
  final Stream<String> progressStream;

  @override
  State<ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<ExportProgressDialog> {
  String _currentMessage = 'Starting export…';
  bool _done = false;
  String? _exportPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.progressStream.listen(
      (msg) {
        if (mounted) setState(() => _currentMessage = msg);
      },
    );
    widget.exportFuture
        .then((path) {
          if (mounted) {
            setState(() {
              _done = true;
              _exportPath = path;
            });
          }
        })
        .catchError((Object e) {
          if (mounted) {
            setState(() {
              _done = true;
              _errorMessage = e.toString();
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 420),
      title: Text(
        _done
            ? (_errorMessage != null ? 'Export failed' : 'Export complete')
            : 'Exporting pack…',
        style: const TextStyle(
          fontFamily: FontFamily.battlefrontUI,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.packName,
            style: const TextStyle(
              fontFamily: FontFamily.battlefrontUI,
              color: kWhiteColor1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (!_done) ...[
            const ProgressBar(),
            const SizedBox(height: 10),
            Text(
              _currentMessage,
              style: const TextStyle(
                fontFamily: FontFamily.battlefrontUI,
                color: kWhiteColor,
                fontSize: 13,
              ),
            ),
          ] else if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: FontFamily.battlefrontUI,
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ] else ...[
            const Text(
              'Exported to:',
              style: TextStyle(
                fontFamily: FontFamily.battlefrontUI,
                color: kWhiteColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              _exportPath ?? '',
              style: const TextStyle(
                fontFamily: FontFamily.battlefrontUI,
                color: kWhiteColor1,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: _done
          ? [
              Button(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(_exportPath),
              ),
              if (_exportPath != null)
                FilledButton(
                  child: const Text('Open folder'),
                  onPressed: () {
                    _openFolder(_exportPath!);
                    Navigator.of(context).pop(_exportPath);
                  },
                ),
            ]
          : const [],
    );
  }

  void _openFolder(String path) {
    Process.run('explorer', [path]);
  }
}
