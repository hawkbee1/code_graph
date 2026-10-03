import 'package:code_graph/code_graph.dart';
import 'package:test/test.dart';

void main() {
  group(CodeNodeKind, () {
    group('isEnterable', () {
      test('is true for type declarations and ghost parents', () {
        expect(
          CodeNodeKind.values.where((k) => k.isEnterable),
          unorderedEquals([
            CodeNodeKind.classDecl,
            CodeNodeKind.mixinDecl,
            CodeNodeKind.enumDecl,
            CodeNodeKind.extensionDecl,
            CodeNodeKind.extensionTypeDecl,
            CodeNodeKind.ghostParent,
          ]),
        );
      });

      test('is false for members, functions and external packages', () {
        for (final kind in [
          CodeNodeKind.method,
          CodeNodeKind.constructor,
          CodeNodeKind.getter,
          CodeNodeKind.setter,
          CodeNodeKind.function,
          CodeNodeKind.externalPackage,
        ]) {
          expect(kind.isEnterable, isFalse, reason: kind.name);
        }
      });
    });

    group('isExternal', () {
      test('is true only for ghost parents and external packages', () {
        expect(
          CodeNodeKind.values.where((k) => k.isExternal),
          unorderedEquals([
            CodeNodeKind.ghostParent,
            CodeNodeKind.externalPackage,
          ]),
        );
      });
    });
  });
}
