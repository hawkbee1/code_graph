import 'package:code_graph/code_graph.dart';

/// A small code map that uses every node kind and every link kind, with
/// nesting (a subclass inside its parent, members inside classes).
CodeMap tinyMap() {
  const location = SourceLocation(
    filePath: 'lib/src/user.dart',
    startLine: 3,
    endLine: 40,
  );
  final nodes = <CodeNode>[
    const CodeNode(
      id: 'lib/main.dart#main',
      kind: CodeNodeKind.function,
      name: 'main',
      location: SourceLocation(
        filePath: 'lib/main.dart',
        startLine: 1,
        endLine: 4,
      ),
      loc: 3,
      packageName: 'tiny_app',
    ),
    const CodeNode(
      id: 'lib/src/user.dart#UserRepository',
      kind: CodeNodeKind.classDecl,
      name: 'UserRepository',
      location: location,
      loc: 30,
      packageName: 'tiny_app',
      annotations: [
        Annotation(patternId: 'repository', role: 'repository', confidence: 1),
      ],
    ),
    const CodeNode(
      id: 'lib/src/user.dart#UserRepository.new',
      kind: CodeNodeKind.constructor,
      name: 'new',
      qualifiedName: 'UserRepository.new',
      parentId: 'lib/src/user.dart#UserRepository',
      location: location,
      loc: 2,
    ),
    const CodeNode(
      id: 'lib/src/user.dart#UserRepository.save',
      kind: CodeNodeKind.method,
      name: 'save',
      qualifiedName: 'UserRepository.save',
      parentId: 'lib/src/user.dart#UserRepository',
      location: location,
      loc: 8,
    ),
    const CodeNode(
      id: 'lib/src/user.dart#UserRepository.name',
      kind: CodeNodeKind.getter,
      name: 'name',
      qualifiedName: 'UserRepository.name',
      parentId: 'lib/src/user.dart#UserRepository',
      location: location,
      loc: 1,
    ),
    const CodeNode(
      id: 'lib/src/user.dart#UserRepository.name=',
      kind: CodeNodeKind.setter,
      name: 'name=',
      qualifiedName: 'UserRepository.name=',
      parentId: 'lib/src/user.dart#UserRepository',
      location: location,
      loc: 1,
    ),
    const CodeNode(
      id: 'lib/src/user.dart#CachedUserRepository',
      kind: CodeNodeKind.classDecl,
      name: 'CachedUserRepository',
      parentId: 'lib/src/user.dart#UserRepository',
      location: location,
      loc: 12,
    ),
    const CodeNode(
      id: 'lib/src/user.dart#Loggable',
      kind: CodeNodeKind.mixinDecl,
      name: 'Loggable',
      location: location,
      loc: 5,
    ),
    const CodeNode(
      id: 'lib/src/user.dart#Role',
      kind: CodeNodeKind.enumDecl,
      name: 'Role',
      location: location,
      loc: 3,
    ),
    const CodeNode(
      id: 'lib/src/user.dart#UserX',
      kind: CodeNodeKind.extensionDecl,
      name: 'UserX',
      location: location,
      loc: 4,
    ),
    const CodeNode(
      id: 'lib/src/user.dart#UserId',
      kind: CodeNodeKind.extensionTypeDecl,
      name: 'UserId',
      location: location,
      loc: 2,
    ),
    const CodeNode(
      id: 'ghost:flutter:StatelessWidget',
      kind: CodeNodeKind.ghostParent,
      name: 'StatelessWidget',
      packageName: 'flutter',
    ),
    const CodeNode(
      id: 'lib/main.dart#App',
      kind: CodeNodeKind.classDecl,
      name: 'App',
      parentId: 'ghost:flutter:StatelessWidget',
      location: SourceLocation(
        filePath: 'lib/main.dart',
        startLine: 6,
        endLine: 12,
      ),
      loc: 6,
    ),
    const CodeNode(
      id: 'pkg:flutter',
      kind: CodeNodeKind.externalPackage,
      name: 'flutter',
      packageName: 'flutter',
    ),
  ];
  final graph = CodeGraph(
    project: ProjectInfo(
      generator: 'dart_code_3d test',
      source: const GitDescriptor(
        url: 'https://github.com/example/tiny_app',
        ref: 'main',
        commit: 'abc1234',
      ),
      createdAt: DateTime.utc(2026, 10, 3, 12),
      rules: const {
        'files.exclude_generated': true,
        'files.generated_patterns': ['**/*.g.dart'],
      },
      entryNodeId: 'lib/main.dart#main',
      stats: const GraphStats(files: 2, nodes: 14, links: 6, durationMs: 42),
    ),
    nodes: {for (final n in nodes) n.id: n},
    links: const [
      CodeLink(
        fromId: 'lib/main.dart#main',
        toId: 'lib/src/user.dart#UserRepository.new',
        kind: LinkKind.call,
      ),
      CodeLink(
        fromId: 'lib/src/user.dart#UserRepository.save',
        toId: 'lib/src/user.dart#UserRepository.name',
        kind: LinkKind.call,
        resolution: LinkResolution.byName,
        count: 3,
      ),
      CodeLink(
        fromId: 'lib/main.dart#App',
        toId: 'pkg:flutter',
        kind: LinkKind.import,
        resolution: LinkResolution.external,
      ),
      CodeLink(
        fromId: 'lib/src/user.dart#CachedUserRepository',
        toId: 'lib/src/user.dart#Loggable',
        kind: LinkKind.mixinLink,
      ),
      CodeLink(
        fromId: 'lib/src/user.dart#UserX',
        toId: 'lib/src/user.dart#UserRepository',
        kind: LinkKind.implementsLink,
        resolution: LinkResolution.ambiguous,
      ),
      CodeLink(
        fromId: 'lib/main.dart#App',
        toId: 'pkg:flutter',
        kind: LinkKind.extendsExternal,
        resolution: LinkResolution.external,
      ),
    ],
  );
  var i = 0;
  return CodeMap(
    graph: graph,
    placements: {
      for (final id in graph.nodes.keys)
        id: Placement(
          x: 1.5 * i,
          y: -0.25 * i,
          z: 0.1 * i,
          radius: 0.5 + 0.125 * i++,
        ),
    },
  );
}

