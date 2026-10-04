import 'dart:convert';
import 'dart:io';

import 'package:code_graph/code_graph.dart';
import 'package:scene/scene.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

import '../../helpers/tiny_map.dart';

void main() {
  group(CodeMapCodec, () {
    const codec = CodeMapCodec();

    group('round trip', () {
      test('decode(encode(map)) returns the same tiny map', () {
        final map = tinyMap();

        expect(codec.decode(codec.encode(map)), map);
      });

      test('decodeFromJson(encodeToJson(map)) returns the same tiny map', () {
        final map = tinyMap();

        expect(codec.decodeFromJson(codec.encodeToJson(map)), map);
      });

      test('keeps the order of children', () {
        final graph = codec.decode(codec.encode(tinyMap())).graph;

        expect(
          graph
              .childrenOf('lib/src/user.dart#UserRepository')
              .map((n) => n.name),
          ['new', 'save', 'name', 'name=', 'CachedUserRepository'],
        );
      });

      test('handles 20,000 nodes and 60,000 links in under 10 s', () {
        final map = generatedMap(nodeCount: 20000, linkCount: 60000);
        final watch = Stopwatch()..start();

        final json = codec.encodeToJson(map);
        final encodeMs = watch.elapsedMilliseconds;
        final decoded = codec.decodeFromJson(json);
        final totalMs = watch.elapsedMilliseconds;

        final bytes = codec.encodeToBytes(map);
        final fileMs = watch.elapsedMilliseconds - totalMs;

        expect(decoded, map);
        expect(totalMs, lessThan(10000));
        expect(bytes.length, lessThan(5000000));
        // Recorded in the session log.
        // ignore: avoid_print
        print(
          'codec 20k nodes / 60k links: encode ${encodeMs}ms, decode '
          '${totalMs - encodeMs}ms, ${(json.length / 1e6).toStringAsFixed(1)} '
          'MB JSON, .dc3d file ${(bytes.length / 1e6).toStringAsFixed(1)} MB '
          '(${fileMs}ms)',
        );
      });
    });

    group('bytes', () {
      test('round-trips through a gzip-compressed file', () {
        final bytes = codec.encodeToBytes(tinyMap());

        expect(bytes.take(2), [0x1F, 0x8B]);
        expect(codec.decodeFromBytes(bytes), tinyMap());
      });

      test('reads plain .fscene JSON bytes', () {
        final bytes = File('test/fixtures/tiny.fscene').readAsBytesSync();

        expect(codec.decodeFromBytes(bytes), tinyMap());
      });

      test('throws $CodeMapFormatException for bytes that are not a map', () {
        for (final bytes in [
          <int>[0x1F, 0x8B, 1, 2, 3],
          utf8.encode('not json'),
          <int>[0xFF, 0xFE, 0x00],
          utf8.encode('{"fscene": 5, "nodes": {}, "roots": []}'),
        ]) {
          expect(
            () => codec.decodeFromBytes(bytes),
            throwsA(isA<CodeMapFormatException>()),
            reason: '$bytes',
          );
        }
      });
    });

    group('encode', () {
      test('matches the committed tiny.fscene byte for byte', () {
        expect(
          codec.encodeToJson(tinyMap()),
          File('test/fixtures/tiny.fscene').readAsStringSync(),
          reason:
              'run `dart run test/fixtures/write_fixtures.dart` after an '
              'intended format change and review the diff',
        );
      });

      test('is deterministic', () {
        expect(codec.encodeToJson(tinyMap()), codec.encodeToJson(tinyMap()));
      });

      test('declares the feature and the generator', () {
        final doc = codec.encode(tinyMap());

        expect(doc.featuresUsed, contains(CodeMapCodec.feature));
        expect(doc.generator, 'dart_code_3d test');
      });

      test('shares one sphere geometry and one material per used kind', () {
        final doc = codec.encode(tinyMap());

        expect(
          doc.resources.values.whereType<GeometryResource>(),
          hasLength(1),
        );
        expect(
          doc.resources.values.whereType<MaterialResource>().map((m) => m.name),
          unorderedEquals(CodeNodeKind.values.map((k) => k.name)),
        );
      });

      test('derives node transforms from placements relative to the parent '
          'radius', () {
        final map = tinyMap();
        final doc = codec.encode(map);
        NodeSpec named(String name) =>
            doc.nodes.values.singleWhere((n) => n.name == name);
        final parent = map.placements['lib/src/user.dart#UserRepository']!;
        final child = map.placements['lib/src/user.dart#UserRepository.save']!;

        final parentTransform =
            named('UserRepository').transform as TrsTransform;
        final childTransform = named('save').transform as TrsTransform;

        expect(parentTransform.translation, parent.position);
        expect(parentTransform.scale, Vector3.all(parent.radius));
        expect(
          childTransform.translation.distanceTo(child.position / parent.radius),
          lessThan(1e-6),
        );
        expect(
          childTransform.scale.x,
          closeTo(child.radius / parent.radius, 1e-6),
        );
      });

      test('nests the code nodes under one root', () {
        final doc = codec.encode(tinyMap());

        expect(doc.roots, hasLength(1));
        expect(doc.node(doc.roots.single)!.name, CodeMapCodec.rootName);
      });

      test('is accepted by readFscene', () {
        final json = File('test/fixtures/tiny.fscene').readAsStringSync();

        expect(readFscene(json).nodes, hasLength(15));
      });
    });

    group('decode', () {
      late SceneDocument doc;

      setUp(() => doc = codec.encode(tinyMap()));

      Map<String, PropertyValue> rootComponent(String type) => doc
          .node(doc.roots.single)!
          .components
          .singleWhere((c) => c.type == type)
          .properties;

      Matcher throwsFormat(Object message) => throwsA(
        isA<CodeMapFormatException>().having(
          (e) => e.message,
          'message',
          message,
        ),
      );

      test('throws $CodeMapFormatException for a scene without code map', () {
        final plain = SceneDocument()..createNode(name: 'cube', root: true);

        expect(
          () => codec.decode(plain),
          throwsFormat(contains('not a dart_code_3D code map')),
        );
      });

      test('throws $CodeMapFormatException for a newer schema version', () {
        rootComponent(CodeMapCodec.projectComponent)['schemaVersion'] =
            const IntValue(ProjectInfo.currentSchemaVersion + 1);

        expect(
          () => codec.decode(doc),
          throwsFormat(contains('Update the app')),
        );
      });

      test('throws $CodeMapFormatException for a missing field', () {
        rootComponent(CodeMapCodec.projectComponent).remove('info');

        expect(
          () => codec.decode(doc),
          throwsFormat('missing or invalid "info"'),
        );
      });

      test('throws $CodeMapFormatException for a link to an unknown index', () {
        rootComponent(CodeMapCodec.linksComponent)['to'] = ListValue([
          for (var i = 0; i < 6; i++) const IntValue(999),
        ]);

        expect(
          () => codec.decode(doc),
          throwsFormat('link to unknown node index 999'),
        );
      });

      test('throws $CodeMapFormatException for an unknown enum value', () {
        rootComponent(CodeMapCodec.linksComponent)['kindNames'] = ListValue([
          for (var i = 0; i < 5; i++) const StringValue('teleport'),
        ]);

        expect(
          () => codec.decode(doc),
          throwsFormat('unknown value "teleport"'),
        );
      });

      test('throws $CodeMapFormatException for an inconsistent graph', () {
        // Point the entry node at a node that does not exist.
        final info =
            rootComponent(CodeMapCodec.projectComponent)['info']!
                as StringValue;
        rootComponent(CodeMapCodec.projectComponent)['info'] = StringValue(
          info.value.replaceFirst('lib/main.dart#main', 'nowhere'),
        );

        expect(
          () => codec.decode(doc),
          throwsFormat(contains('Inconsistent code map')),
        );
      });

      test('reads a map without links component as having no links', () {
        doc
            .node(doc.roots.single)!
            .components
            .removeWhere((c) => c.type == CodeMapCodec.linksComponent);

        expect(codec.decode(doc).graph.links, isEmpty);
      });

      test('ignores child nodes that are not code nodes', () {
        final extra = doc.createNode(name: 'light');
        doc.node(doc.roots.single)!.children
          ..add(extra.id)
          ..add(const LocalId(1, 999));

        expect(codec.decode(doc), tinyMap());
      });

      test('reads integer placements and optional fields', () {
        final element = doc.nodes.values
            .singleWhere((n) => n.name == 'flutter')
            .components
            .singleWhere((c) => c.type == CodeMapCodec.elementComponent)
            .properties;
        element['radius'] = const IntValue(2);

        final placement = codec.decode(doc).placements['pkg:flutter']!;

        expect(placement.radius, 2);
      });

      test('throws $CodeMapFormatException for fields of the wrong type', () {
        Map<String, PropertyValue> element(String name) => doc.nodes.values
            .singleWhere((n) => n.name == name)
            .components
            .singleWhere((c) => c.type == CodeMapCodec.elementComponent)
            .properties;

        element('main')['loc'] = const StringValue('3');
        expect(
          () => codec.decode(doc),
          throwsFormat('missing or invalid "loc"'),
        );

        element('main')['loc'] = const IntValue(3);
        element('main')['x'] = const StringValue('0');
        expect(() => codec.decode(doc), throwsFormat('missing or invalid "x"'));

        element('main')['x'] = const DoubleValue(0);
        rootComponent(CodeMapCodec.linksComponent).remove('from');
        expect(
          () => codec.decode(doc),
          throwsFormat('missing or invalid "from"'),
        );
      });

      test('describes the problem in toString', () {
        expect(
          const CodeMapFormatException('boom').toString(),
          'CodeMapFormatException: boom',
        );
      });
    });
  });
}
