// Not required for test files
// ignore_for_file: prefer_const_constructors
import 'package:test/test.dart';
import 'package:code_graph/code_graph.dart';

void main() {
  group('CodeGraph', () {
    test('can be instantiated', () {
      expect(CodeGraph(), isNotNull);
    });
  });
}
