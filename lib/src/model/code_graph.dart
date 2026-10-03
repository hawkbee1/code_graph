import 'package:code_graph/src/model/code_node.dart';
import 'package:code_graph/src/model/link.dart';
import 'package:code_graph/src/model/project_info.dart';
import 'package:equatable/equatable.dart';

/// Thrown when a [CodeGraph] or a code map is inconsistent.
class CodeGraphException implements Exception {
  /// Creates an exception with a human-readable [message].
  const new(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'CodeGraphException: $message';
}

/// The analyzed code: nodes (spheres) in a containment tree, and links.
///
/// The constructor validates the graph: node ids match their keys, every
/// parent and link endpoint exists, there is no containment cycle, and the
/// entry node exists.
class CodeGraph extends Equatable {
  /// Creates and validates a graph.
  new({
    required this.project,
    required Map<String, CodeNode> nodes,
    List<CodeLink> links = const [],
  }) : nodes = Map.unmodifiable(nodes),
       links = List.unmodifiable(links) {
    _validate();
  }

  /// Reads a graph written by [toJson].
  factory fromJson(Map<String, Object?> json) {
    final nodes = [
      for (final n in json['nodes']! as List<Object?>)
        CodeNode.fromJson(n! as Map<String, Object?>),
    ];
    return CodeGraph(
      project: ProjectInfo.fromJson(json['project']! as Map<String, Object?>),
      nodes: {for (final n in nodes) n.id: n},
      links: [
        for (final l in json['links']! as List<Object?>)
          CodeLink.fromJson(l! as Map<String, Object?>),
      ],
    );
  }

  /// Metadata about the analysis.
  final ProjectInfo project;

  /// Every node, by id, in insertion order.
  final Map<String, CodeNode> nodes;

  /// Every link.
  final List<CodeLink> links;

  late final Map<String?, List<CodeNode>> _children = () {
    final children = <String?, List<CodeNode>>{};
    for (final node in nodes.values) {
      (children[node.parentId] ??= []).add(node);
    }
    return children;
  }();

  late final Map<String, List<CodeLink>> _linksFrom = _indexLinks(
    (l) => l.fromId,
  );

  late final Map<String, List<CodeLink>> _linksTo = _indexLinks((l) => l.toId);

  Map<String, List<CodeLink>> _indexLinks(String Function(CodeLink) key) {
    final index = <String, List<CodeLink>>{};
    for (final link in links) {
      (index[key(link)] ??= []).add(link);
    }
    return index;
  }

  /// Nodes at the top level of the world, in insertion order.
  List<CodeNode> get topLevel => childrenOf(null);

  /// Direct children of [id] (of the world when null), in insertion order.
  List<CodeNode> childrenOf(String? id) => _children[id] ?? const [];

  /// Ancestors of [id], nearest first.
  List<CodeNode> ancestorsOf(String id) {
    final ancestors = <CodeNode>[];
    var parentId = nodes[id]?.parentId;
    while (parentId != null) {
      final parent = nodes[parentId]!;
      ancestors.add(parent);
      parentId = parent.parentId;
    }
    return ancestors;
  }

  /// Nesting depth of [id]: 0 at the top level.
  int depthOf(String id) => ancestorsOf(id).length;

  /// Links starting from [id].
  List<CodeLink> linksFrom(String id) => _linksFrom[id] ?? const [];

  /// Links pointing to [id].
  List<CodeLink> linksTo(String id) => _linksTo[id] ?? const [];

  /// A JSON representation of this graph (the engine's debug format; the
  /// shared file format is the `.fscene` written by `CodeMapCodec`).
  Map<String, Object?> toJson() => {
    'project': project.toJson(),
    'nodes': [for (final n in nodes.values) n.toJson()],
    'links': [for (final l in links) l.toJson()],
  };

  void _validate() {
    for (final MapEntry(:key, :value) in nodes.entries) {
      if (key != value.id) {
        throw CodeGraphException('node "${value.id}" is stored under "$key"');
      }
      final parentId = value.parentId;
      if (parentId != null && !nodes.containsKey(parentId)) {
        throw CodeGraphException(
          'node "$key" has an unknown parent "$parentId"',
        );
      }
    }
    for (final link in links) {
      for (final end in [link.fromId, link.toId]) {
        if (!nodes.containsKey(end)) {
          throw CodeGraphException(
            'link ${link.fromId} -> ${link.toId} references unknown node '
            '"$end"',
          );
        }
      }
    }
    // Containment cycles: walk up from every node, remembering finished
    // nodes so the whole check stays linear.
    final acyclic = <String>{};
    for (final start in nodes.keys) {
      final path = <String>{};
      String? current = start;
      while (current != null && !acyclic.contains(current)) {
        if (!path.add(current)) {
          throw CodeGraphException('containment cycle through "$current"');
        }
        current = nodes[current]!.parentId;
      }
      acyclic.addAll(path);
    }
    final entry = project.entryNodeId;
    if (entry != null && !nodes.containsKey(entry)) {
      throw CodeGraphException('unknown entry node "$entry"');
    }
  }

  @override
  List<Object?> get props => [project, nodes, links];
}
