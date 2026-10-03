import 'package:code_graph/code_graph.dart';
import 'package:test/test.dart';

void main() {
  group('stableHash', () {
    test('matches the FNV-1a 32-bit reference values', () {
      expect(stableHash(''), 0x811C9DC5);
      expect(stableHash('a'), 0xE40C292C);
      expect(stableHash('foobar'), 0xBF9CF968);
      expect(stableHash('héllo'), 0xF1E5B55F);
    });

    test('changes with the seed', () {
      expect(stableHash('a', seed: 1), isNot(stableHash('a')));
    });
  });
}
