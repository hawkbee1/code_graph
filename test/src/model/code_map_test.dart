import 'package:code_graph/code_graph.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

import '../../helpers/tiny_map.dart';

void main() {
  group(Placement, () {
    test('exposes its position as a vector', () {
      const placement = Placement(x: 1, y: 2, z: 3, radius: 4);

      expect(placement.position, Vector3(1, 2, 3));
    });
  });

  group(CodeMap, () {
    test('throws $CodeGraphException when a node has no placement', () {
      final graph = tinyMap().graph;

      expect(
        () => CodeMap(graph: graph, placements: const {}),
        throwsA(isA<CodeGraphException>()),
      );
    });

    test('throws $CodeGraphException for a placement of an unknown node', () {
      final map = tinyMap();

      expect(
        () => CodeMap(
          graph: map.graph,
          placements: {
            ...map.placements,
            'x': const Placement(x: 0, y: 0, z: 0, radius: 1),
          },
        ),
        throwsA(
          isA<CodeGraphException>().having(
            (e) => e.message,
            'message',
            'placement for unknown node "x"',
          ),
        ),
      );
    });

    test('supports value equality', () {
      expect(tinyMap(), tinyMap());
    });
  });
}
