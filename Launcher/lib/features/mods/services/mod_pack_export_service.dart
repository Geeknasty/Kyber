import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:kyber_collection/kyber_collection.dart';
import 'package:kyber_launcher/features/mods/services/mod_service.dart';
import 'package:kyber_launcher/features/settings/dialogs/chromium_download_dialog.dart';
import 'package:kyber_launcher/injection_container.dart';
import 'package:path/path.dart' as p;

class ModPackExportService {
  static Future<String?> pickExportDirectory(FrostyMod pack) {
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose export location for "${pack.details.name}"',
    );
  }

  static Future<String> exportPack(
    FrostyMod pack,
    String selectedDir, {
    void Function(String message)? onProgress,
  }) async {
    assert(pack.isCollection, 'exportPack requires a collection mod');

    final exportDir = Directory(
      p.join(
        selectedDir,
        '${_sanitiseName(pack.details.name)} - ${_sanitiseName(pack.details.version)}',
      ),
    );
    await exportDir.create(recursive: true);

    final iconsDir = Directory(p.join(exportDir.path, 'icons'));
    await iconsDir.create();

    final affectedFilesDir = Directory(
      p.join(exportDir.path, 'affected_files'),
    );
    await affectedFilesDir.create();

    final allLocalMods = [
      ...sl.get<ModService>().mods,
      ...sl.get<ModService>().hiddenMods,
    ];

    final filenames = pack.mods ?? <String>[];
    final entries = <Map<String, dynamic>>[];
    final basePath = ModService.getBasePath();

    for (var i = 0; i < filenames.length; i++) {
      final filename = filenames[i];

      FrostyMod? mod = allLocalMods
          .where((m) => m.filename == filename)
          .firstOrNull;
      mod ??= allLocalMods
          .where((m) => p.basename(m.filename) == p.basename(filename))
          .firstOrNull;

      if (mod == null) {
        onProgress?.call(
          'Skipping ${i + 1}/${filenames.length}: $filename (not found locally)',
        );
        entries.add({
          'name': p.basenameWithoutExtension(filename),
          'version': '',
          'category': '',
          'size_bytes': 0,
          'size_formatted': '0 B',
          'type': 'MOD',
          'filename': filename,
          'icon_path': '',
          'affected_files_path': '',
        });
        continue;
      }

      onProgress?.call(
        'Exporting ${i + 1}/${filenames.length}: ${mod.details.name}',
      );

      String relativeIconPath = '';
      if (mod.icon != null && mod.icon!.isNotEmpty) {
        final iconName = '${_sanitiseName(mod.details.name)}.png';
        final destIcon = File(p.join(iconsDir.path, iconName));
        await destIcon.writeAsBytes(mod.icon!);
        relativeIconPath = p.join('icons', iconName);
      }

      onProgress?.call(
        'Reading affected files ${i + 1}/${filenames.length}: ${mod.details.name}',
      );
      String relativeAffectedPath = '';
      try {
        final modJson = jsonEncode(mod.toJson());
        final affected = await compute(_readFileInIsolate, {
          'path': basePath,
          'modJson': modJson,
        });

        if (affected.isNotEmpty) {
          final safeName = _sanitiseName(mod.details.name);
          final affectedFile = File(
            p.join(affectedFilesDir.path, '$safeName.json'),
          );
          await affectedFile.writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'mod_name': mod.details.name,
              'mod_version': mod.details.version,
              'affected_files': affected,
            }),
          );
          relativeAffectedPath = p.join('affected_files', '$safeName.json');
        }
      } catch (_) {}

      entries.add({
        'name': mod.details.name,
        'version': mod.details.version,
        'category': mod.details.category,
        'size_bytes': mod.size,
        'size_formatted': formatBytes(mod.size, 1),
        'type': mod.isCollection ? 'PACK' : 'MOD',
        'filename': mod.filename,
        'icon_path': relativeIconPath,
        'affected_files_path': relativeAffectedPath,
      });
    }
    onProgress?.call('Writing manifest…');
    final manifest = {
      'pack_name': pack.details.name,
      'pack_version': pack.details.version,
      'pack_category': pack.details.category,
      'total_mods': entries.length,
      'exported_at': DateTime.now().toIso8601String(),
      'mods': entries,
    };

    final manifestFile = File(p.join(exportDir.path, 'manifest.json'));
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    return exportDir.path;
  }

  static Map<String, List<String>> _readFileInIsolate(
    Map<String, dynamic> args,
  ) {
    final path = args['path']! as String;
    final modJson = args['modJson']! as String;
    final mod = FrostyMod.fromJson(
      jsonDecode(modJson) as Map<String, dynamic>,
    );
    final reader = ModReader(
      File(p.join(path, mod.filename)).openSync(),
    );
    return _readResources(reader, mod);
  }

  static Map<String, List<String>> _readResources(
    ModReader reader,
    FrostyMod mod,
  ) {
    final resources = reader.readResources(mod);
    final affectedFiles = <String, List<String>>{};
    for (final resource in resources.skip(5)) {
      final name = resource.type.toString().split('.').last;
      affectedFiles
          .putIfAbsent(name, () => [])
          .add(resource.name ?? 'Unknown resource name');
    }
    return affectedFiles;
  }

  static String _sanitiseName(String name) =>
      name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
}
