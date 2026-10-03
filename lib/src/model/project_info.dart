import 'package:equatable/equatable.dart';

/// Where the analyzed code came from.
sealed class SourceDescriptor extends Equatable {
  const new();

  /// Reads a descriptor written by [toJson].
  factory fromJson(Map<String, Object?> json) => switch (json['type']) {
    'folder' => LocalFolderDescriptor(name: json['name']! as String),
    'git' => GitDescriptor(
      url: json['url']! as String,
      ref: json['ref'] as String?,
      commit: json['commit'] as String?,
    ),
    'zip' => ZipDescriptor(fileName: json['fileName']! as String),
    final type => throw FormatException('Unknown source type: $type'),
  };

  /// A short label for lists, e.g. `AltMe @ main`.
  String get label;

  /// A JSON representation of this descriptor.
  Map<String, Object?> toJson();
}

/// A local folder. Only its name is kept (no absolute path in shared files).
class LocalFolderDescriptor extends SourceDescriptor {
  /// Creates a folder descriptor.
  const new({required this.name});

  /// The folder's name.
  final String name;

  @override
  String get label => name;

  @override
  Map<String, Object?> toJson() => {'type': 'folder', 'name': name};

  @override
  List<Object?> get props => [name];
}

/// A git repository downloaded as an archive.
class GitDescriptor extends SourceDescriptor {
  /// Creates a git descriptor.
  const new({required this.url, this.ref, this.commit});

  /// The repository URL as entered by the user.
  final String url;

  /// The branch or tag, or null for the default branch.
  final String? ref;

  /// The commit, when known.
  final String? commit;

  @override
  String get label {
    final name = url.split('/').where((s) => s.isNotEmpty).last;
    final repo = name.endsWith('.git')
        ? name.substring(0, name.length - 4)
        : name;
    return ref == null ? repo : '$repo @ $ref';
  }

  @override
  Map<String, Object?> toJson() => {
    'type': 'git',
    'url': url,
    if (ref != null) 'ref': ref,
    if (commit != null) 'commit': commit,
  };

  @override
  List<Object?> get props => [url, ref, commit];
}

/// A zip file chosen by the user.
class ZipDescriptor extends SourceDescriptor {
  /// Creates a zip descriptor.
  const new({required this.fileName});

  /// The zip file's name.
  final String fileName;

  @override
  String get label => fileName;

  @override
  Map<String, Object?> toJson() => {'type': 'zip', 'fileName': fileName};

  @override
  List<Object?> get props => [fileName];
}

/// Counters describing an analysis.
class GraphStats extends Equatable {
  /// Creates stats.
  const new({
    this.files = 0,
    this.parseErrors = 0,
    this.nodes = 0,
    this.links = 0,
    this.durationMs = 0,
  });

  /// Reads stats written by [toJson]; missing counters are 0.
  factory fromJson(Map<String, Object?> json) => GraphStats(
    files: (json['files'] as int?) ?? 0,
    parseErrors: (json['parseErrors'] as int?) ?? 0,
    nodes: (json['nodes'] as int?) ?? 0,
    links: (json['links'] as int?) ?? 0,
    durationMs: (json['durationMs'] as int?) ?? 0,
  );

  /// Dart files analyzed.
  final int files;

  /// Files skipped because they could not be parsed.
  final int parseErrors;

  /// Code nodes produced.
  final int nodes;

  /// Links produced.
  final int links;

  /// Total analysis time in milliseconds.
  final int durationMs;

  /// A JSON representation of these stats.
  Map<String, Object?> toJson() => {
    'files': files,
    'parseErrors': parseErrors,
    'nodes': nodes,
    'links': links,
    'durationMs': durationMs,
  };

  @override
  List<Object?> get props => [files, parseErrors, nodes, links, durationMs];
}

/// Metadata about an analysis: what, when, with which rules.
class ProjectInfo extends Equatable {
  /// Creates project metadata.
  const new({
    required this.generator,
    required this.source,
    required this.createdAt,
    this.schemaVersion = currentSchemaVersion,
    this.rules = const {},
    this.entryNodeId,
    this.stats = const GraphStats(),
  });

  /// Reads metadata written by [toJson].
  factory fromJson(Map<String, Object?> json) => ProjectInfo(
    schemaVersion: json['schemaVersion']! as int,
    generator: json['generator']! as String,
    source: SourceDescriptor.fromJson(json['source']! as Map<String, Object?>),
    createdAt: DateTime.parse(json['createdAt']! as String),
    rules: (json['rules'] as Map<String, Object?>?) ?? const {},
    entryNodeId: json['entryNodeId'] as String?,
    stats: GraphStats.fromJson(
      (json['stats'] as Map<String, Object?>?) ?? const {},
    ),
  );

  /// The schema version this package writes. Readers refuse newer versions.
  static const currentSchemaVersion = 1;

  /// Version of the code map schema.
  final int schemaVersion;

  /// What produced the map, e.g. `dart_code_3d 0.1.0`.
  final String generator;

  /// Where the analyzed code came from.
  final SourceDescriptor source;

  /// When the analysis ran (UTC).
  final DateTime createdAt;

  /// The rule values used: rule id → JSON value (opaque to this package).
  final Map<String, Object?> rules;

  /// The node the camera starts in front of, if any.
  final String? entryNodeId;

  /// Analysis counters.
  final GraphStats stats;

  /// A JSON representation of this metadata.
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'generator': generator,
    'source': source.toJson(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'rules': rules,
    if (entryNodeId != null) 'entryNodeId': entryNodeId,
    'stats': stats.toJson(),
  };

  @override
  List<Object?> get props => [
    schemaVersion,
    generator,
    source,
    createdAt,
    rules,
    entryNodeId,
    stats,
  ];
}
