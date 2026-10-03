import 'package:code_graph/code_graph.dart';
import 'package:test/test.dart';

import '../../helpers/tiny_map.dart';

final _project = ProjectInfo(
  generator: 'test',
  source: const LocalFolderDescriptor(name: 'p'),
  createdAt: DateTime.utc(2026),
);

CodeNode _node(String id, {String? parent}) =>
    CodeNode(id: id, kind: CodeNodeKind.classDecl, name: id, parentId: parent);

Matcher _throwsGraphError(String message) => throwsA(
  isA<CodeGraphException>().having((e) => e.message, 'message', message),
);

void main() {
  group(CodeGraph, () {
    group('validation', () {
      test('throws $CodeGraphException when a node is stored under '
          'another id', () {
        expect(
          () => CodeGraph(project: _project, nodes: {'b': _node('a')}),
          _throwsGraphError('node "a" is stored under "b"'),
        );
      });

      test('throws $CodeGraphException for an unknown parent', () {
        expect(
          () => CodeGraph(
            project: _project,
            nodes: {'a': _node('a', parent: 'x')},
          ),
          _throwsGraphError('node "a" has an unknown parent "x"'),
        );
      });

      test('throws $CodeGraphException for a dangling link', () {
        expect(
          () => CodeGraph(
            project: _project,
            nodes: {'a': _node('a')},
            links: const [
              CodeLink(fromId: 'a', toId: 'x', kind: LinkKind.call),
            ],
          ),
          _throwsGraphError('link a -> x references unknown node "x"'),
        );
      });

      test('throws $CodeGraphException for a containment cycle', () {
        expect(
          () => CodeGraph(
            project: _project,
            nodes: {
              'a': _node('a', parent: 'b'),
              'b': _node('b', parent: 'a'),
            },
          ),
          throwsA(isA<CodeGraphException>()),
        );
      });

      test('throws $CodeGraphException for an unknown entry node', () {
        expect(
          () => CodeGraph(
            project: ProjectInfo(
              generator: 'test',
              source: const LocalFolderDescriptor(name: 'p'),
              createdAt: DateTime.utc(2026),
              entryNodeId: 'x',
            ),
            nodes: {'a': _node('a')},
          ),
          _throwsGraphError('unknown entry node "x"'),
        );
      });

      test('describes the problem in toString', () {
        expect(
          const CodeGraphException('boom').toString(),
          'CodeGraphException: boom',
        );
      });
    });

    group('indexes', () {
      late CodeGraph graph;

      setUp(() => graph = tinyMap().graph);

      test('lists top-level nodes in insertion order', () {
        expect(graph.topLevel.map((n) => n.name), [
          'main',
          'UserRepository',
          'Loggable',
          'Role',
          'UserX',
          'UserId',
          'StatelessWidget',
          'flutter',
        ]);
      });

      test('lists the children of a node', () {
        expect(
          graph
              .childrenOf('lib/src/user.dart#UserRepository')
              .map((n) => n.name),
          ['new', 'save', 'name', 'name=', 'CachedUserRepository'],
        );
        expect(graph.childrenOf('lib/main.dart#main'), isEmpty);
      });

      test('lists ancestors nearest first and computes depth', () {
        expect(graph.ancestorsOf('lib/main.dart#App').map((n) => n.id), [
          'ghost:flutter:StatelessWidget',
        ]);
        expect(graph.depthOf('lib/main.dart#main'), 0);
        expect(graph.depthOf('lib/src/user.dart#UserRepository.save'), 1);
      });

      test('lists links from and to a node', () {
        expect(graph.linksFrom('lib/main.dart#App'), hasLength(2));
        expect(graph.linksTo('pkg:flutter'), hasLength(2));
        expect(graph.linksFrom('pkg:flutter'), isEmpty);
        expect(graph.linksTo('lib/main.dart#main'), isEmpty);
      });
    });

    test('round-trips through JSON', () {
      final graph = tinyMap().graph;

      expect(CodeGraph.fromJson(graph.toJson()), graph);
    });

    test('is unmodifiable', () {
      final graph = tinyMap().graph;

      expect(() => graph.nodes.remove('pkg:flutter'), throwsUnsupportedError);
      expect(graph.links.clear, throwsUnsupportedError);
    });
  });
}
