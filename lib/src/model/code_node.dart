import 'package:code_graph/src/model/code_node_kind.dart';
import 'package:equatable/equatable.dart';

/// Where a declaration is in the source.
class SourceLocation extends Equatable {
  /// Creates a location.
  const new({
    required this.filePath,
    required this.startLine,
    required this.endLine,
  });

  /// Reads a location written by [toJson].
  factory fromJson(Map<String, Object?> json) => SourceLocation(
    filePath: json['filePath']! as String,
    startLine: json['startLine']! as int,
    endLine: json['endLine']! as int,
  );

  /// Path relative to the analyzed root, with `/` separators.
  final String filePath;

  /// First line (1-based).
  final int startLine;

  /// Last line (1-based, inclusive).
  final int endLine;

  /// A JSON representation of this location.
  Map<String, Object?> toJson() => {
    'filePath': filePath,
    'startLine': startLine,
    'endLine': endLine,
  };

  @override
  List<Object?> get props => [filePath, startLine, endLine];
}

/// A design-pattern role detected on a node (none in the MVP).
class Annotation extends Equatable {
  /// Creates an annotation.
  const new({
    required this.patternId,
    required this.role,
    required this.confidence,
  });

  /// Reads an annotation written by [toJson].
  factory fromJson(Map<String, Object?> json) => Annotation(
    patternId: json['patternId']! as String,
    role: json['role']! as String,
    confidence: (json['confidence']! as num).toDouble(),
  );

  /// The detected pattern, e.g. `bloc`.
  final String patternId;

  /// The node's role in that pattern, e.g. `event`.
  final String role;

  /// How sure the detector is, from 0 to 1.
  final double confidence;

  /// A JSON representation of this annotation.
  Map<String, Object?> toJson() => {
    'patternId': patternId,
    'role': role,
    'confidence': confidence,
  };

  @override
  List<Object?> get props => [patternId, role, confidence];
}

/// One sphere of the 3D world: a declaration, a ghost parent or a package.
///
/// Ids are stable across analyses of the same code:
/// `<filePath>#<qualifiedName>` for declarations, `pkg:<name>` for external
/// packages and `ghost:<package>:<Class>` for ghost parents.
class CodeNode extends Equatable {
  /// Creates a node.
  const new({
    required this.id,
    required this.kind,
    required this.name,
    String? qualifiedName,
    this.parentId,
    this.location,
    this.loc = 0,
    this.packageName,
    this.annotations = const [],
  }) : qualifiedName = qualifiedName ?? name;

  /// Reads a node written by [toJson].
  factory fromJson(Map<String, Object?> json) {
    final location = json['location'] as Map<String, Object?>?;
    final annotations = (json['annotations'] as List<Object?>?) ?? const [];
    return CodeNode(
      id: json['id']! as String,
      kind: CodeNodeKind.values.byName(json['kind']! as String),
      name: json['name']! as String,
      qualifiedName: json['qualifiedName'] as String?,
      parentId: json['parentId'] as String?,
      location: location == null ? null : SourceLocation.fromJson(location),
      loc: (json['loc'] as int?) ?? 0,
      packageName: json['packageName'] as String?,
      annotations: [
        for (final a in annotations)
          Annotation.fromJson(a! as Map<String, Object?>),
      ],
    );
  }

  /// Stable id, unique in the graph.
  final String id;

  /// What the node stands for.
  final CodeNodeKind kind;

  /// Short name, e.g. `save`.
  final String name;

  /// Name qualified by its enclosing declarations, e.g. `UserRepository.save`.
  final String qualifiedName;

  /// Id of the containing node, or null at the top level of the world.
  final String? parentId;

  /// Where the declaration is; null for ghost parents and packages.
  final SourceLocation? location;

  /// Lines of code of the declaration itself (0 for ghost parents and
  /// packages).
  final int loc;

  /// The project package of a declaration, or the external package name.
  final String? packageName;

  /// Design-pattern roles detected on this node.
  final List<Annotation> annotations;

  /// Whether the user can fly into this node's sphere.
  bool get isEnterable => kind.isEnterable;

  /// Whether this node comes from outside the analyzed project.
  bool get isExternal => kind.isExternal;

  /// A JSON representation of this node (null fields are omitted).
  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    if (qualifiedName != name) 'qualifiedName': qualifiedName,
    if (parentId != null) 'parentId': parentId,
    if (location != null) 'location': location!.toJson(),
    if (loc != 0) 'loc': loc,
    if (packageName != null) 'packageName': packageName,
    if (annotations.isNotEmpty)
      'annotations': [for (final a in annotations) a.toJson()],
  };

  @override
  List<Object?> get props => [
    id,
    kind,
    name,
    qualifiedName,
    parentId,
    location,
    loc,
    packageName,
    annotations,
  ];
}
