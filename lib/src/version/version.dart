import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:dcli/src/pubspec/pubspec_file.dart';
import '../pubspec_helper.dart';

/// Returns the version no. for the local pubspec.yaml.
///
/// We start in the current working directory (CWD) and search
/// up the tree path until we find a pubspec and then return
///
/// If you pass [startingDir] then we start the search from
/// [startingDir] rather than the CWD.
///
Version version({String startingDir}) {
  startingDir ??= pwd;
  var pubspec = getPubSpec(startingDir: startingDir);
  return pubspec.version;
}

/// Updates the pubspec.yaml and versiong.g.dart with the
/// new version no.
void updateVersion(
    Version newVersion, PubSpecFile pubspec, String pubspecPath) {
  print('');

  // recreate the version file
  var packageRootPath = dirname(pubspecPath);

  print('Saving to path is: $pubspecPath');

  // updated the verions no.
  pubspec.version = newVersion;

  // write new version.g.dart file.
  var versionPath = join(packageRootPath, 'lib', 'src', 'version');
  if (!exists(versionPath)) createDir(versionPath, recursive: true);
  var versionFile = join(versionPath, 'version.g.dart');
  print('Regenerating version file at ${absolute(versionFile)}');
  versionFile.write('/// GENERATED BY pub_release do not modify.');
  versionFile.append('/// ${pubspec.name} version');
  versionFile.append("String packageVersion = '$newVersion';");

  // rewrite the pubspec.yaml with the new version
  pubspec.saveToFile(pubspecPath);
}

/// Ask the user to select the new version no.
/// Pass in  the current [currentVersion] number.
Version askForVersion(Version currentVersion) {
  var options = <_NewVersion>[
    _NewVersion('Small Patch'.padRight(25), currentVersion.nextPatch),
    _NewVersion('Non-breaking change'.padRight(25), currentVersion.nextMinor),
    _NewVersion('Breaking change'.padRight(25), currentVersion.nextBreaking),
    _NewVersion('Keep the current Version'.padRight(25), currentVersion),
    _CustomVersion('Enter custom version no.'.padRight(25))
  ];

  print('');
  print(blue('What sort of changes have been made since the last release?'));
  var selected = menu(prompt: 'Select the change level:', options: options);

  if (selected is _CustomVersion) {
    selected.requestCustomVersion();
  }

  return confirmVersion(selected.version);
}

/// Ask the user to confirm the selected version no.
Version confirmVersion(Version version) {
  print('');
  print(green('The new version is: $version'));
  print('');

  if (!confirm('Is this the correct version')) {
    do {
      try {
        version = null;
        var versionString = ask('Enter the new version: ');

        if (!confirm('Is $versionString the correct version')) {
          exit(1);
        }

        version = Version.parse(versionString);
      } on FormatException catch (e) {
        print(e);
      }
    } while (version == null);
  }
  return version;
}

/// Used by version menu to provide a nice message
/// for the user.
class _NewVersion {
  final String message;
  final Version _version;

  _NewVersion(this.message, this._version);

  @override
  String toString() => '$message  (${_version ?? "?"})';

  Version get version {
    return _version;
  }
}

/// Used by the version menu to allow the user to select a custom version.
/// When this classes [version] property is called it triggers
class _CustomVersion extends _NewVersion {
  @override
  Version _version;
  _CustomVersion(String message) : super(message, null);

  @override
  Version get version => _version;

  /// Ask the user to type a custom version no.
  void requestCustomVersion() {
    do {
      try {
        var entered =
            ask('Enter the new Version No.:', validator: Ask.required);
        _version = Version.parse(entered);
      } on FormatException catch (e) {
        print(e);
      }
    } while (version == null);
  }
}
