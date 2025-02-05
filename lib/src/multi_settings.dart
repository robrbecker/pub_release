import 'package:dcli/dcli.dart' as dcli;
import 'package:dcli/dcli.dart';
import 'package:settings_yaml/settings_yaml.dart';

///
/// reads/writes to the pubrelease_multi.yaml file.
///

/// Holds settings information for a project
/// including any package dependencies use by the 'multi' command.
///
class MultiSettings {
  static const filename = 'pubrelease_multi.yaml';

  static late final pathToYaml = dcli.join(homeProjectPath, 'tool', filename);
  final packages = <Package>[];

  static String? _pathToHomeProject;

  static set homeProjectPath(String pathToHomeProject) =>
      _pathToHomeProject = pathToHomeProject;

  static String get homeProjectPath =>
      _pathToHomeProject ?? dcli.DartProject.fromPath('.').pathToProjectRoot;

  /// Load the pubrelease_multi.yaml into memory.
  /// [pathTo] is intended for aiding with unit testing by allowing
  /// the test to pass an alternate path. Normally [pathTo] should not
  /// be passed as the file will be loaded from its default location.
  /// If you pass [pathTo] it must include the filename.
  MultiSettings.load({String? pathTo}) {
    pathTo ??= pathToYaml;
    final settings = SettingsYaml.load(pathToSettings: pathTo);

    for (final entry in settings.valueMap.entries) {
      final package =
          Package(entry.key, truepath(homeProjectPath, entry.value as String));
      if (!dcli.exists(package.path)) {
        throw PubReleaseException(
            'The path ${package.path} for ${package.name} does not exist.');
      }

      if (!dcli.exists(dcli.join(package.path, 'pubspec.yaml'))) {
        throw PubReleaseException(
            'The pubspec.yaml for ${package.name} does not exist.');
      }

      packages.add(package);
    }
  }

  bool hasDependencies() {
    return packages.isNotEmpty;
  }

  bool containsPackage(String packageName) {
    bool found = false;

    for (final package in packages) {
      if (package.name == packageName) {
        found = true;
        break;
      }
    }
    return found;
  }

  bool validate() {
    var valid = true;
    try {
      for (final package in packages) {
        if (!dcli.exists(package.path)) {
          throw PubReleaseException(
              'The path ${package.path} for ${package.name} does not exist.');
        }

        if (!dcli.exists(dcli.join(package.path, 'pubspec.yaml'))) {
          throw PubReleaseException(
              'The pubspec.yaml for ${package.name} does not exist.');
        }
      }
    } on PubReleaseException catch (e) {
      valid = false;
      print(e);
    }
    return valid;
  }

  static bool exists() {
    return dcli.exists(pathToYaml);
  }
}

class Package {
  Package(this.name, this.path);
  String name;

  /// The truepath to the packages location on the file system.
  String path;
}

class PubReleaseException implements Exception {
  String message;
  PubReleaseException(this.message);
}