/// A generated code map with [nodeCount] nodes (classes with methods, some
/// nested subclasses) and [linkCount] links, for size and speed checks.
CodeMap generatedMap({required int nodeCount, required int linkCount}) {
  final nodes = <String, CodeNode>{};
  String? currentClass;
  for (var i = 0; i < nodeCount; i++) {
    final file = 'lib/src/file_${i ~/ 50}.dart';
    final isClass = i % 10 == 0;
    final id = '$file#n$i';
    nodes[id] = CodeNode(
      id: id,
      kind: isClass ? CodeNodeKind.classDecl : CodeNodeKind.method,
      name: 'n$i',
      // Every third class is nested in the previous one.
      parentId: isClass ? (i % 30 == 0 ? null : currentClass) : currentClass,
      location: SourceLocation(filePath: file, startLine: i, endLine: i + 5),
      loc: 5 + i % 40,
    );
    if (isClass) currentClass = id;
  }
  final ids = nodes.keys.toList();
  final graph = CodeGraph(
    project: ProjectInfo(
      generator: 'dart_code_3d test',
      source: const LocalFolderDescriptor(name: 'generated'),
      createdAt: DateTime.utc(2026),
    ),
    nodes: nodes,
    links: [
      for (var i = 0; i < linkCount; i++)
        CodeLink(
          fromId: ids[(i * 7) % ids.length],
          toId: ids[(i * 13 + 1) % ids.length],
          kind: LinkKind.call,
          count: 1 + i % 3,
        ),
    ],
  );
  return CodeMap(
    graph: graph,
    placements: {
      for (final (i, id) in ids.indexed)
        id: Placement(x: i * 0.5, y: i * -0.3, z: i * 0.2, radius: 1 + i % 7),
    },
  );
}
