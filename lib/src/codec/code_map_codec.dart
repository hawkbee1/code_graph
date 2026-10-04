import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:code_graph/src/codec/kind_colors.dart';
import 'package:code_graph/src/model/code_graph.dart';
import 'package:code_graph/src/model/code_map.dart';
import 'package:code_graph/src/model/code_node.dart';
import 'package:code_graph/src/model/code_node_kind.dart';
import 'package:code_graph/src/model/link.dart';
import 'package:code_graph/src/model/project_info.dart';
import 'package:code_graph/src/stable_hash.dart';
import 'package:scene/scene.dart';
import 'package:vector_math/vector_math.dart';

/// Thrown when a scene document is not a readable code map.
class CodeMapFormatException implements Exception {
  /// Creates an exception with a human-readable [message].
  const new(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'CodeMapFormatException: $message';
}

/// Converts a [CodeMap] to a flutter_scene [SceneDocument] (`.fscene`) and
/// back.
///
/// The document nests one node per code node exactly like the containment
/// tree, under a root node named `dc3d root`. Each node has a `mesh`
/// component (one shared sphere geometry, one material per kind) and a
/// `dc3d.code_element` component holding the node's data and its exact
/// placement. Node transforms are derived from the placements for renderers
/// and editors; decoding reads the exact values from the components, because
/// scene transforms are single precision and scale is inherited by children.
/// The root carries `dc3d.project` (metadata) and `dc3d.code_links` (links,
/// stored as columns of node indices to keep files small).
class CodeMapCodec {
  /// Creates a codec.
  const new();

  /// Feature flag every code map document declares in `featuresUsed`.
  static const feature = 'dc3d.v1';

  /// Name of the root node.
  static const rootName = 'dc3d root';

  /// Type of the per-node component.
  static const elementComponent = 'dc3d.code_element';

  /// Type of the root's metadata component.
  static const projectComponent = 'dc3d.project';

  /// Type of the root's links component.
  static const linksComponent = 'dc3d.code_links';

  // Session salt of the id allocator: a fixed value keeps ids deterministic.
  static const _idSession = 0x0DC3D001;

  /// Extension of code map files: a gzip-compressed `.fscene`.
  ///
  /// Gzip makes them ~25 times smaller (the JSON is verbose); `gunzip`
  /// gives back a plain `.fscene` the Flutter Scene Editor opens.
  static const fileExtension = 'dc3d';

  /// Encodes [map] as a code map file: gzip-compressed `.fscene` JSON.
  Uint8List encodeToBytes(CodeMap map) =>
      const GZipEncoder().encodeBytes(utf8.encode(encodeToJson(map)));

  /// Decodes a code map file written by [encodeToBytes], or plain `.fscene`
  /// JSON bytes (gzip is detected from its magic number).
  ///
  /// Throws a [CodeMapFormatException] for anything that is not a readable
  /// code map, including corrupt or non-gzip binary data.
  CodeMap decodeFromBytes(List<int> bytes) {
    final isGzip = bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B;
    try {
      final json = utf8.decode(
        isGzip ? const GZipDecoder().decodeBytes(bytes, verify: true) : bytes,
      );
      return decodeFromJson(json);
    } on CodeMapFormatException {
      rethrow;
      // Files are untrusted input: flutter_scene's reader throws TypeErrors on
      // malformed documents, so every failure must become a format error.
    } catch (e) {
      throw CodeMapFormatException('This file is not a readable code map: $e');
    }
  }

  /// Encodes [map] as `.fscene` JSON.
  String encodeToJson(CodeMap map) => writeFscene(encode(map));

  /// Decodes `.fscene` JSON written by [encodeToJson].
  ///
  /// Throws a [CodeMapFormatException] when [source] is not a code map; it
  /// may throw flutter_scene's own errors when it is not a scene document at
  /// all. Use [decodeFromBytes] for files, which reports every failure as a
  /// [CodeMapFormatException].
  CodeMap decodeFromJson(String source) => decode(readFscene(source));

