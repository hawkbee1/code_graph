// Regenerates test/fixtures/tiny.fscene from test/helpers/tiny_map.dart.
// Run from the package root: dart run test/fixtures/write_fixtures.dart
// Then read the diff: the file documents the .fscene format for humans.

import 'dart:io';

import 'package:code_graph/code_graph.dart';

import '../helpers/tiny_map.dart';

void main() {
  File('test/fixtures/tiny.fscene')
      .writeAsStringSync(const CodeMapCodec().encodeToJson(tinyMap()));
  stdout.writeln('wrote test/fixtures/tiny.fscene');
}
