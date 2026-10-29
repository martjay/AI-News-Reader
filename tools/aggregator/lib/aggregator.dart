import 'dart:io';

Directory? findRepoRoot({Directory? from}) {
  var dir = from ?? Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/config/sources.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  return null;
}
