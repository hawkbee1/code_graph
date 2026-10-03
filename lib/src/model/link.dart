import 'package:equatable/equatable.dart';

/// What a link between two code nodes means.
enum LinkKind {
  /// A function, method or constructor call.
  call,

  /// An `import` directive.
  import,

  /// An `implements` clause.
  implementsLink,

  /// A `with` clause.
  mixinLink,

  /// `extends` of a class outside the project, when ghost parents are off.
  extendsExternal,
}

/// How sure the engine is about a link's target.
enum LinkResolution {
  /// The target was resolved from declared types.
  exact,

  /// The receiver type was unknown; the only project member with that name.
  byName,

  /// One of several project members with that name.
  ambiguous,

  /// A member of an external package.
  external,
}

/// A directed link from one code node to another.
class CodeLink extends Equatable {
  /// Creates a link from [fromId] to [toId].
  const new({
    required this.fromId,
    required this.toId,
    required this.kind,
    this.resolution = LinkResolution.exact,
    this.count = 1,
  });

  /// Reads a link written by [toJson].
  factory fromJson(Map<String, Object?> json) => CodeLink(
    fromId: json['from']! as String,
    toId: json['to']! as String,
    kind: LinkKind.values.byName(json['kind']! as String),
    resolution: LinkResolution.values.byName(json['resolution']! as String),
    count: json['count']! as int,
  );

  /// Id of the node the link starts from (e.g. the calling method).
  final String fromId;

  /// Id of the node the link points to (e.g. the called method).
  final String toId;

  /// What the link means.
  final LinkKind kind;

  /// How sure the engine is about [toId].
  final LinkResolution resolution;

  /// How many times this link occurs in the code (merged duplicates).
  final int count;

  /// A JSON representation of this link.
  Map<String, Object?> toJson() => {
    'from': fromId,
    'to': toId,
    'kind': kind.name,
    'resolution': resolution.name,
    'count': count,
  };

  @override
  List<Object?> get props => [fromId, toId, kind, resolution, count];
}