  /// Encodes [map] as a scene document. The result is deterministic: the
  /// same map always gives the same document.
  SceneDocument encode(CodeMap map) {
    final graph = map.graph;
    final doc = SceneDocument(
      documentId: _documentId(graph),
      allocator: IdAllocator(session: _idSession),
    )..generator = graph.project.generator;
    doc.featuresUsed.add(feature);

    final geometry = doc.addResource(
      GeometryResource(
        doc.newId(),
        procedural: SphereGeometrySpec(radius: 1, segments: 24, rings: 12),
      ),
    );
    final usedKinds = {for (final n in graph.nodes.values) n.kind};
    final materials = <CodeNodeKind, LocalId>{};
    for (final kind in CodeNodeKind.values.where(usedKinds.contains)) {
      final color = kindColors[kind]!;
      materials[kind] = doc
          .addResource(
            MaterialResource(
              doc.newId(),
              type: 'physicallyBased',
              name: kind.name,
              properties: {
                'baseColor': ColorValue(color.r, color.g, color.b, 1),
              },
            ),
          )
          .id;
    }

    final root = doc.createNode(name: rootName, root: true);
    final indices = <String, int>{};

    void addChildren(NodeSpec parentSpec, String? parentId, double scale) {
      for (final node in graph.childrenOf(parentId)) {
        final placement = map.placements[node.id]!;
        indices[node.id] = indices.length;
        final spec = doc.createNode(
          name: node.name,
          transform: TrsTransform(
            translation: placement.position / scale,
            scale: Vector3.all(placement.radius / scale),
          ),
          components: [
            ComponentSpec(
              'mesh',
              properties: {
                'geometry': ResourceRefValue(geometry.id),
                'material': ResourceRefValue(materials[node.kind]!),
              },
            ),
            ComponentSpec(
              elementComponent,
              properties: _elementProperties(
                node,
                placement,
                indices[node.id]!,
              ),
            ),
          ],
        );
        parentSpec.children.add(spec.id);
        addChildren(spec, node.id, placement.radius);
      }
    }

    addChildren(root, null, 1);
    root.components
      ..add(
        ComponentSpec(
          projectComponent,
          properties: {
            'schemaVersion': IntValue(graph.project.schemaVersion),
            'generator': StringValue(graph.project.generator),
            'info': StringValue(jsonEncode(graph.project.toJson())),
          },
        ),
      )
      ..add(
        ComponentSpec(
          linksComponent,
          properties: _linkProperties(graph.links, indices),
        ),
      );
    return doc;
  }

  /// Decodes a document written by [encode].
  CodeMap decode(SceneDocument doc) {
    final root = doc.roots
        .map(doc.node)
        .whereType<NodeSpec>()
        .where((n) => _component(n, projectComponent) != null)
        .firstOrNull;
    if (root == null) {
      throw const CodeMapFormatException(
        'This file is not a dart_code_3D code map (no $projectComponent).',
      );
    }
    final projectProps = _component(root, projectComponent)!.properties;
    final version = _int(projectProps, 'schemaVersion');
    if (version > ProjectInfo.currentSchemaVersion) {
      throw CodeMapFormatException(
        'This code map uses schema version $version; this app reads up to '
        '${ProjectInfo.currentSchemaVersion}. Update the app.',
      );
    }
    final project = ProjectInfo.fromJson(
      jsonDecode(_string(projectProps, 'info')) as Map<String, Object?>,
    );

    final nodes = <String, CodeNode>{};
    final placements = <String, Placement>{};
    final idsByIndex = <int, String>{};

    void readChildren(NodeSpec parentSpec, String? parentId) {
      for (final childId in parentSpec.children) {
        final spec = doc.node(childId);
        final element = spec == null
            ? null
            : _component(spec, elementComponent);
        if (spec == null || element == null) continue;
        final props = element.properties;
        final node = _readNode(props, parentId);
        nodes[node.id] = node;
        placements[node.id] = Placement(
          x: _double(props, 'x'),
          y: _double(props, 'y'),
          z: _double(props, 'z'),
          radius: _double(props, 'radius'),
        );
        idsByIndex[_int(props, 'index')] = node.id;
        readChildren(spec, node.id);
      }
    }

    readChildren(root, null);
    final linksSpec = _component(root, linksComponent);
    final links = linksSpec == null
        ? const <CodeLink>[]
        : _readLinks(linksSpec.properties, idsByIndex);
    try {
      return CodeMap(
        graph: CodeGraph(project: project, nodes: nodes, links: links),
        placements: placements,
      );
    } on CodeGraphException catch (e) {
      throw CodeMapFormatException('Inconsistent code map: ${e.message}');
    }
  }

  static DocumentId _documentId(CodeGraph graph) {
    final identity =
        '${jsonEncode(graph.project.toJson())}|${graph.nodes.length}|'
        '${graph.links.length}';
    final bytes = Uint8List(16);
    final view = ByteData.view(bytes.buffer);
    for (var i = 0; i < 4; i++) {
      view.setUint32(i * 4, stableHash(identity, seed: 0x811C9DC5 + i));
    }
    // UUIDv4 layout, like DocumentId.generate.
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    return DocumentId(bytes);
  }

