import 'package:code_graph/code_graph.dart';
import 'package:test/test.dart';

void main() {
  group(SourceLocation, () {
    test('round-trips through JSON', () {
      const location = SourceLocation(
        filePath: 'lib/a.dart',
        startLine: 2,
        endLine: 9,
      );

      expect(SourceLocation.fromJson(location.toJson()), location);
    });
  });

  group(Annotation, () {
    test('round-trips through JSON', () {
      const annotation = Annotation(
        patternId: 'bloc',
        role: 'event',
        confidence: 0.75,
      );

      expect(Annotation.fromJson(annotation.toJson()), annotation);
    });

    test('reads an integer confidence', () {
      expect(
        Annotation.fromJson(const {
          'patternId': 'p',
          'role': 'r',
          'confidence': 1,
        }),
        const Annotation(patternId: 'p', role: 'r', confidence: 1),
      );
    });
  });

  group(CodeNode, () {
    test('uses the name as qualified name by default', () {
      const node = CodeNode(id: 'x', kind: CodeNodeKind.function, name: 'f');

      expect(node.qualifiedName, 'f');
      expect(node.loc, 0);
      expect(node.annotations, isEmpty);
    });

    test('delegates isEnterable and isExternal to its kind', () {
      const cls = CodeNode(id: 'c', kind: CodeNodeKind.classDecl, name: 'C');
      const pkg = CodeNode(
        id: 'pkg:p',
        kind: CodeNodeKind.externalPackage,
        name: 'p',
      );

      expect(cls.isEnterable, isTrue);
      expect(cls.isExternal, isFalse);
      expect(pkg.isEnterable, isFalse);
      expect(pkg.isExternal, isTrue);
    });

    test('omits empty fields from JSON', () {
      const node = CodeNode(id: 'x', kind: CodeNodeKind.function, name: 'f');

      expect(node.toJson(), {'id': 'x', 'kind': 'function', 'name': 'f'});
      expect(CodeNode.fromJson(node.toJson()), node);
    });

    test('round-trips every field through JSON', () {
      const node = CodeNode(
        id: 'lib/a.dart#A.m',
        kind: CodeNodeKind.method,
        name: 'm',
        qualifiedName: 'A.m',
        parentId: 'lib/a.dart#A',
        location: SourceLocation(
          filePath: 'lib/a.dart',
          startLine: 1,
          endLine: 3,
        ),
        loc: 3,
        packageName: 'a',
        annotations: [Annotation(patternId: 'p', role: 'r', confidence: 0.5)],
      );

      expect(CodeNode.fromJson(node.toJson()), node);
    });
  });
}