  static Map<String, PropertyValue> _elementProperties(
    CodeNode node,
    Placement placement,
    int index,
  ) {
    final location = node.location;
    return {
      'index': IntValue(index),
      'id': StringValue(node.id),
      'kind': StringValue(node.kind.name),
      'name': StringValue(node.name),
      'qualifiedName': StringValue(node.qualifiedName),
      if (location != null) ...{
        'filePath': StringValue(location.filePath),
        'startLine': IntValue(location.startLine),
        'endLine': IntValue(location.endLine),
      },
      'loc': IntValue(node.loc),
      if (node.packageName != null)
        'packageName': StringValue(node.packageName!),
      'enterable': BoolValue(node.isEnterable),
      'external': BoolValue(node.isExternal),
      'x': DoubleValue(placement.x),
      'y': DoubleValue(placement.y),
      'z': DoubleValue(placement.z),
      'radius': DoubleValue(placement.radius),
      if (node.annotations.isNotEmpty)
        'annotations': ListValue([
          for (final a in node.annotations)
            MapValue({
              'patternId': StringValue(a.patternId),
              'role': StringValue(a.role),
              'confidence': DoubleValue(a.confidence),
            }),
        ]),
    };
  }

  static CodeNode _readNode(Map<String, PropertyValue> props, String? parent) {
    final filePath = props['filePath'];
    final annotations = props['annotations'];
    return CodeNode(
      id: _string(props, 'id'),
      kind: _enum(CodeNodeKind.values, _string(props, 'kind')),
      name: _string(props, 'name'),
      qualifiedName: _string(props, 'qualifiedName'),
      parentId: parent,
      location: filePath is StringValue
          ? SourceLocation(
              filePath: filePath.value,
              startLine: _int(props, 'startLine'),
              endLine: _int(props, 'endLine'),
            )
          : null,
      loc: _int(props, 'loc'),
      packageName: switch (props['packageName']) {
        StringValue(:final value) => value,
        _ => null,
      },
      annotations: [
        if (annotations is ListValue)
          for (final a in annotations.values.whereType<MapValue>())
            Annotation(
              patternId: _string(a.values, 'patternId'),
              role: _string(a.values, 'role'),
              confidence: _double(a.values, 'confidence'),
            ),
      ],
    );
  }

  static Map<String, PropertyValue> _linkProperties(
    List<CodeLink> links,
    Map<String, int> indices,
  ) {
    ListValue ints(Iterable<int> values) =>
        ListValue([for (final v in values) IntValue(v)]);
    return {
      'kindNames': ListValue([
        for (final k in LinkKind.values) StringValue(k.name),
      ]),
      'resolutionNames': ListValue([
        for (final r in LinkResolution.values) StringValue(r.name),
      ]),
      'from': ints(links.map((l) => indices[l.fromId]!)),
      'to': ints(links.map((l) => indices[l.toId]!)),
      'kind': ints(links.map((l) => l.kind.index)),
      'resolution': ints(links.map((l) => l.resolution.index)),
      'count': ints(links.map((l) => l.count)),
    };
  }

  static List<CodeLink> _readLinks(
    Map<String, PropertyValue> props,
    Map<int, String> idsByIndex,
  ) {
    List<int> ints(String key) => [
      for (final v in _list(props, key)) (v as IntValue).value,
    ];
    List<String> strings(String key) => [
      for (final v in _list(props, key)) (v as StringValue).value,
    ];
    final kindNames = strings('kindNames');
    final resolutionNames = strings('resolutionNames');
    final from = ints('from');
    final to = ints('to');
    final kind = ints('kind');
    final resolution = ints('resolution');
    final count = ints('count');
    String id(int index) =>
        idsByIndex[index] ??
        (throw CodeMapFormatException('link to unknown node index $index'));
    return [
      for (var i = 0; i < from.length; i++)
        CodeLink(
          fromId: id(from[i]),
          toId: id(to[i]),
          kind: _enum(LinkKind.values, kindNames[kind[i]]),
          resolution: _enum(
            LinkResolution.values,
            resolutionNames[resolution[i]],
          ),
          count: count[i],
        ),
    ];
  }

  static ComponentSpec? _component(NodeSpec node, String type) =>
      node.components.where((c) => c.type == type).firstOrNull;

  static Never _missing(String key) =>
      throw CodeMapFormatException('missing or invalid "$key"');

  static String _string(Map<String, PropertyValue> props, String key) =>
      switch (props[key]) {
        StringValue(:final value) => value,
        _ => _missing(key),
      };

  static int _int(Map<String, PropertyValue> props, String key) =>
      switch (props[key]) {
        IntValue(:final value) => value,
        _ => _missing(key),
      };

  static double _double(Map<String, PropertyValue> props, String key) =>
      switch (props[key]) {
        DoubleValue(:final value) => value,
        IntValue(:final value) => value.toDouble(),
        _ => _missing(key),
      };

  static List<PropertyValue> _list(
    Map<String, PropertyValue> props,
    String key,
  ) => switch (props[key]) {
    ListValue(:final values) => values,
    _ => _missing(key),
  };

  static T _enum<T extends Enum>(List<T> values, String name) =>
      values.asNameMap()[name] ??
      (throw CodeMapFormatException('unknown value "$name"'));
}
